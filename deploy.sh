#!/bin/bash

# Deployment script for EC2
# This script automates the deployment process

set -e  # Exit on error

echo "🚀 Starting RAG Service Deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${RED}❌ Error: .env file not found!${NC}"
    echo "Please create a .env file with required configuration."
    echo "See DEPLOYMENT.md for details."
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Error: Docker is not installed!${NC}"
    echo "Please install Docker first. See DEPLOYMENT.md for instructions."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ Error: Docker Compose is not installed!${NC}"
    echo "Please install Docker Compose first. See DEPLOYMENT.md for instructions."
    exit 1
fi

echo -e "${GREEN}✅ Prerequisites check passed${NC}"

# Pull latest code if in git repository
if [ -d .git ]; then
    echo "📥 Pulling latest code from Git..."
    git pull origin main || git pull origin master || echo "⚠️  Could not pull from Git (not a blocker)"
fi

# Build and start services
echo "🔨 Building Docker images..."
docker-compose build

echo "🚀 Starting services..."
docker-compose up -d

# Wait for services to be healthy
echo "⏳ Waiting for services to start..."
sleep 10

# Check API health
echo "🏥 Checking API health..."
if curl -f http://localhost:8000/api/v1/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ API is healthy${NC}"
else
    echo -e "${YELLOW}⚠️  API health check failed (may still be starting)${NC}"
fi

# Check Qdrant health
echo "🏥 Checking Qdrant health..."
if curl -f http://localhost:6333/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Qdrant is healthy${NC}"
else
    echo -e "${YELLOW}⚠️  Qdrant health check failed${NC}"
fi

# Check Ollama health
echo "🏥 Checking Ollama health..."
sleep 5  # Give Ollama time to start
if curl -f http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Ollama is running${NC}"
    echo "📥 Checking if models are installed..."
    MODELS=$(docker exec rag-ollama ollama list 2>/dev/null || echo "")
    if echo "$MODELS" | grep -q "all-minilm:16-v2"; then
        echo -e "${GREEN}✅ Embedding model found${NC}"
    else
        echo -e "${YELLOW}⚠️  Embedding model not found. Run: docker exec rag-ollama ollama pull all-minilm:16-v2${NC}"
    fi
    if echo "$MODELS" | grep -q "llama2"; then
        echo -e "${GREEN}✅ LLM model found${NC}"
    else
        echo -e "${YELLOW}⚠️  LLM model not found. Run: docker exec rag-ollama ollama pull llama2${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Ollama health check failed (may still be starting)${NC}"
fi

# Show running containers
echo ""
echo "📊 Running containers:"
docker-compose ps

echo ""
echo -e "${GREEN}✅ Deployment complete!${NC}"
echo ""
echo "Access your services:"
echo "  - UI: http://$(curl -s ifconfig.me):8501"
echo "  - API: http://$(curl -s ifconfig.me):8000"
echo "  - API Docs: http://$(curl -s ifconfig.me):8000/docs"
echo ""
echo "View logs: docker-compose logs -f"
echo "Stop services: docker-compose down"

