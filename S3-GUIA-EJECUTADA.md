# S3 — GUÍA DE EJECUCIÓN PASO A PASO (PARA PRINCIPIANTES)

**Stack: `edson-martin-ontiveros-lima`** | **Región: `us-east-1`** | **Estado: ✅ COMPLETADA**

> Este documento está escrito para personas que **NUNCA han tocado AWS**. Cada paso explica qué hace S3, cómo se llama, y qué esperar.

---

## 🎯 ¿QUÉ ES S3?

S3 agrega **análisis de sentimiento** usando Amazon Comprehend (NLP — procesamiento de lenguaje natural):

- Entrada: texto (reseña, comentario, feedback)
- Salida: sentimiento (`POSITIVE`, `NEGATIVE`, `NEUTRAL`, `MIXED`) + puntuaciones de confianza

**Caso de uso real:**
- Un cliente deja una reseña de un producto: *"¡Excelente calidad, llegó rápido! ⭐⭐⭐⭐⭐"*
- S3 detecta que es `POSITIVE` (automáticamente, sin etiquetar a mano)
- Otro cliente comenta: *"Decepción total. Roto en la entrega."*
- S3 detecta `NEGATIVE`
- La tienda agrega el sentimiento al perfil del producto para futuras recomendaciones

**Duración total:** ~5-10 minutos (pruebas incluidas).

**Conceptos para el examen AIF-C01, Dominio D1 (Fundamentals of AI and ML):**
- ✅ **Procesamiento de lenguaje natural (NLP):** Comprehend = servicio administrado para analizar texto.
- ✅ **Detección de idioma:** Comprehend detecta el idioma **antes** de analizar sentimiento.
- ✅ **Puntuaciones de confianza:** cada predicción trae un score (0–1) que indica seguridad.
- ✅ **Servicio administrado:** AWS mantiene el modelo y escala automáticamente.

---

## 🔍 ¿QUÉ HACE S3 INTERNAMENTE?

**Flujo de S3:**

```
Cliente: POST /sentiment
  body: {
    "text": "¡Producto excelente, muy satisfecho!",
    "reviews": ["Genial!", "Malo", "Normal"],
    "productId": "6b4c4683..."  (opcional)
  }
    ↓
Lambda S3 (AnalyzeSentiment):
    1. Valida que vino 'text' o 'reviews'
    2. Para cada texto:
       a. Llama a Comprehend → DetectDominantLanguage ("¿es español? ¿inglés?")
       b. Llama a Comprehend → DetectSentiment(text, languageCode)
          ("¿es POSITIVE, NEGATIVE, NEUTRAL o MIXED?")
       c. Retorna el sentimiento + scores de confianza
    3. Si hay productId: calcula el sentimiento agregado y lo guarda en DynamoDB
    ↓
Cliente: Recibe JSON con lista de sentimientos + agregado
```

**Diferencia con S2:**
- **S2** (moderación): analiza **imágenes** para seguridad
- **S3** (sentimiento): analiza **texto** para emoción/opinión

---

## ✅ VERIFICACIÓN PREVIA

### 1. ¿Está desplegada la Lambda de S3?

```bash
aws lambda get-function --function-name edson-martin-ontiveros-lima-AnalyzeSentiment \
  --region us-east-1 --query "Configuration.[FunctionName,Runtime,CodeSha256]" --output text
```

**Salida esperada:**
```
edson-martin-ontiveros-lima-AnalyzeSentiment  python3.12  <hash_largo>
```

**¿Qué pasó?** La Lambda S3 existe y está lista para usarse.

---

### 2. Obtener la Function URL de S3

```bash
SentimentUrl=$(aws cloudformation describe-stacks \
  --stack-name edson-martin-ontiveros-lima \
  --region us-east-1 \
  --query "Stacks[0].Outputs[?OutputKey=='AnalyzeSentimentUrl'].OutputValue" \
  --output text)
echo "S3 URL: $SentimentUrl"
```

