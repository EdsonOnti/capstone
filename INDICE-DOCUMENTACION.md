# 📚 ÍNDICE COMPLETO DE DOCUMENTACIÓN

## 🎯 EMPEZAR AQUÍ

Si es tu primer día, empieza con esto en orden:

1. **[README.md](README.md)** ← Guía ejecutiva (5 min)
   - S0–S6 implementadas
   - Flujo de imagen: moderación + visualización
   - Ruta a S7 RAG
   - Stack actual + conceptos clave

2. **[GUIA-CLIENTE-ADMIN.md](GUIA-CLIENTE-ADMIN.md)** ← Usar el app (10 min)
   - Modo cliente: buscar, ver reseñas, sentimiento
   - Modo admin: crear, editar, subir imágenes

3. **[FLUJO-IMAGEN-MODERATION-GATING.md](FLUJO-IMAGEN-MODERATION-GATING.md)** ← Entender S0–S2 (20 min)
   - Cómo statusImage controla visualización
   - Código S2 Rekognition + DynamoDB update
   - Frontend cliente vs admin
   - Testing manual

---

## 📖 DOCUMENTACIÓN POR TEMA

### 🏗️ **ARQUITECTURA**

| Documento | Contenido | Cuándo leer |
|-----------|----------|-----------|
| **[README.md](README.md)** | Visión ejecutiva S0–S6 + ruta a S7 | Punto de entrada |
| **[FLUJO-IMAGEN-AUTOMATIZADO.md](FLUJO-IMAGEN-AUTOMATIZADO.md)** | Arquitectura técnica completa S0–S6 + código reutilizable | Profundidad técnica |
| **[FLUJO-IMAGEN-MODERATION-GATING.md](FLUJO-IMAGEN-MODERATION-GATING.md)** | S0–S2: Upload → Moderación → Visualización | Entender gating |
| **[S7-ROADMAP-RAG.md](S7-ROADMAP-RAG.md)** | RAG: embeddings, vector DB, búsqueda semántica + código | Prepararse para S7 |

### 🧪 **TESTING Y DEBUGGING**

| Documento | Contenido | Cuándo leer |
|-----------|----------|-----------|
| **[TEST-END-TO-END.md](TEST-END-TO-END.md)** | Testing CLI + UI + debugging | Cuando algo no funciona |
| **[TESTING-GUIA-PASO-A-PASO.md](TESTING-GUIA-PASO-A-PASO.md)** | Pasos manuales guiados | Cuando quieras verificar todo funciona |

### 📱 **FRONTEND**

| Documento | Contenido | Archivo |
|-----------|----------|---------|
| Upload functions | `getPresignedUrl`, `uploadImageToS3`, `uploadProductImage` | `frontend/src/lib/api.ts` |
| ProductModal | File input + preview + loading | `frontend/src/components/ProductModal.tsx` |
| Deploy script | Inyecta API URL + sube a S3 | `scripts/deploy-frontend.sh` |

### 🔧 **BACKEND**

| Documento | Contenido | Archivo |
|-----------|----------|---------|
| Presigned URL | Función `presignedUpload()` genera URLs | `functions/router/index.js` |
| Dependencies | AWS SDK v3 | `functions/router/package.json` |
| SAM template | S3 policies + env vars | `template.sandbox.yaml` |

### 🪣 **S3 + CLOUDFRONT**

| Documento | Contenido | Archivo |
|-----------|----------|---------|
| ProductsBucket | Bucket S3 público para imágenes | `template.sandbox.yaml` |
| BucketPolicy | Permite lectura pública (GetObject) | `template.sandbox.yaml` |
| CloudFront Distribution | CDN global, HTTPS, caché | `template.sandbox.yaml` |

### 📊 **SCRIPTS**

| Script | Qué hace | Ubicación |
|--------|----------|-----------|
| `upload-product-images.sh` | Descarga 4 imágenes Unsplash → S3 → DynamoDB | `scripts/` |
| `deploy-frontend.sh` | Inyecta API URL + sube frontend a S3 | `scripts/` |
| `test-image-upload.sh` | Test CLI automatizado (presigned URL → S3 → DynamoDB) | `scripts/` |
| `deploy.sh` | Deploy backend (sam build && sam deploy) | `scripts/` |

---

## 🎯 PREGUNTAS FRECUENTES: DÓNDE BUSCAR

### "¿Qué se implementó en S0–S6?"
👉 [README.md](README.md) → Sección "Lo que se ha implementado"

### "¿Cómo funciona el flujo de imagen S0–S2?"
👉 [FLUJO-IMAGEN-MODERATION-GATING.md](FLUJO-IMAGEN-MODERATION-GATING.md)

### "¿Cómo se ve el frontend cliente vs admin?"
👉 [GUIA-CLIENTE-ADMIN.md](GUIA-CLIENTE-ADMIN.md)

### "¿Por qué la imagen no se ve?"
👉 [FLUJO-IMAGEN-MODERATION-GATING.md](FLUJO-IMAGEN-MODERATION-GATING.md) → "Estados y Transiciones"

### "¿Cómo funciona la búsqueda semántica (S7)?"
👉 [S7-ROADMAP-RAG.md](S7-ROADMAP-RAG.md) → "Conceptos Clave"

