#!/bin/bash

# Update script for EC2 deployment
# Pulls latest code and rebuilds services

set -e

echo "🔄 Updating RAG Service..."

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if in git repository
if [ ! -d .git ]; then
    echo -e "${YELLOW}⚠️  Not a git repository. Skipping git pull.${NC}"
else
    echo "📥 Pulling latest code..."
    git pull origin main || git pull origin master
fi

echo "🔨 Rebuilding services..."
docker-compose up -d --build

echo "⏳ Waiting for services to restart..."
sleep 5

echo -e "${GREEN}✅ Update complete!${NC}"
echo ""
echo "View logs: docker-compose logs -f"
docker-compose ps