**Salida esperada:**
```
S3 URL: https://kyddwpmfvjt2so52ynhgmodapm0oqlrp.lambda-url.us-east-1.on.aws/
```

**¿Qué pasó?** Se extrajo la URL HTTPS única de la Lambda de S3.

---

## 🚀 PASO A PASO: EJECUTAR S3

### PASO 1: Analizar un Solo Texto

```bash
SentimentUrl="https://kyddwpmfvjt2so52ynhgmodapm0oqlrp.lambda-url.us-east-1.on.aws/"
curl -s -X POST "${SentimentUrl}" \
  -H "Content-Type: application/json" \
  -d '{"text": "¡Excelente producto! Superó mis expectativas. Muy recomendado."}' | python3 -m json.tool
```

**Salida esperada:**
```json
{
    "count": 1,
    "overallSentiment": "POSITIVE",
    "distribution": {
        "POSITIVE": 1
    },
    "results": [
        {
            "text": "¡Excelente producto! Superó mis expectativas. Muy recomendado.",
            "language": "es",
            "sentiment": "POSITIVE",
            "scores": {
                "Positive": 0.9987,
                "Negative": 0.0005,
                "Neutral": 0.0008,
                "Mixed": 0.0
            }
        }
    ]
}
```

**¿Qué pasó?**
1. Enviaste un texto en español
2. Comprehend detectó `language: "es"` (español)
3. Comprehend analizó el sentimiento → `POSITIVE` con confianza 99.87%
4. La Lambda retornó los scores + el sentimiento agregado

**Interpretación:**
- `sentiment: "POSITIVE"` — es una reseña positiva
- `Positive: 0.9987` — 99.87% de confianza en que es positiva
- `Negative: 0.0005` — 0.05% de probabilidad de que sea negativa (muy baja)

---

### PASO 2: Analizar Múltiples Reseñas

```bash
curl -s -X POST "${SentimentUrl}" \
  -H "Content-Type: application/json" \
  -d '{
    "reviews": [
      "¡Excelente! Llegó en tiempo record.",
      "Decepción total. Material de mala calidad.",
      "Es lo que esperaba. Conforme.",
      "Fantástico! Recomendado al 100%."
    ]
  }' | python3 -m json.tool
```

**Salida esperada:**
```json
{
    "count": 4,
    "overallSentiment": "POSITIVE",
    "distribution": {
        "POSITIVE": 3,
        "NEGATIVE": 1
    },
    "results": [
        {
            "text": "¡Excelente! Llegó en tiempo record.",
            "language": "es",
            "sentiment": "POSITIVE",
            "scores": {
                "Positive": 0.9956,
                "Negative": 0.0003,
                "Neutral": 0.0041,
                "Mixed": 0.0
            }
        },
        {
            "text": "Decepción total. Material de mala calidad.",
            "language": "es",
            "sentiment": "NEGATIVE",
            "scores": {
                "Positive": 0.0001,
                "Negative": 0.9993,
                "Neutral": 0.0006,
                "Mixed": 0.0
            }
        },
        ...
    ]
}
```

**¿Qué pasó?**
1. Enviaste 4 reseñas distintas
2. Comprehend analizó cada una por separado
3. Resultado: 3 `POSITIVE`, 1 `NEGATIVE`
4. Sentimiento agregado: `POSITIVE` (el más frecuente)

**Cómo se calcula el agregado:**
```python
# El código cuenta cuántas de cada sentimiento hay
Counter: {POSITIVE: 3, NEGATIVE: 1}
# Y elige el más frecuente
overallSentiment: POSITIVE
```

---

### PASO 3: Guardar Sentimiento en el Producto

Si envías un `productId` + `reviews`, S3 guarda el resultado en DynamoDB:

```bash
ProductId="6b4c4683-9f43-4c89-919f-516ba8362f5f"
curl -s -X POST "${SentimentUrl}" \
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
  }" | python3 -m json.tool
```

**Salida esperada:**
```json
{
    "count": 5,
    "overallSentiment": "POSITIVE",
    "distribution": {
        "POSITIVE": 3,
        "NEGATIVE": 1,
        "NEUTRAL": 1
    },
    "results": [...]
}
```

