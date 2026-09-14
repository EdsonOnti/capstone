# ÍNDICE: GUÍAS DE EJECUCIÓN S0 Y S1

**Stack:** `edson-martin-ontiveros-lima`  
**Región:** `us-east-1`  
**Estado:** ✅ S0 y S1 completadas  
**Fecha:** 2026-09-14  

---

## 📚 GUÍAS DISPONIBLES

### 1. [S0-GUIA-EJECUTADA.md](S0-GUIA-EJECUTADA.md)

**Para:** Personas que **nunca han tocado AWS**

**Contenido:**
- ¿Qué es S0? (tienda serverless sin IA)
- Requisitos previos verificados ✅
- Paso a paso: configuración, build, deploy, validación
- Arquitectura en palabras simples (Serverless, Lambda, DynamoDB, Function URL)
- IAM en S0 (mínimo privilegio explicado)
- Conceptos para el examen (servicios administrados, pago por uso)
- Checklist de validación
- Errores comunes y soluciones
- Cleanup (cuándo, cómo)

**Duración de lectura:** ~15 minutos  
**Necesario leer antes de:** S1  

---

### 2. [S1-GUIA-EJECUTADA.md](S1-GUIA-EJECUTADA.md)

**Para:** Personas que completaron S0 y quieren entender Rekognition

**Contenido:**
- ¿Qué es S1? (auto-etiquetado de imágenes)
- Caso de uso real (filtros, búsqueda, control de calidad)
- Concepto pedagógico (D1 del examen: inferencia, confianza, administrado)
- Validación: confirmar que S1 ya existe (Lambda + Function URL)
- Paso 1: Preparar una imagen (URL pública vs. S3)
- Paso 2: Llamar Rekognition (curl con explicación)
- Paso 3: Verificar guardado en DynamoDB
- Arquitectura de S1 (diagrama + componentes)
- Permisos IAM detallados
- Flujo completo de código (paso a paso)
- Conceptos para el examen (entrenamiento vs. inferencia, confianza, administrado)
- Checklist de validación
- Errores comunes y soluciones
- Vista previa de S2–S8

**Duración de lectura:** ~20 minutos  
**Necesario leer después de:** S0  

---

### 3. [RESUMEN-S0-S1-COMPLETADA.md](RESUMEN-S0-S1-COMPLETADA.md)

**Para:** Quién quiere ver el **panorama completo rápido**

**Contenido:**
- Qué se desplegó en S0 (DynamoDB, Lambda, Function URL, 4 productos)
- Cómo se logró (comandos exactos)
- Qué se desplegó en S1 (Rekognition Lambda)
- Flujo de S1 (cliente → Lambda → Rekognition → DynamoDB)
- Estado actual (tabla)
- Conceptos aprendidos en S0 y S1
- Cambios en el código (PermissionsBoundary)
- Costo estimado
- Referencias a documentación completa
- Conexión con AIF-C01 (dominios D1 y D5)
- Próximos pasos

**Duración de lectura:** ~5 minutos  
**Útil como:** resumen ejecutivo, check-in rápido  

---

## 🎯 FLUJO RECOMENDADO DE LECTURA

### Para principiantes en AWS:

1. **[S0-GUIA-EJECUTADA.md](S0-GUIA-EJECUTADA.md)** (15 min)
   - Entender qué es serverless, DynamoDB, Lambda, Function URL
   - Ver cómo se hace deploy
   - Validar que S0 está funcionando

2. **[S1-GUIA-EJECUTADA.md](S1-GUIA-EJECUTADA.md)** (20 min)
   - Entender Rekognition (inferencia con modelo preentrenado)
   - Ver cómo funciona mínimo privilegio en Rekognition
   - Probar S1 llamando la Lambda

3. **[RESUMEN-S0-S1-COMPLETADA.md](RESUMEN-S0-S1-COMPLETADA.md)** (5 min)
   - Repaso rápido y conexión con el examen

### Para el que quiere solo validar estado:

- **[RESUMEN-S0-S1-COMPLETADA.md](RESUMEN-S0-S1-COMPLETADA.md)** (5 min)
- **[CLAUDE.md](CLAUDE.md)** (si necesita arquitectura general)

### Para el que quiere entender cada línea:

- **[S0-GUIA-EJECUTADA.md](S0-GUIA-EJECUTADA.md)** (15 min)
- **[S1-GUIA-EJECUTADA.md](S1-GUIA-EJECUTADA.md)** (20 min)
- **[CLAUDE.md](CLAUDE.md)** (arquitectura y comandos)
- **[docs/IAM.md](docs/IAM.md)** (permisos en detalle)

---

## ✅ ESTADO DE CADA GUÍA

| Guía | Estado | Completitud | Ejemplos |
|------|--------|------------|----------|
| S0-GUIA-EJECUTADA.md | ✅ Completa | 100% | Sí (6 ejemplos reales) |
| S1-GUIA-EJECUTADA.md | ✅ Completa | 100% | Sí (5+ ejemplos) |
| RESUMEN-S0-S1-COMPLETADA.md | ✅ Completa | 100% | Sí (comandos exactos) |

---

## 🔗 REFERENCIAS CRUZADAS

### En S0-GUIA-EJECUTADA.md:
- Explica conceptos básicos (serverless, Lambda, DynamoDB)
- Enlaza a S1 para continuar

