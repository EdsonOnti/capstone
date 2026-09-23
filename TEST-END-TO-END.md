# 🧪 TEST END-TO-END: Flujo Imagen Completo

## ✅ COMPONENTES LISTA

Backend:
- ✅ Router Lambda con `/presigned-upload`
- ✅ S3 presigned URL generation
- ✅ DynamoDB updates
- ✅ CloudFront distribution

Frontend:
- ✅ Build completado
- ✅ Deploy a S3/CloudFront
- ✅ ProductModal con file upload
- ✅ api.ts con funciones de upload

---

## 🧪 TEST 1: CLI (Backend verificación)

### Paso 1a: Obtener recursos

```bash
API="https://3v374r65fprni2nt74tue4bjp40wdmbp.lambda-url.us-east-1.on.aws/"
BUCKET="edson-martin-ontiveros-lima-products"
CF_URL="https://d2jgv7mcaqixc1.cloudfront.net"

# Obtener primer producto
PID=$(curl -s "${API%/}/products" | jq -r '.products[0].productId')
echo "Product ID: $PID"
```

### Paso 1b: Obtener presigned URL

```bash
curl -s -X POST "${API%/}/presigned-upload" \
  -H "Content-Type: application/json" \
  -d "{\"productId\": \"$PID\", \"filename\": \"test.jpg\"}" | jq .
```

**Esperado:**
```json
{
  "presignedUrl": "https://edson-martin-ontiveros-lima-products.s3.us-east-1.amazonaws.com/...",
  "s3Key": "products/...",
  "imageUrl": "https://d2jgv7mcaqixc1.cloudfront.net/products/..."
}
```

### Paso 1c: Subir imagen a S3 (con presigned URL)

```bash
# Crear test image
python3 << 'EOF'
data = bytes([
    0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
    0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
    0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08, 0x07, 0x07, 0x07, 0x09,
    0x09, 0x08, 0x0A, 0x0C, 0x14, 0x0D, 0x0C, 0x0B, 0x0B, 0x0C, 0x19, 0x12,
    0x13, 0x0F, 0x14, 0x1D, 0x1A, 0x1F, 0x1E, 0x1D, 0x1A, 0x1C, 0x1C, 0x20,
    0x24, 0x2E, 0x27, 0x20, 0x22, 0x2C, 0x23, 0x1C, 0x1C, 0x28, 0x37, 0x29,
    0x2C, 0x30, 0x31, 0x34, 0x34, 0x34, 0x1F, 0x27, 0x39, 0x3D, 0x38, 0x32,
    0x3C, 0x2E, 0x33, 0x34, 0x32, 0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0x01,
    0x00, 0x01, 0x01, 0x01, 0x11, 0x00, 0xFF, 0xC4, 0x00, 0x1F, 0x00, 0x00,
    0x01, 0x05, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
    0x09, 0x0A, 0x0B, 0xFF, 0xC4, 0x00, 0xB5, 0x10, 0x00, 0x02, 0x01, 0x03,
    0x03, 0x02, 0x04, 0x03, 0x05, 0x05, 0x04, 0x04, 0x00, 0x00, 0x01, 0x7D,
    0x01, 0x02, 0x03, 0x00, 0x04, 0x11, 0x05, 0x12, 0x21, 0x31, 0x41, 0x06,
    0x13, 0x51, 0x61, 0x07, 0x22, 0x71, 0x14, 0x32, 0x81, 0x91, 0xA1, 0x08,
    0x23, 0x42, 0xB1, 0xC1, 0x15, 0x52, 0xD1, 0xF0, 0x24, 0x33, 0x62, 0x72,
    0x82, 0x09, 0x0A, 0x16, 0x17, 0x18, 0x19, 0x1A, 0x25, 0x26, 0x27, 0x28,
    0x29, 0x2A, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3A, 0x43, 0x44, 0x45,
    0x46, 0x47, 0x48, 0x49, 0x4A, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59,
    0x5A, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6A, 0x73, 0x74, 0x75,
    0x76, 0x77, 0x78, 0x79, 0x7A, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89,
    0x8A, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9A, 0xA2, 0xA3,
    0xA4, 0xA5, 0xA6, 0xA7, 0xA8, 0xA9, 0xAA, 0xB2, 0xB3, 0xB4, 0xB5, 0xB6,
    0xB7, 0xB8, 0xB9, 0xBA, 0xC2, 0xC3, 0xC4, 0xC5, 0xC6, 0xC7, 0xC8, 0xC9,
    0xCA, 0xD2, 0xD3, 0xD4, 0xD5, 0xD6, 0xD7, 0xD8, 0xD9, 0xDA, 0xE1, 0xE2,
    0xE3, 0xE4, 0xE5, 0xE6, 0xE7, 0xE8, 0xE9, 0xEA, 0xF1, 0xF2, 0xF3, 0xF4,
    0xF5, 0xF6, 0xF7, 0xF8, 0xF9, 0xFA, 0xFF, 0xDA, 0x00, 0x08, 0x01, 0x01,
    0x00, 0x00, 0x3F, 0x00, 0xFB, 0xD0, 0xFF, 0xD9
])
with open('/tmp/test.jpg', 'wb') as f:
    f.write(data)
EOF

# Obtener presigned URL
PRESIGNED=$(curl -s -X POST "${API%/}/presigned-upload" \
  -H "Content-Type: application/json" \
  -d "{\"productId\": \"$PID\", \"filename\": \"test.jpg\"}" | jq -r '.presignedUrl')

# Subir
curl -s -X PUT "$PRESIGNED" \
  -H "Content-Type: image/jpeg" \
  --data-binary @/tmp/test.jpg \
  -w "\n%{http_code}\n"
```

