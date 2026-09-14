# S2 — GUÍA DE EJECUCIÓN PASO A PASO (PARA PRINCIPIANTES)

**Stack: `edson-martin-ontiveros-lima`** | **Región: `us-east-1`** | **Estado: ✅ COMPLETADA**

> Este documento está escrito para personas que **NUNCA han tocado AWS**. Cada paso explica qué hace S2, cómo se llama, y qué esperar.

---

## 🎯 ¿QUÉ ES S2?

S2 agrega **dos capacidades a través de Rekognition**:

1. **Moderación de contenido:** ¿Es la imagen apta para el catálogo de una tienda? (detecta desnudez, violencia, etc.)
2. **Alt-text accesible:** Genera una descripción en texto para personas con discapacidad visual.

**Caso de uso real:**
- Un cliente sube una foto de un producto a la tienda.
- S2 verifica que no sea contenido inapropiado (moderación).
- S2 genera una descripción accesible ("Imagen de producto que muestra: vestido, tela, moda").
- Si pasa moderación, se publica; si no, se rechaza.

**Duración total:** ~5-10 minutos (pruebas incluidas).

**Conceptos para el examen AIF-C01, Dominio D4 (Responsible AI):**
- ✅ **Seguridad del contenido:** usar modelos preentrenados para detectar material no apropiado.
- ✅ **Accesibilidad:** generar alt-text es parte de la inclusión digital (WCAG 2.1).
- ✅ **Servicio administrado:** Rekognition mantiene el modelo y la infraestructura.

---

## 🔍 ¿QUÉ HACE S2 INTERNAMENTE?

**Flujo de S2:**

```
Cliente: POST /products/{id}/moderate
    ↓
Lambda S2 (ModerateImage):
    1. Lee el productId de la URL
    2. Busca el producto en DynamoDB (necesita imageUrl)
    3. Descarga la imagen (vía URL pública o S3)
    4. Llama a Rekognition → DetectModerationLabels
       ("¿Tiene desnudez? ¿Violencia? ¿Contenido explícito?")
    5. Llama a Rekognition → DetectLabels (para el alt-text)
    6. Genera el alt-text ("Imagen de producto que muestra: ...")
    7. Guarda en DynamoDB:
       - moderationStatus: "APPROVED" o "FLAGGED"
       - moderationFlags: lista de problemas (si hay)
       - altText: descripción accesible
    ↓
Cliente: Recibe JSON con status, flags y alt-text
```

**Diferencia con S1:**
- **S1** (labels): etiqueta lo que VE ("tela", "color", "forma").
- **S2** (moderation + alt): valida seguridad del contenido ADEMÁS de generar texto accesible.

---

## ✅ VERIFICACIÓN PREVIA

### 1. ¿Está desplegada la Lambda de S2?

```bash
aws lambda get-function --function-name edson-martin-ontiveros-lima-ModerateImage \
  --region us-east-1 --query "Configuration.[FunctionName,Runtime,CodeSha256]" --output text
```

**Salida esperada:**
```
edson-martin-ontiveros-lima-ModerateImage  python3.12  <hash_largo>
```

**¿Qué pasó?** La Lambda S2 existe y está lista para usarse.

---

### 2. Obtener la Function URL de S2

```bash
ModerateUrl=$(aws cloudformation describe-stacks \
  --stack-name edson-martin-ontiveros-lima \
  --region us-east-1 \
  --query "Stacks[0].Outputs[?OutputKey=='ModerateImageUrl'].OutputValue" \
  --output text)
echo "S2 URL: $ModerateUrl"
```

**Salida esperada:**
```
S2 URL: https://dxx7tz2zbuvnm27akybd5cv7v40uwmmq.lambda-url.us-east-1.on.aws/
```

**¿Qué pasó?** Se extrajo la URL HTTPS única de la Lambda de S2.

---

### 3. Verificar que hay productos con imagen

```bash
aws dynamodb scan --table-name edson-martin-ontiveros-lima-Products \
  --region us-east-1 \
  --projection-expression "productId,#n,imageUrl" \
  --expression-attribute-names '{"#n":"name"}' \
  --output text | head -5
```

