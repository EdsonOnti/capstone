# 🛍️ TechModa — E-commerce Serverless con IA

[![Status](https://img.shields.io/badge/status-S0%E2%80%93S6%20Completadas-brightgreen)](.)
[![AWS](https://img.shields.io/badge/AWS-SAM%20%7C%20Lambda%20%7C%20DynamoDB-orange)](.)
[![Python](https://img.shields.io/badge/Python-3.12-blue)](.)
[![Node.js](https://img.shields.io/badge/Node.js-22.x-green)](.)
[![License](https://img.shields.io/badge/License-MIT-purple)](.)

Capstone educativo para **AWS AI Practitioner (AIF-C01)**: una tienda online serverless que integra 6 servicios de IA de AWS en arquitectura progresiva. Desde etiquetado automático de imágenes hasta búsqueda semántica con Claude.

---

## 📊 Estado del Proyecto

| Sesión | Servicio | Objetivo | Estado |
|--------|----------|----------|--------|
| **S0** | Lambda + DynamoDB | Base serverless CRUD | ✅ Completada |
| **S1** | Rekognition | Etiquetado automático de imágenes | ✅ Completada |
| **S2** | Rekognition | Moderación + alt-text accesible | ✅ Completada |
| **S3** | Comprehend | Análisis de sentimiento en reseñas | ✅ Completada |
| **S4** | Translate | Catálogo multiidioma ES↔EN | ✅ Completada |
| **S5** | Polly | Síntesis de voz para accesibilidad | ✅ Completada |
| **S6** | Bedrock Claude | Generación de descripciones | ✅ Completada |
| **S7** | Bedrock Embeddings | RAG + búsqueda semántica | 🚀 Roadmap |
| **S8–S11** | Varios | Chatbot, gobernanza, cleanup | 📋 Planeado |

**Progreso:** 6/12 sesiones (50%) | ~10.000 líneas de código | ~35 archivos nuevos

---

## 🎯 ¿Qué Se Implementó?

### Backend (AWS Serverless)

```
Lambda Functions (13 total)
├─ S0: Router CRUD (Node.js 22.x)
├─ S1: EnrichLabels (Python 3.12) — Rekognition DetectLabels
├─ S2: ModerateImage (Python 3.12) — Rekognition Moderation + alt-text
├─ S3: AnalyzeSentiment (Python 3.12) — Comprehend DetectSentiment
├─ S4: TranslateCatalog (Python 3.12) — Amazon Translate
├─ S5: SynthesizeVoice (Python 3.12) — Amazon Polly
├─ S6: GenerateDescription (Python 3.12) — Bedrock Claude
└─ Utilities: Seed, Validation, Monitoring

Base de Datos (DynamoDB)
└─ Table: Products
   ├─ PK: productId
   ├─ Originales: name, price, stock, category, description, imageUrl
   ├─ S1: aiLabels (etiquetas), aiLabelsRaw
   ├─ S2: moderationStatus, moderationFlags, altText, statusImage
   ├─ S3: reviewSentiment, reviewSentimentCounts
   ├─ S4: translations.es, translations.en
   ├─ S5: audioUrl, audioTranscript
   └─ S6: generatedDescription, descriptionTone

Almacenamiento (S3 + CloudFront)
├─ ProductsBucket: imágenes de productos
├─ FrontendBucket: aplicación React
└─ CloudFront: CDN global HTTPS

Infraestructura (SAM + CloudFormation)
├─ 3 templates: base, sandbox (usado), full
├─ IAM: mínimo privilegio por función Lambda
└─ ~200+ líneas de IaC por sesión
```

### Frontend (React + Vite + TypeScript)

```
React Components
├─ ProductCard: Tarjeta de producto con etiquetas S1
├─ ProductModal: Modal con detalles (S0-S6)
│  ├─ Imagen (gating S2: solo si APPROVED)
│  ├─ Etiquetas visuales (S1)
│  ├─ Alt-text accesible (S2)
│  ├─ Descripción (S6 o original)
│  ├─ Audio (S5 — play/download)
│  └─ Reseñas + Sentimiento (S3)
├─ ReviewsSection: Agregar reseña + análisis de sentimiento
├─ SearchBox: Búsqueda por nombre/categoría (S7: semántica)
├─ ChatBox: Chat con asistente (S7–S8)
└─ AdminPanel: CRUD, upload de imágenes (S0, S2)

State Management
├─ API calls: fetch wrapper con presigned URLs (S3)
├─ Context: modo cliente vs admin
└─ TypeScript: tipos completos para productos

Styling
├─ Tailwind CSS
├─ Componentes responsive
└─ Tema claro/oscuro
```

### Características por Sesión

#### ✅ S0: Base Serverless
```
GET    /products           — Listar productos
POST   /products           — Crear producto
GET    /products/{id}      — Obtener producto
PUT    /products/{id}      — Actualizar
DELETE /products/{id}      — Eliminar
```
- **Backend:** Router Lambda Node.js, Function URLs (sin API Gateway)
- **DB:** DynamoDB on-demand, 4 productos seed
- **Frontend:** Listado, búsqueda, filtro por categoría
- **Deploy:** CloudFormation + SAM

#### ✅ S1: Rekognition Labels
```
POST /products/{id}/enrich-labels
```
- **Entrada:** ID del producto (obtiene imageUrl de DDB)
- **Proceso:** Rekognition DetectLabels (máx 10 etiquetas, confianza >70%)
- **Salida:** Guarda `aiLabels` (array con name + confidence)
- **UX:** Etiquetas visibles en modal del producto
- **Caso de uso:** Búsqueda mejorada, clasificación automática

#### ✅ S2: Moderación + Accesibilidad
```
POST /products/{id}/moderate
```
- **Entrada:** ID del producto
- **Proceso:** 
  1. Rekognition DetectModerationLabels (detecta contenido inapropiado)
  2. Rekognition DetectLabels (genera alt-text)
- **Salida:** 
  - `statusImage`: APPROVED / FLAGGED / PENDING
  - `moderationFlags`: array de problemas detectados
  - `altText`: descripción accesible (WCAG 2.1)
- **Gating:** Cliente solo ve si statusImage == APPROVED
- **Admin:** Ve TODAS + razones del rechazo
- **Caso de uso:** Control de contenido + inclusión

#### ✅ S3: Análisis de Sentimiento
```
POST /products/{id}/analyze-sentiment
```
- **Entrada:** Array de reseñas de cliente
- **Proceso:**
  1. Comprehend DetectDominantLanguage (auto-detecta idioma)
  2. Comprehend DetectSentiment (POSITIVE/NEGATIVE/NEUTRAL/MIXED)
- **Salida:**
  - `reviewSentiment`: sentimiento general
  - `reviewSentimentCounts`: {POSITIVE: 3, NEGATIVE: 1, ...}
- **UX:** Dashboard de sentimiento en modal de producto
- **Caso de uso:** Métrica de satisfacción del cliente en tiempo real

#### ✅ S4: Traducción Automática
```
POST /products/{id}/translate?target=en|es
```
- **Entrada:** ID producto, idioma destino
- **Proceso:** Amazon Translate TranslateText (EN ↔ ES)
- **Salida:** Guarda `translations.es` y `translations.en`
- **UX:** Selector de idioma en frontend
- **Caso de uso:** Alcance global sin traductores

#### ✅ S5: Síntesis de Voz
```
POST /products/{id}/synthesize-voice
```
- **Entrada:** ID producto, idioma (es-ES, en-US)
- **Proceso:** Amazon Polly SynthesizeSpeech (mp3, varias voces)
- **Salida:** URL de audio en S3, guarda en DDB
- **UX:** Player de audio en modal, botón descargar
- **Caso de uso:** Accesibilidad para usuarios con discapacidad visual

#### ✅ S6: Generación de Descripciones
```
POST /products/{id}/describe?tone=elegante|divertido|minimalista
```
- **Entrada:** ID producto, tono deseado, etiquetas S1
- **Proceso:** 
  1. Construye prompt con: nombre, categoría, price, aiLabels
  2. Bedrock Converse API (Claude Haiku)
  3. Parámetros: maxTokens=200, temperature=0.7
- **Salida:** Descripción generada, tokens utilizados
- **Almacenamiento:** `generatedDescription`, `descriptionTone`
- **Caso de uso:** Marketing a escala, tono consistente

---

## 🏗️ Arquitectura General

```
┌─────────────────────────────────────────────────────────────┐
│                 FRONTEND (React/Vite/TS)                    │
│             CloudFront HTTPS + S3 Static                   │
└──────────────┬──────────────────────────────────────────────┘
               │ fetch()
               ▼
┌─────────────────────────────────────────────────────────────┐
│           LAMBDA ROUTER (S0) Node.js 22.x                  │
│    GET /products | POST | PUT | DELETE                     │
└──────────────┬──────────────────────────────────────────────┘
               │
        ┌──────┴──────────┬──────────┬──────────┐
        ▼                 ▼          ▼          ▼
    ┌────────────┐  ┌────────────┐ ┌────────────┐ ┌────────────┐
    │     S1     │  │     S2     │ │     S3     │ │    DDB     │
    │ Rekognition│  │ Rekognition│ │ Comprehend │ │ Products   │
    │  Labels    │  │ Moderation │ │ Sentiment  │ │   Table    │
    └────────────┘  └────────────┘ └────────────┘ └────────────┘
         ↓               ↓              ↓              ↓
      [labels]      [flags + alt] [sentiment]    [data store]
        
    ┌────────────┐  ┌────────────┐ ┌────────────┐
    │     S4     │  │     S5     │ │     S6     │
    │ Translate  │  │   Polly    │ │  Bedrock   │
    │            │  │            │ │   Claude   │
    └────────────┘  └────────────┘ └────────────┘
    [translations] [audio url]   [description]
```

### Flujo de Moderación y Visualización

```
Admin sube imagen → S3 + DynamoDB
    ↓ statusImage = PENDING
    ↓ (cliente NO ve)
    
S2 Rekognition valida
    ├─ ✅ APPROVED → statusImage = APPROVED
    │              → Cliente VE la imagen
    └─ ❌ FLAGGED  → statusImage = FLAGGED
                   → Cliente NO ve
                   → Admin ve + razones
```

---

## 🚀 Instalación y Deployment

### Prerequisites

```bash
# Cuenta AWS con:
# • Permisos: Lambda, DynamoDB, S3, CloudFormation, IAM, Rekognition, Comprehend
# • Region: us-east-1
# • Bedrock Model Access (para S6)

# Herramientas:
# • AWS CLI v2
# • SAM CLI v1.100+
# • Node.js 22.x
# • Python 3.12
# • npm / pip
```

### Paso 1: Clonar y Configurar

```bash
git clone https://github.com/EdsonOnti/capstone.git
cd capstone

# Copiar config (primera vez solo)
cp samconfig.us-east-1.example samconfig.toml
```

### Paso 2: Deploy Backend

```bash
# Build + Deploy (primera vez: ~3 min, después: ~1 min)
bash scripts/deploy.sh

# O manual:
sam build -t template.sandbox.yaml
sam deploy -t template.sandbox.yaml \
  --stack-name edson-martin-ontiveros-lima \
  --region us-east-1 \
  --capabilities CAPABILITY_IAM CAPABILITY_AUTO_EXPAND \
  --resolve-s3 --no-confirm-changeset
```

### Paso 3: Deploy Frontend

```bash
cd frontend

# Build
npm run build

# Deploy a S3 + inyectar API URL
bash ../scripts/deploy-frontend.sh
```

### Paso 4: Semillar Datos

```bash
# 4 productos de ejemplo
bash scripts/bootstrap.sh
# O:
bash ai/seed/seed-products.sh
```

### Verificación

```bash
# Ver outputs del stack (URLs)
aws cloudformation describe-stacks \
  --stack-name edson-martin-ontiveros-lima \
  --region us-east-1 \
  --query "Stacks[0].Outputs[*].[OutputKey,OutputValue]" \
  --output table

# Frontend: https://d33x5tfyjkvcnh.cloudfront.net
# API: https://xxxx.lambda-url.us-east-1.on.aws
```

---

## 📖 Cómo Usar

### Modo Cliente

1. **Abre el frontend:** https://d33x5tfyjkvcnh.cloudfront.net
2. **Busca productos:**
   - Por nombre (búsqueda)
   - Por categoría (filtro)
3. **Abre un producto:**
   - Ve imagen (si S2 APPROVED)
   - Lee etiquetas (S1)
   - Escucha audio (S5)
   - Lee descripción (S6 o original)
4. **Lee reseñas y sentimiento:** (S3)
5. **Agrega tu reseña:**
   - Escribe comentario
   - Click "Enviar reseña"

### Modo Admin

1. **Click "Modo Admin"** (esquina superior derecha)
2. **Crear producto:**
   - Nombre, descripción, precio, stock, categoría
   - Upload imagen local o URL
3. **Editar producto:**
   - Modifica campos
   - Cambia imagen (dispara S2 again)
4. **Ver status de imagen:**
   - Badge "✅ Aprobada" = APPROVED
   - Badge "⚠️ Rechazada" = FLAGGED + razones
   - Badge "⏳ En revisión" = PENDING

---

## 📚 Documentación Detallada

| Documento | Contenido |
|-----------|----------|
| **[README.md](README.md)** | Este archivo — visión ejecutiva |
| **[FLUJO-IMAGEN-MODERATION-GATING.md](FLUJO-IMAGEN-MODERATION-GATING.md)** | S2: gating de imágenes, código completo, testing |
| **[S7-ROADMAP-RAG.md](S7-ROADMAP-RAG.md)** | RAG: embeddings, vector DB, búsqueda semántica + código Python |
| **[QUICKSTART-2026.md](QUICKSTART-2026.md)** | Onboarding en 10 minutos |
| **[GUIA-CLIENTE-ADMIN.md](GUIA-CLIENTE-ADMIN.md)** | Paso a paso: cómo usar frontend |
| **[FLUJO-IMAGEN-AUTOMATIZADO.md](FLUJO-IMAGEN-AUTOMATIZADO.md)** | Arquitectura técnica S0–S6 |
| **[S0-GUIA-EJECUTADA.md](S0-GUIA-EJECUTADA.md)** | S0 base serverless — código comentado |
| **[S1-GUIA-EJECUTADA.md](S1-GUIA-EJECUTADA.md)** | S1 Rekognition labels — deploy + testing |
| **[S2-GUIA-EJECUTADA.md](S2-GUIA-EJECUTADA.md)** | S2 Moderación + alt-text |
| **[S3-GUIA-EJECUTADA.md](S3-GUIA-EJECUTADA.md)** | S3 Sentimiento — Comprehend |
| **[CAPSTONE-STATUS.md](CAPSTONE-STATUS.md)** | Estado completo de sesiones |

---

## 🛠️ Stack Tecnológico

### Backend
```yaml
Compute:           Lambda (Node.js 22.x, Python 3.12)
Database:          DynamoDB (on-demand, GSI)
Storage:           S3 (imágenes, frontend)
CDN:               CloudFront (HTTPS, caché)
Infrastructure:    SAM + CloudFormation
Monitoring:        CloudWatch Logs

AI Services:
  • Rekognition (DetectLabels, DetectModerationLabels)
  • Comprehend (DetectSentiment, DetectDominantLanguage)
  • Translate (TranslateText)
  • Polly (SynthesizeSpeech)
  • Bedrock (Claude Haiku — converse API)
```

### Frontend
```yaml
Framework:         React 18 + Vite
Language:          TypeScript
Styling:           Tailwind CSS
State:             React Context API
HTTP:              Fetch API + presigned URLs
Icons:             Heroicons
Deployment:        S3 + CloudFront
```

### DevOps
```yaml
IaC:               SAM templates (YAML)
Package Manager:   npm (frontend), pip (backend)
Testing:           Shell scripts, manual curl
CI/CD:             bash scripts (deploy.sh, bootstrap.sh)
Version Control:   Git + GitHub
```

---

## 💡 Conceptos Clave (AIF-C01)

### Dominio 1: Fundamentals of AI/ML
- **S1:** Computer Vision — Rekognition DetectLabels
- **S2:** Responsible AI — Moderación, accesibilidad (WCAG 2.1)
- **S3:** NLP — Detección de idioma, análisis de sentimiento
- **S4:** NLP — Traducción automática neuronal
- **S5:** Speech — Síntesis de voz

### Dominio 2: Generative AI & Foundation Models
- **S6:** Claude Haiku — prompt engineering, tokens, temperatura
- **S7:** Embeddings & RAG (roadmap)
- **S8:** Multi-turn dialogue (roadmap)

### Dominio 3: Implementation
- **S0–S6:** Lambda, DynamoDB, IAM mínimo privilegio
- **Deploy:** SAM, CloudFormation, presigned URLs
- **Arquitectura:** Serverless, Function URLs

### Dominio 4: Responsible AI
- **S2:** Moderación de contenido, alt-text accesible
- **S6:** Mitigación de alucinaciones (prompt anclado a datos)

### Dominio 5: Security
- **IAM:** Cada Lambda solo accede lo necesario (roles específicos)
- **S3:** Presigned URLs (no credenciales en frontend)
- **Secrets:** .env gitignored, variables de entorno en Lambda

---

## 🎯 Roadmap (S7–S11)

### S7: RAG + Búsqueda Semántica (Próximo)
```python
# Embeddings
embedding = bedrock.invoke_model(
  modelId="amazon.titan-embed-text-v2:0",
  body={"inputText": "vestido elegante para boda", "dimensions": 384}
)

# Vector Search (DynamoDB GSI)
similar_products = query_by_similarity(embedding, top_k=5)

# Generation
response = bedrock.converse(
  modelId="claude-haiku",
  messages=[{"role": "user", "content": "Basándote en estos productos..."}]
)
```

### S8: Chatbot Multi-turno
- Historial de conversación
- Context window management
- Session storage en DynamoDB

### S9: Guardrails & Bias Detection
- AWS Bedrock Guardrails
- Detección de sesgos
- Safety filters

### S10: Governance & Cost
- CloudWatch budgets
- Cost allocation tags
- Audit trail (CloudTrail)

### S11: Cleanup & Analysis
- Borrar stack
- Análisis de costos acumulados
- Reporte final

---

## 💸 Estimación de Costos

| Servicio | Volumen (mes) | Costo |
|----------|---------------|-------|
| **Lambda** | 10k invokes | $0.20 |
| **DynamoDB** | 100k RCU + 100k WCU | $15–25 |
| **S3** (storage) | 500 MB | $0.01 |
| **CloudFront** | 10 GB | $0.85 |
| **Rekognition** | 500 images | $2.50 |
| **Comprehend** | 500k units | $1.00 |
| **Translate** | 50k characters | $0.50 |
| **Polly** | 10k chars | $0.50 |
| **Bedrock** | 100k tokens Claude | $0.50 |
| **TOTAL** | — | **~$21–31/mes** |

*Nota: Primeros 12 meses de free tier reducen significativamente.*

---

## 📋 Scripts Disponibles

```bash
# Core deployment
bash scripts/deploy.sh                    # Backend (sam build + deploy)
bash scripts/deploy-all.sh                # Backend + frontend
bash scripts/bootstrap.sh                 # Deploy + seed (idempotente)

# Testing
bash scripts/test-lambdas.sh              # Probar todas las Lambdas
bash scripts/test-image-upload.sh         # Test S0 + S2
bash scripts/test-lambdas-parallel.sh     # Tests en paralelo

# Utilities
bash scripts/status.sh                    # Ver estado del stack
bash scripts/logs.sh                      # Ver logs de Lambdas
bash scripts/validate-all.sh              # Validar templates SAM
bash scripts/delete-all.sh                # Limpiar stack
```

---

## 🔐 Seguridad

✅ **Implementado:**
- IAM mínimo privilegio (cada Lambda su rol)
- Presigned URLs (credenciales no en frontend)
- .env gitignored (secretos locales)
- HTTPS via CloudFront
- CORS permitido en Function URLs (*)

⚠️ **Para Producción:**
- Agregar autenticación (Cognito)
- JWT tokens
- Rate limiting
- WAF (Web Application Firewall)
- Encryption at rest (KMS)

---

## 🤝 Cómo Contribuir

```bash
# 1. Fork este repo
# 2. Crea una rama para tu feature
git checkout -b feature/mi-feature

# 3. Commit cambios
git add .
git commit -m "feat: descripción clara del cambio"

# 4. Push a tu fork
git push origin feature/mi-feature

# 5. Abre Pull Request a main branch
```

---

## 📞 Soporte y Debugging

### Problema: "Imagen no se ve en cliente"
→ Revisar: `statusImage` en DDB. Si FLAGGED, revisar `moderationFlags`.
→ Doc: [FLUJO-IMAGEN-MODERATION-GATING.md](FLUJO-IMAGEN-MODERATION-GATING.md)

### Problema: "Lambda timeout"
→ Aumentar timeout en SAM template (Timeout: 60)
→ Revisar CloudWatch Logs: `aws logs tail /aws/lambda/xxx --follow`

### Problema: "AccessDenied en Bedrock S6"
→ Ir a AWS console → Bedrock → Model access
→ Habilitar Claude Haiku 4.5 en us-east-1

### Problema: "Presupuesto agotado"
→ Ver: `scripts/status.sh`
→ Cleanup: `bash scripts/delete-all.sh`

---

## 📝 Licencia

MIT License — Usa libremente con atribución.

---

## 🎓 Aprendizajes Clave

Este capstone enseña:

1. **Arquitectura Serverless:** Sin servidores, escalabilidad automática, pago por invocación
2. **IA Administrada:** Rekognition, Comprehend, Polly, Translate, Bedrock — sin entrenar modelos
3. **IAM Seguridad:** Mínimo privilegio, roles específicos por función
4. **Full Stack:** Backend Python + Node.js, frontend React, DevOps SAM
5. **Integración:** Composición de servicios de AWS (Rekognition + Comprehend, Translate + Bedrock)
6. **Responsible AI:** Moderación, accesibilidad, mitigación de alucinaciones
7. **Deployment:** Infrastructure as Code, automation scripts, monitoring

---

## 📊 Métricas del Proyecto

| Métrica | Valor |
|---------|-------|
| Sesiones Completadas | 6/12 (50%) |
| Líneas de Código | ~10.000+ |
| Archivos | 38 nuevos |
| Lambdas | 13 funciones |
| Commits | 12 |
| Documentación | 14 archivos MD |
| Tiempo Estimado | ~12 horas de desarrollo |
| Costo AWS (dev/pruebas) | ~$0.01–0.05 |

---

## 🚀 Próximos Pasos

1. **Haz push a GitHub:**
   ```bash
   git push -u origin master
   ```

2. **Deploy en tu cuenta AWS:**
   ```bash
   bash scripts/bootstrap.sh
   ```

3. **Prueba todas las sesiones:**
   ```bash
   bash scripts/test-lambdas.sh
   ```

4. **Lee la documentación detallada:**
   - [S7-ROADMAP-RAG.md](S7-ROADMAP-RAG.md) para RAG
   - [FLUJO-IMAGEN-MODERATION-GATING.md](FLUJO-IMAGEN-MODERATION-GATING.md) para gating

5. **Implementa S7:**
   - Embeddings + Vector Search
   - Búsqueda semántica
   - Claude con contexto

---

## 👨‍💻 Autor

Desarrollado como **capstone educativo** para AWS AI Practitioner (AIF-C01) bootcamp.

**Última actualización:** Septiembre 2026  
**Versión:** 1.0 (S0–S6 Completadas)

---

## ⭐ Si Te Fue Útil

- ⭐ Dale una estrella al repo
- 🔗 Comparte con compañeros
- 💬 Abre issues con preguntas

**Happy Coding! 🎉**

