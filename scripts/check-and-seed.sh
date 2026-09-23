#!/bin/bash
#
# Check y Seed: Verifica cuántos productos hay en DynamoDB y, si está vacía, siembra.
#
# Uso:
#   bash scripts/check-and-seed.sh
#
# Si la tabla tiene 0 productos → siembra automáticamente
# Si la tabla tiene datos → solo muestra el estado
#

set -euo pipefail

STACK_NAME="${STACK_NAME:-edson-martin-ontiveros-lima}"
REGION="${AWS_REGION:-us-east-1}"

echo "📋 Verificando estado de DynamoDB..."
echo ""

# Get table name from CloudFormation
TABLE_NAME=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$REGION" \
    --query "Stacks[0].Outputs[?OutputKey=='ProductsTableName'].OutputValue" \
    --output text 2>/dev/null || echo "")

if [ -z "$TABLE_NAME" ] || [ "$TABLE_NAME" = "None" ]; then
    echo "❌ No se encontró ProductsTableName en el stack $STACK_NAME"
    echo "    ¿Ejecutaste 'bash scripts/deploy-sandbox.sh' primero?"
    exit 1
fi

echo "📊 Tabla: $TABLE_NAME"

# Count items
COUNT=$(aws dynamodb scan \
    --table-name "$TABLE_NAME" \
    --region "$REGION" \
    --select COUNT \
    --output text 2>/dev/null || echo "0")

echo "📦 Productos: $COUNT"
echo ""

if [ "$COUNT" -eq 0 ]; then
    echo "⚠️  La tabla está VACÍA. Sembrando 4 productos..."
    echo ""

    # Run seed
    if [ -f "ai/seed/seed-products.sh" ]; then
        bash ai/seed/seed-products.sh
        echo ""
        echo "✅ Seed completado"
        echo ""

        # Verify
        NEW_COUNT=$(aws dynamodb scan \
            --table-name "$TABLE_NAME" \
            --region "$REGION" \
            --select COUNT \
            --output text 2>/dev/null || echo "0")
        echo "📦 Productos ahora: $NEW_COUNT"
    else
        echo "❌ No encontré ai/seed/seed-products.sh"
        exit 1
    fi
else
    echo "✅ La tabla ya tiene datos (probablemente del deploy anterior)"
    echo "   Los datos se preservan entre deploys de CloudFormation."
    echo ""
    echo "📝 Para ver los productos:"
    echo "   API_URL=\$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query \"Stacks[0].Outputs[?OutputKey=='ApiUrl'].OutputValue\" --output text)"
    echo "   curl -s \"\${API_URL%/}/products\" | python3 -m json.tool"
fi

echo ""
echo "=========================================="
