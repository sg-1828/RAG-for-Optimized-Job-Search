# Resume Search Guide for Employers

## Overview

This guide explains how employers can search for candidate profiles using natural language queries and view complete resumes.

## Workflow

1. **Search for profiles** using natural language queries
2. **Review top matching resumes** with summary information
3. **Click on resume ID** to view complete resume details

---

## Step 1: Search for Profiles

Use the agent-enhanced resume search endpoint to find candidates matching your requirements.

### Endpoint
`POST /api/v1/search/resumes`

### Example Request

```bash
curl -X POST "http://localhost:8000/api/v1/search/resumes" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "python developer with AWS experience and 5+ years",
    "useAgent": true,
    "pageSize": 10,
    "includeExplanation": true
  }'
```

### Example Response

```json
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
      "score": 0.92,
      "highlights": [
        "Backend engineer with 6 years of experience in Python and AWS."
      ]
    },
    {
      "resumeId": "res_2",
      "candidateId": "cand_2",
      "name": "Bob Smith",
      "title": "Data Engineer",
      "location": "Remote",
      "skills": ["python", "spark", "airflow"],
      "yearsOfExperience": 4,
      "score": 0.88,
      "highlights": [
        "Data engineer focused on ETL pipelines and distributed systems."
      ]
    }
  ],
  "totalCount": 2,
  "page": 1,
  "pageSize": 10,
  "debug": {
    "explanation": "These candidates match because they have Python experience with relevant cloud and data engineering skills."
  }
}
```

### Key Points

- **resumeId**: Use this ID to retrieve the complete resume
- **score**: Relevance score (0.0 to 1.0, higher is better)
- **highlights**: Brief summary snippets
- Results are sorted by relevance (highest score first)

---

## Step 2: View Complete Resume

After identifying interesting candidates from the search results, retrieve the full resume details using the resume ID.

### Endpoint
`GET /api/v1/search/resumes/{resume_id}`

### Example Request

```bash
curl "http://localhost:8000/api/v1/search/resumes/res_1"
```

### Example Response

```json
{
  "resumeId": "res_1",
  "candidateId": "cand_1",
  "name": "Alice Johnson",
  "title": "Backend Engineer",
  "location": "NYC",
  "skills": ["python", "aws", "django", "postgresql", "docker"],
  "yearsOfExperience": 6,
  "industries": ["Financial Services", "Technology"],
  "fullText": "Backend engineer with 6 years of experience in Python and AWS. Expert in building scalable web applications using Django and FastAPI. Strong experience with cloud infrastructure on AWS, including EC2, S3, RDS, and Lambda. Proficient in containerization with Docker and orchestration with Kubernetes. Led a team of 3 developers in building a microservices architecture handling 1M+ requests per day. Experience with CI/CD pipelines, automated testing, and database optimization.",
  "metadata": {
    "email": "alice.johnson@example.com",
    "phone": "+1-555-0123"
  }
}
```

### Key Fields

- **fullText**: Complete resume content
- **skills**: All skills listed
- **industries**: Industry experience
- **metadata**: Additional candidate information (if available)

---

## Natural Language Query Examples

The agent can understand various natural language patterns:

### Skills-Based Queries
```
"python developer with AWS experience"
"senior engineer with Docker and Kubernetes"
"data scientist with machine learning background"
"frontend developer react typescript"
```

### Experience-Based Queries
```
"python developer with 5+ years experience"
"senior backend engineer 10 years"
"junior developer entry level"
```

### Location-Based Queries
```
"python developer in NYC"
"remote backend engineer"
"engineer in San Francisco or remote"
```

### Combined Queries
```
"senior python developer with AWS experience in NYC with 5+ years"
"data engineer with Spark and Airflow 3+ years remote"
"backend engineer docker kubernetes microservices"
```

---

## Complete Workflow Example

### Python Example

