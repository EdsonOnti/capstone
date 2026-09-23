# 🧪 Test Visual: Modo Cliente vs Modo Admin

## 📺 Instrucciones de Prueba

### Parte 1: Modo Cliente (7 minutos)

#### 1.1 Abre el frontend
```
URL: https://d33x5tfyjkvcnh.cloudfront.net
Espera: La página carga, ves 4 tarjetas de productos
```

#### 1.2 Verifica que estés en Modo Cliente
```
✓ Esquina superior derecha debe decir: "Modo Cliente" (no "Modo Admin")
✓ Las tarjetas deben tener botones PÚRPURA "Ver" + AZUL "Agregar al Carrito"
✓ NO deben aparecer botones "Editar"/"Eliminar"
```

#### 1.3 Click "Ver" en un producto (ej: el primero)
```
Espera: Se abre modal con la información del producto
Verifica:
  ✓ Imagen del producto visible y grande
  ✓ Nombre, descripción, precio, stock
  ✓ Etiquetas AI (e.g., "Explosion", "Fire")
  ✓ Status de moderación (e.g., "✅ Imagen aprobada" o "⚠️ Contenido sensible")
```

#### 1.4 Agregar primera reseña
```
En la sección "Reseñas de clientes":
1. Escribe en textarea: "Excelente producto, muy recomendado!"
2. Click "Enviar reseña"
Verifica:
  ✓ Loading spinner durante envío
  ✓ Mensaje de éxito: "✅ Reseña agregada"
  ✓ La reseña aparece en "Historial de reseñas"
```

#### 1.5 Agregar segunda reseña (negativa)
```
1. Escribe: "No me gustó, la talla no coincide"
2. Click "Enviar reseña"
Verifica:
  ✓ La reseña aparece en el historial
  ✓ Total: 2 reseñas visibles
```

#### 1.6 Agregar tercera reseña (positiva)
```
1. Escribe: "Súper recomendado, muy buena calidad!"
2. Click "Enviar reseña"
Verifica:
  ✓ Total: 3 reseñas en el historial
```

#### 1.7 Analizar sentimiento
```
1. Click "Analizar sentimiento (S3)"
Espera: Loading spinner, ~1-2 segundos
Verifica:
  ✓ Aparece sección "Análisis de sentimiento"
  ✓ Emoji: 😊 (POSITIVE)
  ✓ Título: "POSITIVE"
  ✓ Distribución mostrada:
    - POSITIVE: 2
    - NEGATIVE: 1
  ✓ Cada reseña muestra su sentimiento individual
```

#### 1.8 Cierra el modal
```
Click X (esquina superior derecha)
Verifica:
  ✓ Modal cierra
  ✓ Vuelves a ver las 4 tarjetas
```

---

### Parte 2: Modo Admin (8 minutos)

#### 2.1 Cambia a Modo Admin
```
Click "Modo Cliente" (esquina superior derecha)
Verifica:
  ✓ El botón ahora dice "Modo Admin"
  ✓ El botón tiene fondo AZUL
  ✓ Las tarjetas ahora muestran:
    - Botón AZUL "Editar"
    - Botón ROJO "Eliminar"
    (Sin "Ver" ni "Carrito")
  ✓ Aparece nuevo botón AZUL: "Agregar Nuevo Producto"
```

#### 2.2 Click "Editar" en un producto
```
Click "Editar" en cualquier tarjeta
Verifica:
  ✓ Se abre modal: "Editar Producto"
  ✓ Campos precargados:
    - Nombre
    - Descripción
    - Precio
    - Stock
    - Categoría
    - Imagen actual visible
  ✓ NO aparece sección de "Reseñas de clientes"
```

#### 2.3 Cambiar imagen (subida local)
```
1. Click "Cambiar imagen" (botón con icono de upload)
2. Se abre file picker
3. Selecciona una imagen local .jpg/.png
Espera: ~2-5 segundos (se sube a S3)
Verifica:
  ✓ Preview local aparece durante la subida
  ✓ Spinner de carga: "Subiendo..."
  ✓ La imagen S3 aparece en la vista previa
  ✓ La URL de CloudFront se autoguarda
  ✓ Botón cambia de "Seleccionar imagen" a "Cambiar imagen"
```

#### 2.4 Editar otro campo
```
1. Cambia el nombre a: "Camisa Azul Editada - TEST"
2. Cambia stock a: "99"
3. Click "Actualizar"
Espera: Modal cierra, vuelves a ver tarjetas
Verifica:
  ✓ El producto ahora muestra nombre actualizado
  ✓ El stock es 99
```

