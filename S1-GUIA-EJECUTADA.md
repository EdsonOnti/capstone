# S1 — AUTO-ETIQUETADO DE IMÁGENES CON REKOGNITION (GUÍA EJECUTADA)

**Stack: `edson-martin-ontiveros-lima`** | **Región: `us-east-1`** | **Estado: ✅ COMPLETADA**

> Este documento registra la ejecución paso a paso de **S1** (Rekognition DetectLabels) para una persona que nunca ha tocado AWS.

---

## 🎯 ¿QUÉ ES S1?

S1 agrega **etiquetado automático de imágenes** a los productos de la tienda.

### Flujo:

```
Tienes un producto con foto
       ↓
Llamas a la Lambda de Rekognition
       ↓
Amazon Rekognition analiza la imagen
       ↓
Devuelve etiquetas con confianza
Ejemplo: ["Clothing", "Dress", "Fabric", "Apparel"]
       ↓
Se guardan en DynamoDB
```

### Caso de uso real:

- Filtros de catálogo: "Mostrar solo Ropa"
- Búsqueda por facetas: clientes ven "Zapatos", "Vestidos", etc.
- Control de calidad: rechazar fotos que no son de producto

### Concepto pedagógico (D1 del examen):

- **Inferencia vs. Entrenamiento:** Aquí solo hacemos inferencia (pedir predicción a un modelo ya hecho). **No hay entrenamiento ni GPUs.**
- **Confianza/Score:** Cada etiqueta trae % de confianza (0–100%). Con `MinConfidence=80`, solo aceptamos etiquetas con ≥80% seguridad.
- **Servicio administrado:** AWS mantiene el modelo. Vos solo llamas la API.

**Duración:** ~10 minutos

---

## 🚨 REQUISITO PREVIO

✅ **S0 desplegada y funcional** (productos ya en DynamoDB, API respondiendo)

Comando para verificar:
```bash
curl -s "https://3v374r65fprni2nt74tue4bjp40wdmbp.lambda-url.us-east-1.on.aws/products" | jq '.products | length'
# Debe retornar: 4
```

---

## 🏗️ ¿POR QUÉ S1 YA ESTÁ DEPLOYADA?

En S0, usamos `template.sandbox.yaml` que **ya incluye S1** (Rekognition) porque:
- **Deploy más rápido:** sandbox template = sin CloudFront
- **Para práctica rápida:** levanta en ~2–3 min en lugar de 10+

Si hubiéramos usado `template.yaml` (base pura), tendríamos que:
1. Copiar `template-snippet.yaml` de S1
2. Pegarlo en el template
3. Hacer `sam build && sam deploy`

Pero el resultado es el mismo: una Lambda nueva con su Function URL.

---

## ✅ VALIDACIÓN: VERIFICAR QUE S1 YA EXISTE

### Paso 1: Confirmar que la Lambda existe

```bash
aws lambda list-functions --region us-east-1 \
  --query "Functions[?contains(FunctionName, 'EnrichLabels')].FunctionName" \
  --output table
```

**Salida esperada:**
```
----------------------
|  ListFunctions    |
+--------------------+
|  edson-martin-... -EnrichLabels  |
+--------------------+
```

✅ **La Lambda `EnrichLabels` existe.**

### Paso 2: Obtener la Function URL de S1

```bash
EnrichLabelsUrl=$(aws cloudformation describe-stacks \
  --stack-name edson-martin-ontiveros-lima \
  --region us-east-1 \
  --query "Stacks[0].Outputs[?OutputKey=='EnrichLabelsUrl'].OutputValue" \
  --output text)
echo "S1 Function URL: $EnrichLabelsUrl"
```

**Salida esperada:**
```
S1 Function URL: https://s4agnwvtu4afqbwhrfd25mnmp40kqgxs.lambda-url.us-east-1.on.aws/
```

✅ **La Function URL es accesible.**

---

## 🖼️ PASO 1: PREPARAR UNA IMAGEN

**¿Por qué?** Rekognition necesita una imagen real para analizar. Los productos de seed vinieron con `imageUrl` = placeholder.

### Opción A: Usar una URL pública

La más simple para pruebas:

```bash
PRODUCT_ID="6b4c4683-9f43-4c89-919f-516ba8362f5f"  # Un productId real

aws dynamodb update-item \
  --table-name edson-martin-ontiveros-lima-Products \
  --region us-east-1 \
  --key "{\"productId\":{\"S\":\"$PRODUCT_ID\"}}" \
  --update-expression "SET imageUrl = :url" \
  --expression-attribute-values "{\":url\":{\"S\":\"https://httpbin.org/image/jpeg\"}}" \
  --return-values UPDATED_NEW
```

**Qué pasó:** Se actualizó el campo `imageUrl` del producto en DynamoDB con una URL pública que funciona.

### Opción B: Subir a S3 (producción)

```bash
# 1. Crear/descargar una imagen
curl -s -L "https://via.placeholder.com/200/FF6B6B/FFFFFF?text=Tenis" -o /tmp/tenis.jpg

# 2. Subir a S3
aws s3 cp /tmp/tenis.jpg "s3://tu-bucket/assets/tenis.jpg" --region us-east-1

# 3. Actualizar el producto
aws dynamodb update-item \
  --table-name edson-martin-ontiveros-lima-Products \
  --region us-east-1 \
  --key "{\"productId\":{\"S\":\"$PRODUCT_ID\"}}" \
  --update-expression "SET imageUrl = :url" \
  --expression-attribute-values "{\":url\":{\"S\":\"s3://tu-bucket/assets/tenis.jpg\"}}" \
  --return-values UPDATED_NEW
```

**Ventaja:** Rekognition accede a S3 más rápido (mismo cloud) y el rol de la Lambda puede leer del bucket.

---

## 🚀 PASO 2: LLAMAR A LA LAMBDA DE REKOGNITION

```bash
PRODUCT_ID="6b4c4683-9f43-4c89-919f-516ba8362f5f"
EnrichLabelsUrl="https://s4agnwvtu4afqbwhrfd25mnmp40kqgxs.lambda-url.us-east-1.on.aws/"

curl -s -X POST "${EnrichLabelsUrl%/}/products/$PRODUCT_ID/labels" | python3 -m json.tool
```

**Desglose:**
- `-X POST` → verbo HTTP POST
- `${EnrichLabelsUrl%/}` → quita la barra final de la URL
- `/products/$PRODUCT_ID/labels` → ruta que entiende la Lambda
- `python3 -m json.tool` → formatea el JSON bonito

**Salida esperada (ejemplo real):**

```json
{
    "productId": "6b4c4683-9f43-4c89-919f-516ba8362f5f",
    "imageSource": "url",
    "minConfidence": 80.0,
    "labels": [
        {
            "name": "Animal",
            "confidence": 99.99
        },
        {
            "name": "Canine",
            "confidence": 99.99
        },
        {
            "name": "Fox",
            "confidence": 99.99
        },
        {
            "name": "Kit Fox",
            "confidence": 99.99
        },
        {
            "name": "Mammal",
            "confidence": 99.99
        },
        {
            "name": "Wildlife",
            "confidence": 99.99
        },
        {
            "name": "Kangaroo",
            "confidence": 98.3
        },
        {
            "name": "Grey Fox",
            "confidence": 89.79
        },
        {
            "name": "Coyote",
            "confidence": 88.29
        },
        {
            "name": "Red Wolf",
            "confidence": 85.51
        },
        {
            "name": "Wolf",
            "confidence": 85.51
        }
    ]
}
```

**Qué pasó:**
1. La Lambda recibió el POST
2. Leyó el `productId` de la URL
3. Consultó DynamoDB para obtener el `imageUrl`
4. Llamó a Rekognition `DetectLabels` con esa URL
5. Rekognition analizó y retornó etiquetas con confianzas
6. La Lambda guardó los resultados en DynamoDB (`aiLabels` y `aiLabelsRaw`)
7. Retornó el JSON al cliente

---

## ✅ PASO 3: VERIFICAR QUE SE GUARDÓ EN DYNAMODB

