# 🛍️ TechModa — Capstone AWS AI (AIF-C01)

**Estado:** ✅ S0–S3 completadas | ✅ S4–S6 implementadas | 🚀 Ruta hacia **S7 RAG** en progreso

---

## 📊 Lo que se ha implementado

### ✅ S0 — Base Serverless
**Lambda router CRUD + DynamoDB + Function URLs**
- 4 productos base en BD
- Operaciones CRUD funcionales (GET, POST, PUT, DELETE)
- Autenticación: ninguna (desarrollo)
- Frontend en CloudFront + S3 estático

### ✅ S1 — Visión: Etiquetado Automático
**Rekognition `DetectLabels`**
- Analiza imágenes de productos automáticamente
- Genera etiquetas + confianzas
- Campos: `aiLabels`, `aiLabelsRaw`
- **UX:** Búsqueda y clasificación mejoradas

### ✅ S2 — Moderación + Accesibilidad
**Rekognition `DetectModerationLabels` + generación de alt-text**
- Detecta contenido inapropiado
- Genera descripciones accesibles (WCAG 2.1)
- Campos: `moderationStatus`, `moderationFlags`, `altText`
- **Control de calidad:** Seguridad de contenido + inclusión

### ✅ S3 — NLP: Análisis de Sentimiento
**Comprehend `DetectSentiment` + `DetectDominantLanguage`**
- Analiza reseñas de clientes automáticamente
- Clasifica: POSITIVE / NEGATIVE / NEUTRAL / MIXED
- Campos: `reviewSentiment`, `reviewSentimentCounts`
- **Business intelligence:** Métricas de satisfacción en tiempo real

### ✅ S4 — Traducción: Catálogo Multiidioma
**Amazon Translate**
- Traduce automáticamente `name` + `description` ES↔EN
- Traducciones guardadas en `translations.es`, `translations.en`
- **Globalización:** Alcance a clientes en dos idiomas
- Detección automática de idioma vía Comprehend

### ✅ S5 — Síntesis de Voz: Audio Accesible
**Amazon Polly**
- Genera audio de descripciones de producto (accesibilidad)
- Soporta múltiples voces y lenguajes
- Campos: `audioUrl`, `audioTranscript`
- **Inclusión:** Usuarios con discapacidad visual

### ✅ S6 — Generación de Texto: Descripciones de Producto
**Amazon Bedrock + Claude**
- Genera descripciones de marketing con IA generativa
- Parámetros: tono (elegante, divertido, minimalista), etiquetas visuales
- Tokens controlados, temperatura configurable
- **Marketing:** Descripciones consistentes a escala
- **Mitigación:** Ancla a datos reales, prompts anti-alucinación

---

## 🎯 Flujo Actual: De la Imagen Bruta a la Exhibición

```
┌────────────────────────────────────────────────────────────┐
│          SUBIDA DE IMAGEN (Admin)                          │
│          S3 presigned URL + upload directo                │
└──────────────┬───────────────────────────────────────────┘
               │
        ┌──────┴──────────────────────┐
        │ statusImage = PENDING        │
        │ (NO visible aún)             │
        └──────┬──────────────────────┘
               │
        ┌──────▼─────────────────────────────────────────┐
        │ S1 — Rekognition Labels                       │
        │ └─ Extrae aiLabels (etiquetas visuales)       │
        └──────┬─────────────────────────────────────────┘
               │
        ┌──────▼─────────────────────────────────────────┐
        │ S2 — Moderación + Alt-text                    │
        │ ├─ Detecta contenido inapropiado              │
        │ ├─ Status = APPROVED / FLAGGED                │
        │ └─ Genera altText para accesibilidad (WCAG)   │
        └──────┬─────────────────────────────────────────┘
               │
        ┌──────▼─────────────────────────────────────────┐
        │ ✅ APROBADA POR MODERACIÓN                    │
        │ statusImage = APPROVED                         │
        │ (Ahora SÍ visible en frontend cliente)         │
        └──────┬─────────────────────────────────────────┘
               │
        ┌──────▼─────────────────────────────────────────┐
        │ S4 — Traducción (Paralelo)                    │
        │ └─ Traduce name + description ES↔EN           │
        └──────┬─────────────────────────────────────────┘
        ┌──────▼─────────────────────────────────────────┐
        │ S5 — Síntesis de Voz (Paralelo)              │
        │ └─ Genera audio con Polly para accesibilidad  │
        └──────┬─────────────────────────────────────────┘
        ┌──────▼─────────────────────────────────────────┐
        │ S6 — Generación de Descripción (Paralelo)    │
        │ └─ Claude reescribe con tono + etiquetas     │
        └──────────────────────────────────────────────┘
               │
        ┌──────▼─────────────────────────────────────────┐
        │    FRONTEND CLIENTE (React/Vite)             │
        │  ├─ Imagen visible (status APPROVED)          │
        │  ├─ Etiquetas S1                              │
        │  ├─ Alt-text accesible (S2)                   │
        │  ├─ Audio disponible (S5)                     │
        │  ├─ Descripción S6 o original                 │
        │  ├─ Traducciones S4 (ES/EN)                  │
        │  └─ Reseñas + Sentimiento (S3)               │
        └──────────────────────────────────────────────┘
```

