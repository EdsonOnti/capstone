# 🎨 FLUJO DE IMAGEN AUTOMATIZADO (COMPLETO)

## ✅ ESTADO ACTUAL

Backend (✅ **COMPLETADO**):
- [x] Endpoint POST `/presigned-upload` desplegado en Router Lambda
- [x] Genera URLs firmadas válidas por 1 hora
- [x] Retorna: `presignedUrl`, `s3Key`, `imageUrl` (CloudFront)
- [x] S3CrudPolicy agregada a RouterFunction
- [x] Env vars: `PRODUCTS_BUCKET`, `CLOUDFRONT_URL`
- [x] Test exitoso con test-image-upload.sh

Frontend (✅ **EN PROGRESO**):
- [x] Funciones de upload agregadas a `frontend/src/lib/api.ts`
- [x] ProductModal actualizado con file input
- [ ] Build y deploy del frontend (último paso)

---

## 📐 ARQUITECTURA DEL FLUJO

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. USUARIO SELECCIONA ARCHIVO                                   │
│    ProductModal → <input type="file" />                         │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. FRONTEND SOLICITA PRESIGNED URL                              │
│    POST /presigned-upload                                       │
│    Body: {productId, filename}                                  │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. ROUTER LAMBDA GENERA URL FIRMADA                             │
│    - Crea s3Key único: products/{id}-{timestamp}-{filename}     │
│    - Genera presigned URL con AWS SDK v3                        │
│    - Retorna URL + s3Key + imageUrl (CloudFront)                │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. FRONTEND SUBE DIRECTAMENTE A S3                              │
│    PUT {presignedUrl}                                           │
│    Payload: archivo binario (CORS: credentials=false)           │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│ 5. S3 RECIBE + CLOUDFRONT CACHEA                                │
│    ProductsBucket → ProductsDistribution (CloudFront)           │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│ 6. FRONTEND ACTUALIZA DYNAMODB                                  │
│    PUT /products/{id}                                           │
│    Body: {imageKey, imageUrl}                                   │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│ 7. DYNAMODB GUARDA METADATOS                                    │
│    Producto.imageKey = s3Key                                    │
│    Producto.imageUrl = https://cf.../products/...jpg            │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│ 8. FRONTEND RENDERIZA IMAGEN                                    │
│    <img src={product.imageUrl} />                               │
│    → Descarga desde CloudFront (fast, cached)                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🚀 IMPLEMENTACIÓN COMPLETADA

### Backend (Router)

**Archivo:** `functions/router/index.js`

✅ **Agregado:**
```javascript
// Importes
const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');

// Instancia
const s3Client = new S3Client({ region: process.env.AWS_REGION || 'us-east-1' });

// Función presignedUpload() — genera URLs firmadas
// Ruteo — POST /presigned-upload
```

**Archivo:** `template.sandbox.yaml`

✅ **Agregado:**
```yaml
RouterFunction:
  Policies:
    - S3CrudPolicy:
        BucketName: !Ref ProductsBucket
  Environment:
    Variables:
      PRODUCTS_BUCKET: !Ref ProductsBucket
      CLOUDFRONT_URL: !Sub 'https://${ProductsDistribution.DomainName}'
```

**Archivo:** `functions/router/package.json`

✅ **Creado:**
```json
{
  "dependencies": {
    "@aws-sdk/client-s3": "^3.600.0",
    "@aws-sdk/s3-request-presigner": "^3.600.0"
  }
}
```

✅ **Deploy:** `bash scripts/deploy.sh` — ✅ UPDATE_COMPLETE

---

### Frontend (API)

**Archivo:** `frontend/src/lib/api.ts`

✅ **Agregado:**
```typescript
// Nuevas funciones:
getPresignedUrl(productId, filename) // POST /presigned-upload
uploadImageToS3(presignedUrl, file)  // PUT {presignedUrl}
uploadProductImage(productId, file)  // Flujo completo (1+2+3)
```

### Frontend (Componentes)

**Archivo:** `frontend/src/components/ProductModal.tsx`

✅ **Agregado:**
- Estado: `isUploading`, `uploadError`
- Handler: `handleImageUpload()` — llama `api.uploadProductImage()`
- Input: File picker con drag-drop visual
- Preview: Muestra imagen local mientras se sube
- Error handling: Muestra errores de upload