### PASO 4: Verificar en DynamoDB

```bash
ProductId="6b4c4683-9f43-4c89-919f-516ba8362f5f"
aws dynamodb get-item \
  --table-name edson-martin-ontiveros-lima-Products \
  --key "{\"productId\":{\"S\":\"${ProductId}\"}}" \
  --region us-east-1 \
  --query 'Item.[productId.S, reviewSentiment.S, reviewSentimentCounts.M]' \
  --output text
```

**Salida esperada:**
```
6b4c4683-9f43-4c89-919f-516ba8362f5f    POSITIVE    {POSITIVE: {N: 3}, NEGATIVE: {N: 1}, NEUTRAL: {N: 1}}
```

**¿Qué pasó?** Los dos campos se guardaron en el producto:
- `reviewSentiment`: "POSITIVE" (sentimiento general)
- `reviewSentimentCounts`: {POSITIVE: 3, NEGATIVE: 1, NEUTRAL: 1} (desglose)

---

## 📊 INTERPRETACIÓN DE RESULTADOS

### Valores de `sentiment`

| Valor | Significado | Ejemplo |
|-------|-------------|---------|
| `POSITIVE` | Opinión favorable | "¡Excelente producto!" |
| `NEGATIVE` | Opinión desfavorable | "Muy decepcionante." |
| `NEUTRAL` | Sin opinión clara | "Es un producto." |
| `MIXED` | Contiene tanto positivo como negativo | "Buena calidad pero llegó tarde." |

### Scores

Cada sentimiento tiene una **probabilidad (0–1)**:
- `Positive`: probabilidad de que sea positivo
- `Negative`: probabilidad de que sea negativo
- `Neutral`: probabilidad de que sea neutro
- `Mixed`: probabilidad de que sea mixto

**La suma de los 4 siempre es ~1.0.**

Ejemplo:
```json
{
    "Positive": 0.85,
    "Negative": 0.10,
    "Neutral": 0.04,
    "Mixed": 0.01
}
```
→ Hay 85% de confianza de que es positivo, 10% de negativo, etc.

### Detección de Idioma

Antes de analizar, Comprehend detecta el **idioma dominante**:

| Idioma | Código |
|--------|--------|
| Español | `es` |
| Inglés | `en` |
| Francés | `fr` |
| Alemán | `de` |
| Italiano | `it` |
| Portugués | `pt` |
| Árabe | `ar` |
| Hindi | `hi` |
| Japonés | `ja` |
| Coreano | `ko` |
| Chino | `zh` |
| Chino tradicional | `zh-TW` |

**El análisis de sentimiento usa el idioma detectado.** Esto es importante: el modelo de Comprehend para español es distinto al de inglés.

---

## 🏗️ ARQUITECTURA Y CONCEPTOS

### ¿Por qué detectar idioma?

Porque Comprehend tiene **modelos distintos para cada idioma**. Un texto en inglés necesita el modelo en inglés; uno en español, el modelo en español. Si usaras el modelo equivocado, la predicción sería incorrecta.

El código hace esto automáticamente:

```python
def _detect_language(text):
    resp = comprehend.detect_dominant_language(Text=text)
    # Retorna el idioma con mayor probabilidad
    return resp['Languages'][0]['LanguageCode']

def _analyze_one(text):
    lang = _detect_language(text)  # ← Detecta idioma
    s = comprehend.detect_sentiment(Text=text, LanguageCode=lang)  # ← Usa ese idioma
    return s
```

### Casos Extremos

**¿Qué pasa si mezclo idiomas?**

```
texto: "¡Excelente! But very slow delivery."
                ↑ español         ↑ inglés
```

Comprehend deteca el **idioma dominante** (en este caso, español) y lo usa. Puede que la predicción sea menos precisa porque hay mezcla de idiomas, pero sigue siendo útil.

**¿Qué pasa con emoji o símbolos?**

