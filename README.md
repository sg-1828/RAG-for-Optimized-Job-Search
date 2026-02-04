# RAG-for-Optimized-Job-Search


# main two commands to start
PYTHONPATH=src uvicorn rag_service.main:app --reload --host 0.0.0.0 --port 8000
PYTHONPATH=src streamlit run src/rag_service/ui/app.py --server.port 8501 --server.headless true
# RAG Job & Resume Search Service
## Local Run & Test Guide

Semantic, typo‑tolerant **job and resume search API** built with FastAPI and a vector‑based retrieval pipeline. Uses **Qdrant** vector database (can be self-hosted or Qdrant Cloud). Data must be ingested via provided scripts before searching.

## Features

### Search Endpoints
- `POST /api/v1/search/jobs` – natural language job search with intelligent query interpretation
- `POST /api/v1/search/resumes` – natural language resume search with intelligent query interpretation
- `POST /api/v1/search/interpret` – interpret queries without executing search
- `GET /api/v1/search/resumes/{resume_id}` – get complete resume details by ID

### Admin & Health
- `GET /api/v1/admin/list` – list items from vector collections
- `DELETE /api/v1/admin/delete/{collection}/{item_id}` – delete items from collections
- `GET /api/v1/health` – health check endpoint

### Search Capabilities
- **BM25 keyword search** – improved lexical matching with term frequency saturation
- **Typo correction** – SymSpell-based spell checking for queries
- **Vector similarity search** – semantic search using Qdrant vector database
- **Hybrid search** – combines vector and keyword scoring for best results
- **Metadata filters** – location, skills, years of experience, industries, job family
- **Agent features** – natural language query interpretation and rewriting (required)

### Additional
- Streamlit UI for data visualization and management

---

## 1. Prerequisites

Install the following before proceeding:

- **Python 3.10+** (check with `python --version` or `python3 --version`)
- **Qdrant** - Vector database (self-hosted or cloud)
- **Ollama** - For embeddings (or configure OpenAI/Azure)
- **Git** (optional, for cloning)

---

## 2. Local Setup - Step by Step

### Step 1: Install Qdrant

#### Option A: Docker (Recommended)
```bash
docker pull qdrant/qdrant
docker run -p 6333:6333 -p 6334:6334 qdrant/qdrant
```

#### Option B: Qdrant Cloud
Sign up at https://cloud.qdrant.io and get your cluster URL and API key.

#### Verify Qdrant is Running
```bash
curl http://localhost:6333/health
# Should return: {"status":"ok"}
```

### Step 2: Install Ollama (for Embeddings)

Download and install from https://ollama.ai

```bash
# macOS/Linux
curl -fsSL https://ollama.ai/install.sh | sh

# Or download installer for your OS
```

Start Ollama:
```bash
ollama serve
```

Pull the embedding model:
```bash
ollama pull all-minilm:16-v2
```

Verify Ollama is running:
```bash
curl http://localhost:11434/api/tags
```

### Step 3: Clone and Setup Python Environment

```bash
# Clone repository
git clone <your-repo-url> job-search-service
cd job-search-service

# Create virtual environment
python3 -m venv .venv

# Activate virtual environment
# On macOS/Linux:
source .venv/bin/activate
# On Windows:
# .venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

### Step 4: Configure Environment Variables

Create a `.env` file in the project root:

```bash
# Create .env file
touch .env  # or: New-Item .env (Windows PowerShell)
```

Add the following to `.env`:

```bash
# Core Service Config
ENVIRONMENT=dev
API_PREFIX=/api/v1
VECTOR_TOP_K=20

# Qdrant Configuration (self-hosted)
QDRANT_HOST=localhost
QDRANT_PORT=6333

# OR if using Qdrant Cloud, use:
# QDRANT_URL=https://your-cluster.qdrant.io
# QDRANT_API_KEY=your-api-key

# Embedding Configuration (Ollama)
EMBEDDING_PROVIDER=ollama
EMBEDDING_DIM=768
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_EMBED_MODEL=all-minilm:16-v2

# Agent Configuration (Required)
AGENT_ENABLED=true
LLM_PROVIDER=openai
LLM_MODEL=gpt-3.5-turbo
OPENAI_API_KEY=sk-your-openai-api-key-here
LLM_TEMPERATURE=0.3
LLM_MAX_TOKENS=500

# Upload Mode (for UI file browsing)
# UPLOAD=local    # Browse files from local machine (default)
# UPLOAD=remote   # Browse files from EC2 server