---

## 📸 TEST: CLI

**Script:** `bash scripts/test-image-upload.sh`

```
✅ Imagen descargada (4K)
✅ Subida a S3: products/{id}-{timestamp}-test.jpg
✅ DynamoDB actualizado con imageUrl + imageKey
✅ Imagen accesible vía CloudFront
```

---

## 🎯 PRÓXIMOS PASOS: FRONTEND

### Paso 1: Build del frontend

```bash
cd frontend
npm install
npm run build
```

Esto genera `frontend/dist/` listo para deployar a S3.

### Paso 2: Deploy del frontend a S3 + CloudFront

```bash
bash scripts/deploy-frontend.sh
```

Esto:
1. Inyecta `ApiUrl` en `env-config.js` (runtime config)
2. Sube `dist/` a `FrontendBucket`
3. Invalida CloudFront cache
4. Imprime URL del frontend (FrontendUrl output)

### Paso 3: Prueba manual en navegador

1. Abre el URL del frontend (`FrontendUrl` output)
2. Verifica que los productos cargan (están en DynamoDB)
3. Click en "Editar" en algún producto
4. En el modal: Click en "Seleccionar imagen"
5. Selecciona una imagen local (JPG, PNG, etc.)
6. Espera "Subiendo..." a completar
7. Deberías ver el preview de la imagen
8. Click en "Actualizar"
9. Recarga la página
10. ✅ La imagen debería estar visible en la tarjeta del producto
11. La URL debería ser de CloudFront: `https://d2jgv7mcaqixc1.cloudfront.net/products/...jpg`

---

## 🔍 DEBUGGING: Errores comunes

### Error: "Presigned URL error: 400"
→ Verifica que `productId` sea un UUID válido (está editando un producto existente)

### Error: "S3 upload failed: 403"
→ La presigned URL expiró o el bucket policy está incorrecta
→ Corre `bash scripts/test-image-upload.sh` para verificar backend

### Imagen cargada pero no aparece en la tarjeta
→ Abre DevTools → Network tab
→ Verifica que el PUT a S3 devolvió 200 OK
→ Verifica que el PUT a /products/{id} devolvió 200 OK
→ Recarga página → localStorage / caché might be stale

### CloudFront devuelve 403 "Access Denied"
→ Verifica que ProductsBucketPolicy permite s3:GetObject para Principal: '*'
→ Verifica que el objeto está en S3: `aws s3 ls s3://${BUCKET}/products/ --recursive`

---

## 📋 CHECKLIST DE ESTADO

**Backend:**
- [x] `/presigned-upload` endpoint funcionando
- [x] AWS SDK v3 configurado
- [x] S3 policies correctas
- [x] Env vars inyectadas
- [x] Template actualizado
- [x] Deploy exitoso

**Frontend API:**
- [x] `getPresignedUrl()` implementada
- [x] `uploadImageToS3()` implementada
- [x] `uploadProductImage()` flujo completo
- [x] Error handling agregado

**Frontend UI:**
- [x] ProductModal: file input agregado
- [x] ProductModal: preview de imagen
- [x] ProductModal: estado loading
- [x] ProductModal: error messages
- [x] Iconos (Upload, Loader) importados

**Deployment:**
- [ ] `npm run build` (frontend build)
- [ ] `bash scripts/deploy-frontend.sh` (frontend a S3/CloudFront)
- [ ] Test en navegador

---

## 🎬 PRÓXIMOS CAMBIOS QUE PODRÍAS HACER

### 1. Validación de archivo
```typescript
if (file.size > 5 * 1024 * 1024) {
  throw new Error('Archivo demasiado grande (max 5MB)');
}
if (!file.type.startsWith('image/')) {
  throw new Error('Solo se aceptan imágenes');
}
```

### 2. Compresión de imagen (antes de upload)
- Usar librería como `compressorjs` o `sharp` (server-side)
- Reduce tamaño + tiempo de upload

### 3. Indicador de progreso
```typescript
const xhr = new XMLHttpRequest();
xhr.upload.addEventListener('progress', (e) => {
  const percent = (e.loaded / e.total) * 100;
  // Mostrar progress bar
});
```

