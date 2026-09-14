# ESTADO DEL CAPSTONE TECHMODA

**Fecha:** 2026-09-14 | **Stack:** `edson-martin-ontiveros-lima` | **Región:** `us-east-1`

---

## 📊 RESUMEN EJECUTIVO

| Aspecto | Estado |
|---------|--------|
| **Sesiones Completadas** | 4/12 (S0, S1, S2, S3) ✅ |
| **Código Funcional** | ✅ Todas probadas y deployadas |
| **Documentación** | ✅ 7 guías MD + código comentado |
| **Stack AWS** | ✅ CREATE_COMPLETE en us-east-1 |
| **Git** | ✅ 4 commits registrados |
| **Costo (pruebas)** | ~$0.003 (negligible) |

---

## 🚀 SESIONES COMPLETADAS

### S0 — Base Serverless ✅
**Objetivo:** Infraestructura sin servidores (serverless)
- **Lambda:** Router CRUD Node.js
- **BD:** DynamoDB con 4 productos
- **API:** Function URL pública
- **Documentación:** [S0-GUIA-EJECUTADA.md](S0-GUIA-EJECUTADA.md)
- **Conceptos clave:** Serverless, Lambda, DynamoDB, Function URLs, IAM mínimo privilegio

### S1 — Rekognition Labels ✅
**Objetivo:** Auto-etiquetado de imágenes
- **Servicio:** Rekognition `DetectLabels`
- **Entrada:** URL de imagen
- **Salida:** Etiquetas con confianzas
- **Campos guardados:** `aiLabels`, `aiLabelsRaw`
- **Documentación:** [S1-GUIA-EJECUTADA.md](S1-GUIA-EJECUTADA.md) (vea summary anterior)
- **Conceptos clave:** Visión, inferencia, confianza, modelos preentrenados

### S2 — Moderación + Alt-text ✅
**Objetivo:** Seguridad de contenido + accesibilidad
- **Servicio:** Rekognition `DetectModerationLabels` + `DetectLabels`
- **Entrada:** URL de imagen
- **Salida:** Status (APPROVED/FLAGGED) + alt-text accesible
- **Campos guardados:** `moderationStatus`, `moderationFlags`, `altText`
- **Documentación:** [S2-GUIA-EJECUTADA.md](S2-GUIA-EJECUTADA.md)
- **Conceptos clave:** Responsible AI, WCAG 2.1, moderación de contenido, accesibilidad

### S3 — Análisis de Sentimiento ✅
**Objetivo:** Análisis de opinión en reseñas
- **Servicio:** Comprehend `DetectSentiment` + `DetectDominantLanguage`
- **Entrada:** Texto o lista de reseñas
- **Salida:** Sentimiento (POSITIVE/NEGATIVE/NEUTRAL/MIXED) + puntuaciones
- **Campos guardados:** `reviewSentiment`, `reviewSentimentCounts`
- **Documentación:** [S3-GUIA-EJECUTADA.md](S3-GUIA-EJECUTADA.md)
- **Conceptos clave:** NLP, detección de idioma, análisis de texto, puntuaciones de confianza

---

## 📁 ESTRUCTURA DE GUÍAS

```
capstone/
├── S0-GUIA-EJECUTADA.md              (371 líneas)
├── S1-GUIA-EJECUTADA.md              (leído en sesión anterior)
├── S2-GUIA-EJECUTADA.md              (437 líneas)
├── S3-GUIA-EJECUTADA.md              (451 líneas)
├── RESUMEN-S0-S1-COMPLETADA.md       (245 líneas)
├── RESUMEN-S2-S3-COMPLETADA.md       (258 líneas)
├── INDICE-GUIAS-EJECUTADAS.md        (270 líneas)
├── CAPSTONE-STATUS.md                (este archivo)
└── CLAUDE.md                         (actualizado con sesiones)
```

**Características comunes en todas las guías:**
- Escrita para **principiantes sin experiencia en AWS**
- Cada comando incluye **salida esperada real**
- Checklist de validación ✅
- Sección "Errores comunes y soluciones"
- Conexión con el **examen AIF-C01**
- Estimación de costo

---

## 🎯 PRÓXIMAS SESIONES (OPCIONALES)

### S4 — Traducción (Translate)
- Traducir catálogo a múltiples idiomas
- Servicio: AWS Translate `TranslateText`
- Campos: `translations`