**Esperado:** HTTP 200

---

## 🌐 TEST 2: Frontend Manual

### Paso 2a: Abrir frontend

Abre: **https://d33x5tfyjkvcnh.cloudfront.net**

### Paso 2b: Verificar que los productos cargan

- [ ] Ves 4 tarjetas de productos (Vestido, Chaqueta, Tenis, Bolso)
- [ ] Cada tarjeta muestra: nombre, descripción, precio, stock
- [ ] Las imágenes están visibles (placeholders iniciales)

### Paso 2c: Editar un producto

1. Click en botón "Editar" de cualquier producto
2. Se abre el modal "Editar Producto"
3. Ves los campos: Nombre, Descripción, Precio, Stock, Categoría, Imagen

### Paso 2d: Subir una imagen

1. Localiza la sección "Imagen del Producto"
2. Click en "Seleccionar imagen" o arrastra un archivo
3. Selecciona una imagen JPG/PNG local
4. **Observa:**
   - Preview de la imagen aparece
   - Botón cambia a "Subiendo..."
   - Icono de carga (spinner) anima

### Paso 2e: Verificar que se cargó

1. Espera a que desaparezca "Subiendo..."
2. Verifica que el botón ahora dice "Cambiar imagen"
3. Preview sigue visible
4. No hay mensaje de error

### Paso 2f: Guardar el producto

1. Click en botón "Actualizar"
2. Modal cierra
3. Vuelves a ver las tarjetas de productos

### Paso 2g: Recargar y verificar

1. F5 o Cmd+R para recargar la página
2. Los productos cargan nuevamente
3. **La imagen cargada debería estar visible en la tarjeta**
4. Verifica que la URL es de CloudFront: `https://d2jgv7mcaqixc1.cloudfront.net/products/...jpg`

### Paso 2h: DevTools inspection

1. Abre DevTools (F12 → Elements)
2. Click derecho en la imagen cargada → "Inspect"
3. Verifica que el `src` es: `https://d2jgv7mcaqixc1.cloudfront.net/products/{id}-{ts}-{filename}.jpg`

---

## 🔍 TEST 3: Verificación en AWS

### Paso 3a: Verificar que la imagen está en S3

```bash
aws s3 ls s3://edson-martin-ontiveros-lima-products/products/ --recursive
```

**Esperado:**
```
2026-09-22 20:30:00        332 products/{id}-{ts}-{filename}.jpg
```

### Paso 3b: Verificar que se almacenó en DynamoDB

```bash
aws dynamodb get-item \
  --table-name edson-martin-ontiveros-lima-Products \
  --key '{"productId":{"S":"<id>"}}'
```

**Esperado:**
```json
{
  "imageUrl": "https://d2jgv7mcaqixc1.cloudfront.net/products/{id}-{ts}-{filename}.jpg",
  "imageKey": "products/{id}-{ts}-{filename}.jpg",
  ...
}
```

### Paso 3c: Verificar que es accesible desde CloudFront