```bash
PRODUCT_ID="6b4c4683-9f43-4c89-919f-516ba8362f5f"

aws dynamodb get-item \
  --table-name edson-martin-ontiveros-lima-Products \
  --region us-east-1 \
  --key "{\"productId\":{\"S\":\"$PRODUCT_ID\"}}" \
  --query 'Item.{productId:productId, name:name, aiLabels:aiLabels}' \
  --output json | python3 -m json.tool
```

**Salida esperada:**
```json
{
    "productId": {
        "S": "6b4c4683-9f43-4c89-919f-516ba8362f5f"
    },
    "name": {
        "S": "Tenis blancos minimalistas"
    },
    "aiLabels": {
        "L": [
            {
                "S": "Animal"
            },
            {
                "S": "Canine"
            },
            {
                "S": "Fox"
            },
            ...
        ]
    }
}
```

**Qué pasó:** El producto ahora tiene:
- `aiLabels`: array de nombres de etiquetas (strings)
- `aiLabelsRaw`: array de objetos con nombre + confianza (para usar en búsquedas/filtros)

---

## 🏗️ ARQUITECTURA DE S1

```
                   [Cliente]
                       |
                   curl POST
                       ↓
       [Lambda Function URL de S1]
           https://s4agn...
                       |
                       ↓
              [app.py - Lambda Python]
                    |
         ┌──────────┼──────────┐
         ↓          ↓          ↓
    1. Lee producto   2. Si imagen S3,
       de DynamoDB       Rekognition la lee
                         con el rol de Lambda
     3. Extrae imageUrl
                         4. Llama Rekognition
     5. Envía imagen
                         6. Rekognition retorna
     7. Guarda en DynamoDB  etiquetas + confianzas
                         8. Retorna JSON
                       ↓
                  [Cliente recibe]
                   {"labels":[...]}
```

### Componentes clave:

| Componente | Tipo | Función |
|-----------|------|---------|
| **EnrichLabelsFunction** | Lambda Python 3.12 | Orquesta: lee producto, llama Rekognition, guarda resultado |
| **Rekognition DetectLabels** | Servicio administrado AWS | Analiza imagen, retorna etiquetas |
| **DynamoDB** | BD administrada | Almacena producto + etiquetas |
| **Función URL** | HTTP endpoint | Expone la Lambda sin API Gateway |

---

## 🔐 PERMISOS (IAM) DE S1

La Lambda `EnrichLabels` tiene exactamente estos permisos:

```yaml
Policies:
  - DynamoDBCrudPolicy:
      TableName: ProductsTable
      # Puede: GetItem, UpdateItem, etc. SOLO en ProductsTable
      # NO puede: tocar otras tablas
      
  - Statement:
      Action: rekognition:DetectLabels
      Resource: "*"
      # SOLO detectLabels (no DetectFaces, no DetectModerationLabels, etc.)
      # Rekognition NO admite ARN de recurso, solo acción
      
  - Statement:
      Action: s3:GetObject
      Resource: arn:${AWS::Partition}:s3:::${AWS::StackName}-*/*
      # SOLO GetObject (leer)
      # SOLO buckets del stack (${AWS::StackName})
```

**¿Por qué importa?** Esto es **mínimo privilegio**: si la Lambda se compromete, el atacante **solo puede**:
- ✅ Leer y actualizar 1 tabla DynamoDB
- ✅ Leer imágenes de buckets del stack
- ✅ Llamar a Rekognition DetectLabels
- ❌ NO puede borrar la tabla
- ❌ NO puede leer buckets ajenos
- ❌ NO puede modificar otros servicios

---

## ⚠️ ERRORES COMUNES Y SOLUCIONES

