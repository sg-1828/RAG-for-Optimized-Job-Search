# Dockerfile

FROM python:3.11-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# System deps (if you need build tools or pg headers later, add them here)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Python deps
COPY pyproject.toml* poetry.lock* requirements.txt* ./ 2>/dev/null || true

# If you use requirements.txt
RUN if [ -f "requirements.txt" ]; then \
      pip install --no-cache-dir -r requirements.txt; \
    fi

# If you use Poetry instead, uncomment this block and comment the one above
# RUN pip install --no-cache-dir poetry \
#   && poetry config virtualenvs.create false \
#   && poetry install --no-interaction --no-ansi

# Copy source
COPY ./src ./src

ENV PYTHONPATH=/app/src

EXPOSE 8000

# Embedding configuration; override via env
ENV EMBEDDING_PROVIDER=ollama
ENV EMBEDDING_DIM=768
ENV OLLAMA_BASE_URL=http://localhost:11434
ENV OLLAMA_EMBED_MODEL=all-minilm:16-v2

# Qdrant defaults (for self-hosted local dev)
ENV QDRANT_HOST=qdrant
ENV QDRANT_PORT=6333

CMD ["uvicorn", "rag_service.main:app", "--host", "0.0.0.0", "--port", "8000"]
