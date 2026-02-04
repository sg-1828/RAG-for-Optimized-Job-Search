# EC2 Deployment Guide

This guide walks you through deploying the RAG Job & Resume Search Service to EC2 using Docker.

## Prerequisites

- EC2 instance with:
  - Ubuntu 20.04+ or Amazon Linux 2
  - At least 4GB RAM (8GB+ recommended)
  - Docker and Docker Compose installed
  - Ports 8000, 8501, 6333, 6334 open in security group
- GitHub repository access
- OpenAI API key (or Azure OpenAI credentials) for agent features
- (Optional) Qdrant Cloud account for production vector DB

---

## Step 1: Prepare EC2 Instance

### 1.1 Connect to EC2

```bash
ssh -i your-key.pem ubuntu@your-ec2-ip
```

### 1.2 Install Docker and Docker Compose

**For Ubuntu:**

```bash
# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker --version
docker-compose --version

# Log out and back in for group changes to take effect
exit
```

**For Amazon Linux 2:**

```bash
sudo yum update -y
sudo yum install docker -y
sudo service docker start
sudo usermod -a -G docker ec2-user
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### 1.3 Configure Security Group

In AWS Console, ensure your EC2 security group allows:
- **Port 8000** (FastAPI backend) - from your team's IPs or 0.0.0.0/0
- **Port 8501** (Streamlit UI) - from your team's IPs or 0.0.0.0/0
- **Port 6333** (Qdrant HTTP) - internal only (or restrict to your IPs)
- **Port 6334** (Qdrant gRPC) - internal only
- **Port 11434** (Ollama) - internal only (if using Ollama)
- **Port 22** (SSH) - from your IP only

---

## Step 2: Clone Repository on EC2

```bash
# Navigate to home directory
cd ~

# Clone your repository
git clone https://github.com/your-username/your-repo-name.git job-search-service
cd job-search-service

# Verify files
ls -la
```

---

## Step 3: Create Environment File

Create a `.env` file in the project root:

```bash
nano .env
```

Add the following configuration (adjust values as needed):

```bash
# Core Service Config
ENVIRONMENT=prod
API_PREFIX=/api/v1
VECTOR_TOP_K=20

# Qdrant Configuration (using containerized Qdrant)
QDRANT_HOST=qdrant
QDRANT_PORT=6333

# OR if using Qdrant Cloud (recommended for production):
# QDRANT_URL=https://your-cluster.qdrant.io
# QDRANT_API_KEY=your-qdrant-api-key

# Embedding Configuration - Using Ollama (Free, Local)
# Alternative: Use OpenAI embeddings by setting EMBEDDING_PROVIDER=openai
EMBEDDING_PROVIDER=ollama
EMBEDDING_DIM=768
OLLAMA_BASE_URL=http://ollama:11434
OLLAMA_EMBED_MODEL=all-minilm:16-v2

# Agent Configuration - Using OpenAI for LLM (Recommended for better JSON parsing)
AGENT_ENABLED=true
LLM_PROVIDER=openai
LLM_MODEL=gpt-3.5-turbo
OPENAI_API_KEY=sk-your-openai-api-key-here
LLM_TEMPERATURE=0.3
LLM_MAX_TOKENS=500

# Alternative: If you want to use Ollama for LLM instead (free but less reliable):
# AGENT_ENABLED=true
# LLM_PROVIDER=ollama
# OLLAMA_LLM_MODEL=llama2
# LLM_TEMPERATURE=0.3
# LLM_MAX_TOKENS=500

# UI Configuration
UPLOAD=local
# OR for remote EC2 file access:
# UPLOAD=remote
# EC2_HOST=another-ec2-instance.compute.amazonaws.com
# EC2_USERNAME=ubuntu
# EC2_PORT=22
# EC2_KEY_PATH=/path/to/key.pem
# EC2_RESUME_FOLDER=/home/ubuntu/resumes
```

**Note:** 
- Replace `sk-your-openai-api-key-here` with your actual OpenAI API key from https://platform.openai.com/api-keys
- If you prefer to use Ollama for LLM instead, see `OLLAMA_SETUP.md` for detailed instructions
- For embeddings, Ollama is still used by default (free and works well)

Save and exit (Ctrl+X, then Y, then Enter).

**Important:** Never commit `.env` to Git! It contains sensitive keys.

---

## Step 4: Build and Start Services

### Option A: Using Docker Compose (Recommended)

```bash
# Build and start all services
docker-compose up -d --build

# View logs
docker-compose logs -f

# Check service status
docker-compose ps
```

### Option B: Build Images Manually

```bash
# Build API image
docker build -f Dockerfile.api -t rag-api:latest .

# Build UI image
docker build -f Dockerfile.ui -t rag-ui:latest .

# Start Qdrant
docker run -d --name qdrant -p 6333:6333 -p 6334:6334 qdrant/qdrant:latest

# Start API (with environment variables)
docker run -d --name rag-api \
  --env-file .env \
  -p 8000:8000 \
  --link qdrant:qdrant \
  rag-api:latest

# Start UI
docker run -d --name rag-ui \
  -e API_BASE_URL=http://localhost:8000/api/v1 \
  -p 8501:8501 \
  --link rag-api:api \
  rag-ui:latest
```

---

## Step 5: Initialize Ollama Models (Optional)

**Note:** This step is only needed if you're using Ollama for embeddings. If you're using OpenAI for LLM (recommended), you can skip this step.

If using Ollama for embeddings, start the Ollama service and pull the embedding model:

```bash
# Start Ollama service (if not already running)
docker-compose up -d ollama

