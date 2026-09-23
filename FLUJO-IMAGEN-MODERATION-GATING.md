# 🖼️ Flujo de Imagen: Moderación y Gating (S0–S2)

**Objetivo:** Entender cómo una imagen se valida antes de ser visible en el frontend cliente.

---

## 📋 El Problema

En una tienda online:
- ❌ Admin sube una imagen inapropiada sin darse cuenta
- ❌ Cliente la ve en vivo → demanda, reputación dañada, GDPR/cumplimiento
- ✅ La solución: **Moderación automática** + **gating de visualización**

---

## ✅ La Solución: 3 Estados de Imagen

```
Cuando un Admin sube una imagen:

┌─────────────────────────────────┐
│  statusImage = "PENDING"        │
│  (Se subió, aún no revisada)    │
│  ❌ NO visible en frontend      │
└────────────────┬────────────────┘
                 │
         (S2 Moderación)
                 │
        ┌────────┴────────┐
        │                 │
    ✅ APPROVED        ❌ FLAGGED
    │                 │
    ▼                 ▼
moderationStatus:  moderationStatus:
"APPROVED"         "FLAGGED"
moderationFlags:   moderationFlags:
[] (vacío)         ["explicit", "violence", ...]


statusImage =     statusImage =
"APPROVED"        "FLAGGED"

✅ VISIBLE        ❌ NO VISIBLE
en cliente        en cliente
```

---

## 🔄 Flujo Detallado: Paso a Paso

### Paso 0: Admin sube imagen (S0 + presigned URL)

**Entrada:**
```bash
POST /products/:id/upload-image
Body: { imageUrl: "https://example.com/dress.jpg" }
```

**Backend (S0 router):**
```javascript
// functions/router/index.js
const uploadProductImage = async (productId, imageUrl) => {
  // 1. Descarga la imagen de internet
  const buffer = await fetch(imageUrl).then(r => r.arrayBuffer())
  
  // 2. Sube a S3
  const s3Key = `products/${productId}/original.jpg`
  await s3.putObject({
    Bucket: process.env.PRODUCTS_BUCKET,
    Key: s3Key,
    Body: buffer,
    ContentType: 'image/jpeg'
  })
  
  // 3. Guarda en DynamoDB con estado PENDING
  await dynamodb.updateItem({
    TableName: process.env.TABLE_NAME,
    Key: { productId: { S: productId } },
    UpdateExpression: 'SET imageUrl = :url, statusImage = :status, imageKey = :key',
    ExpressionAttributeValues: {
      ':url': { S: imageUrl },
      ':status': { S: 'PENDING' },
      ':key': { S: s3Key }
    }
  })
  
  return { productId, statusImage: 'PENDING' }
}
```

**Estado en DynamoDB:**
```json
{
  "productId": "P001",
  "name": "Floral Dress",
  "imageUrl": "https://example.com/dress.jpg",
  "imageKey": "products/P001/original.jpg",
  "statusImage": "PENDING",      ← ⚠️ Aún no visible
  "moderationStatus": null,
  "moderationFlags": []
}
```

---

### Paso 1: S2 Moderación (Rekognition)

**Disparador:** Manual o automático (EventBridge)

**Función Lambda S2 (`moderate-image`):**
```python
# sessions/S02-moderation-alttext/functions/moderate-image/app.py

import boto3
import json

rekognition = boto3.client('rekognition', region_name='us-east-1')
dynamodb = boto3.resource('dynamodb', region_name='us-east-1')

def lambda_handler(event, context):
    product_id = extract_id(event)  # De path o body
    
    # 1. Obtener producto actual
    table = dynamodb.Table(os.environ['TABLE_NAME'])
    product = table.get_item(Key={'productId': product_id})['Item']
    
    s3_key = product['imageKey']  # "products/P001/original.jpg"
    bucket = os.environ['PRODUCTS_BUCKET']
    
    # 2. Llamar a Rekognition
    # a) Detectar contenido inapropiado
    moderation_response = rekognition.detect_moderation_labels(
        Image={'S3Object': {'Bucket': bucket, 'Name': s3_key}},
        MinConfidence=50
    )
    
    # b) Generar alt-text (de todas formas)
    labels_response = rekognition.detect_labels(
        Image={'S3Object': {'Bucket': bucket, 'Name': s3_key}},
        MaxLabels=10,
        MinConfidence=50
    )
    
    # 3. Procesar resultados
    moderation_labels = moderation_response.get('ModerationLabels', [])
    
    # ¿Se detectó algo inapropiado?
    inappropriate = [m['Name'] for m in moderation_labels if m['Confidence'] > 80]
    
    if inappropriate:
        moderation_status = 'FLAGGED'
        moderation_flags = inappropriate
    else:
        moderation_status = 'APPROVED'
        moderation_flags = []
    
    # Alt-text (siempre)
    alt_text = ', '.join([l['Name'] for l in labels_response['Labels'][:5]])
    
    # 4. Actualizar DynamoDB
    table.update_item(
        Key={'productId': product_id},
        UpdateExpression='''
            SET statusImage = :status,
                moderationStatus = :mod_status,
                moderationFlags = :flags,
                altText = :alt_text
        ''',
        ExpressionAttributeValues={
            ':status': 'APPROVED' if moderation_status == 'APPROVED' else 'FLAGGED',
            ':mod_status': moderation_status,
            ':flags': moderation_flags,
            ':alt_text': alt_text
        }
    )
    
    return {
        'statusCode': 200,
        'body': {
            'productId': product_id,
            'moderationStatus': moderation_status,
            'moderationFlags': moderation_flags,
            'altText': alt_text
        }
    }
```

