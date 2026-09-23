# Workflow de Despliegue con Template Sandbox

**Configuración:** `template.sandbox.yaml` (S0-S5 + Frontend con CloudFront)

---

## 📋 Resumen de Cambios

### ✅ 1. `template.sandbox.yaml` — Ahora incluye Frontend

Se agregaron:
- ✅ `FrontendBucket` (S3)
- ✅ `FrontendBucketPolicy`
- ✅ `FrontendDistribution` (CloudFront)
- ✅ Outputs: `FrontendBucketName`, `FrontendUrl`, `AudioBucketName`

**Resultado:** `template.sandbox.yaml` es ahora completo (backend S0-S5 + frontend)

### ✅ 2. Script Nuevo: `scripts/deploy-sandbox.sh`

Automatiza:
```bash
sam build -t template.sandbox.yaml
sam deploy -t template.sandbox.yaml [con flags correctos]
```

**Uso:**
```bash
bash scripts/deploy-sandbox.sh
```

### ✅ 3. `deploy-frontend.sh` — Sin cambios

Sigue funcionando igual porque ahora `template.sandbox.yaml` tiene los outputs correctos.

---

## 🚀 Flujos de Trabajo

### Caso 1: Primer Deploy (Todo desde cero)

```bash
# 1. Build + Deploy Backend + CloudFront + S3 + Lambdas
bash scripts/deploy-sandbox.sh

# 2. Build Frontend + Sync a S3
bash scripts/deploy-frontend.sh

# 3. Verificar que todo está en AWS
bash scripts/status.sh
```

**Tiempo total:** ~3-5 minutos

**Estado después:**
- ✅ Lambdas funcionando (S0-S5)
- ✅ API accesible en CloudFront
- ✅ Frontend accesible en CloudFront URL

---

### Caso 2: Solo Cambios en Backend (template.sandbox.yaml)

Editaste una Lambda, agregaste environment vars, o modificaste policies.

```bash
# 1. Deploy backend (Lambdas, roles, DynamoDB se actualizan)
bash scripts/deploy-sandbox.sh

# 2. Frontend NO se toca (archivos en S3 siguen igual)
# ❌ NO ejecutes deploy-frontend.sh
```

**Tiempo total:** ~1-2 minutos

**Cambios:**
- ✅ Lambdas actualizadas
- ✅ IAM roles actualizados
- ✅ S3 frontend files sin cambios
- ✅ CloudFront sigue igual

---

### Caso 3: Solo Cambios en Frontend (React)

Editaste `frontend/src/`, `frontend/components/`, etc.

```bash
# 1. Backend NO se toca
# ❌ NO ejecutes deploy-sandbox.sh

# 2. Build y deploy frontend (solo archivos a S3)
bash scripts/deploy-frontend.sh
```

**Tiempo total:** ~30 segundos

**Cambios:**
- ✅ HTML, CSS, JS actualizados en S3
- ✅ CloudFront sirve versión nueva automáticamente
- ✅ Lambdas sin cambios
- ✅ DynamoDB sin cambios

---

### Caso 4: Cambios en Backend Y Frontend

```bash
# 1. Deploy backend
bash scripts/deploy-sandbox.sh

# 2. Deploy frontend
bash scripts/deploy-frontend.sh
```

**Tiempo total:** ~2-3 minutos

---

### Caso 5: Después de terminar, Cleanup

```bash
# Borra TODO (stack, buckets, Lambdas)
bash scripts/delete-all.sh

# Si CloudFormation queda en DELETE_FAILED:
bash scripts/fix-failed-delete.sh
```

---

## 🔄 Diagrama de Flujo

```
CAMBIOS EN       → EJECUTA                    → RESULTADO
────────────────────────────────────────────────────────────
template.sandbox → bash scripts/deploy-sandbox.sh
                   (Lambdas, roles, DynamoDB)

frontend/src/   → bash scripts/deploy-frontend.sh
                   (Archivos HTML/CSS/JS en S3)

Ambos           → deploy-sandbox.sh
                   + deploy-frontend.sh

Nada            → (nada, todo sigue igual)
```

---

## 📊 Diferencias entre Métodos

| Lo que cambia | deploy-sandbox | deploy-frontend | Resultado |
|---|---|---|---|
| **Backend (template.sandbox.yaml)** | ✅ Sí | ❌ No | Lambdas actualizadas |
| **Frontend (frontend/src/)** | ❌ No | ✅ Sí | UI actualizada |
| **CloudFormation** | ✅ Sí | ❌ No | — |
| **S3 files** | ❌ No | ✅ Sí | — |
| **DynamoDB** | ✅ Sí | ❌ No | — |
| **Tiempo** | 1-2 min | 30 seg | — |

---

## 🛠️ Comandos Útiles

```bash
# Ver estado de tu stack
bash scripts/status.sh

# Ver logs de una Lambda
bash scripts/logs.sh get [--tail | --errors | --since 1h]

# Validar templates
sam validate --lint -t template.sandbox.yaml

# Ver outputs sin deploy
aws cloudformation describe-stacks \
  --stack-name edson-martin-ontiveros-lima \
  --query 'Stacks[0].Outputs' \
  --output table
```

---

## ✅ Validación Post-Deploy

```bash
# 1. Ver todas las Lambdas en AWS
aws lambda list-functions --region us-east-1 \
  --query "Functions[?contains(FunctionName, 'edson-martin')].FunctionName" \
  --output text

# 2. Probar API Router
API_URL=$(aws cloudformation describe-stacks \
  --stack-name edson-martin-ontiveros-lima \
  --query "Stacks[0].Outputs[?OutputKey=='ApiUrl'].OutputValue" \
  --output text)

curl -s "${API_URL%/}/products" | python3 -m json.tool

# 3. Probar S1 (EnrichLabels)
S1_URL=$(aws cloudformation describe-stacks \
  --stack-name edson-martin-ontiveros-lima \
  --query "Stacks[0].Outputs[?OutputKey=='EnrichLabelsUrl'].OutputValue" \
  --output text)

curl -s "$S1_URL" -X POST \
  -H "Content-Type: application/json" \
  -d '{"productId":"prod-1","imageUrl":"https://example.com/image.jpg"}'
```

---

## 📝 Notas Importantes

### Template Sandbox vs Template Full

```
template.sandbox.yaml          template.full.yaml
├─ S0: Base                     ├─ S0: Base
├─ S1-S5: IA                    ├─ S1-S5: IA
├─ Frontend: ✅ Sí              ├─ S6-S8: Bedrock
├─ CloudFront: ✅ Sí           ├─ Frontend: ✅ Sí
└─ Bedrock: ❌ No              └─ CloudFront: ✅ Sí

USO:
template.sandbox → Bootcamp, desarrollo, testing rápido
template.full    → Demo completa, producción (si habilitaste Bedrock)
```

### ¿Por qué Separar Backend y Frontend?

1. **Velocidad:** Si solo cambias React, deploy en 30 segundos
2. **Independencia:** Frontend = static files, backend = Lambda/DynamoDB
3. **Debugging:** Puedes probar Lambdas sin recompilar UI
4. **CI/CD:** Puedes deployar frontend desde diferente pipeline

---

## 🔗 Referencias

- CLAUDE.md: Arquitectura y conceptos
- docs/IAM.md: Políticas de mínimo privilegio
- scripts/: Otros scripts útiles (logs, status, delete-all)
- sessions/S0-S5: Guías detalladas de cada sesión

