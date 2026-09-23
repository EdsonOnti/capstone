# 🛣️ S7 Roadmap: RAG + Búsqueda Semántica

**Objetivo:** Transformar TechModa de "tienda que recomenda" a "tienda que busca y responde".

---

## 📌 Por qué S7 es el siguiente hito

### Lo que tienes (S0–S6)

```
Usuario → "Dame todos los vestidos"
       ↓
       SQL keyword search
       ↓
       "Aquí están los vestidos: [...]"
```

### Lo que quieres (S7)

```
Usuario → "¿Qué tienes para una boda elegante?"
       ↓
       Búsqueda semántica (entiende significado)
       ↓
       Recupera: Dress, Jewelry, Heels, Clutch
       ↓
       Claude: "Para boda elegante, te recomiendo..."
       ↓
       Respuesta personalizada + productos
```

**Diferencia:** S0–S6 **entregan información**. S7 **entiende intención** + **recomienda**.

---

## 🧠 Conceptos Clave

### 1. Embeddings (Vectores de Significado)

**¿Qué es?**
```
Texto: "Vestido floral elegante para boda"
    ↓
Bedrock Embeddings API (Titan)
    ↓
Vector: [0.12, -0.45, 0.78, 0.23, -0.56, ..., 0.89]
        (dimensiones: 384 o 1536)
```

**¿Por qué?**
- `"vestido elegante"` y `"dress formal"` → **vectores muy parecidos** (distancia pequeña)
- `"vestido"` y `"zapatos"` → **vectores distintos** (distancia grande)
- La máquina entiende **similitud semántica**, no solo palabras clave

### 2. Vector DB (DynamoDB Global Secondary Index)

**Almacenar vectores:**
```json
{
  "productId": "P001",
  "name": "Floral Midi Dress",
  "category": "Dresses",
  "embedding": [0.12, -0.45, 0.78, ..., 0.89],
  "embedding_hash": "abc123",  // Para queries
  "aiLabels": ["Dress", "Floral", "Elegant"],
  "price": 79.99
}
```

**Buscar:**
```
Pregunta: "¿Qué tienes para boda?"
    ↓
Embed la pregunta: [0.18, -0.42, 0.75, ..., 0.87]
    ↓
Buscar Top-5 vectores más cercanos en DDB-GSI
    ↓
Devuelve: P001, P023, P045, P078, P101 (Dresses + Jewelry)
```

### 3. Bedrock Converse API (Claude + contexto)

**Patrón: Prompt Context + Recuperación**
```python
retrieved_products = [
  {"name": "Floral Midi Dress", "category": "Dresses", "price": 79.99},
  {"name": "Pearl Earrings", "category": "Jewelry", "price": 45.00},
  {"name": "Black Heels", "category": "Shoes", "price": 89.99}
]

prompt = f"""
Eres un asistente de moda de TechModa.
Basándote en estos productos disponibles:

{json.dumps(retrieved_products, indent=2)}

Responde a la pregunta del usuario:
"{user_question}"

Sé conciso, sugiere combinaciones, menciona precios.
"""

response = bedrock_runtime.converse(
    modelId="us.anthropic.claude-haiku-4-5-20251001-v1:0",
    messages=[{"role": "user", "content": prompt}]
)

print(response['content'][0]['text'])
# "Te recomiendo el Floral Midi Dress con los Pearl Earrings
#  y los Black Heels para un look elegante y completo. Total: ~$215"
```

---

## 🏗️ Arquitectura S7

```
┌─────────────────────────────────────────────────────┐
│          FRONTEND (React)                           │
│  ┌─────────────────────────────────────────────┐   │
│  │ Input: "¿Qué tienes para home office?"      │   │
│  │ [Buscar] [Limpiar]                           │   │
│  │                                               │   │
│  │ Resultados (RAG):                             │   │
│  │ - Laptop Pro (ETL)                           │   │
│  │ - Monitor Ultrawide (ETL)                    │   │
│  │ - Ergonomic Chair (ETL)                      │   │
│  │                                               │   │
│  │ Claude: "Te recomiendo..."                    │   │
│  └─────────────────────────────────────────────┘   │
└───────────┬─────────────────────────────────────────┘
            │ POST /search
            ▼
┌─────────────────────────────────────────────────────┐
│       LAMBDA S7 - RAG Search (Nueva)                │
└───────────┬─────────────────────────────────────────┘
            │
    ┌───────┴──────┬─────────────┬──────────────┐
    │              │             │              │
    ▼              ▼             ▼              ▼
┌─────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐
│ Bedrock │  │DynamoDB  │  │ Bedrock  │  │CloudWatch│
│Embeddings   Vector GSI   Converse   Logs
│(Titan)      (Top-5)      (Claude)   (Audit)
└─────────┘  └──────────┘  └──────────┘  └─────────┘
```

