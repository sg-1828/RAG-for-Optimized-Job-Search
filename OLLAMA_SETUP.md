# Ollama Setup Guide

This guide explains how to set up and use Ollama for both embeddings and LLM (instead of OpenAI).

## Why Ollama?

- **Free**: No API costs
- **Local**: Runs on your EC2 instance
- **Private**: Data stays on your server
- **Flexible**: Can use various open-source models

## Prerequisites

- EC2 instance with at least **8GB RAM** (16GB+ recommended for larger models)
- Docker and Docker Compose installed

## Quick Setup

### 1. Configure Environment

Create `.env` file:

```bash
# Embeddings - Using Ollama
EMBEDDING_PROVIDER=ollama
EMBEDDING_DIM=768
OLLAMA_BASE_URL=http://ollama:11434
OLLAMA_EMBED_MODEL=all-minilm:16-v2

# LLM - Using Ollama
AGENT_ENABLED=true
LLM_PROVIDER=ollama
OLLAMA_LLM_MODEL=llama2
LLM_TEMPERATURE=0.3
LLM_MAX_TOKENS=500
```

### 2. Start Services

```bash
docker-compose up -d
```

### 3. Pull Required Models

After services start, pull the required models:

```bash
# Pull embedding model (required)
docker exec rag-ollama ollama pull all-minilm:16-v2

# Pull LLM model (required for agent features)
docker exec rag-ollama ollama pull llama2

# Or use a smaller/faster model
docker exec rag-ollama ollama pull llama2:7b
```

### 4. Verify Setup

```bash
# Check Ollama is running
curl http://localhost:11434/api/tags

# Check API health
curl http://localhost:8000/api/v1/health
```

## Available Models

### Embedding Models

- `all-minilm:16-v2` (Recommended) - 384 dimensions, fast
- `nomic-embed-text` - 768 dimensions, better quality
- `mxbai-embed-large` - 1024 dimensions, best quality

### LLM Models

- `llama2` (Recommended) - Good balance of quality and speed
- `llama2:7b` - Smaller, faster version
- `llama2:13b` - Larger, better quality
- `mistral` - Alternative, often faster
- `codellama` - Good for technical queries

## Model Selection Guide

### For Embeddings

**Small instances (< 4GB RAM):**
```bash
OLLAMA_EMBED_MODEL=all-minilm:16-v2
EMBEDDING_DIM=384
```

**Medium instances (4-8GB RAM):**
```bash
OLLAMA_EMBED_MODEL=nomic-embed-text
EMBEDDING_DIM=768
```

**Large instances (8GB+ RAM):**
```bash
OLLAMA_EMBED_MODEL=mxbai-embed-large
EMBEDDING_DIM=1024
```

### For LLM

**Small instances (< 8GB RAM):**
```bash
OLLAMA_LLM_MODEL=llama2:7b
```

**Medium instances (8-16GB RAM):**
```bash
OLLAMA_LLM_MODEL=llama2
```

**Large instances (16GB+ RAM):**
```bash
OLLAMA_LLM_MODEL=llama2:13b
```

## Complete Setup Example

```bash
# 1. Create .env file
cat > .env << EOF
ENVIRONMENT=prod
API_PREFIX=/api/v1
VECTOR_TOP_K=20

QDRANT_HOST=qdrant
QDRANT_PORT=6333

EMBEDDING_PROVIDER=ollama
EMBEDDING_DIM=768
OLLAMA_BASE_URL=http://ollama:11434
OLLAMA_EMBED_MODEL=all-minilm:16-v2

AGENT_ENABLED=true
LLM_PROVIDER=ollama
OLLAMA_LLM_MODEL=llama2
LLM_TEMPERATURE=0.3
LLM_MAX_TOKENS=500
EOF

# 2. Start services
docker-compose up -d

# 3. Wait for services to start
sleep 10

# 4. Pull models
docker exec rag-ollama ollama pull all-minilm:16-v2
docker exec rag-ollama ollama pull llama2

# 5. Verify
curl http://localhost:8000/api/v1/health
```

## Troubleshooting

### Ollama Container Won't Start

```bash
# Check logs
docker logs rag-ollama

# Check if port is available
netstat -tuln | grep 11434

# Restart service
docker-compose restart ollama
```

### Models Not Found

```bash
# List available models
docker exec rag-ollama ollama list

# Pull missing model
docker exec rag-ollama ollama pull <model-name>
```

### Out of Memory

If you get out-of-memory errors:

1. **Use smaller models:**
   ```bash
   OLLAMA_LLM_MODEL=llama2:7b
   OLLAMA_EMBED_MODEL=all-minilm:16-v2
   ```

2. **Increase EC2 instance size**

3. **Limit model context:**
   ```bash
   LLM_MAX_TOKENS=300  # Reduce from 500
   ```

### Slow Response Times

1. **Use faster models:**
   - For embeddings: `all-minilm:16-v2`
   - For LLM: `llama2:7b` or `mistral`

2. **Reduce max tokens:**
   ```bash
   LLM_MAX_TOKENS=300
   ```

3. **Increase EC2 instance size** (more CPU/RAM)

## Performance Tips

1. **Pre-pull models** during deployment to avoid delays
2. **Use appropriate model sizes** for your instance
3. **Monitor resource usage:**
   ```bash
   docker stats rag-ollama
   ```
4. **Consider using GPU instances** for better performance (if available)

## Switching Between Ollama and OpenAI

### To Switch to OpenAI:

```bash
# In .env file
LLM_PROVIDER=openai
OPENAI_API_KEY=sk-your-key-here
LLM_MODEL=gpt-3.5-turbo

# Restart API service
docker-compose restart api
```

### To Switch Back to Ollama:

```bash
# In .env file
LLM_PROVIDER=ollama
OLLAMA_LLM_MODEL=llama2

# Restart API service
docker-compose restart api
```

## Model Management

### List Installed Models

```bash
docker exec rag-ollama ollama list
```

### Remove Unused Models

```bash
docker exec rag-ollama ollama rm <model-name>
```

### Update Models

```bash
docker exec rag-ollama ollama pull <model-name>
```

## Production Recommendations

1. **Use Qdrant Cloud** for vector storage (more reliable)
2. **Keep Ollama for embeddings** (free, works well)
3. **Consider OpenAI for LLM** in production (faster, more reliable)
4. **Or use Azure OpenAI** for enterprise deployments
5. **Monitor Ollama resource usage** and scale instance if needed

## Cost Comparison

- **Ollama**: $0 (runs on your EC2 instance)
- **OpenAI**: ~$0.001-0.002 per query (GPT-3.5-turbo)
- **Azure OpenAI**: Similar to OpenAI, with enterprise features

For high-traffic production, consider the trade-off between cost and performance.

