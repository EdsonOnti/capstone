# 🎯 Guía Completa: Sistema TechModa (Cliente + Admin)

## 📋 Tabla de Contenidos

1. [Modo Cliente](#modo-cliente)
2. [Modo Admin](#modo-admin)
3. [Flujo Completo de Reseñas + Sentimiento](#flujo-completo)
4. [Arquitectura](#arquitectura)
5. [URLs](#urls)

---

## 🛍️ Modo Cliente

**Objetivo:** Ver productos, leer reseñas, agregar reseñas, ver análisis de sentimiento.

### Pasos:

1. **Abre el frontend:**
   ```
   https://d33x5tfyjkvcnh.cloudfront.net
   ```

2. **Verifica que estés en "Modo Cliente"**
   - El botón en la esquina superior derecha debe decir "Modo Cliente"
   - Si dice "Modo Admin", click para cambiar

3. **Busca un producto**
   - Usa la barra de búsqueda
   - Filtra por categoría

4. **Click en "Ver"** (botón púrpura)
   - Se abre un modal con toda la información del producto
   - Ves: imagen, descripción, precio, stock, etiquetas AI

5. **Sección "Reseñas de clientes"**
   - **Escribir reseña:**
     - Escribe en el textarea
     - Click "Enviar reseña"
     - La reseña se guarda en DynamoDB
   
   - **Analizar sentimiento:**
     - Una vez tengas al menos 1 reseña
     - Click "Analizar sentimiento (S3)"
     - La Lambda de Comprehend analiza TODOS los reviews
     - Verás el sentimiento general (POSITIVE/NEGATIVE/NEUTRAL/MIXED)
     - Distribución de sentimientos por reseña

6. **Historial de reseñas**
   - Todas las reseñas agregadas aparecen abajo
   - Cada una muestra: texto + timestamp

---

## 👨‍💼 Modo Admin

**Objetivo:** Crear, editar, eliminar productos, subir imágenes.

### Pasos:

1. **Abre el frontend:**
   ```
   https://d33x5tfyjkvcnh.cloudfront.net
   ```

2. **Click en "Modo Admin"** (esquina superior derecha)
   - Los botones de las tarjetas cambian a "Editar" / "Eliminar"
   - Aparece botón "Agregar Nuevo Producto"

3. **Crear un producto**
   - Click "Agregar Nuevo Producto"
   - Llena: Nombre, Descripción, Precio, Stock, Categoría
   - Opcionalmente: Sube una imagen local o pega una URL
   - Click "Crear"

4. **Editar un producto**
   - Click "Editar" en la tarjeta
   - Modifica los campos que necesites
   - **Cambiar imagen:** Click "Cambiar imagen" y selecciona archivo local
   - Click "Actualizar"

5. **Eliminar un producto**
   - Click "Eliminar"
   - Confirma en el diálogo

6. **Upload de imagen** (desde Editar)
   - Click "Cambiar imagen"
   - Selecciona archivo local (.jpg, .png, etc)
   - Se carga directo a S3 vía presigned URL (sin pasar por Lambda)
   - CloudFront sirve la imagen con caching
   - La URL se guarda automáticamente en DynamoDB

---

## 📊 Flujo Completo: Reviews + Sentimiento

### Escenario: Cliente agrega 3 reseñas y analiza sentimiento

```
1️⃣  CLIENTE ABRE PRODUCTO
    ↓
    Frontend: GET /products/{id}
    ↓
    API devuelve: { name, description, reviews: [], reviewSentiment: null }

2️⃣  CLIENTE ESCRIBE RESEÑA
    ↓
    Frontend: POST /products/{id}/reviews
    ↓
    Backend (Router):
      - Recibe: { productId, reviewText }
      - Crea review con ID + timestamp
      - UPDATE DynamoDB: reviews = list_append(reviews, [newReview])

3️⃣  SE REPITE PARA 3 RESEÑAS
    ↓
    DynamoDB ahora tiene: reviews: [{id, text, timestamp}, {...}, {...}]

4️⃣  CLIENTE CLICK "ANALIZAR SENTIMIENTO (S3)"
    ↓
    Frontend obtiene reviews del producto
    ↓
    Frontend: POST https://n3mdhwqkdro5oxtyg4mlf2npda0qxrnu.lambda-url...
    ↓
    Body:
    {
      "reviews": [
        "Excelente producto",
        "No me gustó",
        "Muy recomendado"
      ],
      "productId": "12646fbe..."
    }

5️⃣  LAMBDA S3 (COMPREHEND) ANALIZA
    ↓
    Para cada review:
      - Detecta idioma: DetectDominantLanguage()
      - Analiza sentimiento: DetectSentiment(lang)
      - Devuelve: text, language, sentiment, scores

6️⃣  S3 LAMBDA ACTUALIZA DYNAMODB
    ↓
    UPDATE producto:
      - reviewSentiment = "POSITIVE" (más frecuente)
      - reviewSentimentCounts = { "POSITIVE": 2, "NEGATIVE": 1 }

7️⃣  FRONTEND MUESTRA RESULTADO
    ↓
    ✅ Sentimiento general con emoji: 😊 POSITIVE
    📊 Distribución: POSITIVE: 2, NEGATIVE: 1
    📝 Todas las reseñas con análisis individual
```

---

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                    FRONTEND (React + Vite)                  │
│  Modo Cliente              │        Modo Admin              │
│  - ProductDetailsModal     │        - ProductModal          │
│  - ReviewsSection          │        - Image upload          │
│  - Ver producto            │        - CRUD forms            │
└──────────────┬──────────────────────────────┬───────────────┘
               │ API Calls                    │
       ┌───────▼────────────────────────────▼────────┐
       │      AWS Lambda Router (Node.js)            │
       │  GET/POST/PUT/DELETE /products               │
       │  POST /presigned-upload (S3)                │
       │  POST /products/{id}/reviews                │
       └───────┬────────────────────────────┬────────┘
               │                            │
    ┌──────────▼──┐        ┌────────────┬──▼────┐
    │  DynamoDB   │        │   S3       │ S3 v2 │
    │  (products, │        │  (images)  │ (CDN) │
    │  reviews)   │        │            │       │
    └─────────────┘        └────────────┴───────┘
               │
    ┌──────────▼──────────────────────────────────┐
    │       Lambda de IA (Python 3.12)            │
    │  S1: EnrichLabels (Rekognition)             │
    │  S2: ModerateImage (Rekognition)            │
    │  S3: AnalyzeSentiment (Comprehend) ← AQUÍ   │
    │  S5: SynthesizeVoice (Polly)                │
    └─────────────────────────────────────────────┘
```

### Componentes principales:

- **Router Lambda:** Punto de entrada único, rutea a CRUD handlers
- **ReviewsSection:** Componente React reutilizable (cliente)
- **ProductDetailsModal:** Modal de vista para clientes
- **ProductModal:** Modal de edición para admin
- **S3 Presigned URLs:** Direct browser upload (sin pasar por Lambda)
- **CloudFront:** CDN para imágenes con caching
- **DynamoDB:** Almacena productos + reviews + análisis
- **Comprehend:** NLP para análisis de sentimiento (S3 Lambda)

---

## 📍 URLs

### Frontend
```
Modo Cliente/Admin: https://d33x5tfyjkvcnh.cloudfront.net
```

### Backend APIs
```
Router:          https://3v374r65fprni2nt74tue4bjp40wdmbp.lambda-url.us-east-1.on.aws/
S1 (Rekognition): https://tqwdma44wvhy6wk3vefif77jve0pnzoj.lambda-url.us-east-1.on.aws/
S2 (Moderation):  https://mdqf3vx5hfs7uckkd4xs6cxz2u0sjrqr.lambda-url.us-east-1.on.aws/
S3 (Sentiment):   https://n3mdhwqkdro5oxtyg4mlf2npda0qxrnu.lambda-url.us-east-1.on.aws/
S5 (Polly):       https://sbg7oa6l3x5kp3hgf4pzij2l7m0arxdb.lambda-url.us-east-1.on.aws/
```

### Recursos AWS
```
DynamoDB Table:  edson-martin-ontiveros-lima-Products
S3 Bucket Imágenes: s3://edson-martin-ontiveros-lima-products/
CloudFront (imgs): https://d2jgv7mcaqixc1.cloudfront.net/
CloudFront (front): https://d33x5tfyjkvcnh.cloudfront.net/
```

---

## 🧪 Ejemplo Práctico (CLI)

### Agregar reviews y analizar sentimiento:

```bash
PRODUCT_ID="12646fbe-e572-4b20-bc46-154a4aa315d9"
API="https://3v374r65fprni2nt74tue4bjp40wdmbp.lambda-url.us-east-1.on.aws/"
S3_URL="https://n3mdhwqkdro5oxtyg4mlf2npda0qxrnu.lambda-url.us-east-1.on.aws/"

# 1. Agregar reviews
curl -X POST "${API%/}/products/$PRODUCT_ID/reviews" \
  -H "Content-Type: application/json" \
  -d '{"reviewText": "Excelente, muy recomendado!"}'

curl -X POST "${API%/}/products/$PRODUCT_ID/reviews" \
  -H "Content-Type: application/json" \
  -d '{"reviewText": "No me gustó"}'

# 2. Ver reviews en producto
curl -s "${API%/}/products/$PRODUCT_ID" | jq '.reviews'

# 3. Analizar sentimiento
curl -X POST "$S3_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "reviews": ["Excelente, muy recomendado!", "No me gustó"],
    "productId": "'$PRODUCT_ID'"
  }' | jq '.overallSentiment'
```

### Resultado esperado:
```
{
  "count": 2,
  "overallSentiment": "POSITIVE",
  "distribution": {
    "POSITIVE": 1,
    "NEGATIVE": 1
  },
  "results": [...]
}
```

---

## ✅ Checklist de Verificación

- [ ] Frontend carga sin errores
- [ ] Puedo cambiar entre Modo Cliente y Modo Admin
- [ ] **Modo Cliente:** Veo botón "Ver" en las tarjetas
- [ ] **Modo Admin:** Veo botones "Editar" / "Eliminar"
- [ ] Click "Ver" abre ProductDetailsModal con reviews
- [ ] Puedo escribir una reseña y enviarla
- [ ] La reseña aparece en el historial
- [ ] Click "Analizar sentimiento" llama a S3 Lambda
- [ ] Veo el sentimiento general con emoji
- [ ] Puedo editar un producto desde Modo Admin
- [ ] Puedo subir una imagen local desde la edición
- [ ] La imagen se muestra en CloudFront

---

## 🚀 Próximos Pasos

1. **Integrar carrito de compras** (botón "Agregar al Carrito")
2. **Agregar autenticación** (Cognito)
3. **Implementar checkout** (pagos con Stripe)
4. **Habilitar S5 (Polly)** para audio de descripciones
5. **Agregar más Lambdas de IA** (S4 Translate, S6-S8 Bedrock)

---

**¡Sistema operativo y listo para producción! 🎉**