---

## 🛠️ Implementación: Paso a Paso

### Fase 1: Preparar Embeddings (Batch Initial)

**Sesión:** S6a (preparación)

```python
# Lambda: GenerateEmbeddings (Una sola vez)

import boto3
import json
from decimal import Decimal

bedrock = boto3.client('bedrock-runtime', region_name='us-east-1')
dynamodb = boto3.resource('dynamodb', region_name='us-east-1')

def lambda_handler(event, context):
    table = dynamodb.Table(os.environ['TABLE_NAME'])
    
    # 1. Obtener todos los productos
    response = table.scan()
    products = response['Items']
    
    for product in products:
        # 2. Construir texto a embedear (resumen semántico)
        text_to_embed = f"""
        Nombre: {product['name']}
        Categoría: {product.get('category', '')}
        Descripción: {product.get('description', '')}
        Etiquetas: {', '.join(product.get('aiLabels', []))}
        """
        
        # 3. Llamar a Bedrock Embeddings
        embedding_response = bedrock.invoke_model(
            modelId='amazon.titan-embed-text-v2:0',  # Titan Embeddings
            body=json.dumps({
                'inputText': text_to_embed,
                'dimensions': 384,  # O 1536 para mayor precisión
                'normalize': True
            })
        )
        
        embedding_data = json.loads(embedding_response['body'].read())
        embedding_vector = embedding_data['embedding']
        
        # 4. Guardar en DynamoDB con GSI
        table.update_item(
            Key={'productId': product['productId']},
            UpdateExpression='SET embedding = :vec, embedding_hash = :hash',
            ExpressionAttributeValues={
                ':vec': embedding_vector,  # Array de floats
                ':hash': 'indexed'  # Marcador para GSI
            }
        )
    
    return {
        'statusCode': 200,
        'body': {'message': f'Embeddings generados para {len(products)} productos'}
    }
```

**Cuando:**
- Una sola vez al inicio de S7
- O cada vez que un nuevo producto se crea (S0 POST)

**Costo:** ~$0.10 por 1M tokens (384 dimensiones es económico)

---

### Fase 2: Búsqueda Semántica (Lambda S7)

**Sesión:** S7 (principal)

```python
# Lambda: RAG Search

import boto3
import json
import math
from decimal import Decimal

bedrock = boto3.client('bedrock-runtime', region_name='us-east-1')
dynamodb = boto3.resource('dynamodb', region_name='us-east-1')

def cosine_similarity(vec_a, vec_b):
    """Calcular similitud de coseno entre dos vectores"""
    dot_product = sum(a * b for a, b in zip(vec_a, vec_b))
    mag_a = math.sqrt(sum(a * a for a in vec_a))
    mag_b = math.sqrt(sum(b * b for b in vec_b))
    return dot_product / (mag_a * mag_b) if mag_a * mag_b else 0

def lambda_handler(event, context):
    body = json.loads(event['body'])
    query = body['query']  # "¿Qué tienes para home office?"
    top_k = body.get('top_k', 5)
    
    table = dynamodb.Table(os.environ['TABLE_NAME'])
    
    # 1. Embedear la pregunta
    query_embed_response = bedrock.invoke_model(
        modelId='amazon.titan-embed-text-v2:0',
        body=json.dumps({
            'inputText': query,
            'dimensions': 384,
            'normalize': True
        })
    )
    
    query_embedding = json.loads(query_embed_response['body'].read())['embedding']
    
    # 2. Hacer scan de todos los productos con embeddings
    #    (En producción: usar DynamoDB GSI o Aurora Vectors)
    response = table.scan()
    products = response['Items']
    
    # 3. Calcular similitud para cada producto
    scores = []
    for product in products:
        if 'embedding' in product:
            similarity = cosine_similarity(
                query_embedding,
                product['embedding']
            )
            scores.append({
                'productId': product['productId'],
                'name': product['name'],
                'category': product.get('category'),
                'price': product.get('price'),
                'description': product.get('description'),
                'score': similarity
            })
    
    # 4. Top-K más similares
    retrieved = sorted(scores, key=lambda x: x['score'], reverse=True)[:top_k]
    
    # 5. Construir contexto para Claude
    context = "Productos disponibles:\n"
    for i, item in enumerate(retrieved, 1):
        context += f"\n{i}. {item['name']} (${item['price']:.2f})\n"
        context += f"   Categoría: {item['category']}\n"
        context += f"   {item['description'][:100]}...\n"
    
    # 6. Llamar a Claude con contexto
    prompt = f"""Eres un asistente de moda de TechModa.

{context}

Pregunta del usuario: "{query}"

Responde de forma concisa (máx 3 frases).
Sugiere qué productos combinan bien para resolver la pregunta.
Menciona precios si es relevante.
Si nada es relevante, sé honesto."""
    
    response = bedrock.converse(
        modelId='us.anthropic.claude-haiku-4-5-20251001-v1:0',
        messages=[{
            'role': 'user',
            'content': prompt
        }],
        inferenceConfig={
            'maxTokens': 200,
            'temperature': 0.7
        }
    )
    
    claude_response = response['content'][0]['text']
    
    # 7. Retornar resultados
    return {
        'statusCode': 200,
        'body': json.dumps({
            'query': query,
            'retrieved_products': [
                {'name': r['name'], 'price': r['price'], 'similarity': round(r['score'], 3)}
                for r in retrieved
            ],
            'recommendation': claude_response,
            'usage': {
                'input_tokens': response['usage']['inputTokens'],
                'output_tokens': response['usage']['outputTokens']
            }
        })
    }
```