# EC2 Connection (Required if UPLOAD=remote)
# EC2_HOST=ec2-xxx-xxx-xxx-xxx.compute-1.amazonaws.com
# EC2_USERNAME=ubuntu
# EC2_PORT=22
# EC2_KEY_PATH=~/.ssh/your-key.pem
# EC2_RESUME_FOLDER=/home/ubuntu/resumes
# OR use password instead of key:
# EC2_PASSWORD=your-password
```

**Note**: Replace `sk-your-openai-api-key-here` with your actual OpenAI API key. Get one from https://platform.openai.com/api-keys

**Alternative**: If using Ollama for LLM (local, free):
```bash
# Agent Configuration (Ollama - local)
AGENT_ENABLED=true
LLM_PROVIDER=ollama
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_LLM_MODEL=llama2
LLM_TEMPERATURE=0.3
LLM_MAX_TOKENS=500

# Pull the LLM model
ollama pull llama2
```

### Step 5: Start the Service

```bash
# Set PYTHONPATH (required)
export PYTHONPATH=src  # macOS/Linux
# Or on Windows PowerShell: $env:PYTHONPATH="src"

# Start the service
uvicorn rag_service.main:app --reload --host 0.0.0.0 --port 8000
```

You should see:
```
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
INFO:     Started reloader process
INFO:     Started server process
INFO:     Waiting for application startup.
INFO:     Application startup complete.
```

### Step 6: Verify Service is Running

In a new terminal window:

```bash
curl http://localhost:8000/api/v1/health
```

Expected response:
```json
{"status":"ok"}
```

### Step 7: Ingest Data

The service starts with an empty vector store. You need to ingest jobs and resumes before searching.

#### Ingest Jobs from Documents

```bash
# Ensure virtual environment is activated
source .venv/bin/activate  # or .venv\Scripts\activate on Windows

# Set PYTHONPATH
export PYTHONPATH=src  # or $env:PYTHONPATH="src" on Windows

# Run ingestion script
python -m rag_service.scripts.ingest_jobs_from_docs /path/to/job/documents/folder
```

The folder should contain PDF or DOCX files with job descriptions.

#### Ingest Resumes from PDFs

**Option 1: From Local Folder**

```bash
# Run ingestion script
python -m rag_service.scripts.ingest_resumes_from_pdfs --folder /path/to/resumes/folder
```

The folder should contain PDF files with resume content.

**Option 2: From EC2 Server**

Ingest resumes directly from an EC2 server by connecting via SSH:

**Step 1: Configure EC2 connection in `.env` file:**

```bash
# EC2 Connection Settings
EC2_HOST=ec2-xxx-xxx-xxx-xxx.compute-1.amazonaws.com
EC2_USERNAME=ubuntu
EC2_PORT=22
EC2_KEY_PATH=~/.ssh/your-key.pem
EC2_RESUME_FOLDER=/home/ubuntu/resumes
# OR use password instead of key:
# EC2_PASSWORD=your-password
```

**Step 2: Run ingestion from EC2:**

```bash
# Using settings from .env file
python -m rag_service.scripts.ingest_resumes_from_pdfs --ec2

# OR override settings via command line arguments:
python -m rag_service.scripts.ingest_resumes_from_pdfs --ec2 \
  --ec2-host ec2-xxx.compute.amazonaws.com \
  --ec2-username ubuntu \
  --ec2-key-path ~/.ssh/my-key.pem \
  --ec2-folder /home/ubuntu/resumes
```

The script will:
1. Connect to EC2 via SSH
2. List all PDF files in the specified remote folder
3. Download files to a temporary directory
4. Process and ingest them into Qdrant
5. Clean up temporary files

**Example**:
```bash
# Create test folders and add some documents
mkdir -p test_data/jobs test_data/resumes

# Add your PDF/DOCX files to these folders, then:
python -m rag_service.scripts.ingest_jobs_from_docs test_data/jobs
python -m rag_service.scripts.ingest_resumes_from_pdfs test_data/resumes
```

### Step 8: Test Search

After ingesting data, test the search:

```bash
# Test job search
curl -X POST "http://localhost:8000/api/v1/search/jobs" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "python developer",
    "useAgent": true,
    "pageSize": 10
  }'

# Test resume search
curl -X POST "http://localhost:8000/api/v1/search/resumes" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "python developer with AWS experience",
    "useAgent": true,
    "pageSize": 10
  }'