# Wait for Ollama to be ready (about 30 seconds)
sleep 30

# Pull embedding model (required if using Ollama for embeddings)
docker exec rag-ollama ollama pull all-minilm:16-v2

# Verify models are installed
docker exec rag-ollama ollama list
```

**Note:** If you're using OpenAI for LLM (recommended), you don't need to pull LLM models in Ollama.

See `OLLAMA_SETUP.md` for model selection guide and troubleshooting if using Ollama for LLM.

---

## Step 6: Verify Deployment

### 6.1 Check Service Health

```bash
# Check API health
curl http://localhost:8000/api/v1/health

# Check Qdrant health
curl http://localhost:6333/health

# Check if containers are running
docker ps
```

### 6.2 Access Services

- **API**: `http://your-ec2-ip:8000`
- **API Docs**: `http://your-ec2-ip:8000/docs`
- **UI**: `http://your-ec2-ip:8501`

---

## Step 7: Set Up Auto-Start on Reboot

Create a systemd service to auto-start Docker Compose:

```bash
sudo nano /etc/systemd/system/rag-service.service
```

Add:

```ini
[Unit]
Description=RAG Job Search Service
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/ubuntu/job-search-service
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
User=ubuntu
Group=docker

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable rag-service.service
sudo systemctl start rag-service.service
```

---

## Step 8: Ingest Initial Data

Once services are running, ingest jobs and resumes:

```bash
# SSH into EC2
ssh -i your-key.pem ubuntu@your-ec2-ip

# Copy data files to EC2 (or use S3, etc.)
scp -i your-key.pem -r ./data/jobs ubuntu@your-ec2-ip:~/data/
scp -i your-key.pem -r ./data/resumes ubuntu@your-ec2-ip:~/data/

# Run ingestion scripts inside API container
docker exec -it rag-api python -m rag_service.scripts.ingest_jobs_from_docs /data/jobs
docker exec -it rag-api python -m rag_service.scripts.ingest_resumes_from_pdfs --folder /data/resumes
```

Or use the UI to upload files directly.

---

## Step 9: Update Deployment (After Code Changes)

```bash
# SSH into EC2
ssh -i your-key.pem ubuntu@your-ec2-ip

# Navigate to project
cd ~/job-search-service

# Pull latest code
git pull origin main

# Rebuild and restart
docker-compose up -d --build

# View logs
docker-compose logs -f api
```

---

## Troubleshooting

### Services Won't Start

```bash
# Check logs
docker-compose logs

# Check individual service
docker-compose logs api
docker-compose logs ui
docker-compose logs qdrant

# Restart services
docker-compose restart
```

### API Returns 503 Errors

- Check if `AGENT_ENABLED=true` in `.env`
- If using OpenAI (recommended):
  - Verify `OPENAI_API_KEY` is set correctly in `.env`
  - Check API key is valid: Visit https://platform.openai.com/api-keys
  - Verify `LLM_PROVIDER=openai` in `.env`
- If using Ollama:
  - Verify Ollama is running: `docker ps | grep ollama`
  - Check if models are pulled: `docker exec rag-ollama ollama list`
  - Pull missing models: `docker exec rag-ollama ollama pull <model-name>`
- Check API logs: `docker-compose logs api`

### Qdrant Connection Issues

```bash
# Check Qdrant is running
docker ps | grep qdrant

# Check Qdrant logs
docker logs rag-qdrant

# Test connection
curl http://localhost:6333/health
```

### UI Can't Connect to API

- Verify `API_BASE_URL` in UI container points to `http://api:8000/api/v1`
- Check both services are on the same Docker network
- Verify API is accessible: `curl http://localhost:8000/api/v1/health`

### Out of Memory

If EC2 runs out of memory:
- Increase instance size (recommended: 8GB+ for Ollama)
- Use smaller Ollama models:
  - `llama2:7b` instead of `llama2`
  - `all-minilm:16-v2` for embeddings
- Or use Qdrant Cloud instead of containerized Qdrant
- Or use OpenAI/Azure for LLM (keeps embeddings on Ollama)

---

## Production Recommendations

1. **Use Qdrant Cloud** instead of containerized Qdrant for better reliability
2. **Use OpenAI/Azure embeddings** instead of Ollama for production
3. **Set up HTTPS** using nginx reverse proxy with Let's Encrypt
4. **Configure log rotation** for Docker containers
5. **Set up monitoring** (CloudWatch, Prometheus, etc.)
6. **Use secrets management** (AWS Secrets Manager) instead of `.env` file
7. **Enable auto-scaling** if traffic increases
8. **Set up automated backups** for Qdrant data

---

## Quick Reference Commands

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f

# Rebuild after code changes
docker-compose up -d --build

# Restart a specific service
docker-compose restart api

# Execute command in container
docker exec -it rag-api bash

# Check resource usage
docker stats

# Clean up unused images
docker system prune -a
```

---

## Access URLs

After deployment, your team can access:

- **Streamlit UI**: `http://your-ec2-public-ip:8501`
- **FastAPI API**: `http://your-ec2-public-ip:8000`
- **API Documentation**: `http://your-ec2-public-ip:8000/docs`
- **Health Check**: `http://your-ec2-public-ip:8000/api/v1/health`

Replace `your-ec2-public-ip` with your actual EC2 instance public IP address.