### S5 — Síntesis de Voz (Polly)
- Generar audio de descripciones (accesibilidad)
- Servicio: Amazon Polly `SynthesizeSpeech`
- Campos: `audioUrl`, `audioTranscript`

### S6–S9 — Bedrock (Modelos Fundacionales)
- S6: Generación de descripciones con Claude
- S7: RAG (Retrieval Augmented Generation) y búsqueda semántica
- S8: Chatbot de asistencia al cliente
- Requiere: habilitar "Model access" en Bedrock console

### S10 — Gobernanza
- Presupuestos y alertas de costo
- Auditoría con CloudTrail
- Etiquetas de recursos

### S11 — Cleanup
- Borrar stack
- Analizar costos finales

---

## 🔧 COMANDOS RÁPIDOS

```bash
# Ver estado actual
aws cloudformation describe-stacks \
  --stack-name edson-martin-ontiveros-lima \
  --region us-east-1 \
  --query "Stacks[0].StackStatus" --output text

# Ver Function URLs
aws cloudformation describe-stacks \
  --stack-name edson-martin-ontiveros-lima \
  --region us-east-1 \
  --query "Stacks[0].Outputs[*].[OutputKey,OutputValue]" --output table

# Ver productos en DynamoDB
aws dynamodb scan --table-name edson-martin-ontiveros-lima-Products \
  --region us-east-1 \
  --projection-expression "productId,#n,moderationStatus,reviewSentiment" \
  --expression-attribute-names '{"#n":"name"}' \
  --output table

# Ver logs de S2
aws logs tail /aws/lambda/edson-martin-ontiveros-lima-ModerateImage \
  --region us-east-1 --follow

# Ver logs de S3
aws logs tail /aws/lambda/edson-martin-ontiveros-lima-AnalyzeSentiment \
  --region us-east-1 --follow
```

---

## 📚 ARCHIVOS PRINCIPALES

### Templates (Infrastructure as Code)
- `template.yaml` — S0 base (sin S1–S3, incluye CloudFront)
- `template.sandbox.yaml` — S0 base + S1/S2/S3/S5 (sin CloudFront, deploy rápido) ✅ **USADO**
- `template.full.yaml` — S0–S8 + gobernanza (completo, más lento)

### Funciones Lambda
```
functions/
├── router/
│   └── index.js                (S0 CRUD Node.js)
└── (S1–S8 están en sessions/)

sessions/
├── S01-rekognition-labels/functions/enrich-labels/app.py
├── S02-moderation-alttext/functions/moderate-image/app.py
└── S03-comprehend-sentiment/functions/analyze-sentiment/app.py
```

### Datos
```
data/
├── products.json               (4 productos base para seed)
└── output/                     (lugar para resultados)

assets/                         (imágenes de entrada, vacío en S0–S3)
```

---

## 🔐 IAM — POLÍTICA DE MÍNIMO PRIVILEGIO

### S0 (Router)
- ✅ DynamoDB: GetItem, PutItem, Scan, UpdateItem, DeleteItem
- ❌ Sin acceso a: Rekognition, Comprehend, S3, etc.

### S1 (EnrichLabels)
- ✅ DynamoDB: GetItem, UpdateItem
- ✅ Rekognition: `DetectLabels`
- ✅ S3: GetObject (buckets del stack)
- ❌ Sin acceso a: Comprehend, Translate, Bedrock, etc.

### S2 (ModerateImage)
- ✅ DynamoDB: GetItem, UpdateItem
- ✅ Rekognition: `DetectModerationLabels`, `DetectLabels`
- ✅ S3: GetObject (buckets del stack)
- ❌ Sin acceso a: Comprehend, Translate, Bedrock, etc.

### S3 (AnalyzeSentiment)
- ✅ DynamoDB: GetItem, UpdateItem
- ✅ Comprehend: `DetectSentiment`, `DetectDominantLanguage`
- ❌ Sin acceso a: Rekognition, Translate, Bedrock, S3, etc.

---

## 💡 PATRONES REUTILIZABLES

### Patrón 1: Lambda + Function URL + DynamoDB
Usado en S1, S2, S3:
```
Entrada (curl) → Lambda (detecta servicio) → DynamoDB (guarda resultado) → Salida JSON
```