```

---

## 3. Quick Start Summary

For those familiar with the setup, here's the quick version:

```bash
# 1. Start Qdrant
docker run -p 6333:6333 qdrant/qdrant &

# 2. Start Ollama
ollama serve &
ollama pull all-minilm:16-v2
ollama pull llama2  # if using Ollama for LLM

# 3. Setup Python
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# 4. Create .env file with configuration (see Step 4 above)

# 5. Start service
export PYTHONPATH=src
uvicorn rag_service.main:app --reload --host 0.0.0.0 --port 8000

# 6. Ingest data (in another terminal)
export PYTHONPATH=src
python -m rag_service.scripts.ingest_jobs_from_docs /path/to/jobs
python -m rag_service.scripts.ingest_resumes_from_pdfs /path/to/resumes

# 7. Test
curl http://localhost:8000/api/v1/health
```

---

## 4. Project layout (relevant parts)

```
rag-search-service/
  ├── src/
  │   └── rag_service/
  │        ├── api/
  │        │   ├── routes_agent.py
  │        │   ├── routes_resumes.py
  │        │   ├── routes_health.py
  │        │   └── routes_admin.py
  │        ├── core/
  │        │   ├── query_pipeline.py
  │        │   ├── ranking.py
  │        │   ├── embeddings.py
  │        │   ├── bm25_scorer.py
  │        │   ├── llm_client.py
  │        │   └── query_agent.py
  │        ├── retrieval/
  │        │   ├── job_retriever.py
  │        │   └── resume_retriever.py
  │        ├── vectorstore/
  │        │   ├── client.py
  │        │   └── client_pg.py
  │        ├── models/
  │        │   ├── api_requests.py
  │        │   └── api_response.py
  │        ├── config/
  │        │   └── settings.py
  │        ├── utils/
  │        │   ├── text_normalization.py
  │        │   └── typo_correction.py
  │        │       (SymSpell-based spell checking)
  │        ├── ui/
  │        │   └── app.py
  │        ├── scripts/
  │        │   ├── ingest_jobs_from_docs.py
  │        │   └── ingest_resumes_from_pdfs.py
  │        └── main.py
  ├── tests/
  ├── pyproject.toml
  ├── requirements.txt
  └── Dockerfile
```

---

## 5. Run with Docker (optional)

Build image:

```
docker build -t rag-search-service:local .
```

Run container:

```
docker run -p 8000:8000 rag-search-service:local
```

Health check:

```
curl http://localhost:8000/api/v1/health
```

---

## 6. Job Search API

### 5.1 Endpoint

- `POST http://localhost:8000/api/v1/search/jobs`

### 5.2 Example request

Search using natural language queries - the agent automatically extracts filters:

```
curl -X POST "http://localhost:8000/api/v1/search/jobs" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "senior backend engineer python aws in nyc with 5+ years experience",
    "useAgent": true,
    "page": 1,
    "pageSize": 10,
    "includeDebug": true,
    "includeExplanation": true
  }'
```

The agent automatically extracts:
- Location: NYC
- Skills: python, aws
- Experience: 5+ years
- Job family: Engineering (inferred)

### 5.3 Example response shape

```
{
  "success": true,
  "results": [
    {
      "jobId": "job_1",
      "title": "Senior Backend Engineer",
      "company": "FinTech Corp",
      "location": "NYC",
      "skills": ["python", "aws", "postgresql"],
      "score": 0.92,
      "highlights": [
        "We are seeking a senior backend engineer with strong Python and AWS experience."
      ]
    }
  ],
  "totalCount": 1,
  "page": 1,
  "pageSize": 10,
  "debug": {
    "originalQuery": "senior backend engineer python aws in nyc with 5+ years experience",
    "interpretedQuery": "senior backend engineer python aws",
    "filtersExtracted": true,
    "agentEnabled": true,
    "interpretation": {
      "location": ["NYC"],
      "skills": ["python", "aws"],
      "minExperienceYears": 5,
      "confidence": 0.9
    },
    "explanation": "These results match because they include senior-level Python backend engineer positions in NYC with the required experience."
  }
}
```

---

## 7. Resume Search API

> **💡 For Employers**: See `RESUME_SEARCH_GUIDE.md` for complete workflow guide on searching profiles and viewing full resumes.

### 6.1 Endpoint

- `POST http://localhost:8000/api/v1/search/resumes`

### 6.2 Example request

Search using natural language - the agent automatically extracts filters:

```
curl -X POST "http://localhost:8000/api/v1/search/resumes" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "python developer with AWS experience and 5+ years in NYC or remote",
    "useAgent": true,
    "pageSize": 10,
    "includeDebug": true,
    "includeExplanation": true
  }'
```

The agent automatically extracts:
- Skills: python, AWS
- Experience: 5+ years
- Locations: NYC, Remote
- Industries: Technology (inferred)

### 6.3 Example response shape

```
{
  "success": true,
  "results": [
    {
      "resumeId": "res_1",
      "candidateId": "cand_1",
      "name": "Alice Johnson",
      "title": "Backend Engineer",
      "location": "NYC",
      "skills": ["python", "aws", "django"],
      "yearsOfExperience": 6,
      "score": 0.88,
      "highlights": [
        "Backend engineer with 6 years of experience in Python and AWS."
      ]
    }
  ],
  "totalCount": 1,
  "page": 1,
  "pageSize": 10,
  "debug": {
    "originalQuery": "python developer with AWS experience and 5+ years in NYC or remote",
    "interpretedQuery": "python developer AWS experience",
    "filtersExtracted": true,
    "agentEnabled": true,
    "interpretation": {
      "locations": ["NYC", "Remote"],
      "skills": ["python", "AWS"],
      "minYearsExperience": 5,
      "confidence": 0.85
    },
    "explanation": "These candidates match because they have Python experience with AWS and meet the experience requirements."
  }
}
```

### 6.4 Get Complete Resume by ID

After searching, retrieve the full resume details using the resume ID:

```
GET /api/v1/search/resumes/{resume_id}
```

Example:
```
curl "http://localhost:8000/api/v1/search/resumes/res_1"
```

Response:
```json
{
  "resumeId": "res_1",
  "candidateId": "cand_1",
  "name": "Alice Johnson",
  "title": "Backend Engineer",
  "location": "NYC",
  "skills": ["python", "aws", "django"],
  "yearsOfExperience": 6,
  "industries": ["Financial Services"],
  "fullText": "Complete resume text content...",
  "metadata": {}
}
```

**Note**: Use the `resumeId` from search results to retrieve the complete resume with full text.

> **📖 See `RESUME_SEARCH_GUIDE.md` for complete workflow guide for employers.**

---

## 8. Admin Endpoints

### 7.1 List items in a collection

```
curl "http://localhost:8000/api/v1/admin/list?collection=job_chunks&offset=0&limit=20"
```

Response:
```
{
  "items": [
    {
      "id": "job_1",
      "preview": "We are seeking a senior backend engineer...",
      "payload": { ... }
    }
  ],
  "total": 2
}
```

### 7.2 Delete an item

```
curl -X DELETE "http://localhost:8000/api/v1/admin/delete/job_chunks/job_1"
```

---

## 9. Running tests

With **pytest** installed:

```
pytest
```

You can create tests for:

- `tests/test_health.py` – checks `/api/v1/health` returns 200 and `{ "status": "ok" }`
- `tests/test_job_search.py` – job search happy/negative paths  
- `tests/test_resume_search.py` – resume search filters and scoring
- `tests/test_admin.py` – admin endpoints functionality

---

## 10. Configuration

Config is handled via Pydantic settings in `rag_service/config/settings.py`.

Key settings:

- `environment` – environment name (`dev`, `staging`, `prod`)
- `api_prefix` – API prefix (default: `/api/v1`)
- `vector_top_k` – number of nearest neighbors retrieved before filtering

### Qdrant Configuration

Override via environment variables:

```
# For Qdrant Cloud
QDRANT_URL=https://your-cluster.qdrant.io
QDRANT_API_KEY=your-api-key

# OR for self-hosted Qdrant
QDRANT_HOST=localhost
QDRANT_PORT=6333

# Embedding configuration
EMBEDDING_PROVIDER=ollama
EMBEDDING_DIM=768
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_EMBED_MODEL=all-minilm:16-v2
```

### Agent Configuration (Required)

Agent features are **required** for search functionality. Configure LLM provider for natural language query interpretation:

