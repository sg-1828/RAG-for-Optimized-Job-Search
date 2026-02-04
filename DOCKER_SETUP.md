# Docker Setup Overview

This project includes multiple Docker configurations for different deployment scenarios.

## Docker Files

### 1. `Dockerfile` (Original)
- Simple single-container setup
- For API service only
- Good for quick local testing

### 2. `Dockerfile.api`
- Optimized for FastAPI backend
- Includes health checks
- Production-ready

### 3. `Dockerfile.ui`
- Optimized for Streamlit UI
- Connects to API service
- Production-ready

### 4. `docker-compose.yml`
- Orchestrates all services:
  - **qdrant**: Vector database
  - **api**: FastAPI backend (port 8000)
  - **ui**: Streamlit UI (port 8501)
  - **ollama**: Optional local embeddings/LLM (port 11434)

## Quick Start

### Local Development
```bash
# Build and run with docker-compose
docker-compose up -d --build

# Access services
# - UI: http://localhost:8501
# - API: http://localhost:8000
```

### Production Deployment
See [DEPLOYMENT.md](./DEPLOYMENT.md) for EC2 deployment instructions.

## Service Architecture

```
┌─────────────┐
│   Browser   │
└──────┬──────┘
       │
       ├───► Streamlit UI (8501)
       │         │
       │         └───► FastAPI API (8000)
       │                    │
       │                    ├───► Qdrant (6333)
       │                    │
       │                    └───► OpenAI/Azure (External)
       │
       └───► FastAPI API (8000) [Direct API access]
```

## Environment Variables

All services use environment variables from `.env` file or docker-compose environment section.

**Required:**
- `AGENT_ENABLED=true`
- `LLM_PROVIDER=openai` (or azure/ollama)
- `OPENAI_API_KEY=sk-...` (if using OpenAI)

**Optional:**
- `QDRANT_HOST`, `QDRANT_PORT` (or use Qdrant Cloud)
- `EMBEDDING_PROVIDER` (ollama/openai/azure)
- `OLLAMA_BASE_URL` (if using Ollama)

See `.env.example` for complete configuration.

## Building Images

### Build API Image
```bash
docker build -f Dockerfile.api -t rag-api:latest .
```

### Build UI Image
```bash
docker build -f Dockerfile.ui -t rag-ui:latest .
```

### Build All with Compose
```bash
docker-compose build
```

## Running Services

### Start All Services
```bash
docker-compose up -d
```

### Start Specific Service
```bash
docker-compose up -d api
docker-compose up -d ui
docker-compose up -d qdrant
```

### View Logs
```bash
docker-compose logs -f
docker-compose logs -f api
docker-compose logs -f ui
```

### Stop Services
```bash
docker-compose down
```

## Health Checks

- **API**: `curl http://localhost:8000/api/v1/health`
- **Qdrant**: `curl http://localhost:6333/health`
- **UI**: Access `http://localhost:8501` in browser

## Troubleshooting

### Port Already in Use
```bash
# Change ports in docker-compose.yml
ports:
  - "8001:8000"  # Change host port
```

### Out of Memory
- Increase EC2 instance size
- Or use Qdrant Cloud instead of containerized Qdrant
- Or use OpenAI embeddings instead of Ollama

### Services Can't Communicate
- Ensure all services are on the same Docker network
- Check service names match in docker-compose.yml
- Verify environment variables are set correctly

## Production Considerations

1. **Use Qdrant Cloud** for better reliability
2. **Use OpenAI/Azure embeddings** for production
3. **Set up HTTPS** with nginx reverse proxy
4. **Use secrets management** (AWS Secrets Manager) instead of `.env`
5. **Enable auto-restart** with `restart: unless-stopped`
6. **Set up monitoring** and logging