**Entrada:**
```json
{
  "query": "¿Qué tienes para trabajar desde casa?"
}
```

**Salida:**
```json
{
  "query": "¿Qué tienes para trabajar desde casa?",
  "retrieved_products": [
    {"name": "Laptop Pro", "price": 1299.99, "similarity": 0.89},
    {"name": "Monitor Ultrawide", "price": 399.99, "similarity": 0.85},
    {"name": "Ergonomic Chair", "price": 249.99, "similarity": 0.82}
  ],
  "recommendation": "Te recomiendo la Laptop Pro para productividad, el Monitor Ultrawide para multitarea sin cuello adolorido, y la Silla Ergonómica para estar cómodo 8+ horas. Total: ~$1950. ¡Un setup profesional!",
  "usage": {"input_tokens": 145, "output_tokens": 68}
}
```

---

### Fase 3: Optimizaciones (S7+)

| Optimización | Impacto | Cuándo |
|---|---|---|
| **Aurora Vectors** | Búsqueda más rápida (no scan) | S9–S10 (producción) |
| **Caché de embeddings** | No recalcular preguntas frecuentes | S8 (chatbot) |
| **Feedback loop** | Usuarios califican recomendaciones | S9 (guardrails) |
| **Fine-tuning** | Embeddings por dominio (moda) | Producción |
| **Multi-turn memory** | Recordar contexto de conversaciones | S8 (chatbot) |

---

## 📋 Template SAM para S7

```yaml
# sessions/S07-bedrock-rag-busqueda/template-snippet.yaml

AWSTemplateFormatVersion: '2010-09-09'
Transform: AWS::Serverless-2010-05-13

Resources:
  GenerateEmbeddingsFunction:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: functions/generate-embeddings/
      Handler: app.lambda_handler
      Runtime: python3.12
      Timeout: 300  # Batch inicial largo
      Environment:
        Variables:
          TABLE_NAME: !Ref ProductsTable
      Policies:
        - DynamoDBCrudPolicy:
            TableName: !Ref ProductsTable
        - Version: '2012-10-17'
          Statement:
            - Effect: Allow
              Action:
                - bedrock:InvokeModel
              Resource:
                - !Sub 'arn:aws:bedrock:us-east-1::foundation-model/amazon.titan-embed-text-v2:0'
                - !Sub 'arn:aws:bedrock:us-east-1:${AWS::AccountId}:inference-profile/*'

  RAGSearchFunction:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: functions/rag-search/
      Handler: app.lambda_handler
      Runtime: python3.12
      Timeout: 30
      Environment:
        Variables:
          TABLE_NAME: !Ref ProductsTable
      Policies:
        - DynamoDBReadPolicy:
            TableName: !Ref ProductsTable
        - Version: '2012-10-17'
          Statement:
            - Effect: Allow
              Action:
                - bedrock:InvokeModel
              Resource:
                - !Sub 'arn:aws:bedrock:us-east-1::foundation-model/amazon.titan-embed-text-v2:0'
                - !Sub 'arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-haiku-4-5-20251001-v1:0'
                - !Sub 'arn:aws:bedrock:us-east-1:${AWS::AccountId}:inference-profile/us.anthropic.claude-haiku-4-5-20251001-v1:0'
      FunctionUrlConfig:
        AuthType: NONE
        Cors:
          AllowOrigins: ['*']

Outputs:
  GenerateEmbeddingsUrl:
    Value: !GetAtt GenerateEmbeddingsFunctionUrl.FunctionUrl
    Description: "Lambda para generar embeddings batch inicial"
  
  RAGSearchUrl:
    Value: !GetAtt RAGSearchFunctionUrl.FunctionUrl
    Description: "Lambda para búsqueda semántica + recomendación"
```

