# 🧪 GUÍA PASO A PASO: TESTING COMPLETO

## ✅ ESTADO ACTUAL

✅ **4 imágenes cargadas en S3**
✅ **DynamoDB actualizado con URLs de CloudFront**
✅ **Frontend desplegado en CloudFront**
✅ **API funcional**
✅ **CloudFront caché invalidado**

---

## 🎯 PASO 1: VERIFICAR QUE TODO ESTÁ EN LUGAR (2 min)

### 1a. Verificar imágenes en S3

```bash
aws s3 ls s3://edson-martin-ontiveros-lima-products/products/ --recursive
```

**Esperado:**
```
2026-09-22 20:58:53     108984 products/vestido.jpg
2026-09-22 20:58:55     271996 products/chaqueta.jpg
2026-09-22 20:58:58     171140 products/tenis.jpg
2026-09-22 20:58:56     240346 products/bolso.jpg
```

### 1b. Verificar DynamoDB tiene URLs

```bash
aws dynamodb scan --table-name edson-martin-ontiveros-lima-Products \
  --projection-expression "productId,#n,imageUrl" \
  --expression-attribute-names '{"#n":"name"}' \
  --region us-east-1 | jq '.Items[] | {name: .#n.S, imageUrl: .imageUrl.S}'
```

**Esperado:**
```json
{
  "name": "Vestido midi floral",
  "imageUrl": "https://d2jgv7mcaqixc1.cloudfront.net/products/vestido.jpg"
}
{
  "name": "Chaqueta de mezclilla oversize",
  "imageUrl": "https://d2jgv7mcaqixc1.cloudfront.net/products/chaqueta.jpg"
}
...
```

### 1c. Verificar API devuelve productos con URLs

```bash
curl -s https://3v374r65fprni2nt74tue4bjp40wdmbp.lambda-url.us-east-1.on.aws/products | \
  jq '.products[] | {name, imageUrl}'
```

**Esperado:**
```json
{
  "name": "Chaqueta de mezclilla oversize",
  "imageUrl": "https://d2jgv7mcaqixc1.cloudfront.net/products/chaqueta.jpg"
}
```

---

## 🌐 PASO 2: ABRIR FRONTEND EN NAVEGADOR (1 min)

### 2a. Abrir URL

Abre en navegador:
```
https://d33x5tfyjkvcnh.cloudfront.net
```

### 2b. Si ves "failed fetch" o imágenes no cargan

**Hacer hard refresh (limpia caché):**
- **Windows/Linux:** Ctrl+Shift+R
- **Mac:** Cmd+Shift+R

O abrir DevTools (F12) → Network tab → marcar "Disable cache" → F5

### 2c. Esperar a que cargue

Deberías ver:
- ✅ 4 tarjetas de productos
- ✅ Nombres: Vestido, Chaqueta, Tenis, Bolso
- ✅ Precios, descripciones, stock
- ✅ **IMÁGENES VISIBLES** (de Unsplash)

Si las imágenes no cargan, ver "Debugging" abajo.

---

## 🖼️ PASO 3: VERIFICAR IMÁGENES DESDE DEVTOOLS (2 min)

### 3a. Abrir DevTools

Presiona: **F12**

### 3b. Ir a "Elements" → Buscar img

1. Click derecho en una imagen del producto
2. Click "Inspect"
3. Deberías ver algo como:

```html
<img 
  src="https://d2jgv7mcaqixc1.cloudfront.net/products/vestido.jpg"
  alt="Vestido midi floral"
  class="w-full h-full object-cover"
/>
```

### 3c. Verificar URL de la imagen

✅ ¿Empieza con `https://d2jgv7mcaqixc1.cloudfront.net/`?
✅ ¿El archivo es `products/vestido.jpg`, `products/chaqueta.jpg`, etc.?

Si todo es correcto → **paso 4**

---

## 📤 PASO 4: PROBAR UPLOAD DE IMAGEN NUEVA (5 min)

### 4a. Click en "Editar" en un producto

1. Abre frontend
2. Click en botón azul "Editar" (en la tarjeta de un producto)
3. Se abre modal: "Editar Producto"

### 4b. Buscar sección "Imagen del Producto"

Deberías ver:
- Preview de la imagen actual (Unsplash)
- Botón "Cambiar imagen"
- Input para pegar URL (opcional)

### 4c. Click "Cambiar imagen" o arrastra un archivo

1. Click en el botón azul "Cambiar imagen"
2. Se abre file picker
3. Selecciona una imagen JPG/PNG de tu disco local
4. Observa:
   - Preview de la imagen LOCAL aparece
   - Botón dice "Subiendo..." con spinner
   - NO debe haber error rojo

### 4d. Esperar a que complete

- Típicamente: 2-5 segundos
- Botón debería cambiar a "Cambiar imagen" (de nuevo)
- Preview debería mostrar la imagen nueva
- Sin mensajes de error

### 4e. Click "Actualizar"

1. Click botón azul "Actualizar"
2. Modal cierra
3. Vuelves a ver las tarjetas

### 4f. Hard refresh y verificar