```bash
# Enable agent
AGENT_ENABLED=true

# Choose LLM provider (one of: openai, azure, ollama)
LLM_PROVIDER=openai
LLM_MODEL=gpt-3.5-turbo

# OpenAI configuration
OPENAI_API_KEY=sk-...
OPENAI_BASE_URL=https://api.openai.com/v1

# OR Azure OpenAI
# LLM_PROVIDER=azure
# AZURE_OPENAI_API_KEY=...
# AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com
# AZURE_OPENAI_API_VERSION=2024-02-15-preview

# OR Ollama (local)
# LLM_PROVIDER=ollama
# OLLAMA_BASE_URL=http://localhost:11434
# OLLAMA_LLM_MODEL=llama2
```

See `AGENT_CONFIGURATION.md` for detailed configuration requirements, or `AGENT_FEATURES_GUIDE.md` for usage guide.

### Complete .env Example

Create a `.env` file in the project root:

```
ENVIRONMENT=dev
VECTOR_TOP_K=20
QDRANT_HOST=localhost
QDRANT_PORT=6333

# Embedding Configuration (Ollama example)
EMBEDDING_PROVIDER=ollama
EMBEDDING_DIM=768
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_EMBED_MODEL=all-minilm:16-v2

# Agent Configuration (Required for search)
AGENT_ENABLED=true
LLM_PROVIDER=openai
OPENAI_API_KEY=sk-your-key-here
LLM_MODEL=gpt-3.5-turbo
LLM_TEMPERATURE=0.3
LLM_MAX_TOKENS=500
```

---

## 11. Agent Features (Required)

The service uses agent capabilities for intelligent query interpretation and rewriting. All search endpoints use natural language understanding by default.

### Quick Start

```bash
# Enable agent features (required for search)
export AGENT_ENABLED=true
export LLM_PROVIDER=openai
export OPENAI_API_KEY=sk-...

# Natural language job search
curl -X POST "http://localhost:8000/api/v1/search/jobs" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "senior python developer in NYC with 5+ years experience",
    "useAgent": true,
    "includeExplanation": true
  }'

# Natural language resume search
curl -X POST "http://localhost:8000/api/v1/search/resumes" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "python developer with AWS experience and 5+ years",
    "useAgent": true,
    "pageSize": 10
  }'
```

**Note**: Agent features are required for search functionality. 

For detailed configuration, see `AGENT_CONFIGURATION.md`.  
For usage examples and API details, see `AGENT_FEATURES_GUIDE.md`.  
For employer workflow guide, see `RESUME_SEARCH_GUIDE.md`.

---

## 12. Troubleshooting

### Service won't start

**Error**: `ModuleNotFoundError` or import errors
- **Solution**: Ensure `PYTHONPATH=src` is set before starting

**Error**: `503 Service Unavailable` on search endpoints
- **Solution**: Agent is not configured. Check:
  - `AGENT_ENABLED=true` in `.env`
  - LLM provider is configured (OpenAI API key, or Ollama running)
  - See `AGENT_CONFIGURATION.md` for details

### Qdrant connection errors

**Error**: Cannot connect to Qdrant
- **Solution**: 
  - Ensure Qdrant is running: `curl http://localhost:6333/health`
  - Check `QDRANT_HOST` and `QDRANT_PORT` in `.env`
  - For Qdrant Cloud, verify `QDRANT_URL` and `QDRANT_API_KEY`

### Ollama connection errors

**Error**: Cannot connect to Ollama
- **Solution**:
  - Ensure Ollama is running: `curl http://localhost:11434/api/tags`
  - Check `OLLAMA_BASE_URL` in `.env`
  - Verify embedding model is pulled: `ollama pull all-minilm:16-v2`

### No search results

**Issue**: Search returns empty results
- **Solution**: 
  - Verify data has been ingested (check with admin endpoints)
  - Ensure embedding provider is working
  - Check vector store has data: `curl "http://localhost:8000/api/v1/admin/list?collection=job_chunks"`

---

## 13. Roadmap (local → production)

The current service uses:

- Ollama embeddings (configurable via `EMBEDDING_PROVIDER`)
- Qdrant vector database (can be self-hosted or Qdrant Cloud)

To evolve to production:

- Configure Qdrant Cloud or scale self-hosted Qdrant for production workloads
- Consider alternative embedding providers (OpenAI, Azure OpenAI) for production
- Add authentication and authorization for admin endpoints
- Set up proper logging and monitoring
- Add database persistence for job and resume metadata
- Fine-tune LLM prompts for better query interpretation accuracy
- Add query caching to reduce LLM API costs
- Implement batch ingestion API endpoints

The external API contracts (`/api/v1/search/jobs`, `/api/v1/search/resumes`, `/api/v1/admin/*`) can remain stable while the internals are upgraded.