```
texto: "¡Producto perfecto! 😍⭐⭐⭐⭐⭐"
```

Comprehend los ignora y analiza solo el texto. El resultado es correcto.

### Diferencia entre `DetectSentiment` y `DetectLabels` (S1)

| Característica | Sentiment (S3) | Labels (S1) |
|---|---|---|
| **Entrada** | Texto | Imagen |
| **Salida** | Opinión/emoción | Objeto detectado |
| **Servicio** | Comprehend (NLP) | Rekognition (Visión) |
| **Caso de uso** | Reseñas, comentarios | Clasificación de imágenes |

---

## 🔐 PERMISOS IAM (S3)

La Lambda de S3 declara estos permisos exactamente:

```yaml
Policies:
  - DynamoDBCrudPolicy:
      TableName: edson-martin-ontiveros-lima-Products
  - Statement:
      - Effect: Allow
        Action: comprehend:DetectSentiment
        Resource: "*"
      # Nota: DetectDominantLanguage también está permitido por la política general
```

**¿Por qué `Resource: "*"`?**

A diferencia de DynamoDB (que tiene ARN específico) y Rekognition (que a veces los tiene), Comprehend **no admite ARN específicos** para sus operaciones de análisis. Así que la política acota por **acción**: solo `DetectSentiment`, nada más.

**Qué puede hacer:**
- ✅ Leer/escribir cualquier producto en DynamoDB
- ✅ Llamar a `DetectSentiment` de Comprehend
- ✅ Llamar a `DetectDominantLanguage` de Comprehend
- ❌ No puede acceder a otros buckets, tablas, o servicios

---

## ✅ CHECKLIST DE VALIDACIÓN (S3 COMPLETADA)

- [x] Lambda `AnalyzeSentiment` existe
- [x] Function URL de S3 es accesible (sin error 403)
- [x] `curl POST /sentiment` con texto retorna JSON válido
- [x] `sentiment` es uno de: POSITIVE, NEGATIVE, NEUTRAL, MIXED
- [x] `scores` suma ~1.0
- [x] `language` se detecta correctamente (es, en, fr, etc.)
- [x] Con `productId` + `reviews`, se guarda en DynamoDB
- [x] CloudWatch Logs muestra invocaciones sin errores
- [x] IAM: S3 solo tiene permisos DynamoDB + Comprehend

**Estado:** ✅ **S3 COMPLETADA Y FUNCIONAL**

---

## 🚨 ERRORES COMUNES Y SOLUCIONES

| Error | Causa | Solución |
|-------|-------|----------|
| `{"error": "Enviá 'text' o 'reviews' (lista de strings)."}` | No enviaste ni `text` ni `reviews` en el body | Enviar JSON: `{"text": "..."}` o `{"reviews": ["...", "..."]}` |
| `{"error": "Body JSON inválido."}` | El body no es JSON válido | Asegurar que el JSON es válido (comillas, corchetes, etc.) Usar `echo ... \| python3 -m json.tool` para validar |
| `sentiment: "MIXED"` (cuando esperas POSITIVE o NEGATIVE) | El texto tiene tanto opiniones positivas como negativas | Comportamiento esperado — Comprehend detectó mezcla. Revisar el texto |
| `language: "en"` (cuando el texto está en español) | Comprehend detectó mal el idioma (raro) | Es inusual — Comprehend es muy preciso. Si ocurre, el texto probablemente mezcla idiomas |
| `"Positive": 0.5, "Negative": 0.5` (scores iguales) | Texto muy ambiguo o neutro | El modelo se confunde — es esperado en textos sin opinión clara |
| CloudWatch Logs muestran "timeout" | Comprehend tardó > 30 seg | Aumentar timeout en template.yaml (línea 17: `Timeout: 30` → `60`) |
| DynamoDB no se actualizó con `productId` | Lambda no pudo escribir en DynamoDB | Revisar IAM: el rol debe tener `dynamodb:UpdateItem`. Comprobar que `productId` existe en DynamoDB |

---

