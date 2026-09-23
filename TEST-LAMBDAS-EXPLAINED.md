# 🧪 Dos Formas de Testear: Secuencial vs Paralelo

## ¿Cuál es la diferencia?

### `test-lambdas.sh` — SECUENCIAL

```
Tiempo 0s:   S1 envía ─────────────────────► Respuesta (2-3s)
Tiempo 3s:   S2 envía ─────────────────────► Respuesta (2-3s)
Tiempo 6s:   S3 envía ─────────────────────► Respuesta (1-2s)
Tiempo 8s:   S5 envía ─────────────────────► Respuesta (3-5s)

TIEMPO TOTAL: ~8-13 segundos
```

**Uso:**
```bash
bash scripts/test-lambdas.sh [productId]
```

**Ventajas:**
- ✅ Fácil de leer (paso a paso)
- ✅ Ves cada respuesta claramente
- ✅ Útil para debugging

---

### `test-lambdas-parallel.sh` — PARALELO ⭐

```
Tiempo 0s:   S1 ──┐
             S2 ──┤
             S3 ──├──► Todas ejecutan simultáneamente
             S5 ──┘

TIEMPO TOTAL: ~3-5 segundos (máximo de cualquiera)
```

**Uso:**
```bash
bash scripts/test-lambdas-parallel.sh [productId]
```

**Ventajas:**
- ✅ **MUCHO MÁS RÁPIDO** (2-3 veces más rápido)
- ✅ Simula mundo real (usuario hace múltiples requests)
- ✅ Verifica que no hay conflictos entre Lambdas

---

## 📊 Comparación

| Aspecto | Secuencial | Paralelo |
|---------|-----------|----------|
| **Tiempo** | 8-13 seg | 3-5 seg |
| **Legibilidad** | ✅ Muy clara | 🔶 Menos clara |
| **Realista** | ❌ No | ✅ Sí |
| **Debugging** | ✅ Fácil | 🔶 Más difícil |
| **Carga real** | ❌ No | ✅ Sí |

---

## 🎯 ¿Cuál usar?

### Usa **SECUENCIAL** si:
- Quieres ver qué hace cada Lambda paso a paso
- Estás debuggeando un problema
- Es tu primera vez

```bash
bash scripts/test-lambdas.sh
```

### Usa **PARALELO** si:
- Quieres probar que todas funcionan simultáneamente
- Quieres simular múltiples usuarios
- Quieres hacerlo rápido

```bash
bash scripts/test-lambdas-parallel.sh
```

---

## ✅ AMBAS AGREGARÁN AUTOMÁTICAMENTE A DYNAMODB

**Cuando ejecutas cualquiera:**

```bash
curl -X POST "$S1" -d '{"productId":"ABC-123", "imageUrl":"..."}'
```

La Lambda **automáticamente**:
1. Procesa la solicitud
2. Llama al servicio de AWS (Rekognition, Comprehend, Polly)
3. **Guarda los resultados en DynamoDB** para ese productId
4. Retorna la respuesta

**NO tienes que hacer nada más.** DynamoDB se actualiza automáticamente.

---

## 🔄 Flujo: Paralelo + DynamoDB

```
Tu shell:
  $ bash scripts/test-lambdas-parallel.sh 3277d67c-cf55...
  
  → S1 enviado...
  → S2 enviado...
  → S3 enviado...
  → S5 enviado...
  ✓ S1 completado
  ✓ S2 completado
  ✓ S3 completado
  ✓ S5 completado

AWS (en paralelo):
  S1 Lambda → Rekognition → DynamoDB: guardar aiLabels
  S2 Lambda → Rekognition → DynamoDB: guardar moderationStatus
  S3 Lambda → Comprehend → DynamoDB: guardar reviewSentiment
  S5 Lambda → Polly → S3 → DynamoDB: guardar audioUrl

Resultado en DynamoDB (para ese productId):
  {
    "productId": "3277d67c-cf55...",
    "name": "Vestido midi floral",
    "aiLabels": [...],           ← Agregado por S1 automáticamente
    "moderationStatus": "...",   ← Agregado por S2 automáticamente
    "reviewSentiment": "...",    ← Agregado por S3 automáticamente
    "audioUrl": "...",           ← Agregado por S5 automáticamente
  }
```

