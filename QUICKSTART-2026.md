# ⚡ Quickstart: TechModa en 10 minutos

## 🎯 Para Principiantes

### Si acabas de clonar el repo:

```bash
# 1. Lee esto primero (ahora, 5 min)
cat README.md

# 2. Si quieres ver cómo se ve (10 min)
# Abre en el navegador:
# https://d33x5tfyjkvcnh.cloudfront.net

# 3. Si quieres entender cómo funciona:
# Lee FLUJO-IMAGEN-MODERATION-GATING.md (20 min)

# 4. Si vas a implementar S7:
# Lee S7-ROADMAP-RAG.md (30 min)
```

---

## 🚀 Para Desarrolladores

### Estado actual
- ✅ 6/12 sesiones completadas (S0–S6)
- ✅ Frontend cliente + admin funcionales
- ✅ Imágenes con gating (moderación)
- 🚀 S7 RAG en roadmap

### Stack
```
Node.js 22.x (S0) + Python 3.12 (S1–S6)
Lambda + DynamoDB + S3 + CloudFront
Rekognition + Comprehend + Translate + Polly + Bedrock
```

### Deploy (si tienes créditos AWS)
```bash
cd capstone
bash scripts/bootstrap.sh          # ~2 min
# Frontend estará en CloudFront (ver outputs)
```

### Ver logs
```bash
aws logs tail /aws/lambda/edson-martin-ontiveros-lima-Router --follow
```

---

## 📚 Documentación por Caso de Uso

| Necesito... | Leo... | Tiempo |
|---|---|---|
| Entender qué se hizo | README.md | 5 min |
| Usar el app (cliente/admin) | GUIA-CLIENTE-ADMIN.md | 10 min |
| Entender moderación de imágenes | FLUJO-IMAGEN-MODERATION-GATING.md | 20 min |
| Arquitectura técnica completa | FLUJO-IMAGEN-AUTOMATIZADO.md | 30 min |
| Preparar S7 (RAG) | S7-ROADMAP-RAG.md | 30 min |
| Ver todo desde 10.000 ft | CAPSTONE-STATUS.md | 15 min |

---

## 🔑 Conceptos Clave (AIF-C01)

### S0: Serverless Fundamentals
- Lambda + Function URLs (sin API Gateway)
- DynamoDB on-demand
- CloudFront + S3 static

### S1–S2: Computer Vision
- Rekognition DetectLabels (etiquetas)
- Rekognition DetectModerationLabels (seguridad)
- Alt-text para accesibilidad (WCAG 2.1)

### S3: NLP
- Comprehend DetectSentiment
- Análisis de reseñas en tiempo real

### S4–S6: IA Generativa
- Translate: multiidioma
- Polly: síntesis de voz
- Bedrock + Claude: generación de descripciones

### S7: RAG & Embeddings
- Embeddings = vectores de significado
- Búsqueda semántica (no solo keywords)
- Claude + contexto = recomendaciones

---

## ✅ Checklist Rápido

- [ ] Leí README.md
- [ ] Entendí qué es statusImage (PENDING/APPROVED/FLAGGED)
- [ ] Sé por qué S4, S5, S6 corren en paralelo
- [ ] Entiendo embeddings (vectores de significado)
- [ ] Sé qué es RAG (Retrieval Augmented Generation)
- [ ] Estoy listo para S7

---

## 💬 Preguntas Rápidas

**P: ¿Cómo subo una imagen?**  
A: Modo Admin → "Agregar Nuevo Producto" → "Sube una imagen local"

**P: ¿Por qué no veo mi imagen?**  
A: statusImage = FLAGGED (Rekognition S2 la rechazó)  
Revisá: FLUJO-IMAGEN-MODERATION-GATING.md

**P: ¿Cómo hago S7?**  
A: Código completo en S7-ROADMAP-RAG.md (Fase 1 y Fase 2)

**P: ¿Cuánto cuesta S7?**  
A: ~$4-7/mes (Embeddings + Claude Haiku)

---

## 🎓 Para Examen AIF-C01

Cada sesión cubre dominios específicos:

```
S0       → D3 (Implementation)
S1–S3    → D1 (Fundamentals)
S2, S9   → D4 (Responsible AI)
S6–S9    → D2 (Generative AI)
S0–S6    → D5 (Security)
S7       → D1 + D2 (Embeddings + RAG)
```

Estudia por sesión en el README.md tabla "Conceptos Clave".

---

**Última actualización:** 2026-09-23  
**Sesiones:** 6/12 (S0–S6)  
**Próximo:** S7 RAG

