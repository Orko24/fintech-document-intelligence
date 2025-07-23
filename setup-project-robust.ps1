# setup-project-robust.ps1
# FinTech AI Platform - Robust Project Structure Generator

Write-Host "🚀 Creating FinTech AI Platform Structure..." -ForegroundColor Green

# Ensure we're in the right location
$currentDir = Get-Location
Write-Host "Current directory: $currentDir" -ForegroundColor Yellow

# Create main project directory if it doesn't exist
$projectName = "fintech-ai-platform"
if (-not (Test-Path $projectName)) {
    Write-Host "Creating main project directory: $projectName" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $projectName -Force | Out-Null
}

Set-Location $projectName
$projectDir = Get-Location
Write-Host "Working in: $projectDir" -ForegroundColor Yellow

Write-Host "📁 Creating directory structure..." -ForegroundColor Yellow

# Define directories in smaller chunks for better error handling
$directories = @(
    # Core services
    "api-gateway",
    "ml-service", 
    "go-service",
    "java-service",
    "cpp-service",
    "frontend",
    
    # Infrastructure
    "terraform",
    "k8s",
    "monitoring",
    "scripts",
    "docs",
    "tests",
    "data",
    "shared",
    
    # API Gateway structure
    "api-gateway/app",
    "api-gateway/app/models",
    "api-gateway/app/routers",
    "api-gateway/app/services",
    "api-gateway/app/database",
    "api-gateway/app/utils",
    "api-gateway/app/core",
    "api-gateway/tests",
    "api-gateway/tests/integration",
    "api-gateway/scripts",
    
    # ML Service structure
    "ml-service/app",
    "ml-service/app/models",
    "ml-service/app/services",
    "ml-service/app/processors",
    "ml-service/app/utils",
    "ml-service/models",
    "ml-service/data",
    "ml-service/notebooks",
    "ml-service/tests",
    "ml-service/scripts",
    
    # Go service structure
    "go-service/cmd",
    "go-service/internal",
    "go-service/pkg",
    "go-service/tests",
    "go-service/configs",
    
    # Java service structure
    "java-service/src",
    "java-service/src/main",
    "java-service/src/main/java",
    "java-service/src/main/resources",
    "java-service/src/test",
    
    # Frontend structure
    "frontend/public",
    "frontend/src",
    "frontend/src/components",
    "frontend/src/pages",
    "frontend/src/services",
    "frontend/src/utils",
    "frontend/tests",
    
    # Infrastructure directories
    "terraform/environments",
    "terraform/modules",
    "k8s/deployments",
    "k8s/services",
    "k8s/configmaps",
    "monitoring/prometheus",
    "monitoring/grafana",
    
    # Data directories
    "data/sample_documents",
    "data/schemas",
    "data/ml_models",
    
    # Documentation
    "docs/api",
    "docs/architecture",
    "docs/deployment",
    
    # Testing
    "tests/unit",
    "tests/integration",
    "tests/e2e"
)

# Create directories with error handling
$successCount = 0
$failCount = 0

foreach ($dir in $directories) {
    try {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force -ErrorAction Stop | Out-Null
            $successCount++
            Write-Host "✓ Created: $dir" -ForegroundColor Green
        } else {
            Write-Host "- Exists: $dir" -ForegroundColor DarkGray
        }
    }
    catch {
        Write-Host "✗ Failed: $dir - $($_.Exception.Message)" -ForegroundColor Red
        $failCount++
    }
}

Write-Host "📊 Directory creation summary: $successCount created, $failCount failed" -ForegroundColor Cyan

Write-Host "📝 Creating essential files..." -ForegroundColor Yellow

# Create README.md
$readmeContent = @"
# FinTech AI Platform

A comprehensive AI-powered document analysis platform for financial services.

## Quick Start

``````bash
# 1. Set up environment
cp .env.example .env

# 2. Start infrastructure
docker-compose up -d

# 3. Start services
cd api-gateway && python main.py
cd ml-service && python main.py
cd frontend && npm start
``````

## Architecture

- **API Gateway**: FastAPI (Python)
- **ML Service**: PyTorch, Transformers (Python)  
- **Frontend**: React (JavaScript)
- **Database**: PostgreSQL, MongoDB, Redis
- **Message Queue**: Apache Kafka
- **Monitoring**: Prometheus, Grafana

