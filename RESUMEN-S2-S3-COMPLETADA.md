# RESUMEN: S2 Y S3 COMPLETADAS

**Stack:** `edson-martin-ontiveros-lima` | **Región:** `us-east-1` | **Fecha:** 2026-09-14

---

## ✅ S2 — MODERACIÓN DE IMAGEN + ALT-TEXT (COMPLETADA)

### Qué se desplegó:

- ✅ **Lambda Rekognition:** `edson-martin-ontiveros-lima-ModerateImage`
- ✅ **Function URL:** `https://dxx7tz2zbuvnm27akybd5cv7v40uwmmq.lambda-url.us-east-1.on.aws/`
- ✅ **Permisos IAM:** DynamoDB + Rekognition (DetectModerationLabels + DetectLabels) + S3 GetObject

### Flujo:

```
Cliente: POST /products/{id}/moderate
    ↓
Rekognition: DetectModerationLabels → ¿Es contenido seguro?
Rekognition: DetectLabels → Genera alt-text accesible
    ↓
DynamoDB: Guarda moderationStatus, moderationFlags, altText
    ↓
Cliente: Recibe {status: "APPROVED"|"FLAGGED", flags: [...], altText: "..."}
```

### Ejecución Real:

```bash
ProductId="6b4c4683-9f43-4c89-919f-516ba8362f5f"
curl -s -X POST "https://dxx7tz2zbuvnm27akybd5cv7v40uwmmq.lambda-url.us-east-1.on.aws//products/${ProductId}/moderate" | jq .
```

**Resultado:**
```json
{
    "productId": "6b4c4683-9f43-4c89-919f-516ba8362f5f",
    "moderationStatus": "APPROVED",
    "moderationFlags": [],
    "altText": "Imagen de producto que muestra: Animal, Canine, Fox, Kit Fox, Mammal."
}
```

### Validación en DynamoDB:

```bash
aws dynamodb get-item \
  --table-name edson-martin-ontiveros-lima-Products \
  --key "{\"productId\":{\"S\":\"${ProductId}\"}}" \
  --query 'Item.[moderationStatus.S, altText.S]' --output text
```

**Resultado:**
```
APPROVED    Imagen de producto que muestra: Animal, Canine, Fox, Kit Fox, Mammal.
```

---

## ✅ S3 — ANÁLISIS DE SENTIMIENTO (COMPLETADA)

### Qué se desplegó:

- ✅ **Lambda Comprehend:** `edson-martin-ontiveros-lima-AnalyzeSentiment`
- ✅ **Function URL:** `https://kyddwpmfvjt2so52ynhgmodapm0oqlrp.lambda-url.us-east-1.on.aws/`
- ✅ **Permisos IAM:** DynamoDB + Comprehend (DetectSentiment + DetectDominantLanguage)

### Flujo:

```
Cliente: POST /sentiment
  body: { "text": "..." } o { "reviews": [...], "productId": "abc" }
    ↓
Comprehend: DetectDominantLanguage → detecta idioma
Comprehend: DetectSentiment → analiza sentimiento (POSITIVE|NEGATIVE|NEUTRAL|MIXED)
    ↓
Si hay productId: DynamoDB → guarda reviewSentiment + reviewSentimentCounts
    ↓
Cliente: Recibe {sentiment: "POSITIVE"|"NEGATIVE", scores: {...}}
```

### Ejecución Real (Un Texto):

```bash
curl -s -X POST "https://kyddwpmfvjt2so52ynhgmodapm0oqlrp.lambda-url.us-east-1.on.aws/" \
  -H "Content-Type: application/json" \
  -d '{"text": "¡Excelente producto! Superó mis expectativas. Muy recomendado."}' | jq .
```

**Resultado:**
```json
{
    "count": 1,
    "overallSentiment": "POSITIVE",
    "results": [
        {
            "text": "¡Excelente producto! Superó mis expectativas. Muy recomendado.",
            "language": "es",
            "sentiment": "POSITIVE",
            "scores": {
                "Positive": 0.9999,
                "Negative": 0.0,
                "Neutral": 0.0001,
                "Mixed": 0.0
            }
        }
    ]
}
```

### Ejecución Real (Múltiples Reseñas + Guardar):

```bash
ProductId="6b4c4683-9f43-4c89-919f-516ba8362f5f"
curl -s -X POST "https://kyddwpmfvjt2so52ynhgmodapm0oqlrp.lambda-url.us-east-1.on.aws/" \
  -H "Content-Type: application/json" \
  -d "{
    \"reviews\": [
      \"¡Increíble! Mucho mejor que en la foto.\",
      \"Buena relación precio-calidad.\",
      \"Decepcionante, la tela se rompió.\",
      \"Recomendado, de verdad.\",
      \"Normal, nada especial.\"
    ],
    \"productId\": \"${ProductId}\"
  }" | jq .
```

**Resultado (salida acortada):**
```json
{
    "count": 5,
    "overallSentiment": "POSITIVE",
    "distribution": {
        "POSITIVE": 3,
        "NEGATIVE": 1,
        "MIXED": 1
    },
    "results": [...]
}
```

### Validación en DynamoDB:

```bash
aws dynamodb get-item --table-name edson-martin-ontiveros-lima-Products \
  --key "{\"productId\":{\"S\":\"${ProductId}\"}}" \
  --query 'Item.[reviewSentiment.S, reviewSentimentCounts.M]' --output text
```

**Resultado:**
```
POSITIVE    {POSITIVE: 3, NEGATIVE: 1, MIXED: 1}
```

---

