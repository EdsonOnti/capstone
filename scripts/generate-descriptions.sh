#!/bin/bash
#
# generate-descriptions.sh
# Genera descripciones IA (S6 Bedrock) para TODOS los productos con status=ACTIVE
#
# Uso:
#   bash scripts/generate-descriptions.sh
#

set -euo pipefail

STACK_NAME="${STACK_NAME:-edson-martin-ontiveros-lima}"
REGION="${AWS_REGION:-us-east-1}"

echo "📝 Generando descripciones IA para productos ACTIVE..."
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
S6_BEDROCK=$(echo "$STACK_OUTPUT" | jq -r '.[] | select(.OutputKey=="GenerateDescriptionUrl").OutputValue')

if [ -z "$API" ] || [ "$API" = "null" ]; then
    echo "❌ No se encontraron URLs del stack"
    exit 1
fi

echo "📡 URLs obtenidas:"
echo "   API: $API"
echo "   S6 (Bedrock): $S6_BEDROCK"
echo ""

# Get all products with status=ACTIVE
echo "📋 Obteniendo productos con status=ACTIVE..."
PRODUCTS=$(curl -s "${API%/}/products" | jq '.products[] | select(.status=="ACTIVE" or .status==null) | .productId' -r)

if [ -z "$PRODUCTS" ]; then
    echo "⚠️  No hay productos ACTIVE"
    exit 0
fi

COUNT=$(echo "$PRODUCTS" | wc -l)
echo "✅ Encontrados $COUNT productos ACTIVE"
echo ""

# Counter
PROCESSED=0
SUCCESS=0
FAILED=0

# Process each product
for PID in $PRODUCTS; do
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔄 Procesando: $PID"

    # Get product
    PRODUCT=$(curl -s "${API%/}/products/${PID}")
    NAME=$(echo "$PRODUCT" | jq -r '.name // "N/A"')

    echo "   Nombre: $NAME"

    # Call S6 Bedrock
    echo "   ➡️  Generando descripción con S6 (Bedrock)..."
    S6_RESULT=$(curl -s -X POST "$S6_BEDROCK" \
      -H "Content-Type: application/json" \
      -d "{\"productId\":\"$PID\",\"tone\":\"professional\",\"save\":true}")

    DESCRIPTION=$(echo "$S6_RESULT" | jq -r '.description // empty')

    if [ -z "$DESCRIPTION" ]; then
        echo "   ❌ Error generando descripción"
        FAILED=$((FAILED + 1))
    else
        echo "   ✅ Descripción generada (${#DESCRIPTION} caracteres)"
        SUCCESS=$((SUCCESS + 1))
    fi

    PROCESSED=$((PROCESSED + 1))
    echo ""
done

echo ""
echo "=================================================="
echo "✅ GENERACIÓN COMPLETADA"
echo "=================================================="
echo ""
echo "📊 Resultados:"
echo "   Total procesados: $PROCESSED"
echo "   ✅ Éxitosos:      $SUCCESS"
echo "   ❌ Fallidos:      $FAILED"
echo ""
echo "🔗 Ver resultados en el frontend:"
echo "   https://d33x5tfyjkvcnh.cloudfront.net"
echo ""