### En S1-GUIA-EJECUTADA.md:
- Asume S0 completada
- Enlaza a RESUMEN para panorama general
- Enlaza a CLAUDE.md para arquitectura

### En RESUMEN-S0-S1-COMPLETADA.md:
- Consolida aprendizajes de S0 y S1
- Enlaza a las guías completas para profundizar
- Enlaza a docs/IAM.md para permisos

---

## 📊 DATOS DE REFERENCIA

### URLs Importantes

| Recurso | URL |
|---------|-----|
| API Base (S0 Router) | `https://3v374r65fprni2nt74tue4bjp40wdmbp.lambda-url.us-east-1.on.aws/` |
| S1 (Rekognition) | `https://s4agnwvtu4afqbwhrfd25mnmp40kqgxs.lambda-url.us-east-1.on.aws/` |
| DynamoDB Table | `edson-martin-ontiveros-lima-Products` |

### Productores de Prueba (IDs UUID)

| Producto | ID | ImageUrl |
|----------|----|-----------
| Tenis blancos | `6b4c4683-9f43-4c89-919f-516ba8362f5f` | `https://httpbin.org/image/jpeg` |
| Vestido midi floral | `81c03ffd-023f-448b-95c8-a38b42349095` | placeholder |
| Chaqueta | `1b12cd04-72e3-452a-95c2-20dbbb6f0dfc` | placeholder |
| Bolso tote | `ea6d625f-5e55-4910-bcae-bd3c7d5e82f0` | placeholder |

### Comando para obtener IDs:

```bash
aws dynamodb scan --table-name edson-martin-ontiveros-lima-Products \
  --query "Items[].productId.S" --output text --region us-east-1
```

---

## 🎓 CÓMO USAR ESTAS GUÍAS PARA ESTUDIAR

### Lectura pasiva (solo leer):
1. Abrí cada guía y leé linealmente
2. Entiende conceptos sin ejecutar

### Lectura activa (ejecutar mientras lees):
1. Abrí la guía en una pestaña
2. Terminal en otra
3. Ejecutá cada comando de la guía
4. Comparar tu salida con la esperada

### Estudio para examen:
1. Lee [RESUMEN-S0-S1-COMPLETADA.md](RESUMEN-S0-S1-COMPLETADA.md) (5 min) para panorama
2. Lee sección "Conceptos para el examen" de cada guía
3. Enlaza a [CLAUDE.md](CLAUDE.md) para contexto arquitectónico
4. Resuelve: "¿cuál servicio usarías para...?" con el patrón S0+S1

---

## 🚀 PRÓXIMAS SESIONES

Las guías de S2–S11 seguirán el mismo formato:
- **S2:** Moderación + alt-text (Rekognition)
- **S3:** Sentimiento (Comprehend)
- **S4:** Traducción (Translate)
- **S5:** Síntesis de voz (Polly)
- **S6–S8:** Bedrock (generativo)
- **S9–S10:** Gobernanza
- **S11:** Cleanup

Cada una tendrá su `SN-GUIA-EJECUTADA.md` detallada.

---

## 📝 NOTAS IMPORTANTES

### Sobre el stack `edson-martin-ontiveros-lima`:

- Está **en us-east-1** (obligatorio para el capstone)
- Está **deployado y funcional** ahora (CREATE_COMPLETE)
- Incluye S1, S2, S3, S5 por usar `template.sandbox.yaml`
- **NO borres** hasta terminar S2–S11
- Limpieza: `bash scripts/delete-all.sh` (pide confirmación)

### Sobre las guías:

- Están escritas en **español** para el bootcamp
- Incluyen **ejemplos ejecutados** (no son teóricos)
- Están enfocadas en **principiantes en AWS** (sin jerga sin explicar)
- Cada una es **autocontenida** (no necesitás releer otras)

### Sobre los cambios en templates:

- Se comentó `PermissionsBoundary` (era bloqueante)
- Cambio mínimo, reversible
- Documentado en commit git

---

## 🤔 PREGUNTAS FRECUENTES

### ¿Necesito leer todas las guías?

No necesariamente. Depende de tu rol:
- **Estudiante de bootcamp:** todas (en orden)
- **Instructor:** RESUMEN + CLAUDE.md
- **Desarrollador que quiere aprender:** S0 → S1 → elegir camino

### ¿Puedo ejecutar S1 sin S0?

No. S1 asume:
- DynamoDB table existente
- Productos en DynamoDB
- Router CRUD funcionando (para actualizar imageUrl)

### ¿Dónde veo los logs?

CloudWatch Logs:
- S0: `/aws/lambda/edson-martin-ontiveros-lima-Router`
- S1: `/aws/lambda/edson-martin-ontiveros-lima-EnrichLabels`

Comando: `aws logs tail /aws/lambda/... --region us-east-1`

### ¿Puedo cambiar el stack name?

Sí, pero:
- Los comandos heredan `--stack-name edson-martin-ontiveros-lima`
- Si cambias, actualiza TODOS los comandos
- Más fácil: mantené el mismo nombre

---

## 📞 SOPORTE

Si encontrás un problema:

1. Checklist de validación de la guía (sección ✅)
2. Sección de "Errores comunes"
3. [CLAUDE.md](CLAUDE.md) sección "Troubleshooting"
4. [docs/SANDBOX-COMPAT.md](docs/SANDBOX-COMPAT.md) si es específico del sandbox

---

**Última actualización:** 2026-09-14 17:25 UTC

