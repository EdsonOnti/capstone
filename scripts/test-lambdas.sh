#!/bin/bash
#
# Test Lambdas: Ejecuta S1-S6 en un producto y muestra cambios
#
# Uso:
#   bash scripts/test-lambdas.sh [productId]              # Ejecuta en UN producto
#   bash scripts/test-lambdas.sh --all-active            # Ejecuta en TODOS los ACTIVE
#
# Si no pasas productId, usa el primer producto del seed.
#

set -euo pipefail

STACK_NAME="${STACK_NAME:-edson-martin-ontiveros-lima}"
REGION="${AWS_REGION:-us-east-1}"

echo "🧪 Test Lambdas S1-S6 (incluyendo S4 Translate y S6 Quality Gate)"
echo "=================================================================="
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
S4=$(echo "$STACK_OUTPUT" | jq -r '.[] | select(.OutputKey=="TranslateCatalogUrl").OutputValue')
S5=$(echo "$STACK_OUTPUT" | jq -r '.[] | select(.OutputKey=="SynthesizeVoiceUrl").OutputValue')
S6=$(echo "$STACK_OUTPUT" | jq -r '.[] | select(.OutputKey=="ValidateQualityUrl").OutputValue')
S6_BEDROCK=$(echo "$STACK_OUTPUT" | jq -r '.[] | select(.OutputKey=="GenerateDescriptionUrl").OutputValue')
S7_INDEX=$(echo "$STACK_OUTPUT" | jq -r '.[] | select(.OutputKey=="IndexEmbeddingsUrl").OutputValue')
S7_SEARCH=$(echo "$STACK_OUTPUT" | jq -r '.[] | select(.OutputKey=="SemanticSearchUrl").OutputValue')
S8_CHAT=$(echo "$STACK_OUTPUT" | jq -r '.[] | select(.OutputKey=="ShoppingAssistantUrl").OutputValue')

if [ -z "$API" ] || [ "$API" = "null" ]; then
    echo "❌ No se encontraron URLs del stack"
    exit 1
fi

echo "📡 URLs obtenidas:"
echo "   API: $API"
echo "   S1:  $S1"
echo "   S2:  $S2"
echo "   S3:  $S3"
echo "   S4:  $S4"
echo "   S5:  $S5"
echo "   S6:  $S6"
echo "   S6 (Bedrock): $S6_BEDROCK"
echo "   S7 (Index):   $S7_INDEX"
echo "   S7 (Search):  $S7_SEARCH"
echo "   S8 (Chat):    $S8_CHAT"
echo ""

# Get product ID (primero del seed o del parámetro)
ALL_ACTIVE=false
if [ -n "${1:-}" ]; then
    if [ "$1" = "--all-active" ]; then
        ALL_ACTIVE=true
    else
        PID="$1"
    fi
else
    # Get first product from API
    PID=$(curl -s "${API%/}/products" | jq -r '.products[0].productId')
fi

if [ "$ALL_ACTIVE" = false ]; then
    if [ -z "$PID" ] || [ "$PID" = "null" ]; then
        echo "❌ No hay productos. Ejecuta: bash scripts/check-and-seed.sh"
        exit 1
    fi
    echo "🎯 Producto para test: $PID"
    PIDS="$PID"
else
    # Get all ACTIVE products
    echo "🎯 Obteniendo todos los productos ACTIVE..."
    PIDS=$(curl -s "${API%/}/products" | jq -r '.products[] | select(.status=="ACTIVE" or .status==null) | .productId')
    COUNT=$(echo "$PIDS" | wc -l)
    echo "✅ Encontrados $COUNT productos ACTIVE"
fi
echo ""

IMG_URL="https://via.placeholder.com/300?text=TestProduct"

# Si ALL_ACTIVE, agregar stats
if [ "$ALL_ACTIVE" = true ]; then
    PROCESSED=0
    GENERATED=0
    echo "🔄 Generando descripciones para todos los productos ACTIVE..."
    echo ""
fi

# Loop sobre todos los PIDs
for PID in $PIDS; do

# Test 1: Ver estado inicial
echo "1️⃣  ESTADO INICIAL (antes de ejecutar Lambdas)"
echo "-------------------------------------------"
curl -s "${API%/}/products" | jq ".products[] | select(.productId==\"$PID\") | {name, aiLabels, moderationStatus, reviewSentiment, audioUrl}"
echo ""

# Test 2: S1 - EnrichLabels
echo "2️⃣  EJECUTANDO S1 - EnrichLabels (Rekognition)"
echo "-------------------------------------------"
S1_RESULT=$(curl -s -X POST "$S1" \
  -H "Content-Type: application/json" \
  -d "{\"productId\":\"$PID\",\"imageUrl\":\"$IMG_URL\"}")

echo "Respuesta:"
echo "$S1_RESULT" | jq '.body'
echo ""