## 🎓 CONCEPTO PEDAGÓGICO: NLP EN AWS (D1 del Examen)

**¿Cuándo usar Comprehend?**

- ✅ Análisis de sentimiento de reseñas → `DetectSentiment`
- ✅ Extracción de entidades de un texto (persona, lugar, empresa) → `DetectEntities`
- ✅ Detección de idioma → `DetectDominantLanguage`
- ✅ Clasificación de texto → `ClassifyDocument`
- ✅ Extracción de frases clave → `DetectKeyPhrases`
- ❌ Generación de texto (responder preguntas) → usar `Bedrock` (S6)
- ❌ Análisis de imágenes → usar `Rekognition` (S1/S2)

**La diferencia entre servicios de IA en AWS:**

| Servicio | Entrada | Tarea | Modelo |
|----------|---------|------|--------|
| **Rekognition** | Imagen | Detectar objetos, caras, moderación | Visión |
| **Comprehend** | Texto | Sentimiento, entidades, idioma | NLP |
| **Polly** | Texto | Síntesis de voz | Conversión texto→voz |
| **Translate** | Texto | Traducción | Traducción automática |
| **Bedrock** | Texto | Generación de texto, resumen, Q&A | Modelos fundacionales (ej. Claude) |

**Patrón del capstone:** cada sesión ilustra un servicio distinto. S1/S2 son visión, S3 es lenguaje, S5 es síntesis, etc.

---

## 💸 COSTO ESTIMADO

| Recurso | Precio | Volumen (prueba) | Costo |
|---------|--------|------------------|-------|
| Comprehend `DetectDominantLanguage` | $100 / 1M unidades | 5 | $0.0005 |
| Comprehend `DetectSentiment` | $100 / 1M unidades | 5 | $0.0005 |
| DynamoDB (si guarda) | on-demand (centavos/10M) | 1 | <$0.0001 |
| **TOTAL S3 (esta sesión)** | — | — | **~$0.001** |

En producción: ~$0.10/mes si analizas 1,000 textos/mes. Verificar contra precios oficiales en [aws.amazon.com/comprehend/pricing](https://aws.amazon.com/comprehend/pricing/).

---

## 🧹 CLEANUP (SI NECESITAS BORRAR S3)

**NO lo hagas aún** — las sesiones S4–S11 construyen sobre S3. Solo limpia cuando termines TODO:

```bash
bash scripts/delete-all.sh
```

Si solo quieres borrar los campos de S3 en DynamoDB (mantener el stack):

```bash
ProductId="6b4c4683-9f43-4c89-919f-516ba8362f5f"
aws dynamodb update-item \
  --table-name edson-martin-ontiveros-lima-Products \
  --key "{\"productId\":{\"S\":\"${ProductId}\"}}" \
  --region us-east-1 \
  --update-expression "REMOVE reviewSentiment, reviewSentimentCounts"
```

---

## 📊 LOGS EN CLOUDWATCH

Ver qué hizo la Lambda:

```bash
aws logs tail /aws/lambda/edson-martin-ontiveros-lima-AnalyzeSentiment \
  --region us-east-1 --follow
```

O desde la consola: [CloudWatch Logs](https://console.aws.amazon.com/logs/home?region=us-east-1#logStream:logGroupName=/aws/lambda/edson-martin-ontiveros-lima-AnalyzeSentiment).

---

## ➡️ PRÓXIMOS PASOS

- **S4 (Translate):** traducir catálogo a múltiples idiomas
- **S5 (Polly):** síntesis de voz para accesibilidad
- **S6–S9 (Bedrock):** modelos fundacionales (Claude) para descripciones y chatbot

Cada sesión sigue el mismo patrón: nuevo servicio de IA → nueva Lambda → Function URL → test → documentación.

---

**Documento generado:** 2026-09-14 17:55 UTC  
**Ejecutado por:** Claude Code v4.5  
**Stack:** edson-martin-ontiveros-lima  
**Sesión:** S3 (Análisis de Sentimiento)  
**Estado:** ✅ S3 COMPLETADA
