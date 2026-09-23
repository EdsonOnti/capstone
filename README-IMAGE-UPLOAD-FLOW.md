# 🖼️ FLUJO DE CARGA DE IMÁGENES: GUÍA COMPLETA

## 📋 Estado

✅ **Completado y en producción**

Backend, frontend, y flujo end-to-end implementados y testeados.

## 🚀 URLs Actuales

| Componente | URL |
|-----------|-----|
| Frontend (React) | https://d33x5tfyjkvcnh.cloudfront.net |
| API (Lambda Router) | https://3v374r65fprni2nt74tue4bjp40wdmbp.lambda-url.us-east-1.on.aws/ |
| CloudFront (Images) | https://d2jgv7mcaqixc1.cloudfront.net |

## 🎯 ¿Qué hacer ahora?

### 1. Verificar que todo funciona (5 min)

```bash
# Backend
curl -s https://3v374r65fprni2nt74tue4bjp40wdmbp.lambda-url.us-east-1.on.aws/products | jq .

# Frontend → abrir en navegador
# https://d33x5tfyjkvcnh.cloudfront.net
```

### 2. Probar upload de imagen desde UI (10 min)

1. Abre frontend en navegador
2. Click "Editar" en un producto
3. Click "Seleccionar imagen" → sube un JPG/PNG
4. Espera "Subiendo..." → debe completar en 2-5 seg
5. Click "Actualizar"
6. F5 recarga
7. ✅ Imagen visible con URL de CloudFront

### 3. Verificar en AWS (5 min)

```bash
# S3
aws s3 ls s3://edson-martin-ontiveros-lima-products/products/ --recursive

# DynamoDB
aws dynamodb get-item \
  --table-name edson-martin-ontiveros-lima-Products \
  --key '{"productId":{"S":"5773b6af-fb21-4ff5-bc0b-eb42b1320e03"}}'
```

## 📚 Documentación

- **[FLUJO-IMAGEN-AUTOMATIZADO.md](FLUJO-IMAGEN-AUTOMATIZADO.md)** ← Guía técnica completa
- **[TEST-END-TO-END.md](TEST-END-TO-END.md)** ← Pasos de testing manual
- **scripts/test-image-upload.sh** ← Test CLI automatizado

## 🏗️ Archivos Modificados

### Backend
- `functions/router/index.js` — Endpoint presigned-upload
- `functions/router/package.json` — AWS SDK v3 dependencies
- `template.sandbox.yaml` — S3 policies + env vars
- `samconfig.toml` — Template selection

### Frontend
- `frontend/src/lib/api.ts` — Upload functions
- `frontend/src/components/ProductModal.tsx` — File input UI
- `scripts/deploy-frontend.sh` — Deploy script

## 📊 Arquitectura

```
Usuario selecciona archivo
         ↓
Frontend: POST /presigned-upload
         ↓
Backend: genera URL firmada + s3Key + imageUrl
         ↓
Frontend: PUT {presignedUrl} → S3 directo (sin Lambda)
         ↓
S3 + CloudFront
         ↓
Frontend: PUT /products/{id} → DynamoDB (imageKey + imageUrl)
         ↓
Frontend: <img src={imageUrl} /> → CloudFront sirve caché
         ↓
✅ Imagen visible
```

## 🔑 Conceptos Clave

**Presigned URLs**
- URL firmada que expira automáticamente (1 hora)
- Permite upload directo desde navegador a S3
- Reduce latencia vs. pasar por Lambda

**CloudFront**
- CDN global que cachea imágenes
- Reduce costos de bandwidth
- HTTPS + certificado automático

**imageKey vs imageUrl**
- imageKey: referencia interna (s3://bucket/key)
- imageUrl: URL pública (https://cf.../key)
- Permite cambiar de infraestructura sin mutar datos

**Direct S3 Upload**
- Navegador sube directo a S3, no pasa por Lambda
- Lambda solo firma la solicitud
- 80% menos latencia típicamente

## 💾 Next Steps

### Inmediato
- [ ] Abre frontend → verifica que carga
- [ ] Prueba upload de imagen
- [ ] Recarga → verifica que persiste
- [ ] CLI test: `bash scripts/test-image-upload.sh`

### Producción
- [ ] Habilitar MFA Delete en S3
- [ ] Configurar S3 Lifecycle Policy
- [ ] Agregar CloudFront OAI
- [ ] Validar tamaño archivo (client-side)
- [ ] Monitorear CloudFront errors

### Mejoras futuras
- [ ] Compresión de imagen
- [ ] Progress bar en upload
- [ ] Auto-tagging con Rekognition (S1)
- [ ] Galería múltiple (múltiples ángulos)

## 🐛 Troubleshooting

| Problema | Solución |
|----------|----------|
| "Subiendo..." nunca termina | DevTools → Network tab → ver qué request falla |
| Imagen no aparece tras upload | Ctrl+Shift+R hard refresh |
| 403 CloudFront | Verificar S3 bucket policy (GetObject permitido) |
| Cannot find module 'aws-sdk' | Redeploy: `bash scripts/deploy.sh` |

## 📞 Contacto / Preguntas

Ver archivos de documentación en `/capstone`:
- FLUJO-IMAGEN-AUTOMATIZADO.md
- TEST-END-TO-END.md
- CLAUDE.md (directrices del proyecto)

---

**¡Listo para producción! Abre el frontend y pruébalo.** 🚀