# Test 3: Verificar actualización
echo "3️⃣  VERIFICANDO ACTUALIZACIÓN EN DYNAMODB (después de S1)"
echo "-------------------------------------------"
curl -s "${API%/}/products" | jq ".products[] | select(.productId==\"$PID\") | {name, aiLabels: (.aiLabels | if . then length else 0 end), moderationStatus, reviewSentiment, audioUrl}"
echo ""

# Test 4: S2 - ModerateImage
echo "4️⃣  EJECUTANDO S2 - ModerateImage (Rekognition)"
echo "-------------------------------------------"
S2_RESULT=$(curl -s -X POST "$S2" \
  -H "Content-Type: application/json" \
  -d "{\"productId\":\"$PID\",\"imageUrl\":\"$IMG_URL\"}")

echo "Respuesta:"
echo "$S2_RESULT" | jq '.body'
echo ""

# Test 5: Verificar actualización
echo "5️⃣  VERIFICANDO ACTUALIZACIÓN EN DYNAMODB (después de S2)"
echo "-------------------------------------------"
curl -s "${API%/}/products" | jq ".products[] | select(.productId==\"$PID\") | {name, aiLabels: (.aiLabels | if . then length else 0 end), moderationStatus, altText: (.altText | if . then \"✅ Present\" else \"❌ No\" end), audioUrl}"
echo ""

# Test 5.5: S4 - TranslateCatalog
echo "5️⃣ .5️⃣  EJECUTANDO S4 - TranslateCatalog (Translate ES→EN)"
echo "-------------------------------------------"
S4_RESULT=$(curl -s -X POST "$S4" \
  -H "Content-Type: application/json" \
  -d "{\"productId\":\"$PID\",\"target\":\"en\"}")

echo "Respuesta:"
echo "$S4_RESULT" | jq '.'
echo ""

# Test 5.6: Verificar S4 en DynamoDB
echo "5️⃣ .6️⃣  VERIFICANDO TRADUCCIÓN EN DYNAMODB (después de S4)"
echo "-------------------------------------------"
curl -s "${API%/}/products" | jq ".products[] | select(.productId==\"$PID\") | {name, translations: .translations}"
echo ""

# Test 6: S3 - AnalyzeSentiment (extrae reviews desde DynamoDB)
echo "6️⃣  EJECUTANDO S3 - AnalyzeSentiment (Comprehend)"
echo "-------------------------------------------"

# Obtener el producto completo de DynamoDB
PRODUCT_FROM_DB=$(curl -s "${API%/}/products" | jq ".products[] | select(.productId==\"$PID\")")

# Extraer los textos de las reseñas (si existen)
REVIEWS=$(echo "$PRODUCT_FROM_DB" | jq -r '.reviews[]?.text' 2>/dev/null | jq -Rs 'split("\n") | map(select(length > 0))' 2>/dev/null || echo '[]')

# Si no hay reseñas, mostrar advertencia
if [ "$REVIEWS" == "[]" ]; then
	echo "⚠️  No hay reseñas en el producto. Saltando S3."
	echo ""
else
	echo "📝 Reseñas encontradas: $(echo "$REVIEWS" | jq 'length')"
	S3_RESULT=$(curl -s -X POST "$S3" \
	  -H "Content-Type: application/json" \
	  -d "{\"reviews\": $REVIEWS, \"productId\": \"$PID\"}")

	echo "Respuesta:"
	echo "$S3_RESULT" | jq '.body'
	echo ""
fi


# Test 7: Verificar actualización
echo "7️⃣  VERIFICANDO ACTUALIZACIÓN EN DYNAMODB (después de S3)"
echo "-------------------------------------------"
curl -s "${API%/}/products" | jq ".products[] | select(.productId==\"$PID\") | {name, moderationStatus, reviewSentiment, audioUrl}"
echo ""

# Test 8: S5 - SynthesizeVoice
echo "8️⃣  EJECUTANDO S5 - SynthesizeVoice (Polly)"
echo "-------------------------------------------"
S5_RESULT=$(curl -s -X POST "$S5" \
  -H "Content-Type: application/json" \
  -d "{\"productId\":\"$PID\"}")

echo "Respuesta:"
S5_BODY=$(echo "$S5_RESULT" | jq -r '.body')
if [ "$S5_BODY" != "null" ]; then
  echo "$S5_BODY" | jq '.'
else
  echo "$S5_RESULT" | jq '.'
fi
echo ""

# Test 9: Verificar actualización S5
echo "9️⃣  VERIFICANDO ACTUALIZACIÓN EN DYNAMODB (después de S5)"
echo "-------------------------------------------"
curl -s "${API%/}/products" | jq ".products[] | select(.productId==\"$PID\") | {name, audioUrl: (.audioUrl | if . then \"✅ Sí\" else \"❌ No\" end)}"
echo ""

# Test 10: S6 - ValidateQuality (Quality Gate)
echo "🔟  EJECUTANDO S6 - ValidateQuality (Moderación)"
echo "-------------------------------------------"
S6_RESULT=$(curl -s -X POST "$S6" \
  -H "Content-Type: application/json" \
  -d "{\"productId\":\"$PID\"}")

