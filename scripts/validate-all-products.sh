#!/bin/bash
#
# validate-all-products.sh
# Ejecuta S1 → S2 → S6 sobre TODOS los productos en DynamoDB
# Asigna status = APPROVED o PENDING_REVIEW automáticamente
#
# Uso:
#   bash scripts/validate-all-products.sh
#

set -euo pipefail

STACK_NAME="${STACK_NAME:-edson-martin-ontiveros-lima}"
REGION="${AWS_REGION:-us-east-1}"

echo "🔍 Validando TODOS los productos en DynamoDB..."
echo "=================================================="
echo ""

# Get all outputs
STACK_OUTPUT=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$REGION" \
    --query 'Stacks[0].Outputs' \
    --output json)

# Extract URLs
API=$(echo "$STACK_OUTPUT" | jq -r '.[] | select(.OutputKey=="ApiUrl").OutputValue')
S1=$(echo "$STACK_OUTPUT" | jq -r '.[] | select(.OutputKey=="EnrichLabelsUrl").OutputValue')
S2=$(echo "$STACK_OUTPUT" | jq -r '.[] | select(.OutputKey=="ModerateImageUrl").OutputValue')
S6=$(echo "$STACK_OUTPUT" | jq -r '.[] | select(.OutputKey=="ValidateQualityUrl").OutputValue')

if [ -z "$API" ] || [ "$API" = "null" ]; then
    echo "❌ No se encontraron URLs del stack"
    exit 1
fi

echo "📡 URLs obtenidas:"
echo "   API: $API"
echo "   S1:  $S1"
echo "   S2:  $S2"
echo "   S6:  $S6"
echo ""

# Get all product IDs
echo "📋 Obteniendo todos los productos..."
PIDS=$(curl -s "${API%/}/products" | jq -r '.products[].productId')

if [ -z "$PIDS" ]; then
    echo "⚠️  No hay productos"
    exit 0
fi

COUNT=$(echo "$PIDS" | wc -l)
echo "✅ Encontrados $COUNT productos"
echo ""

# Counter
VALIDATED=0
APPROVED=0
PENDING=0

# Process each product
for PID in $PIDS; do
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔄 Validando: $PID"

    # Get product
    PRODUCT=$(curl -s "${API%/}/products/${PID}")
    IMAGE_URL=$(echo "$PRODUCT" | jq -r '.imageUrl // empty')

    if [ -z "$IMAGE_URL" ]; then
        echo "⏭️  Sin imagen, saltando (status no cambió)"
        continue
    fi

    echo "   Imagen: $IMAGE_URL"

    # Call S1
    echo "   ➡️  S1 (EnrichLabels)..."
    S1_RESULT=$(curl -s -X POST "$S1" \
      -H "Content-Type: application/json" \
      -d "{\"productId\":\"$PID\",\"imageUrl\":\"$IMAGE_URL\"}")

    # Call S2
    echo "   ➡️  S2 (ModerateImage)..."
    S2_RESULT=$(curl -s -X POST "$S2" \
      -H "Content-Type: application/json" \
      -d "{\"productId\":\"$PID\",\"imageUrl\":\"$IMAGE_URL\"}")

    # Call S6 (obtiene el resultado final)
    echo "   ➡️  S6 (ValidateQuality)..."
    S6_RESULT=$(curl -s -X POST "$S6" \
      -H "Content-Type: application/json" \
      -d "{\"productId\":\"$PID\"}")

    STATUS=$(echo "$S6_RESULT" | jq -r '.overall.status // "ERROR"')
    REASON=$(echo "$S6_RESULT" | jq -r '.overall.reason // ""')

    echo "   ✅ Status asignado: $STATUS"
    if [ -n "$REASON" ]; then
        echo "   📝 Motivo: $REASON"
    fi

    VALIDATED=$((VALIDATED + 1))
    if [ "$STATUS" = "ACTIVE" ]; then
        APPROVED=$((APPROVED + 1))
        echo "   🎉 APROBADO - Visible en cliente"
    else
        PENDING=$((PENDING + 1))
        echo "   ⏳ PENDIENTE - Requiere revisión"
    fi

    echo ""
done

echo ""
echo "=================================================="
echo "✅ VALIDACIÓN COMPLETADA"
echo "=================================================="
echo ""
echo "📊 Resultados:"
echo "   Total procesados: $VALIDATED"
echo "   ✅ Aprobados:     $APPROVED"
echo "   ⏳ Pendientes:    $PENDING"
echo ""
echo "🔗 Ver resultados en el frontend:"
echo "   https://d33x5tfyjkvcnh.cloudfront.net"
echo ""