**Salida esperada:**
```
6b4c4683-9f43-4c89-919f-516ba8362f5f    Tenis blancos minimalistas    https://httpbin.org/image/jpeg
...
```

**¿Qué pasó?** Confirmamos que al menos 1 producto tiene una `imageUrl` válida (necesario para S2).

---

## 🚀 PASO A PASO: EJECUTAR S2

### PASO 1: Elegir un Producto

Usamos el producto que ya tiene una imagen válida de S1 (o la asignamos ahora):

```bash
ProductId="6b4c4683-9f43-4c89-919f-516ba8362f5f"
echo "Moderando producto: $ProductId"
```

### PASO 2: Llamar a S2 (Moderar Imagen)

```bash
ModerateUrl="https://dxx7tz2zbuvnm27akybd5cv7v40uwmmq.lambda-url.us-east-1.on.aws/"
curl -s -X POST "${ModerateUrl%/}/products/${ProductId}/moderate" | python3 -m json.tool
```

**Salida esperada (ejemplo con imagen segura):**
```json
{
    "productId": "6b4c4683-9f43-4c89-919f-516ba8362f5f",
    "moderationStatus": "APPROVED",
    "moderationFlags": [],
    "altText": "Imagen de producto que muestra: Animal, Canine, Fox, Kit Fox, Mammal."
}
```

**¿Qué pasó?**
1. La Lambda leyó el producto de DynamoDB
2. Bajó la imagen desde `https://httpbin.org/image/jpeg`
3. Llamó a `Rekognition.DetectModerationLabels()` → sin problemas de seguridad
4. Llamó a `Rekognition.DetectLabels()` → obtuvo etiquetas (Animal, Canine, etc.)
5. Generó el alt-text con las 5 primeras etiquetas
6. Guardó los campos `moderationStatus`, `moderationFlags` y `altText` en DynamoDB
7. Retornó el veredicto al cliente

---

### PASO 3: Verificar en DynamoDB

Comprobamos que los campos se guardaron:

```bash
aws dynamodb get-item \
  --table-name edson-martin-ontiveros-lima-Products \
  --key "{\"productId\":{\"S\":\"${ProductId}\"}}" \
  --region us-east-1 \
  --query 'Item.[productId.S, moderationStatus.S, altText.S]' \
  --output text
```

**Salida esperada:**
```
6b4c4683-9f43-4c89-919f-516ba8362f5f    APPROVED    Imagen de producto que muestra: Animal, Canine, Fox, Kit Fox, Mammal.
```

**¿Qué pasó?** Los tres campos están ahora en el producto:
- `moderationStatus`: "APPROVED" (pasó la moderación)
- `altText`: descripción accesible para lectores de pantalla

---

## 📊 INTERPRETACIÓN DE RESULTADOS

### `moderationStatus`

| Valor | Significado | Acción |
|-------|-------------|--------|
| `APPROVED` | La imagen es apta para la tienda | Publicar el producto |
| `FLAGGED` | Detección de contenido problemático | Revisar manualmente o rechazar |

### `moderationFlags`

Lista de etiquetas de moderación detectadas. Ejemplo:

```json
{
  "moderationFlags": [
    {"name": "Suggestive", "confidence": 92.5, "parent": ""},
    {"name": "Explicit Nudity", "confidence": 85.3, "parent": "Suggestive"}
  ]
}
```

**Nombres comunes de flags:**
- `Explicit Nudity` — desnudez
- `Suggestive` — contenido sugestivo
- `Violence` — violencia gráfica
- `Visually Disturbing` — imágenes perturbadoras

### `altText`

Descripción en texto plano para personas con discapacidad visual. Ejemplo:

```
"Imagen de producto que muestra: Clothing, Dress, Fashion, Embroidered."
```

Esto se mostraría en la propiedad `alt` de un `<img>` HTML:
```html
<img src="..." alt="Imagen de producto que muestra: Clothing, Dress, Fashion, Embroidered." />
```

---

## 🏗️ ARQUITECTURA Y CONCEPTOS

### ¿Por qué dos llamadas a Rekognition en S2?