#### 2.5 Verificar cambios en cliente
```
1. Click "Modo Cliente" (vuelve a modo cliente)
2. Click "Ver" en el producto que acabas de editar
Verifica:
  ✓ Nombre actualizado: "Camisa Azul Editada - TEST"
  ✓ Stock: 99
  ✓ Si cambió imagen: la nueva imagen visible
  ✓ Las reseñas que agregaste en la Parte 1 SIGUEN PRESENTES
```

#### 2.6 Crear un producto nuevo
```
1. Click "Modo Admin"
2. Click "Agregar Nuevo Producto"
3. Llena:
   - Nombre: "Producto Test"
   - Descripción: "Este es un producto de prueba"
   - Precio: "49.99"
   - Stock: "10"
   - Categoría: "Accesorios"
   - Imagen: URL o upload
4. Click "Crear"
Espera: Modal cierra
Verifica:
  ✓ Nueva tarjeta aparece en la grilla
  ✓ Muestra todos los datos correctos
  ✓ Imagen visible (si la subiste)
```

#### 2.7 Eliminar el producto de test
```
1. Encuentra la tarjeta "Producto Test"
2. Click "Eliminar"
3. Confirma en el diálogo: "¿Estás seguro...?"
Espera: Modal cierra
Verifica:
  ✓ La tarjeta desaparece
  ✓ Vuelven a verse solo los 4 productos originales
```

---

## ✅ Checklist Final

### Modo Cliente
- [ ] Botones correctos (Ver + Carrito)
- [ ] ProductDetailsModal abre al click "Ver"
- [ ] Información del producto completa
- [ ] Puedo escribir reseña
- [ ] Puedo enviar reseña
- [ ] Historial de reseñas se actualiza
- [ ] Botón "Analizar sentimiento" funciona
- [ ] Resultado muestra sentimiento + emoji + distribución
- [ ] Cada reseña muestra su sentimiento individual

### Modo Admin
- [ ] Botones correctos (Editar + Eliminar)
- [ ] Aparece botón "Agregar Nuevo Producto"
- [ ] ProductModal abre al click "Editar"
- [ ] Formulario tiene todos los campos
- [ ] NO aparece sección de reseñas
- [ ] Puedo cambiar imagen (presigned URL)
- [ ] Puedo editar campos y actualizar
- [ ] Puedo crear nuevo producto
- [ ] Puedo eliminar producto

### Integración
- [ ] Cambios en Admin aparecen en Cliente
- [ ] Las reseñas persisten entre cambios de modo
- [ ] Sentimiento se mantiene en DynamoDB
- [ ] No hay errores en consola (F12)

---

## 🐛 Troubleshooting

### Problema: "Ver" no abre modal en modo cliente
**Solución:** Hard refresh (Ctrl+Shift+R), verifica que está en Modo Cliente

### Problema: Upload de imagen dice "Error subiendo imagen"
**Solución:** 
- Verifica que el archivo sea .jpg/.png
- Tamaño < 5MB
- Revisa logs del Router Lambda

### Problema: "Analizar sentimiento" no funciona
**Solución:**
- Asegúrate de haber agregado al menos 1 reseña
- Revisa logs de S3 Lambda (Comprehend)
- Verifica conectividad a Internet

### Problema: Las reseñas no se guardan
**Solución:**
- Verifica que el producto tiene `productId` válido
- Revisa logs del Router Lambda
- Comprueba que DynamoDB tiene la tabla

---

## 📊 Datos de Prueba

```json
{
  "productId": "12646fbe-e572-4b20-bc46-154a4aa315d9",
  "name": "camisa roja claro",
  "reviews": [
    {
      "id": "12646fbe...-1234567890",
      "text": "Excelente producto, muy recomendado!",
      "timestamp": "2026-09-23T04:30:00Z"
    },
    {
      "id": "12646fbe...-1234567891",
      "text": "No me gustó, la talla no coincide",
      "timestamp": "2026-09-23T04:31:00Z"
    },
    {
      "id": "12646fbe...-1234567892",
      "text": "Súper recomendado, muy buena calidad!",
      "timestamp": "2026-09-23T04:32:00Z"
    }
  ],
  "reviewSentiment": "POSITIVE",
  "reviewSentimentCounts": {
    "POSITIVE": 2,
    "NEGATIVE": 1
  }
}
```

---

**¡Listo para testear! 🧪**