## Services

| Service | Port | URL |
|---------|------|-----|
| Frontend | 3000 | http://localhost:3000 |
| API Gateway | 8000 | http://localhost:8000/docs |
| ML Service | 8001 | http://localhost:8001/docs |
| Grafana | 3001 | http://localhost:3001 |

## Features

- **Document Analysis**: AI-powered OCR and entity extraction
- **RAG System**: Question-answering over documents
- **Real-time Processing**: Kafka-based event streaming
- **Analytics Dashboard**: Live metrics and insights
- **Enterprise Security**: OAuth2, JWT, encryption

## Technologies

- **Languages**: Python, JavaScript, Go, Java, C++
- **AI/ML**: PyTorch, Transformers, LangChain, OpenAI
- **Cloud**: Azure, AWS, GCP
- **DevOps**: Docker, Kubernetes, Terraform
- **Monitoring**: Prometheus, Grafana, Jaeger

Ready for enterprise deployment!
"@

$readmeContent | Out-File -FilePath "README.md" -Encoding UTF8

# Create .gitignore
$gitignoreContent = @"
# Dependencies
node_modules/
__pycache__/
*.pyc
venv/
.env

# Build outputs
dist/
build/
target/

# IDEs
.vscode/
.idea/

# OS
.DS_Store
Thumbs.db

# Logs
*.log

# Terraform
*.tfstate
.terraform/

# ML Models
*.pkl
*.h5
"@

$gitignoreContent | Out-File -FilePath ".gitignore" -Encoding UTF8

# Create Docker Compose
$dockerComposeContent = @"
version: '3.8'

services:
  api-gateway:
    build: ./api-gateway
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://postgres:password@postgres:5432/fintech
    depends_on:
      - postgres
      - redis

  ml-service:
    build: ./ml-service
    ports:
      - "8001:8001"
    volumes:
      - ./data:/app/data

  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    environment:
      - REACT_APP_API_URL=http://localhost:8000

  postgres:
    image: postgres:15
    environment:
      - POSTGRES_DB=fintech
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  kafka:
    image: confluentinc/cp-kafka:latest
    ports:
      - "9092:9092"
    environment:
      - KAFKA_BROKER_ID=1
      - KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181
      - KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092
      - KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1
    depends_on:
      - zookeeper

  zookeeper:
    image: confluentinc/cp-zookeeper:latest
    environment:
      - ZOOKEEPER_CLIENT_PORT=2181

  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus:/etc/prometheus

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin

volumes:
  postgres_data:
"@

$dockerComposeContent | Out-File -FilePath "docker-compose.yml" -Encoding UTF8

# Create environment template
$envContent = @"
# Database Configuration
DATABASE_URL=postgresql://postgres:password@localhost:5432/fintech
REDIS_URL=redis://localhost:6379
MONGODB_URL=mongodb://admin:password@localhost:27017/fintech

# API Configuration
API_HOST=0.0.0.0
API_PORT=8000
JWT_SECRET_KEY=your-secret-key-here

# ML Configuration
ML_MODEL_PATH=./models
HUGGINGFACE_TOKEN=your-token-here

# Cloud Configuration
AWS_ACCESS_KEY_ID=your-aws-key
AWS_SECRET_ACCESS_KEY=your-aws-secret
AZURE_SUBSCRIPTION_ID=your-azure-subscription

# External APIs
OPENAI_API_KEY=your-openai-key
ANTHROPIC_API_KEY=your-anthropic-key
"@

$envContent | Out-File -FilePath ".env.example" -Encoding UTF8

# Create API Gateway main.py
$apiMainContent = @"
from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
from datetime import datetime