### 4. Galería de imágenes (múltiples ángulos)
- Agregar más campos: `imageUrl`, `imageUrl2`, `imageUrl3`
- Carousel en ProductCard

### 5. Auto-tagging con Rekognition (S1)
- Lambda S1 lanza automáticamente cuando se detecta PUT en S3
- Agrega tags: `labels` a DynamoDB
- Visible en ProductCard

---

## 📊 FLUJO DE DATOS FINAL

```
Usuario selecciona imagen local
    ↓
Frontend: api.uploadProductImage(productId, file)
    ├─ Step 1: Obtiene presigned URL
    ├─ Step 2: Sube a S3 (directo desde navegador, sin pasar por Lambda)
    └─ Step 3: Actualiza DynamoDB con imageKey + imageUrl
    ↓
DynamoDB: Producto.imageUrl = "https://cf.../products/id-ts-name.jpg"
    ↓
ProductCard re-renderiza: <img src={product.imageUrl} />
    ↓
CloudFront sirve imagen en caché (rápido, HTTPS, global)
    ↓
✅ Imagen visible en la tarjeta
```

---

## ⚡ OPTIMIZACIONES HABILITADAS

| Optimización | Dónde | Beneficio |
|---|---|---|
| **Presigned URL** | Router S3 credentials | No necesita API Gateway ni Lambda intermedia para upload |
| **Direct S3 Upload** | Navegador → S3 | Salta Router Lambda, reduce latencia |
| **CloudFront** | ProductsDistribution | Cachea imágenes globalmente, HTTPS, reduce bandwidth |
| **Lazy loading** | ProductCard (src) | Imágenes cargan on-demand |
| **Versionado S3** | ProductsBucket | Permite rollback de imágenes si es necesario |

---

## 💰 ESTIMACIÓN DE COSTO (mensual, 100 uploads/mes)

| Servicio | Operación | Costo |
|---|---|---|
| S3 (ProductsBucket) | PutObject (100) | ~$0.50 |
| S3 (GetObject) | CloudFront origin (~ 10k views) | ~$0.05 |
| CloudFront | Data transfer out (~ 1 GB) | ~$0.12 |
| Lambda (Router) | Presigned URL requests (100) | < $0.01 |
| DynamoDB | Updates (100) | < $0.01 |
| **Total** | | **~ $0.70 /mes** |

(Números indicativos, verificar precios oficiales)

---

## 🧠 CONCEPTOS CLAVE PARA LA ENTREVISTA / EXAMEN

**¿Por qué presigned URLs?**
- El navegador sube directamente a S3, sin pasar por el backend
- Mejor UX (menos latencia), menos carga en Lambda
- Más seguro: URL expira automáticamente

**¿Por qué CloudFront?**
- Cachea imágenes en edge locations globales
- HTTPS automático
- Reduce costos de bandwidth vs acceso directo a S3

**¿Separar imageKey vs imageUrl?**
- `imageKey`: referencia interna a S3 (parte de la arquitectura)
- `imageUrl`: URL pública para el usuario final (puede cambiar: HTTP→HTTPS, S3→CDN)
- Permite rotación de infraestructura sin romper datos

**¿Versionado de S3?**
- Habilita rollback si se carga una imagen incorrecta
- Auditoría: quién cargó qué y cuándo
- Costo: cada versión ocupa espacio, usar lifecycle policies para limpiar

---

## 📞 SOPORTE

Si falla algo en el test:

```bash
# Revisar logs del router
aws logs tail /aws/lambda/edson-martin-ontiveros-lima-Router --since 5m

# Test presigned-upload manualmente
curl -X POST https://<api-id>.lambda-url.us-east-1.on.aws/presigned-upload \
  -H "Content-Type: application/json" \
  -d '{"productId":"<id>", "filename":"test.jpg"}'

# Listar objetos en S3
aws s3api list-objects-v2 --bucket edson-martin-ontiveros-lima-products --prefix products/

# Verificar DynamoDB
aws dynamodb get-item --table-name edson-martin-ontiveros-lima-Products \
  --key '{"productId":{"S":"<id>"}}'
```

---

**Estado:** ✅ Backend listo para producción
**Siguiente:** Build + deploy frontend