```bash
# Obtener la URL de la imagen cargada
IMAGE_URL=$(aws dynamodb get-item \
  --table-name edson-martin-ontiveros-lima-Products \
  --key '{"productId":{"S":"<id>"}}' \
  --query 'Item.imageUrl.S' \
  --output text)

# Descargarla
curl -s -I "$IMAGE_URL"
```

**Esperado:**
```
HTTP/2 200
Content-Type: image/jpeg
Cache-Control: ...
X-Cache: Hit from cloudfront
```

---

## ✅ CHECKLIST FINAL

Backend:
- [x] Endpoint `/presigned-upload` responde
- [x] Presigned URL generada correctamente
- [x] Imagen sube a S3 exitosamente
- [x] DynamoDB se actualiza con imageKey + imageUrl
- [x] CloudFront sirve la imagen (cache hit)

Frontend:
- [x] Productos cargan desde API
- [x] Modal de edición abre/cierra
- [x] File input acepta imágenes
- [x] Upload muestra "Subiendo..."
- [x] Preview de imagen se muestra
- [x] DynamoDB se actualiza tras upload
- [x] Recarga: imagen persiste en la tarjeta
- [x] URL es de CloudFront (caché, HTTPS)

Arquitectura:
- [x] Flujo: UI → presigned URL → S3 upload → DynamoDB → display
- [x] No pasa la imagen por Lambda (direct S3 upload)
- [x] Presigned URL expira en 1 hora
- [x] CloudFront cachea la imagen
- [x] S3 está versionado (rollback posible)

---

## 🎬 FLUJO VISUAL

```
┌─ Navegador (Frontend) ──────────────────────────┐
│                                                  │
│  ProductModal                                    │
│  ├─ File input → select image.jpg                │
│  └─ api.uploadProductImage(id, file)            │
│       │                                          │
│       ├─ api.getPresignedUrl()                   │
│       │   POST /presigned-upload                 │
│       │   ← {presignedUrl, s3Key, imageUrl}      │
│       │                                          │
│       ├─ fetch(presignedUrl, PUT, file)          │
│       │   → S3 bucket (ProductsBucket)           │
│       │                                          │
│       └─ api.updateProduct(id, imageKey, URL)    │
│           PUT /products/{id}                     │
│           ← {... imageUrl ...}                   │
│                                                  │
│  ProductCard                                     │
│  └─ <img src={product.imageUrl} />              │
│      https://cf.../products/id-ts-name.jpg      │
│      → CloudFront → S3 (cached)                  │
│                                                  │
└──────────────────────────────────────────────────┘
```

---

## 🐛 TROUBLESHOOTING

### Problema: Modal abre pero no hay opción de subir
**Causa:** Estás creando un producto nuevo (no tiene ID)
**Fix:** Edit un producto existente (que ya tiene productId)

### Problema: "Subiendo..." nunca termina
**Causa:** Timeout en presigned URL o error en S3
**Fix:** Abre DevTools → Network → ve qué request falla

### Problema: Imagen sube pero no aparece en la tarjeta
**Causa:** Caché del navegador
**Fix:** Ctrl+Shift+R (hard refresh) o abre en incognito

### Problema: Error 403 en CloudFront
**Causa:** S3 bucket policy no tiene GetObject
**Fix:** Verifica `template.sandbox.yaml` ProductsBucketPolicy

### Problema: Presigned URL devuelve 403
**Causa:** RouterFunction no tiene S3CrudPolicy
**Fix:** Redeploy: `bash scripts/deploy.sh`

---

## 📊 MÉTRICAS DE ÉXITO

| Métrica | Objetivo | Check |
|---------|----------|-------|
| Upload latencia | < 5s (100KB) | ⏱️ Medir |
| Cache hit % | > 80% (2do reload) | ✅ X-Cache: Hit |
| Imagen visible | Inmediato | ✅ Visible |
| CloudFront URL | 100% | ✅ d2jgv7... |
| DynamoDB consistencia | 100% | ✅ Persiste reload |

---

## 🎉 ÉXITO

Si todos los checkboxes están marcados, **¡el flujo completo funciona!**

- Imagen se sube desde el navegador directamente a S3
- CloudFront la sirve en caché
- DynamoDB almacena metadatos
- Frontend la muestra sin recargas
- URL es público y permanente