### "¿Código para S7?"
👉 [S7-ROADMAP-RAG.md](S7-ROADMAP-RAG.md) → "Implementación: Paso a Paso"

### "¿Cuál es la arquitectura completa?"
👉 [FLUJO-IMAGEN-AUTOMATIZADO.md](FLUJO-IMAGEN-AUTOMATIZADO.md)

### "¿Cómo testear todo?"
👉 [S7-ROADMAP-RAG.md](S7-ROADMAP-RAG.md) → "Testing S7"

---

## 🗂️ ESTRUCTURA DE ARCHIVOS DOCUMENTACIÓN

```
capstone/
├── README-IMAGE-UPLOAD-FLOW.md          ← EMPIEZA AQUÍ (guía rápida)
├── RESUMEN-CAMBIOS-COMPLETO.md          ← QUÉ CAMBIÓ (resumen)
├── INDICE-DOCUMENTACION.md              ← TÚ ESTÁS AQUÍ (mapa)
├── FLUJO-IMAGEN-AUTOMATIZADO.md         ← ARQUITECTURA (profundo)
├── TEST-END-TO-END.md                   ← TESTING (CLI + UI)
├── TESTING-GUIA-PASO-A-PASO.md          ← TESTING MANUAL (pasos)
│
├── functions/router/
│   ├── index.js                         ← Presigned URL endpoint
│   └── package.json                     ← AWS SDK v3
│
├── frontend/src/
│   ├── lib/api.ts                       ← Upload functions
│   └── components/ProductModal.tsx      ← File input + preview
│
├── template.sandbox.yaml                ← S3 + CloudFront + policies
├── samconfig.toml                       ← Deploy config
│
└── scripts/
    ├── upload-product-images.sh         ← Carga imágenes Unsplash
    ├── deploy-frontend.sh               ← Deploy frontend
    ├── test-image-upload.sh             ← Test CLI
    └── deploy.sh                        ← Deploy backend
```

---

## 📋 FLUJO DE APRENDIZAJE RECOMENDADO

### Día 1: Entender qué se hizo
1. Lee [README-IMAGE-UPLOAD-FLOW.md](README-IMAGE-UPLOAD-FLOW.md) (5 min)
2. Lee [RESUMEN-CAMBIOS-COMPLETO.md](RESUMEN-CAMBIOS-COMPLETO.md) (15 min)
3. Lee código en `functions/router/index.js` (10 min)
4. Lee código en `frontend/src/lib/api.ts` (10 min)

### Día 2: Entender cómo funciona
1. Lee [FLUJO-IMAGEN-AUTOMATIZADO.md](FLUJO-IMAGEN-AUTOMATIZADO.md) (20 min)
2. Ejecuta [TESTING-GUIA-PASO-A-PASO.md](TESTING-GUIA-PASO-A-PASO.md) (20 min)
3. Prueba upload de imagen desde UI

### Día 3: Debugging y troubleshooting
1. Lee [TEST-END-TO-END.md](TEST-END-TO-END.md) si algo falla
2. Revisa logs: `aws logs tail /aws/lambda/edson-martin-ontiveros-lima-Router`
3. DevTools Console para ver errores CORS

---

## 🚀 URLS EN VIVO

| Recurso | URL |
|---------|-----|
| **Frontend** | https://d33x5tfyjkvcnh.cloudfront.net |
| **API** | https://3v374r65fprni2nt74tue4bjp40wdmbp.lambda-url.us-east-1.on.aws/ |
| **CloudFront (images)** | https://d2jgv7mcaqixc1.cloudfront.net/products/ |

---

## 📞 REFERENCIA RÁPIDA

| Necesito... | Ir a... |
|------------|---------|
| Resumen ejecutivo | README.md |
| Usar el app (cliente/admin) | GUIA-CLIENTE-ADMIN.md |
| Entender S0–S2 (moderación) | FLUJO-IMAGEN-MODERATION-GATING.md |
| Arquitectura técnica completa | FLUJO-IMAGEN-AUTOMATIZADO.md |
| Prepararse para S7 | S7-ROADMAP-RAG.md |
| Código Python para S7 | S7-ROADMAP-RAG.md → "Implementación" |
| Testear S7 | S7-ROADMAP-RAG.md → "Testing S7" |
| Estado actual (S0–S3) | CAPSTONE-STATUS.md |

---

## ✅ CHECKLIST: ¿HAS ENTENDIDO?

- [ ] ¿Qué es una presigned URL?
- [ ] ¿Por qué el navegador sube directo a S3?
- [ ] ¿Cuál es la diferencia entre imageKey e imageUrl?
- [ ] ¿Cómo funciona CloudFront?
- [ ] ¿Qué cambiós se hicieron en backend?
- [ ] ¿Qué cambios se hicieron en frontend?
- [ ] ¿Cuál es el flujo end-to-end?
- [ ] ¿Cómo se genera la presigned URL?
- [ ] ¿Dónde se almacenan las imágenes?

Si respondes "sí" a todas → ¡Entendiste el 100%! 🎉

---

**Última actualización:** 2026-09-22 21:30 UTC

