"""
QUALITY GATE · Validación de moderación de imágenes

Flujo:
  POST /validate-quality
    body: { "productId": "..." }

    1. Lee moderationStatus del producto (de S2 - Rekognition).
    2. Si moderationStatus = "APPROVED" → status = "ACTIVE" (visible en cliente)
    3. Si moderationStatus = "FLAGGED" → status = "PENDING_REVIEW" (revisión manual)
    4. Retorna: { moderation_status, passed, reason }

Servicio: Lee datos de S2 (ModerateImage) ejecutado previamente.
Dominio AIF-C01: D3 — Model Evaluation and Performance Monitoring.
"""

import json
import os

import boto3

PRODUCTS_TABLE = os.environ["PRODUCTS_TABLE"]

table = boto3.resource("dynamodb").Table(PRODUCTS_TABLE)


def _response(status, body):
    return {
        "statusCode": status,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type, Authorization",
        },
        "body": json.dumps(body, ensure_ascii=False),
    }


def lambda_handler(event, context):
    print("Event:", json.dumps(event))

    # Handle CORS preflight
    method = event.get("requestContext", {}).get("http", {}).get("method", "POST")
    if method == "OPTIONS":
        return {
            "statusCode": 200,
            "headers": {
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
                "Access-Control-Allow-Headers": "Content-Type, Authorization",
            },
            "body": "",
        }

    # Parse body
    try:
        body = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return _response(400, {"error": "Body JSON inválido."})

    product_id = body.get("productId")
    if not product_id:
        return _response(400, {"error": "Falta productId en body."})

    # Read product from DynamoDB
    try:
        response = table.get_item(Key={"productId": product_id})
        item = response.get("Item")
        if not item:
            return _response(404, {"error": f"Producto {product_id} no encontrado."})
    except Exception as e:
        print(f"DynamoDB read error: {repr(e)}")
        return _response(500, {"error": "Error al leer DynamoDB."})

    # Extract moderation status from S2
    moderation_status = item.get("moderationStatus", "UNKNOWN")

    # SIMPLE LOGIC: Solo se basa en moderationStatus
    # APPROVED → ACTIVE (visible en cliente)
    # FLAGGED → PENDING_REVIEW (requiere revisión manual)
    moderation_passed = moderation_status == "APPROVED"
    new_status = "ACTIVE" if moderation_passed else "PENDING_REVIEW"

    # Build reason
    reason = ""
    if not moderation_passed:
        reason = f"Image flagged ({moderation_status})."

    # Actualizar producto con status
    try:
        if moderation_passed:
            # Si pasa, remover reviewReason
            table.update_item(
                Key={"productId": product_id},
                UpdateExpression="SET #status = :status REMOVE reviewReason",
                ExpressionAttributeNames={"#status": "status"},
                ExpressionAttributeValues={":status": new_status},
            )
        else:
            # Si no pasa, guardar motivo
            table.update_item(
                Key={"productId": product_id},
                UpdateExpression="SET #status = :status, reviewReason = :reason",
                ExpressionAttributeNames={"#status": "status"},
                ExpressionAttributeValues={":status": new_status, ":reason": reason},
            )
        print(f"✅ Updated {product_id} status to {new_status}")
    except Exception as e:
        print(f"❌ Error updating status: {repr(e)}")
        # No fallar la respuesta si la actualización falla

    return _response(
        200,
        {
            "productId": product_id,
            "moderation_status": moderation_status,
            "overall": {
                "passed": moderation_passed,
                "status": new_status,
                "reason": reason,
            },
        },
    )