## 📊 ESTADO ACTUAL DEL STACK

| Recurso | Estado | Notas |
|---------|--------|-------|
| **Stack** | ✅ CREATE_COMPLETE | edson-martin-ontiveros-lima |
| **DynamoDB** | ✅ 4 items + nuevos campos | S2: moderationStatus, moderationFlags, altText; S3: reviewSentiment, reviewSentimentCounts |
| **Router (S0)** | ✅ Funcional | CRUD completo |
| **S1 (Rekognition Labels)** | ✅ Funcional | aiLabels guardadas |
| **S2 (Moderación)** | ✅ Funcional | moderationStatus, altText guardados ✨ |
| **S3 (Sentimiento)** | ✅ Funcional | reviewSentiment guardado ✨ |
| **IAM** | ✅ Mínimo privilegio | Un rol por Lambda |
| **CloudWatch Logs** | ✅ Activos | S2 y S3 visibles |

---

## 🔑 CONCEPTOS APRENDIDOS

### S2 (Moderación + Alt-text):
- **Moderación de contenido:** detectar automáticamente material no apropiado (desnudez, violencia, etc.)
- **Alt-text accesible:** generar descripciones para personas ciegas/baja visión (WCAG 2.1)
- **Dos operaciones, dos propósitos:** DetectModerationLabels (seguridad) + DetectLabels (accesibilidad)
- **Responsibilidad en IA (D4 del examen):** cumplir regulaciones + inclusividad

### S3 (Sentimiento):
- **NLP preentrenado:** Comprehend analiza lenguaje natural sin entrenar modelos
- **Detección de idioma:** antes de analizar, detecta el idioma automáticamente
- **Puntuaciones de confianza:** cada predicción trae probabilidades (0–1)
- **Casos de uso:** reseñas, comentarios, feedback, monitoreo de marca
- **Fundamentals of AI/ML (D1 del examen):** elegir el servicio correcto (Comprehend para NLP, no Rekognition)

---

## ⚙️ CAMBIOS EN EL CÓDIGO

### `template.sandbox.yaml` — Fix de IAM

**Cambio único:** Agregar `comprehend:DetectDominantLanguage` a la política de S3

```yaml
# De:
- Statement:
    - Effect: Allow
      Action: comprehend:DetectSentiment
      Resource: "*"

# A:
- Statement:
    - Effect: Allow
      Action:
        - comprehend:DetectSentiment
        - comprehend:DetectDominantLanguage
      Resource: "*"
```

**Razón:** S3 necesitaba ambas operaciones: detectar idioma ANTES de analizar sentimiento. Sin `DetectDominantLanguage`, la Lambda fallaba con `AccessDeniedException`.

---

## 🎯 PRÓXIMOS PASOS

### Opción 1: Continuar con S4 (Traducción)
```bash
# S4 ya está en template.sandbox.yaml
# Simplemente llamar la Lambda TranslateCatalog
```

### Opción 2: Continuar con S5 (Polly)
```bash
# S5 ya está desplegada
# Generar síntesis de voz para accesibilidad
```

### Opción 3: Saltar a S6 (Bedrock)
```bash
# Modelos fundacionales (Claude) para descripciones y chatbot
# Requiere habilitar "Model access" en Bedrock console
```

---

## 🔒 PERMISOS IAM (VERIFICADO)

### S2 (ModerateImage):
- ✅ `dynamodb:GetItem`, `dynamodb:UpdateItem` en `ProductsTable`
- ✅ `rekognition:DetectModerationLabels`, `rekognition:DetectLabels` en `Resource: "*"`
- ✅ `s3:GetObject` en `arn:aws:s3:::edson-martin-ontiveros-lima-*/*`
- ❌ No puede tocar otros buckets, tablas u otros servicios

### S3 (AnalyzeSentiment):
- ✅ `dynamodb:GetItem`, `dynamodb:UpdateItem` en `ProductsTable`
- ✅ `comprehend:DetectSentiment`, `comprehend:DetectDominantLanguage` en `Resource: "*"`
- ❌ No puede acceder a S3, Rekognition, o otros servicios

---

## 💸 COSTO ESTIMADO

| Sesión | Servicio | Precio | Volumen (pruebas) | Costo |
|--------|----------|--------|-------------------|-------|
| **S2** | Rekognition | $0.80/1000 imágenes | 2 ops × 1 imagen | $0.0016 |
| **S3** | Comprehend | $100/1M unidades | 2 ops × 5 textos | $0.001 |
| **TOTAL (este sprint)** | — | — | — | **~$0.0026** |

En producción: ~$1–2/mes para S2+S3 con 1,000 imágenes + 1,000 reseñas/mes.

---

## 📁 ARCHIVOS GENERADOS

- **[S2-GUIA-EJECUTADA.md](S2-GUIA-EJECUTADA.md)** — Paso a paso detallado de S2 (moderación + alt-text)
- **[S3-GUIA-EJECUTADA.md](S3-GUIA-EJECUTADA.md)** — Paso a paso detallado de S3 (análisis de sentimiento)
- **[RESUMEN-S2-S3-COMPLETADA.md](RESUMEN-S2-S3-COMPLETADA.md)** — Este archivo

---

## 🧹 CLEANUP

**NO borres aún** — S4–S11 construyen sobre S2 y S3. Solo limpia cuando termines TODO:

```bash
bash scripts/delete-all.sh
```

---

**Estado Final:** ✅ **S2 y S3 completadas, documentadas y validadas**

Próximo: S4 (Traducción), S5 (Polly), S6–S9 (Bedrock)...