**Cambio en DynamoDB — Caso A: Aprobada**

```json
{
  "productId": "P001",
  "name": "Floral Dress",
  "imageUrl": "https://example.com/dress.jpg",
  "imageKey": "products/P001/original.jpg",
  "statusImage": "APPROVED",          ← ✅ Ahora SÍ visible
  "moderationStatus": "APPROVED",
  "moderationFlags": [],
  "altText": "Floral Chiffon Dress with Short Sleeves"
}
```

**Cambio en DynamoDB — Caso B: Rechazada**

```json
{
  "productId": "P002",
  "name": "Mystery Item",
  "imageUrl": "https://bad-image.com/flag.jpg",
  "imageKey": "products/P002/original.jpg",
  "statusImage": "FLAGGED",           ← ❌ NO visible
  "moderationStatus": "FLAGGED",
  "moderationFlags": ["Explicit Nudity", "Violence"],
  "altText": "..."
}
```

---

## 🎨 Frontend: Visualización (React)

### Cliente: No ve imágenes FLAGGED

**`ProductDetailsModal.tsx`:**
```typescript
// Cuando el usuario abre los detalles del producto

interface Product {
  productId: string
  name: string
  imageUrl?: string
  statusImage?: 'APPROVED' | 'FLAGGED' | 'PENDING'
  altText?: string
  // ... otros campos
}

export const ProductDetailsModal = ({ product }: Props) => {
  
  // Determinar si mostrar imagen
  const canShowImage = product.statusImage === 'APPROVED'
  
  return (
    <Modal>
      {/* Imagen: solo si APPROVED */}
      {canShowImage ? (
        <img
          src={product.imageUrl}
          alt={product.altText || product.name}
          loading="lazy"
        />
      ) : (
        <div className="placeholder-image">
          {product.statusImage === 'FLAGGED' && (
            <p>⚠️ Esta imagen no está disponible</p>
          )}
          {product.statusImage === 'PENDING' && (
            <p>⏳ Imagen en revisión</p>
          )}
        </div>
      )}
      
      {/* Alt-text accesible */}
      {canShowImage && product.altText && (
        <p className="sr-only">{product.altText}</p>
      )}
      
      {/* Resto del producto */}
      <h2>{product.name}</h2>
      <p>${product.price}</p>
      ...
    </Modal>
  )
}
```

### Admin: VE TODAS las imágenes + status

**`ProductModalAdmin.tsx`:**
```typescript
export const ProductModalAdmin = ({ product }: Props) => {
  
  return (
    <Modal>
      {/* Imagen: SIEMPRE visible + badge de status */}
      <div style={{ position: 'relative' }}>
        <img src={product.imageUrl} alt={product.name} />
        
        {/* Badge de estado */}
        {product.statusImage === 'APPROVED' && (
          <Badge color="green">✅ Aprobada</Badge>
        )}
        {product.statusImage === 'FLAGGED' && (
          <Badge color="red">⚠️ Rechazada: {product.moderationFlags?.join(', ')}</Badge>
        )}
        {product.statusImage === 'PENDING' && (
          <Badge color="yellow">⏳ En revisión</Badge>
        )}
      </div>
      
      {/* Admin puede cambiar imagen o ver detalles */}
      <button>Cambiar imagen</button>
      {product.moderationFlags && (
        <details>
          <summary>Razones del rechazo</summary>
          <ul>
            {product.moderationFlags.map(flag => <li key={flag}>{flag}</li>)}
          </ul>
        </details>
      )}
      ...
    </Modal>
  )
}
```

---

## 🚦 Estados y Transiciones

