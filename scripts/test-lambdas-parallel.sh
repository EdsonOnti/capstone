#!/bin/bash
#
# Test Lambdas (PARALELO): Ejecuta S1-S5 al mismo tiempo en un producto
#
# Uso:
#   bash scripts/test-lambdas-parallel.sh [productId]
#
# Si no pasas productId, usa el primer producto del seed.
#
# Diferencia con test-lambdas.sh:
#   - test-lambdas.sh: Secuencial (S1 → espera → S2 → espera → S3 → espera → S5)
#   - test-lambdas-parallel.sh: Paralelo (S1, S2, S3, S5 al mismo tiempo)
#

set -euo pipefail

STACK_NAME="${STACK_NAME:-edson-martin-ontiveros-lima}"
REGION="${AWS_REGION:-us-east-1}"

echo "🧪 Test Lambdas S1-S5 (PARALELO)"
echo "==========================================="
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
S3=$(echo "$STACK_OUTPUT" | jq -r '.[] | select(.OutputKey=="AnalyzeSentimentUrl").OutputValue')
S5=$(echo "$STACK_OUTPUT" | jq -r '.[] | select(.OutputKey=="SynthesizeVoiceUrl").OutputValue')

if [ -z "$API" ] || [ "$API" = "null" ]; then
    echo "❌ No se encontraron URLs del stack"
    exit 1
fi

echo "📡 URLs obtenidas:"
echo "   API: $API"
echo "   S1:  $S1"
echo "   S2:  $S2"
echo "   S3:  $S3"
echo "   S5:  $S5"
echo ""

# Get product ID (primero del seed o del parámetro)
if [ -n "${1:-}" ]; then
    PID="$1"
else
    # Get first product from API
    PID=$(curl -s "${API%/}/products" | jq -r '.[0].productId')
fi

if [ -z "$PID" ] || [ "$PID" = "null" ]; then
    echo "❌ No hay productos. Ejecuta: bash scripts/check-and-seed.sh"
    exit 1
fi

IMG_URL="https://via.placeholder.com/300?text=TestProduct"

echo "🎯 Producto para test: $PID"
echo ""

# Test 1: Ver estado inicial
echo "1️⃣  ESTADO INICIAL (antes de ejecutar Lambdas)"
echo "-------------------------------------------"
curl -s "${API%/}/products" | jq ".[] | select(.productId==\"$PID\") | {name, aiLabels, moderationStatus, reviewSentiment, audioUrl}"
echo ""

# Test 2: Ejecutar S1, S2, S3, S5 en PARALELO
echo "2️⃣  EJECUTANDO S1, S2, S3, S5 EN PARALELO"
echo "-------------------------------------------"

# Crear temporal files para guardar resultados
TMP_S1=$(mktemp)
TMP_S2=$(mktemp)
TMP_S3=$(mktemp)
TMP_S5=$(mktemp)

# Trap para limpiar temp files
trap "rm -f $TMP_S1 $TMP_S2 $TMP_S3 $TMP_S5" EXIT

echo "⏱️  Tiempo inicial: $(date '+%H:%M:%S')"
echo ""

# Ejecutar las 4 en background
(
    echo "→ S1 enviado..."
    curl -s -X POST "$S1" \
      -H "Content-Type: application/json" \
      -d "{\"productId\":\"$PID\",\"imageUrl\":\"$IMG_URL\"}" > "$TMP_S1"
    echo "✓ S1 completado"
) &
PID_S1=$!

(
    echo "→ S2 enviado..."
    curl -s -X POST "$S2" \
      -H "Content-Type: application/json" \
      -d "{\"productId\":\"$PID\",\"imageUrl\":\"$IMG_URL\"}" > "$TMP_S2"
    echo "✓ S2 completado"
) &
PID_S2=$!

(
    echo "→ S3 enviado..."
    curl -s -X POST "$S3" \
      -H "Content-Type: application/json" \
      -d "{\"productId\":\"$PID\"}" > "$TMP_S3"
    echo "✓ S3 completado"
) &
PID_S3=$!

(
    echo "→ S5 enviado..."
    curl -s -X POST "$S5" \
      -H "Content-Type: application/json" \
      -d "{\"productId\":\"$PID\"}" > "$TMP_S5"
    echo "✓ S5 completado"
) &
PID_S5=$!

# Esperar todas
wait $PID_S1 $PID_S2 $PID_S3 $PID_S5
echo ""
echo "⏱️  Tiempo final: $(date '+%H:%M:%S')"
echo ""

# Mostrar resultados
echo "📊 RESULTADOS:"
echo "-------------------------------------------"
echo ""
echo "S1 (EnrichLabels):"
cat "$TMP_S1" | jq '.body'
echo ""

echo "S2 (ModerateImage):"
cat "$TMP_S2" | jq '.body'
echo ""

echo "S3 (AnalyzeSentiment):"
cat "$TMP_S3" | jq '.body'
echo ""

echo "S5 (SynthesizeVoice):"
cat "$TMP_S5" | jq '.body'
echo ""

# Test 3: Estado final
echo "3️⃣  ESTADO FINAL (después de todas las Lambdas EN PARALELO)"
echo "-------------------------------------------"
curl -s "${API%/}/products" | jq ".[] | select(.productId==\"$PID\") | {name, aiLabels: (.aiLabels | length), moderationStatus, reviewSentiment, audioUrl: (.audioUrl | if . then \"✅ Sí\" else \"❌ No\" end)}"
echo ""

echo "==========================================="
echo "✅ Test paralelo completado"
echo ""
echo "🎯 Las 4 Lambdas se ejecutaron AL MISMO TIEMPO"
echo "   Los datos se agregaron AUTOMÁTICAMENTE a DynamoDB"
echo ""
echo "📝 Ver todos los campos del producto:"
echo "   curl -s \"${API%/}/products\" | jq '.[] | select(.productId==\"$PID\")'"