**Clave del flujo:** 
- **S2 es el gatekeeper:** Imagen no se muestra hasta APPROVED
- **S4, S5, S6 enriquecen** en paralelo (no bloquean la visualización)
- **Todo en DynamoDB:** Un solo `GET /products/:id` trae todo

---

## 🛣️ Ruta a S7 (RAG + Búsqueda Semántica)

### Por qué S7 es el siguiente paso

Hasta S6, **los usuarios navegan**. Con S7, **los usuarios preguntan**.

**S7 — RAG: Búsqueda Semántica + Chatbot**

```
"¿Qué tienes para trabajar desde casa?"
         ↓
  Embed pregunta → [0.12, -0.45, 0.78, ...]
         ↓
  Busca vectores similares en DynamoDB
         ↓
  Recupera: Laptop, Monitor, Silla ajustable
         ↓
  Prompt a Claude: "Basándote en estos productos,
                   recomienda un setup para oficina
                   en casa con presupuesto bajo"
         ↓
  "Te recomiendo: la Laptop (portátil), el Monitor
   (calibrado para leer largo rato) y la Silla
   (soporte lumbar)..."
```

**Arquitectura S7:**
```
┌─────────────┐
│  Frontend   │
│  Chat box   │
└──────┬──────┘
       │ "¿Qué tienes para home office?"
       ▼
┌──────────────────────────────────────────┐
│ Lambda S7 — RAG Retrieval                │
│ (Nueva)                                   │
└──────┬───────────────────────────────────┘
       │
       ├─ 1. Bedrock Embeddings API
       │     Convierte pregunta a vector
       │
       ├─ 2. DynamoDB Vector Search
       │     Busca Top-K productos similares
       │
       └─ 3. Bedrock Claude (Converse API)
           Prompt: "Productos recuperados + pregunta"
           Respuesta: recomendación personalizada
```

**Por qué S7 es importante:**
- ✅ **Cierra el loop IA:** Datos (S0) → Etiquetas (S1) → Moderación (S2) → Sentimiento (S3) → **Búsqueda semántica + recomendación (S7)**
- ✅ **Requiere todos los bloques:** Bedrock, embeddings, búsqueda vectorial, retrieval
- ✅ **Escala a S8:** El chatbot multi-turno está aquí

---

## 📈 Mejoras Realizadas (S0–S6)

| Mejora | Sesión | Impacto |
|--------|--------|--------|
| Infraestructura serverless | S0 | Escalabilidad automática, sin DevOps |
| **Gating de imagen** | S2 | Solo imágenes aprobadas llegan a clientes |
| Moderación + alt-text | S2 | Cumplimiento legal (WCAG) + accesibilidad |
| Análisis de sentimiento | S3 | Insights de clientes en tiempo real |
| Etiquetado automático | S1 | Búsqueda mejorada (keywords AI) |
| Traducción automática | S4 | Alcance global (ES/EN) sin traductores |
| Síntesis de voz | S5 | Inclusión: usuarios con discapacidad visual |
| Generación de descripciones | S6 | Marketing a escala, tono consistente |
| CloudFront + S3 | S0-S6 | CDN global, imágenes + frontend rápidos |
| IAM mínimo privilegio | S0-S6 | Seguridad: cada Lambda solo accede lo necesario |

---

## 🚀 Mejoras Futuras (S7+)

### Corto Plazo (S7–S8)
- **RAG completo:** Búsqueda semántica sobre todo el catálogo
- **Chatbot multiidioma:** Claude + Comprehend Translate
- **Caché de embeddings:** No recalcular para búsquedas frecuentes
- **Historial de conversaciones:** Cognito + sesiones

### Mediano Plazo (S9–S10)
- **Gobernanza de datos:** Tags, provenance tracking, auditoría
- **Cost optimization:** Presupuestos + alertas con CloudWatch
- **Analytics dashboard:** Búsquedas populares, productos más recomendados
- **Autenticación:** Cognito + JWT tokens

### Largo Plazo (Producción)
- **Fine-tuning:** Embeddings customizados por dominio
- **A/B Testing:** Distintos prompts de Claude por cohorte
- **Observabilidad:** X-Ray tracing, métricas personalizadas
- **Load testing:** Patrón de compra vs. throughput
- **Feedback loop:** Usuarios califican recomendaciones S7

---

## 🎓 Stack Actual