Rekognition tiene **dos operaciones distintas:**
1. `DetectModerationLabels()` — especializada en seguridad (desnudez, violencia)
2. `DetectLabels()` — etiquetas generales (ropa, color, etc.)

**No se reutiliza S1** (etiquetas) porque:
- S1 y S2 tienen **thresholds distintos** (confianza mínima).
- S2 necesita **moderación** además de etiquetas.
- Son dos Lambdas con dos Function URLs — pueden llamarse independientemente.

### ¿Cómo se genera el alt-text?

El código toma las **5 primeras etiquetas** de `DetectLabels` y las une:

```python
def _build_alt_text(labels, product_name):
    top = [l["Name"] for l in labels[:5]]
    if not top:
        return f"Imagen del producto {product_name}."
    return f"Imagen de producto que muestra: {', '.join(top)}."
```

**Ejemplo:**
- Etiquetas de Rekognition: `["Clothing", "Dress", "Fashion", "Embroidered", "Red", "Beige", ...]`
- Top 5: `["Clothing", "Dress", "Fashion", "Embroidered", "Red"]`
- Alt-text: `"Imagen de producto que muestra: Clothing, Dress, Fashion, Embroidered, Red."`

---

## 🔐 PERMISOS IAM (S2)

La Lambda de S2 declara estos permisos exactamente:

```yaml
Policies:
  - DynamoDBCrudPolicy:
      TableName: edson-martin-ontiveros-lima-Products
  - Statement:
      - Effect: Allow
        Action:
          - rekognition:DetectModerationLabels
          - rekognition:DetectLabels
        Resource: "*"
  - Statement:
      - Effect: Allow
        Action: s3:GetObject
        Resource: arn:aws:s3:::edson-martin-ontiveros-lima-*/*
```

**Qué puede hacer:**
- ✅ Leer/escribir cualquier producto en DynamoDB
- ✅ Llamar a `DetectModerationLabels` y `DetectLabels` de Rekognition
- ✅ Descargar objetos de buckets S3 del stack (si la imagen fuera S3)
- ❌ No puede acceder a otros buckets, tablas, o servicios

**¿Por qué esto importa para el examen?** Esto es **mínimo privilegio en acción**: cada Lambda tiene exactamente lo que necesita, ni más ni menos.

---

## ✅ CHECKLIST DE VALIDACIÓN (S2 COMPLETADA)

- [x] Lambda `ModerateImage` existe
- [x] Function URL de S2 es accesible (sin error 403)
- [x] `curl POST /products/<id>/moderate` retorna JSON válido
- [x] `moderationStatus` es "APPROVED" o "FLAGGED"
- [x] `altText` contiene descripción accesible
- [x] Los 3 campos se guardaron en DynamoDB
- [x] CloudWatch Logs muestra invocaciones sin errores
- [x] IAM: S2 solo tiene permisos DynamoDB + Rekognition + S3 GetObject

**Estado:** ✅ **S2 COMPLETADA Y FUNCIONAL**

---

## 🚨 ERRORES COMUNES Y SOLUCIONES

| Error | Causa | Solución |
|-------|-------|----------|
| `{"error": "Falta el productId en la ruta."}` | URL mal formada. No incluye `/products/<id>/` | Usar: `curl -X POST "...lambda-url.../products/6b4c4683.../moderate"` |
| `{"error": "Producto ... no encontrado."}` | El productId no existe en DynamoDB | Verificar el UUID con `aws dynamodb scan --table-name ... \| jq '.Items[].productId.S'` |
| `{"error": "El producto no tiene una imageUrl válida."}` | `imageUrl` es null, vacío, o empieza con "REEMPLAZAR" | Actualizar el producto con una URL real: `aws dynamodb update-item --table-name ... --key ... --update-expression "SET imageUrl = :url" --expression-attribute-values "{\":url\":{\"S\":\"https://...jpg\"}}"` |
| `{"error": "Fallo al moderar la imagen", "detail": "..."}` | Error en Rekognition (URL inaccesible, formato no soportado, etc.) | Verificar que la URL sea accesible desde Lambda. Probar: `curl -I https://httpbin.org/image/jpeg` (debe retornar 200) |
| `moderationFlags` vacío pero `moderationStatus="APPROVED"` | Comportamiento esperado — la imagen NO tiene contenido problemático | Es normal; significa que la imagen pasó moderación sin problemas |
| CloudWatch Logs muestran "timeout" | La descarga de la imagen tardó > 30 seg | Aumentar timeout en template.yaml (línea 17: `Timeout: 30` → `60`) |

