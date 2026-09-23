#!/bin/bash
#
# Deploy Sandbox script for TechModa AI Capstone
# Despliega template.sandbox.yaml: backend (S0-S5 + frontend) sin Bedrock.
#
# Template.sandbox.yaml contiene:
#   - S0: Router CRUD + DynamoDB
#   - S1-S5: Lambdas de IA (Rekognition, Comprehend, Polly) + AudioBucket
#   - Frontend: S3 + CloudFront
#
# Cada Lambda declara sus Policies y SAM le crea un rol de mínimo privilegio (docs/IAM.md).
# CAPABILITY_IAM es obligatoria: el stack crea roles.
# CAPABILITY_AUTO_EXPAND es obligatoria: lo exige el Transform de SAM.
#

set -e

STACK_NAME="${STACK_NAME:-edson-martin-ontiveros-lima}"
REGION="${AWS_REGION:-us-east-1}"

echo "=========================================="
echo "  TechModa - Sandbox Deploy (S0-S5+Frontend)"
echo "=========================================="
echo ""
echo "  Stack:  $STACK_NAME"
echo "  Region: $REGION"
echo "  Template: template.sandbox.yaml"
echo ""

echo "📦 sam build -t template.sandbox.yaml..."
sam build -t template.sandbox.yaml

echo ""
echo "🚀 sam deploy -t template.sandbox.yaml..."
if [ -f "samconfig.toml" ]; then
    echo "📝 Usando configuración existente en samconfig.toml"
    sam deploy -t template.sandbox.yaml
else
    echo "⚠️  No hay samconfig.toml — desplegando con flags explícitos."
    sam deploy \
        -t template.sandbox.yaml \
        --stack-name "$STACK_NAME" \
        --region "$REGION" \
        --capabilities CAPABILITY_IAM CAPABILITY_AUTO_EXPAND \
        --resolve-s3 \
        --no-confirm-changeset \
        --no-fail-on-empty-changeset
fi

echo ""
echo "=========================================="
echo "  ✅ Backend Deploy Complete!"
echo "=========================================="
echo ""
echo "📋 Outputs de tu stack:"
echo "-------------------------------------------"
echo ""

# Get stack outputs
OUTPUTS=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$REGION" \
    --query 'Stacks[0].Outputs' \
    --output json 2>/dev/null || echo "[]")

echo "$OUTPUTS" | python3 -m json.tool 2>/dev/null || echo "No outputs found"

echo ""
echo "⚠️  IMPORTANTE:"
echo "    - Frontend bucket está VACÍO (sin archivos aún)"
echo "    - CloudFront URL está lista pero devuelve error 403/404"
echo ""
echo "📝 Próximo paso:"
echo "    bash scripts/deploy-frontend.sh"
echo ""
echo "    Esto va a:"
echo "    1. Compilar el React (npm run build)"
echo "    2. Subir los archivos a S3"
echo "    3. CloudFront sirve tu frontend"
echo ""
echo "=========================================="