1. F5 o Ctrl+Shift+R
2. Las tarjetas recarga
3. ✅ Tu imagen nueva debería estar visible
4. ✅ La URL debería ser de CloudFront: `https://d2jgv7mcaqixc1.cloudfront.net/products/...jpg`

---

## 🔍 DEBUGGING: Si las imágenes no cargan

### Error 1: "Failed fetch" en consola

**Causa:** El frontend no puede descargar imágenes
**Solución:**
```bash
# 1. Verificar CloudFront puede servir
curl -I https://d2jgv7mcaqixc1.cloudfront.net/products/vestido.jpg

# 2. Si devuelve 200 → es caché del navegador
# Solución: Ctrl+Shift+R (hard refresh)

# 3. Si devuelve 403/404 → problema en S3/bucket policy
# Solución: bash scripts/deploy.sh (redeploy)
```

### Error 2: "undefined" o "REEMPLAZAR_CON_TU_IMAGEN"

**Causa:** imageUrl no se actualizó en DynamoDB
**Verificar:**
```bash
# Verificar que DynamoDB tiene imageUrl
aws dynamodb get-item \
  --table-name edson-martin-ontiveros-lima-Products \
  --key '{"productId":{"S":"<ID>"}}' | jq '.Item.imageUrl'

# Si está vacío → ejecutar:
bash scripts/upload-product-images.sh
```

### Error 3: Upload falla con "Subiendo..." infinito

**Causa:** Presigned URL error o S3 no accesible
**Solución:**
1. DevTools → Network tab
2. Intenta subir imagen de nuevo
3. Busca request POST `/presigned-upload`
   - ¿Devolvió 200? → Ok, backend ok
   - ¿Devolvió 400/500? → problema en backend, revisar logs:
     ```bash
     aws logs tail /aws/lambda/edson-martin-ontiveros-lima-Router --since 5m
     ```
4. Busca request PUT a S3 (`s3.us-east-1.amazonaws.com`)
   - ¿Devolvió 200? → Ok, imagen llegó a S3
   - ¿Devolvió 403? → S3 policy issue, redeploy:
     ```bash
     bash scripts/deploy.sh
     ```

### Error 4: Imagen se sube pero no aparece en tarjeta

**Causa:** Caché del navegador
**Solución:**
```bash
# Hard refresh (limpia caché local)
# Ctrl+Shift+R (Windows/Linux) o Cmd+Shift+R (Mac)

# Si persiste, invalidar CloudFront:
aws cloudfront create-invalidation \
  --distribution-id E1MOSG4LW50OGX \
  --paths "/*"
```

---

## ✅ CHECKLIST FINAL

**Backend:**
- [ ] Imágenes visibles en S3
- [ ] DynamoDB tiene imageUrl para cada producto
- [ ] API devuelve productos con imageUrl

**Frontend:**
- [ ] Frontend carga sin errores
- [ ] Ves 4 tarjetas de productos
- [ ] Cada tarjeta muestra una imagen (Unsplash)
- [ ] Las URLs son de CloudFront

**Upload:**
- [ ] Puedo hacer click "Editar"
- [ ] Puedo seleccionar archivo local
- [ ] Upload completa sin errores
- [ ] Tras recarga, la imagen nueva está visible
- [ ] La URL es de CloudFront

---

## 📞 RESUMEN DE URLS

| Recurso | URL |
|---------|-----|
| **Frontend** | https://d33x5tfyjkvcnh.cloudfront.net |
| **API** | https://3v374r65fprni2nt74tue4bjp40wdmbp.lambda-url.us-east-1.on.aws/ |
| **Imágenes** | https://d2jgv7mcaqixc1.cloudfront.net/products/{filename}.jpg |
| **S3 Bucket** | s3://edson-martin-ontiveros-lima-products |
| **DynamoDB Table** | edson-martin-ontiveros-lima-Products |

---

## 🎯 FLUJO COMPLETO

```
1. Usuario abre https://d33x5tfyjkvcnh.cloudfront.net
         ↓
2. Frontend: GET /products
         ↓
3. API (Lambda): retorna productos con imageUrl (CloudFront)
         ↓
4. Frontend renderiza: <img src={imageUrl} />
         ↓
5. Navegador: GET https://d2jgv7mcaqixc1.cloudfront.net/products/vestido.jpg
         ↓
6. CloudFront: sirve desde caché (o de S3 si no está cacheado)
         ↓
7. Imagen visible en tarjeta del producto
         ↓
✅ ÉXITO
```

---

## 🚀 NEXT STEPS DESPUÉS DE VERIFICAR TODO

1. **Producción:**
   - [ ] Habilitar MFA Delete en S3
   - [ ] Configurar S3 Lifecycle Policy
   - [ ] Monitorear CloudFront errors

2. **Mejoras:**
   - [ ] Compresión de imagen en cliente
   - [ ] Validación de tamaño (max 5MB)
   - [ ] Progress bar en upload
   - [ ] Auto-tagging con Rekognition

3. **Documentación:**
   - [ ] Compartir URLs con el equipo
   - [ ] Documentar arquitectura
   - [ ] Crear runbook de maintenance

---

**¡Listo! Sigue estos pasos en orden.** 🎯