```
         ┌─────────────────────┐
         │   PENDING           │
         │ (Recién subida)     │
         └──────────┬──────────┘
                    │
            (S2 Moderación)
                    │
        ┌───────────┴──────────┐
        │                      │
    ✅ APPROVED            ❌ FLAGGED
    │                      │
    ├─ Cliente ve          ├─ Cliente NO ve
    ├─ S4 traduce          ├─ Admin ve + razones
    ├─ S5 audio            ├─ Workflow: Revisar
    ├─ S1 etiquetas        │  o eliminar
    └─ S6 descripción      └─ Potencial re-upload
                            (Nueva moderación)
```

---

## 💡 Conceptos Clave

| Concepto | Significado | Por qué importa |
|----------|-------------|-----------------|
| **statusImage** | PENDING / APPROVED / FLAGGED | Controla si cliente ve la imagen |
| **moderationStatus** | Resultado de S2 (APPROVED/FLAGGED) | Documentación para Admin |
| **moderationFlags** | Array de razones (Explicit, Violence, etc.) | Admin entiende el rechazo |
| **altText** | Descripción accesible (WCAG 2.1) | Usuarios con discapacidad visual |
| **Gating** | Mostrar/ocultar basado en `statusImage` | Control de contenido + seguridad |

---

## 🔐 IAM: S2 Acceso a S3 + Rekognition

**Política IAM para `ModerateImageFunction`:**
```yaml
Policies:
  - DynamoDBCrudPolicy:
      TableName: !Ref ProductsTable
  - Version: '2012-10-17'
    Statement:
      - Effect: Allow
        Action:
          - rekognition:DetectModerationLabels
          - rekognition:DetectLabels
        Resource: '*'  # Rekognition no admite ARN de recurso
      - Effect: Allow
        Action:
          - s3:GetObject
        Resource: !Sub 'arn:aws:s3:::${ProductsBucket}/products/*'
```

---

## ✅ Checklist: Implementación S0–S2

- [x] S0: Upload → S3 + DynamoDB con `statusImage = PENDING`
- [x] S2: Rekognition detección de moderación
- [x] S2: Actualizar `moderationStatus`, `moderationFlags`, `altText`
- [x] S2: Cambiar `statusImage` a APPROVED o FLAGGED
- [x] Frontend Cliente: Condicional `if (statusImage === 'APPROVED')`
- [x] Frontend Admin: Ver todas + badges de status
- [x] IAM: S2 acceso S3 GetObject + Rekognition
- [x] Prueba manual: Upload → Moderación → Ver/No ver en cliente

---

## 🧪 Testing Manual

### 1. Upload una imagen limpia

```bash
# Admin sube una imagen
curl -X POST https://API/products/P001/upload-image \
  -H "Content-Type: application/json" \
  -d '{
    "imageUrl": "https://upload.wikimedia.org/wikipedia/commons/3/3a/Cat03.jpg"
  }'

# Respuesta
{
  "productId": "P001",
  "statusImage": "PENDING"
}
```

### 2. Revisar en DynamoDB

```bash
aws dynamodb get-item --table-name ...-Products \
  --key '{"productId": {"S": "P001"}}' | jq '.Item | {statusImage, moderationStatus, altText}'
```

**Antes de S2:**
```json
{
  "statusImage": "PENDING",
  "moderationStatus": null,
  "altText": null
}
```

### 3. Ejecutar S2 (Moderación)

```bash
# Trigger S2
curl -X POST https://S2_URL/products/P001/moderate \
  -H "Content-Type: application/json"

# Respuesta
{
  "productId": "P001",
  "moderationStatus": "APPROVED",
  "moderationFlags": [],
  "altText": "Cat Sitting on Ground"
}
```

### 4. Verificar en DynamoDB

```bash
aws dynamodb get-item --table-name ...-Products \
  --key '{"productId": {"S": "P001"}}' | jq '.Item | {statusImage, moderationStatus, moderationFlags, altText}'
```

**Después de S2:**
```json
{
  "statusImage": "APPROVED",
  "moderationStatus": "APPROVED",
  "moderationFlags": [],
  "altText": "Cat Sitting on Ground"
}
```

### 5. Ver en Frontend

- **Cliente:** ✅ Imagen visible
- **Admin:** ✅ Imagen visible + badge verde "Aprobada"

---

## 🎓 Conexión AIF-C01: Responsible AI

**Dominio D4:** Responsible AI & Governance

| Principio | Aplicación en TechModa |
|-----------|----------------------|
| **Safety** | S2 moderación previene daño reputacional |
| **Fairness** | Moderación automática (sin prejuicios humanos) |
| **Transparency** | Admin ve razones del rechazo (`moderationFlags`) |
| **Accountability** | Log en CloudWatch + DynamoDB audit trail |
| **Accessibility** | `altText` en WCAG 2.1 |

---

**Última actualización:** 2026-09-23  
**Sesiones:** S0 (upload) + S2 (moderación)  
**Próximo:** S7 búsqueda semántica