| Error | Causa | Solución |
|-------|-------|----------|
| `HTTP Error 404: Not Found` | La URL de imagen no existe o es inaccesible | Usar una URL pública que funcione (`httpbin.org/image/jpeg` siempre funciona). Probar `curl https://...` desde la terminal. |
| `HTTP Error 403: Forbidden` | El servidor bloqueó la request (Wikimedia, etc. tienen User-Agent whitelist) | Cambiar a otra URL o subir la imagen a S3. |
| `Unable to get object metadata from S3...` | La ruta S3 es incorrecta o el rol no tiene permisos | Verificar: (a) `aws s3 ls s3://bucket/key` existe, (b) el rol de Lambda tiene `s3:GetObject` en ese ARN. |
| `Falta el productId en la ruta` (400) | El ID no se envió o está mal | Verificar: `curl POST "{URL%/}/products/ID/labels"` — ID debe ser un UUID válido. |
| `Producto ... no encontrado` (404) | El productId no existe en DynamoDB | Listar productos: `aws dynamodb scan --table-name ... --query "Items[].productId"` |
| `TypeError: Float types are not supported` | DynamoDB rechazó `float` al guardar confianzas | Ya está solucionado en el código: usa `Decimal(str(v))` antes de DynamoDB. |
| `AccessDeniedException` de Rekognition | IAM sin `rekognition:DetectLabels` | Verificar que el template-snippet.yaml se pegó correctamente con el permiso `rekognition:DetectLabels`. |

---

## 📊 DATOS GUARDADOS EN DYNAMODB

Después de llamar S1, el producto tiene dos campos nuevos:

```json
{
  "productId": "6b4c4683...",
  "name": "Tenis blancos minimalistas",
  "price": 74.5,
  ...
  "aiLabels": [
    "Animal",
    "Canine",
    "Fox",
    "Kit Fox",
    "Mammal",
    "Wildlife"
  ],
  "aiLabelsRaw": [
    {
      "name": "Animal",
      "confidence": 99.99
    },
    {
      "name": "Canine",
      "confidence": 99.99
    },
    ...
  ]
}
```

**Uso:**
- `aiLabels`: búsqueda simple (¿contiene "Clothing"?)
- `aiLabelsRaw`: filtros con confianza (¿"Dress" con ≥90%?)

---

## 🔄 FLUJO COMPLETO DE CÓDIGO

### 1. Entrada (HTTP POST)

```python
event = {
    "rawPath": "/products/6b4c4683-9f43-4c89-919f-516ba8362f5f/labels",
    "requestContext": {"http": {"method": "POST"}}
}
```

### 2. Extrae productId

```python
product_id = _path_id(event)
# Busca: primero rawPath, luego queryString, luego body
# Retorna: "6b4c4683-9f43-4c89-919f-516ba8362f5f"
```

### 3. Lee producto de DynamoDB

```python
item = table.get_item(Key={"productId": product_id}).get("Item")
# Retorna: {
#   "productId": "6b4c...",
#   "name": "Tenis",
#   "imageUrl": "https://httpbin.org/image/jpeg",
#   ...
# }
```

### 4. Construye parámetro para Rekognition

```python
if image_url.startswith("s3://"):
    # Parsea s3://bucket/key
    image_param = {
        "S3Object": {
            "Bucket": "bucket",
            "Name": "key"
        }
    }
else:  # https://...
    # Descarga bytes
    with urllib.request.urlopen(image_url) as r:
        image_param = {"Bytes": r.read()}
```

### 5. Llama a Rekognition

```python
result = rekognition.detect_labels(
    Image=image_param,
    MaxLabels=15,
    MinConfidence=80
)
# Retorna: {
#   "Labels": [
#     {"Name": "Animal", "Confidence": 99.99},
#     {"Name": "Canine", "Confidence": 99.99},
#     ...
#   ]
# }
```

### 6. Procesa resultados

```python
labels = [
    {"name": l["Name"], "confidence": round(l["Confidence"], 2)}
    for l in result.get("Labels", [])
]
# Retorna: [
#   {"name": "Animal", "confidence": 99.99},
#   {"name": "Canine", "confidence": 99.99},
#   ...
# ]
```

### 7. Guarda en DynamoDB

```python
table.update_item(
    Key={"productId": product_id},
    UpdateExpression="SET aiLabels = :labels, aiLabelsRaw = :raw",
    ExpressionAttributeValues={
        ":labels": ["Animal", "Canine", ...],  # strings
        ":raw": [
            {"name": "Animal", "confidence": Decimal("99.99")},  # NO float
            ...
        ]
    }
)
```

### 8. Retorna al cliente

```python
return _response(200, {
    "productId": product_id,
    "imageSource": "url",
    "minConfidence": 80.0,
    "labels": labels
})
```

