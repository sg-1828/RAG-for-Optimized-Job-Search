# Quick Deployment Guide

## TL;DR - Deploy to EC2 in 5 Steps

### 1. Prepare EC2 Instance

```bash
# SSH into EC2
ssh -i your-key.pem ubuntu@your-ec2-ip

# Install Docker & Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
exit  # Log out and back in
```

### 2. Clone Repository

```bash
git clone https://github.com/your-username/your-repo-name.git job-search-service
cd job-search-service
```

### 3. Configure Environment

```bash
# Copy example env file
cp .env.example .env

# Edit with your values
nano .env
```

**Minimum required in `.env` (for OpenAI setup - recommended):**
```bash
AGENT_ENABLED=true
LLM_PROVIDER=openai
LLM_MODEL=gpt-3.5-turbo
OPENAI_API_KEY=sk-your-openai-api-key-here
EMBEDDING_PROVIDER=ollama
OLLAMA_EMBED_MODEL=all-minilm:16-v2
```

**Note:** Get your OpenAI API key from https://platform.openai.com/api-keys

### 4. Deploy

```bash
# Make scripts executable
chmod +x deploy.sh

# Run deployment
./deploy.sh
```

**Note:** If using Ollama for embeddings, you may need to run `./setup-ollama.sh` after deployment.

### 5. Access Services

- **UI**: `http://your-ec2-ip:8501`
- **API**: `http://your-ec2-ip:8000`
- **API Docs**: `http://your-ec2-ip:8000/docs`

---

## Update After Code Changes

```bash
cd ~/job-search-service
./update.sh
```

---

## Manual Deployment (Alternative)

```bash
# Build and start
docker-compose up -d --build

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```

---

## Troubleshooting

**Services won't start?**
```bash
docker-compose logs
```

**API returns 503?**
- Check `AGENT_ENABLED=true` in `.env`
- If using OpenAI (recommended):
  - Verify `OPENAI_API_KEY` is set correctly in `.env`
  - Check API key is valid at https://platform.openai.com/api-keys
- If using Ollama:
  - Verify Ollama is running: `docker ps | grep ollama`
  - Check models are installed: `docker exec rag-ollama ollama list`
  - Pull missing models: `./setup-ollama.sh`

**Can't access from browser?**
- Check EC2 security group allows ports 8000 and 8501
- Verify services are running: `docker-compose ps`

For detailed instructions, see:
- [DEPLOYMENT.md](./DEPLOYMENT.md) - Full deployment guide
- [OLLAMA_SETUP.md](./OLLAMA_SETUP.md) - Ollama configuration and model selection