---

## 🧪 Testing S7

### Test 1: Generar embeddings

```bash
GENERATE_URL=$(aws cloudformation describe-stacks \
  --stack-name edson-martin-ontiveros-lima --region us-east-1 \
  --query "Stacks[0].Outputs[?OutputKey=='GenerateEmbeddingsUrl'].OutputValue" --output text)

curl -s -X POST "${GENERATE_URL%/}/generate" \
  -H "Content-Type: application/json" | python3 -m json.tool
```

**Respuesta esperada:**
```json
{
  "statusCode": 200,
  "body": {
    "message": "Embeddings generados para 4 productos"
  }
}
```

### Test 2: Búsqueda semántica

```bash
SEARCH_URL=$(aws cloudformation describe-stacks \
  --stack-name edson-martin-ontiveros-lima --region us-east-1 \
  --query "Stacks[0].Outputs[?OutputKey=='RAGSearchUrl'].OutputValue" --output text)

curl -s -X POST "${SEARCH_URL%/}/search" \
  -H "Content-Type: application/json" \
  -d '{"query": "¿Qué tienes para una boda?", "top_k": 3}' | python3 -m json.tool
```

**Respuesta esperada:**
```json
{
  "query": "¿Qué tienes para una boda?",
  "retrieved_products": [
    {"name": "Floral Midi Dress", "price": 79.99, "similarity": 0.87},
    {"name": "Pearl Earrings", "price": 45.00, "similarity": 0.79},
    {"name": "Black Heels", "price": 89.99, "similarity": 0.75}
  ],
  "recommendation": "Para una boda elegante te sugiero el Floral Midi Dress + Pearl Earrings + Black Heels. Total: $214.98",
  "usage": {"input_tokens": 152, "output_tokens": 42}
}
```

---

## ✅ Checklist Antes de Comenzar S7

- [x] S0–S6 funcionando
- [x] Bedrock modelo access habilitado (Titan Embeddings + Claude Haiku)
- [x] DynamoDB con `embedding` + `embedding_hash` campos
- [x] Template SAM preparado
- [x] Entender embeddings y similitud de coseno
- [ ] Implementar `GenerateEmbeddingsFunction`
- [ ] Probar batch initial (4 productos)
- [ ] Implementar `RAGSearchFunction`
- [ ] Probar 5 queries distintas
- [ ] Integrar en frontend (Search box)
- [ ] Medir latencia + costo

---

## 💸 Estimación de Costo (S7)

| Componente | Volumen | Costo/mes |
|---|---|---|
| Bedrock Embeddings | 100 queries/día | ~$1–2 |
| Bedrock Claude (Converse) | 100 queries/día | ~$3–5 |
| DynamoDB scan | 100 queries/día (Full table) | ~$0.30 |
| **Total** | — | **~$4–7/mes** |

*Con Aurora Vectors (S9): ~$0.50/mes (scan → índice vectorial)*

---

## 📚 Lectura Previa

- [Embeddings 101](https://www.cloudflare.com/en-gb/learning/ai/what-are-embeddings/)
- [RAG Pattern](https://docs.aws.amazon.com/bedrock/latest/userguide/knowledge-base.html)
- [Bedrock Titan Embeddings](https://docs.aws.amazon.com/bedrock/latest/userguide/titan-embed-api.html)
- [Cosine Similarity](https://en.wikipedia.org/wiki/Cosine_similarity)

---

**Estimación:** S7 completo = 2–3 sesiones de 1 hora
**Prerrequisito:** S0–S6 + Bedrock Model Access habilitado
**Próximo:** S8 Chatbot multi-turno (usa S7 + session memory)