---

## 🎓 CONCEPTO PEDAGÓGICO: RESPONSIBLE AI (D4 del Examen)

**¿Por qué moderación es crítica?**

1. **Seguridad legal:** una tienda debe evitar contenido que viole leyes locales.
2. **Brand safety:** proteger la reputación de la marca.
3. **Inclusividad:** el alt-text asegura que TODOS (incluyendo personas ciegas) puedan ver el catálogo.

**¿Cuándo deberías elegir Rekognition?**
- ✅ Detectar violencia, desnudez, contenido inapropiado en imágenes → `Rekognition`
- ✅ Generar alt-text para imágenes → `Rekognition` (etiquetas)
- ❌ Moderar **texto** (comentarios, reseñas) → usar `Comprehend` (S3) o `TextRank`
- ❌ Crear un sistema de recomendaciones → usar `Personalize` o Bedrock

**El patrón del capstone:** cada sesión es un servicio distinto. S2 y S3 usan servicios **distintos** (Rekognition vs. Comprehend) para tareas **distintas** (visión vs. lenguaje).

---

## 💸 COSTO ESTIMADO

| Recurso | Precio | Volumen (prueba) | Costo |
|---------|--------|------------------|-------|
| Rekognition `DetectModerationLabels` | $0.80 / 1000 imágenes | 1 | $0.0008 |
| Rekognition `DetectLabels` | $0.80 / 1000 imágenes | 1 | $0.0008 |
| **TOTAL S2 (esta sesión)** | — | — | **~$0.0016** |

En producción: ~$1/mes si moderas 1,000 imágenes/mes. Verificar contra precios oficiales en [aws.amazon.com/rekognition/pricing](https://aws.amazon.com/rekognition/pricing/).

---

## 🧹 CLEANUP (SI NECESITAS BORRAR S2)

**NO lo hagas aún** — las sesiones S3–S11 construyen sobre S2. Solo limpia cuando termines TODO:

```bash
bash scripts/delete-all.sh
```

Si solo quieres borrar los campos de S2 en DynamoDB (mantener el stack):

```bash
ProductId="6b4c4683-9f43-4c89-919f-516ba8362f5f"
aws dynamodb update-item \
  --table-name edson-martin-ontiveros-lima-Products \
  --key "{\"productId\":{\"S\":\"${ProductId}\"}}" \
  --region us-east-1 \
  --update-expression "REMOVE moderationStatus, moderationFlags, altText"
```

---

## 📊 LOGS EN CLOUDWATCH

Ver qué hizo la Lambda:

```bash
aws logs tail /aws/lambda/edson-martin-ontiveros-lima-ModerateImage \
  --region us-east-1 --follow
```

O desde la consola: [CloudWatch Logs](https://console.aws.amazon.com/logs/home?region=us-east-1#logStream:logGroupName=/aws/lambda/edson-martin-ontiveros-lima-ModerateImage).

---

## ➡️ PRÓXIMO PASO: S3 (ANÁLISIS DE SENTIMIENTO)

S3 agrega **análisis de sentimiento de reseñas** usando Amazon Comprehend (procesamiento de lenguaje natural).

- Texto → detecta idioma → analiza sentimiento (POSITIVE, NEGATIVE, NEUTRAL, MIXED)
- Útil para: reseñas de clientes, comentarios, feedback

Detalle completo en: **S3-GUIA-EJECUTADA.md**

---

**Documento generado:** 2026-09-14 17:45 UTC  
**Ejecutado por:** Claude Code v4.5  
**Stack:** edson-martin-ontiveros-lima  
**Sesión:** S2 (Moderación + Alt-text)  
**Estado:** ✅ S2 COMPLETADA