```python
import requests

BASE_URL = "http://localhost:8000/api/v1"

# Step 1: Search for candidates
search_response = requests.post(
    f"{BASE_URL}/search/resumes",
    json={
        "query": "python developer with AWS experience and 5+ years",
        "useAgent": True,
        "pageSize": 10,
        "includeExplanation": True
    }
)

search_data = search_response.json()

print(f"Found {search_data['totalCount']} matching candidates\n")

# Step 2: Display summary of top candidates
for i, candidate in enumerate(search_data['results'], 1):
    print(f"{i}. {candidate['name']} - {candidate['title']}")
    print(f"   Location: {candidate['location']}")
    print(f"   Experience: {candidate['yearsOfExperience']} years")
    print(f"   Skills: {', '.join(candidate['skills'])}")
    print(f"   Match Score: {candidate['score']:.2f}")
    print(f"   Resume ID: {candidate['resumeId']}")
    print(f"   Highlights: {candidate['highlights'][0] if candidate['highlights'] else 'N/A'}")
    print()

# Step 3: Get full resume for a specific candidate
resume_id = search_data['results'][0]['resumeId']  # Get first candidate
full_resume = requests.get(f"{BASE_URL}/search/resumes/{resume_id}")

resume_data = full_resume.json()
print(f"\n=== Full Resume: {resume_data['name']} ===\n")
print(f"Title: {resume_data['title']}")
print(f"Location: {resume_data['location']}")
print(f"Experience: {resume_data['yearsOfExperience']} years")
print(f"Skills: {', '.join(resume_data['skills'])}")
print(f"\nFull Text:\n{resume_data['fullText']}")
```

### cURL Example

```bash
# Step 1: Search
SEARCH_RESULT=$(curl -s -X POST "http://localhost:8000/api/v1/search/resumes" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "python developer with AWS experience",
    "useAgent": true,
    "pageSize": 10
  }')

# Extract first resume ID (using jq)
RESUME_ID=$(echo $SEARCH_RESULT | jq -r '.results[0].resumeId')

# Step 2: Get full resume
curl "http://localhost:8000/api/v1/search/resumes/$RESUME_ID"
```

---

## Response Format Details

### Search Results (Summary View)

Each result in the search response contains:
- `resumeId`: **Use this to get full resume**
- `candidateId`: Internal candidate identifier
- `name`: Candidate name
- `title`: Current/latest job title
- `location`: Candidate location
- `skills`: List of skills
- `yearsOfExperience`: Years of experience
- `score`: Relevance score (0.0-1.0)
- `highlights`: Brief text snippets

### Full Resume Details

The full resume endpoint returns:
- All summary fields (same as search results)
- `fullText`: **Complete resume text content**
- `industries`: Industry experience
- `metadata`: Additional information (email, phone, etc.)

---

## Tips for Best Results

1. **Be specific**: Include skills, experience level, and location
2. **Use natural language**: Write queries as you would describe the ideal candidate
3. **Top 10 by default**: Results are sorted by relevance, top 10 are most relevant
4. **Review scores**: Higher scores indicate better matches
5. **Check highlights**: Quick way to see why candidates matched
6. **View full resume**: Always check complete resume for comprehensive details

---

## Error Handling

### Resume Not Found
```json
{
  "detail": "Resume with ID 'res_999' not found"
}
```
**Solution**: Verify the resume ID exists in search results

### Agent Not Enabled
```json
{
  "detail": "Agent features are not enabled. Set AGENT_ENABLED=true and configure LLM provider."
}
```
**Solution**: Use standard endpoint `/api/v1/search/resumes` with explicit filters, or enable agent features

---

## Agent Features

All search endpoints use agent capabilities by default for intelligent query interpretation. The agent:
- Extracts filters (skills, experience, locations) from natural language
- Rewrites queries for better semantic search
- Provides explanations of search results (optional)

If agent features are not enabled, search endpoints will return an error. Ensure `AGENT_ENABLED=true` and LLM provider is configured.

---

## API Reference

### Search Resumes
- **POST** `/api/v1/search/resumes` - Natural language search with intelligent query interpretation

### Get Full Resume
- **GET** `/api/v1/search/resumes/{resume_id}` - Retrieve complete resume by ID

See `AGENT_FEATURES_GUIDE.md` for more details on agent capabilities.