```yaml
Lenguajes:       Node.js 22.x (S0), Python 3.12 (S1–S6)
Almacén:         DynamoDB (productos, reseñas, vectores S7)
Imágenes:        S3 + CloudFront (CDN)
Compute:         Lambda (serverless, 13 funciones)
Visión:          Rekognition (etiquetas, moderación)
NLP:             Comprehend (sentimiento, idioma)
Traducción:      Amazon Translate
Síntesis:        Amazon Polly
IA Generativa:   Bedrock (Claude Haiku)
Embeddings:      Bedrock Titan (S7)
IaC:             SAM + CloudFormation
Frontend:        React + Vite + TypeScript
Observabilidad:  CloudWatch Logs, CloudFormation Outputs
```

---

## ✅ Checklist: ¿Estoy listo para S7?

- [x] S0 base funcionando (CRUD + DynamoDB)
- [x] S1 Rekognition Labels activo
- [x] S2 Moderación + alt-text (gating de imagen)
- [x] S3 Análisis de sentimiento activo
- [x] S4 Traducción ES↔EN
- [x] S5 Síntesis de voz (Polly)
- [x] S6 Generación de descripciones (Claude)
- [ ] S7 RAG + búsqueda semántica ← **PRÓXIMO HITO**
- [ ] S8 Chatbot multi-turno (S7 + session management)

---

## 📚 Documentación

| Tema | Archivo | Cuándo leer |
|------|---------|-----------|
| **Arquitectura completa** | [FLUJO-IMAGEN-AUTOMATIZADO.md](FLUJO-IMAGEN-AUTOMATIZADO.md) | Entender todo en profundidad |
| **Guías paso a paso** | `sessions/S0{0..6}/GUIA.md` | Reproducir sesiones |
| **Cliente vs Admin** | [GUIA-CLIENTE-ADMIN.md](GUIA-CLIENTE-ADMIN.md) | Usar el frontend |
| **Estado y checklist** | [CAPSTONE-STATUS.md](CAPSTONE-STATUS.md) | Referencia rápida |
| **Índice de docs** | [INDICE-DOCUMENTACION.md](INDICE-DOCUMENTACION.md) | Encontrar qué buscas |

---

## 🚀 Comandos Rápidos

```bash
# Estado del stack
bash scripts/status.sh

# Ver outputs (URLs)
aws cloudformation describe-stacks \
  --stack-name edson-martin-ontiveros-lima --region us-east-1 \
  --query "Stacks[0].Outputs[*].[OutputKey,OutputValue]" --output table

# Ver productos en BD
aws dynamodb scan --table-name edson-martin-ontiveros-lima-Products \
  --region us-east-1 --output table

# Logs en tiempo real
aws logs tail /aws/lambda/edson-martin-ontiveros-lima-Router --follow

# Deploy (backend + frontend)
bash scripts/deploy-all.sh

# Bootstrap completo
bash scripts/bootstrap.sh
```

---

## 💡 Conceptos Clave (AIF-C01)

| Concepto | Sesión | Aplicación |
|----------|--------|-----------|
| **Serverless** | S0 | Escalabilidad sin servidores |
| **Computer Vision** | S1–S2 | Etiquetado + moderación |
| **NLP** | S3 | Análisis de texto / sentimiento |
| **Responsible AI** | S2 | Moderación + accesibilidad (WCAG) |
| **IAM least privilege** | S0–S6 | Seguridad: cada función solo accede lo necesario |
| **Traducción automática** | S4 | Multiidioma sin traductores |
| **Síntesis de voz** | S5 | Accesibilidad |
| **Foundation Models** | S6 | Generación de texto con Claude |
| **Generative AI** | S6 | Prompting, tokens, temperatura, alucinaciones |
| **Embeddings / Vector Search** | S7 | Búsqueda semántica (no solo keywords) |
| **RAG** | S7 | Generación aumentada con retrieval |
| **Multi-turn dialogue** | S8 | Chatbot con contexto |

---

## 📞 ¿Cómo Usar Este README?

1. **Primera vez:** Lee "Lo que se ha implementado" + "Flujo Actual"
2. **Entender S7:** Lee "Ruta a S7" + "Checklist"
3. **Usar el app:** Ve a [GUIA-CLIENTE-ADMIN.md](GUIA-CLIENTE-ADMIN.md)
4. **Referencia técnica:** Usa "Comandos Rápidos" y "Stack Actual"
5. **Profundizar:** Ve a sesiones específicas en `sessions/`

---

## 🔗 URLs en Vivo (Después del Deploy)

- **Frontend Cliente:** https://d33x5tfyjkvcnh.cloudfront.net
- **API Router:** https://3v374r65fprni2nt74tue4bjp40wdmbp.lambda-url.us-east-1.on.aws/
- **Imágenes CDN:** https://d2jgv7mcaqixc1.cloudfront.net/products/

---

**Última actualización:** 2026-09-23  
**Sesiones completadas:** 6/12 (S0, S1, S2, S3, S4, S5, S6)  
**Próximo hito:** S7 RAG + Búsqueda Semántica  
**Objetivo final:** S8 Chatbot multi-turno