---

## 📝 Ejemplos de Uso

### Ejemplo 1: Testear con el primer producto (secuencial)

```bash
bash scripts/test-lambdas.sh

# Output:
# 1️⃣  ESTADO INICIAL
#     {
#       "name": "Vestido midi floral",
#       "aiLabels": null,
#       "moderationStatus": null,
#       ...
#     }
# 
# 2️⃣  EJECUTANDO S1
#     (respuesta de Rekognition)
# 
# 3️⃣  VERIFICANDO ACTUALIZACIÓN
#     {
#       "name": "Vestido midi floral",
#       "aiLabels": [...],  ← ¡Ahora tiene datos!
#       ...
#     }
# ... (S2, S3, S5)
# 9️⃣  ESTADO FINAL
#     Todos los campos llenos
```

### Ejemplo 2: Testear con un productId específico (paralelo)

```bash
bash scripts/test-lambdas-parallel.sh 3277d67c-cf55-4206-bdbf-501dd6727b3c

# Output:
# ⏱️  Tiempo inicial: 18:14:32
# → S1 enviado...
# → S2 enviado...
# → S3 enviado...
# → S5 enviado...
# ✓ S1 completado
# ✓ S2 completado
# ✓ S3 completado
# ✓ S5 completado
# ⏱️  Tiempo final: 18:14:36  ← Solo 4 segundos (paralelo)
#
# S1 (EnrichLabels):
# {"productId":"3277d67c...", "aiLabels":[...]}
#
# S2 (ModerateImage):
# {"productId":"3277d67c...", "moderationStatus":"APPROVED", ...}
#
# S3 (AnalyzeSentiment):
# {"productId":"3277d67c...", "reviewSentiment":"POSITIVE", ...}
#
# S5 (SynthesizeVoice):
# {"productId":"3277d67c...", "audioUrl":"https://..."}
#
# 3️⃣  ESTADO FINAL
# {
#   "name": "Vestido midi floral",
#   "aiLabels": 12,              ← 12 etiquetas
#   "moderationStatus": "APPROVED",
#   "reviewSentiment": "POSITIVE",
#   "audioUrl": "✅ Sí"          ← URL de audio generada
# }
```

---

## 🚀 Flujo Completo: Desde Cero hasta Verificar Todo

```bash
# 1. Limpiar y seedear (si necesitas empezar de nuevo)
bash scripts/check-and-seed.sh

# 2. Ver los 4 productos sin procesar
API=$(aws cloudformation describe-stacks --stack-name edson-martin-ontiveros-lima --query 'Stacks[0].Outputs[?OutputKey==`ApiUrl`].OutputValue' --output text)
curl -s "${API%/}/products" | python3 -m json.tool

# 3. Testear con el primer producto (secuencial, para entender)
bash scripts/test-lambdas.sh

# 4. Testear de nuevo con paralelo (para verificar que todo funciona simultáneamente)
bash scripts/test-lambdas-parallel.sh

# 5. Verificar que DynamoDB está actualizado
curl -s "${API%/}/products" | python3 -m json.tool | head -80
```

---

## 🎯 Respuestas a tu pregunta

**¿Al agregar un productId haría curl de todas las lambdas al mismo tiempo?**

- ✅ Con `test-lambdas-parallel.sh`: **SÍ, todas al mismo tiempo**
- ❌ Con `test-lambdas.sh`: No, una por una

**¿Agregaría las nuevas etiquetas a DynamoDB automáticamente?**

- ✅ **SÍ, ambas lo hacen automáticamente**
- Cada curl POST hace que la Lambda procese y guarde en DynamoDB

**¿Puedo pasar un productId específico?**

- ✅ **SÍ**:
  ```bash
  bash scripts/test-lambdas.sh 3277d67c-cf55-4206-bdbf-501dd6727b3c
  bash scripts/test-lambdas-parallel.sh 3277d67c-cf55-4206-bdbf-501dd6727b3c
  ```