---

## 💡 CONCEPTOS PARA EL EXAMEN (D1)

### 1. Diferencia: Entrenamiento vs. Inferencia

| Aspecto | Entrenamiento | Inferencia (S1) |
|---------|---------------|-----------------|
| **Qué es** | Crear un modelo nuevo | Usar un modelo existente |
| **Dónde** | SageMaker (costoso, lento) | Rekognition (rápido, barato) |
| **Tiempo** | Horas/días | Milisegundos |
| **Datos** | Dataset grande | 1 imagen |
| **Cost** | $$$$ | $ (centavos) |

**En el examen:** Si la pregunta es "etiquetar fotos", responde **Rekognition (inferencia)**, no SageMaker.

### 2. Confianza / Score

Cada predicción trae un % de confianza (0–100):
- **99.99%:** El modelo está muy seguro (etiqueta confiable)
- **60%:** El modelo está inseguro (descartar o usar con cautela)
- **Umbral:** `MinConfidence=80` → solo acepta etiquetas con ≥80%

**Trade-off:**
- Umbral bajo (20%) → más etiquetas, más ruido
- Umbral alto (95%) → pocas etiquetas, muy precisas

### 3. Servicio Administrado

AWS mantiene:
- El modelo entrenado
- El hardware (GPUs)
- Las versiones
- La escalabilidad

Vos solo:
- Llamas la API
- Pagas por uso
- Mantienes los permisos (IAM)

---

## ✅ CHECKLIST DE VALIDACIÓN (S1 COMPLETADA)

- [x] Lambda `EnrichLabels` existe en Lambda console
- [x] Function URL de S1 es accesible (sin error 404)
- [x] Producto tiene `imageUrl` válida (pública o S3)
- [x] `curl POST /products/{id}/labels` retorna 200 + JSON con etiquetas
- [x] Todas las etiquetas tienen `confidence ≥ 80`
- [x] DynamoDB tiene campos `aiLabels` y `aiLabelsRaw`
- [x] CloudWatch Logs muestra evento completo sin errores
- [x] Rol de Lambda tiene: DynamoDB Crud, Rekognition DetectLabels, S3 GetObject

**Estado:** ✅ **S1 COMPLETADA Y FUNCIONAL**

---

## 📈 SIGUIENTES SESIONES (VISTA PREVIA)

| Sesión | Servicio | Qué hace | Patrón |
|--------|----------|----------|--------|
| **S2** | Rekognition | Detecta contenido inapropiado + genera alt-text | Igual a S1 (otra API de Rekognition) |
| **S3** | Comprehend | Analiza sentimiento en reviews | Mismo patrón (servicio distinto) |
| **S4** | Translate | Traduce descripciones | Mismo patrón |
| **S5** | Polly | Lee descripciones en voz alta | Mismo patrón + guarda audio en S3 |
| **S6–S8** | Bedrock | Genera descripciones + búsqueda semántica + chatbot | **Cambio:** IA generativa, context history |

**Patrón común:** Nueva Lambda + nueva Function URL + consultar DynamoDB + servicio de IA + guardar resultado.

---

## 🧹 CLEANUP (SOLO SI NO CONTINUES A S2)

```bash
# Borrar solo S1 (sin tocar S0)
# = Editar template.yaml y quitar EnrichLabelsFunction
# = sam deploy

# Borrar TODO
bash scripts/delete-all.sh   # Pide confirmación
```

---

## 📚 REFERENCIAS

- **AWS Rekognition:** https://aws.amazon.com/rekognition/
- **AWS AIF-C01 Domain 1:** https://docs.aws.amazon.com/aws-certification/latest/examguides/ai-practitioner-01.html
- **CLAUDE.md (arquict tectura del capstone):** [CLAUDE.md](CLAUDE.md)
- **docs/IAM.md (mínimo privilegio):** [docs/IAM.md](docs/IAM.md)

---

**Documento generado:** 2026-09-14 17:20 UTC  
**Ejecutado por:** Claude Code v4.5  
**Stack:** edson-martin-ontiveros-lima  
**Estado:** ✅ S0 + S1 COMPLETADAS