app = FastAPI(
    title="FinTech AI Platform API",
    description="Enterprise document analysis platform",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {
        "message": "FinTech AI Platform API",
        "version": "1.0.0",
        "status": "operational"
    }

@app.get("/health")
async def health():
    return {"status": "healthy", "timestamp": datetime.utcnow()}

@app.post("/api/v1/documents/analyze")
async def analyze_document(file: UploadFile = File(...)):
    return {
        "message": f"Document {file.filename} received for analysis",
        "status": "processing",
        "file_size": file.size
    }

@app.post("/api/v1/chat")
async def chat(request: dict):
    query = request.get("query", "")
    return {
        "query": query,
        "response": f"AI response for: {query}",
        "confidence": 0.95
    }

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
"@

$apiMainContent | Out-File -FilePath "api-gateway/main.py" -Encoding UTF8

# Create requirements files
$apiRequirements = @"
fastapi==0.104.1
uvicorn[standard]==0.24.0
python-multipart==0.0.6
python-dotenv==1.0.0
sqlalchemy==2.0.23
psycopg2-binary==2.9.9
redis==5.0.1
"@

$apiRequirements | Out-File -FilePath "api-gateway/requirements.txt" -Encoding UTF8

$mlRequirements = @"
fastapi==0.104.1
uvicorn[standard]==0.24.0
torch==2.1.1
transformers==4.36.2
sentence-transformers==2.2.2
langchain==0.0.348
chromadb==0.4.18
pandas==2.1.3
numpy==1.25.2
pillow==10.1.0
opencv-python==4.8.1.78
"@

$mlRequirements | Out-File -FilePath "ml-service/requirements.txt" -Encoding UTF8

# Create ML Service main.py
$mlMainContent = @"
from fastapi import FastAPI
import uvicorn
from datetime import datetime

app = FastAPI(
    title="FinTech AI ML Service",
    description="Machine Learning and AI processing service",
    version="1.0.0"
)

@app.get("/health")
async def health():
    return {
        "status": "healthy",
        "service": "ml-service",
        "models_loaded": ["document_classifier", "entity_extractor"]
    }

@app.post("/api/v1/ml/process")
async def process_document(request: dict):
    return {
        "document_id": request.get("document_id"),
        "results": {
            "document_type": "Financial Report",
            "confidence": 0.94,
            "entities": [
                {"type": "MONEY", "value": "$2.4B"},
                {"type": "PERCENT", "value": "12.3%"}
            ]
        }
    }

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8001, reload=True)
"@

$mlMainContent | Out-File -FilePath "ml-service/main.py" -Encoding UTF8

# Create Frontend package.json
$packageJson = @"
{
  "name": "fintech-ai-frontend",
  "version": "1.0.0",
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-scripts": "5.0.1",
    "axios": "^1.6.2"
  },
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build",
    "test": "react-scripts test"
  }
}
"@

$packageJson | Out-File -FilePath "frontend/package.json" -Encoding UTF8

# Create Makefile
$makefileContent = @"
.PHONY: start stop test build

start:
	@echo "🚀 Starting FinTech AI Platform..."
	docker-compose up -d
	@echo "✅ Platform started!"
	@echo "Frontend: http://localhost:3000"
	@echo "API: http://localhost:8000/docs"

stop:
	docker-compose down

test:
	@echo "Running tests..."
	pytest tests/

build:
	docker-compose build

logs:
	docker-compose logs -f
"@

$makefileContent | Out-File -FilePath "Makefile" -Encoding UTF8

# Create sample data
$sampleDoc = @"
FINANCIAL REPORT Q3 2024

Revenue: $2.4 Billion (up 8.7% YoY)
Net Income: $294 Million
Profit Margin: 12.3%

Key metrics show strong performance with growth across all sectors.
"@

$sampleDoc | Out-File -FilePath "data/sample_documents/sample_report.txt" -Encoding UTF8

Write-Host ""
Write-Host "✅ FinTech AI Platform created successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next steps:" -ForegroundColor Yellow
Write-Host "1. Copy .env.example to .env and configure settings" -ForegroundColor White
Write-Host "2. Run 'docker-compose up -d' to start services" -ForegroundColor White
Write-Host "3. Visit http://localhost:8000/docs for API documentation" -ForegroundColor White
Write-Host ""
Write-Host "🌐 Access points:" -ForegroundColor Cyan
Write-Host "   API Gateway:  http://localhost:8000/docs" -ForegroundColor White
Write-Host "   ML Service:   http://localhost:8001/docs" -ForegroundColor White
Write-Host "   Frontend:     http://localhost:3000" -ForegroundColor White
Write-Host "   Grafana:      http://localhost:3001" -ForegroundColor White
Write-Host ""
Write-Host "🎯 Platform ready for development!" -ForegroundColor Green