### Patrón 2: Mínimo Privilegio IAM
Cada Lambda declara solo lo que necesita:
```yaml
Policies:
  - DynamoDBCrudPolicy: { TableName: ... }
  - Statement: [{ Action: [servicio:Operacion], Resource: "*" }]
```

### Patrón 3: Respuestas JSON
Todas retornan:
```json
{
  "statusCode": 200,
  "body": { ... },
  "headers": { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" }
}
```

---

## 📊 DATOS GUARDADOS EN DYNAMODB

**Tabla:** `edson-martin-ontiveros-lima-Products`

### Campos Originales (S0)
- `productId` (PK)
- `name`, `price`, `stock`, `category`, `description`, `imageUrl`

### Campos S1 (Rekognition)
- `aiLabels` — lista de etiquetas: `[{"name": "...", "confidence": ...}]`
- `aiLabelsRaw` — respuesta completa de Rekognition (debug)

### Campos S2 (Moderación)
- `moderationStatus` — `"APPROVED"` o `"FLAGGED"`
- `moderationFlags` — lista de problemas detectados
- `altText` — descripción accesible

### Campos S3 (Sentimiento)
- `reviewSentiment` — `"POSITIVE"`, `"NEGATIVE"`, `"NEUTRAL"`, o `"MIXED"`
- `reviewSentimentCounts` — tally de cada sentimiento

---

## 💸 COSTOS ACUMULADOS

| Sesión | Servicio | Volumen (pruebas) | Costo |
|--------|----------|-------------------|-------|
| **S0** | DynamoDB | 1 tabla | ~$0 |
| **S1** | Rekognition DetectLabels | 1 imagen | $0.0008 |
| **S2** | Rekognition Moderate+Labels | 1 imagen | $0.0016 |
| **S3** | Comprehend Sentiment+Language | 5 textos | $0.001 |
| **TOTAL** | — | — | **~$0.0034** |

En producción (estimado): ~$2–5/mes para S0–S3 con volumen bajo.

---

## 📝 GIT HISTORY

```
e52bf10 Actualizar CLAUDE.md: agregar estado de sesiones completadas (S0-S3)
de82cb0 S2 y S3 completadas: moderación + alt-text + análisis de sentimiento
b85096a Añadir índice de guías ejecutadas S0 y S1
408a498 S0 y S1 completadas: deployment y documentación paso a paso
495a19e Initial commit
```

---

## ✅ CHECKLIST FINAL (S0–S3)

- [x] Stack desplegado sin errores (CREATE_COMPLETE)
- [x] 4 productos en DynamoDB
- [x] S0 CRUD funcional (GET, POST, PUT, DELETE)
- [x] S1 Labels funcional — etiquetas guardadas
- [x] S2 Moderación funcional — status + altText guardados
- [x] S3 Sentimiento funcional — sentiment + counts guardados
- [x] CloudWatch Logs sin errores (todas las Lambdas ejecutadas)
- [x] IAM con mínimo privilegio (verificado por rol)
- [x] 7 guías MD escritas (para principiantes sin AWS)
- [x] 4 commits en git registrando cambios
- [x] Costos monitoreados (~$0.003 en pruebas)

---

## 🎓 CONEXIÓN CON AIF-C01

**Dominios del examen cubiertos en S0–S3:**

| Dominio | Sesión | Concepto |
|---------|--------|----------|
| **D1: Fundamentals** | S1, S3 | Inferencia, confianza, modelos preentrenados, NLP |
| **D2: Data Science** | S0 | Almacenamiento de datos (DynamoDB) |
| **D3: Implementation** | S0–S3 | Lambda, Function URLs, IAM |
| **D4: Responsible AI** | S2 | Moderación, accesibilidad (alt-text) |
| **D5: Security** | S0–S3 | IAM mínimo privilegio, logging (CloudWatch) |

---

## 🚀 PRÓXIMA ACCIÓN

Según el objetivo:

1. **Aprender más sesiones:** Optar por S4, S5, o S6–S9 (Bedrock)
2. **Prepararse para examen:** Releer guías + revisar conceptos en cada Dominio
3. **Producción:** Configurar Budgets (CloudWatch), analizar costos, agregar autenticación
4. **Demo:** Mostrar a stakeholders con navegador (frontend en CloudFront)

---

**Generado:** 2026-09-14 18:00 UTC  
**Stack:** edson-martin-ontiveros-lima (us-east-1)  
**Responsable:** Claude Code v4.5
