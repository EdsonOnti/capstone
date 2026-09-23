#!/bin/bash
# Upload product images from URLs to S3 and update DynamoDB

set -euo pipefail

STACK_NAME="edson-martin-ontiveros-lima"
REGION="us-east-1"
BUCKET="edson-martin-ontiveros-lima-products"
CF_URL="https://d2jgv7mcaqixc1.cloudfront.net"

echo "🖼️  Cargando imágenes de Unsplash → S3 → DynamoDB"
echo "=================================================="
echo ""

# Get product IDs
echo "📋 Obteniendo IDs de productos..."
API=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$REGION" \
  --query "Stacks[0].Outputs[?OutputKey=='ApiUrl'].OutputValue" \
  --output text)

PRODUCTS=$(curl -s "${API%/}/products" | jq '.products')

VESTIDO_ID=$(echo "$PRODUCTS" | jq -r '.[] | select(.name=="Vestido midi floral") | .productId')
TENIS_ID=$(echo "$PRODUCTS" | jq -r '.[] | select(.name=="Tenis blancos minimalistas") | .productId')
CHAQUETA_ID=$(echo "$PRODUCTS" | jq -r '.[] | select(.name=="Chaqueta de mezclilla oversize") | .productId')
BOLSO_ID=$(echo "$PRODUCTS" | jq -r '.[] | select(.name=="Bolso tote de lona") | .productId')

echo "✅ Vestido: $VESTIDO_ID"
echo "✅ Tenis: $TENIS_ID"
echo "✅ Chaqueta: $CHAQUETA_ID"
echo "✅ Bolso: $BOLSO_ID"
echo ""

# Define images
declare -A IMAGES=(
  ["Vestido"]="$VESTIDO_ID|https://plus.unsplash.com/premium_photo-1673384389447-5a4364e7c93b?q=80&w=988&auto=format&fit=crop"
  ["Tenis"]="$TENIS_ID|https://images.unsplash.com/photo-1600269452121-4f2416e55c28?q=80&w=1065&auto=format&fit=crop"
  ["Chaqueta"]="$CHAQUETA_ID|https://images.unsplash.com/photo-1551028719-00167b16eac5?q=80&w=1035&auto=format&fit=crop"
  ["Bolso"]="$BOLSO_ID|https://images.unsplash.com/photo-1605733513597-a8f8341084e6?q=80&w=2129&auto=format&fit=crop"
)

# Upload each image
for PRODUCT in "${!IMAGES[@]}"; do
  IFS='|' read -r PID URL <<< "${IMAGES[$PRODUCT]}"
  
  echo "📸 $PRODUCT ($PID)"
  
  # Download image
  TEMP_FILE="/tmp/${PRODUCT,,}.jpg"
  echo "  ⬇️  Descargando de Unsplash..."
  curl -s -L "$URL" -o "$TEMP_FILE" 2>/dev/null || {
    echo "  ❌ Error descargando $PRODUCT"
    continue
  }
  
  # Get file size
  SIZE=$(du -h "$TEMP_FILE" | cut -f1)
  echo "  ✅ Descargado: $SIZE"
  
  # Upload to S3
  S3_KEY="products/${PRODUCT,,}.jpg"
  echo "  ⬆️  Subiendo a S3: $S3_KEY"
  aws s3 cp "$TEMP_FILE" "s3://$BUCKET/$S3_KEY" \
    --region "$REGION" \
    --content-type "image/jpeg" \
    --quiet
  
  # Generate CloudFront URL
  IMAGE_URL="$CF_URL/$S3_KEY"
  echo "  🔗 CloudFront URL: $IMAGE_URL"
  
  # Update DynamoDB
  echo "  💾 Actualizando DynamoDB..."
  curl -s -X PUT "${API%/}/products/$PID" \
    -H "Content-Type: application/json" \
    -d "{\"imageKey\": \"$S3_KEY\", \"imageUrl\": \"$IMAGE_URL\"}" > /dev/null
  
  echo "  ✅ $PRODUCT actualizado"
  echo ""
  
  rm -f "$TEMP_FILE"
done

echo "╔════════════════════════════════════════════════════════╗"
echo "║                   ✅ COMPLETADO                        ║"
echo "║                                                        ║"
echo "║  Las 4 imágenes están en S3 + DynamoDB actualizado     ║"
echo "║  Próximo: Abre el frontend y verifica las imágenes     ║"
echo "║                                                        ║"
echo "║  Frontend: https://d33x5tfyjkvcnh.cloudfront.net       ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

