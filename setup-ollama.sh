#!/bin/bash

# Script to set up Ollama models after deployment
# Run this after docker-compose up -d

set -e

echo "🦙 Setting up Ollama models..."

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Wait for Ollama to be ready
echo "⏳ Waiting for Ollama to be ready..."
for i in {1..30}; do
    if curl -f http://localhost:11434/api/tags > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Ollama is ready${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${YELLOW}⚠️  Ollama is taking longer than expected. Continuing anyway...${NC}"
    fi
    sleep 2
done

# Pull embedding model
echo "📥 Pulling embedding model (all-minilm:16-v2)..."
docker exec rag-ollama ollama pull all-minilm:16-v2 || {
    echo -e "${YELLOW}⚠️  Failed to pull embedding model. You may need to pull it manually.${NC}"
}

# Pull LLM model
echo "📥 Pulling LLM model (llama2)..."
docker exec rag-ollama ollama pull llama2 || {
    echo -e "${YELLOW}⚠️  Failed to pull LLM model. You may need to pull it manually.${NC}"
    echo "💡 Tip: For smaller instances, try: docker exec rag-ollama ollama pull llama2:7b"
}

# List installed models
echo ""
echo "📋 Installed models:"
docker exec rag-ollama ollama list

echo ""
echo -e "${GREEN}✅ Ollama setup complete!${NC}"
echo ""
echo "If any models failed to download, you can pull them manually:"
echo "  docker exec rag-ollama ollama pull <model-name>"
echo ""
echo "For smaller instances, consider using:"
echo "  docker exec rag-ollama ollama pull llama2:7b"