echo "Respuesta:"
echo "$S6_RESULT" | jq '.overall'
echo ""

# Extraer el status recomendado
S6_STATUS=$(echo "$S6_RESULT" | jq -r '.overall.status // "UNKNOWN"')
S6_REASON=$(echo "$S6_RESULT" | jq -r '.overall.reason // ""')

echo "📋 Recomendación: status=$S6_STATUS, reason=\"$S6_REASON\""
echo ""

# Test 11: S6 Bedrock - GenerateDescription
if [ "$ALL_ACTIVE" = false ]; then
    echo "1️⃣ 0️⃣  EJECUTANDO S6 (Bedrock) - GenerateDescription"
    echo "-------------------------------------------"
fi
S6_BEDROCK_RESULT=$(curl -s -X POST "$S6_BEDROCK" \
  -H "Content-Type: application/json" \
  -d "{\"productId\":\"$PID\",\"tone\":\"professional\",\"save\":true}")

if [ "$ALL_ACTIVE" = false ]; then
    echo "Respuesta:"
    echo "$S6_BEDROCK_RESULT" | jq '.description'
    echo ""
fi

# Check if description was generated
AI_DESC=$(echo "$S6_BEDROCK_RESULT" | jq -r '.description // empty')
if [ -n "$AI_DESC" ]; then
    GENERATED=$((GENERATED + 1))
fi
PROCESSED=$((PROCESSED + 1))

# Test 11.5: Verificar actualización de descripción (solo si no es ALL_ACTIVE)
if [ "$ALL_ACTIVE" = false ]; then
    echo "1️⃣ 0️⃣ .5️⃣  VERIFICANDO DESCRIPCIÓN EN DYNAMODB (después de S6 Bedrock)"
    echo "-------------------------------------------"
    curl -s "${API%/}/products" | jq ".products[] | select(.productId==\"$PID\") | {name, description: (.description | if . then \"✅ Present\" else \"❌ No\" end), aiDescription: (.aiDescription | if . then \"✅ Sí\" else \"❌ No\" end)}"
    echo ""
fi

# Test 12: Estado final (solo si no es ALL_ACTIVE)
if [ "$ALL_ACTIVE" = false ]; then
    echo "1️⃣ 2️⃣  ESTADO FINAL (después de todas las Lambdas)"
    echo "-------------------------------------------"
    curl -s "${API%/}/products" | jq ".products[] | select(.productId==\"$PID\") | {name, status: (.status // \"N/A\"), aiLabels: (.aiLabels | if . then length else 0 end), moderationStatus, reviewSentiment, translations: (if .translations then \"✅ Sí\" else \"❌ No\" end), audioUrl: (.audioUrl | if . then \"✅ Sí\" else \"❌ No\" end), aiDescription: (.aiDescription | if . then \"✅ Sí\" else \"❌ No\" end)}"
    echo ""

    echo "==========================================="
    echo "✅ Test completado"
    echo ""
    echo "📝 Próximo paso (opcional):"
    echo "Si el status recomendado es ACTIVE:"
    echo "   curl -X PUT \"${API%/}/products/$PID/status\" \\"
    echo "     -H 'Content-Type: application/json' \\"
    echo "     -d '{\"newStatus\":\"ACTIVE\"}'"
    echo ""
    echo "📝 Ver todos los campos del producto:"
    echo "   curl -s \"${API%/}/products\" | jq '.products[] | select(.productId==\"$PID\")'"
fi

done

# S7 - Index Embeddings (si ALL_ACTIVE, indexar todos)
if [ "$ALL_ACTIVE" = true ]; then
    echo ""
    echo "🔄 Indexando embeddings con S7..."
    echo "=================================================="
    curl -s -X POST "$S7_INDEX" \
      -H "Content-Type: application/json" > /dev/null
    echo "✅ Índice de embeddings construido"
    echo ""

    # S8 - Chat test (solo si es ALL_ACTIVE)
    echo "💬 Probando S8 - Asistente de compras..."
    echo "=================================================="
    S8_RESULT=$(curl -s -X POST "$S8_CHAT" \
      -H "Content-Type: application/json" \
      -d "{\"message\":\"Busco algo abrigado para el invierno\"}")

    echo "Respuesta del asistente:"
    echo "$S8_RESULT" | jq '.response // .message // .'
    echo ""
fi

# Final summary si ALL_ACTIVE
if [ "$ALL_ACTIVE" = true ]; then
    echo ""
    echo "=================================================="
    echo "✅ GENERACIÓN COMPLETADA"
    echo "=================================================="
    echo ""
    echo "📊 Resultados:"
    echo "   Total procesados: $PROCESSED"
    echo "   ✅ Generados:     $GENERATED"
    echo ""
    echo "🔗 Ver resultados en el frontend:"
    echo "   https://d33x5tfyjkvcnh.cloudfront.net"
    echo ""
fi
