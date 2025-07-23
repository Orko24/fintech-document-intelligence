# setup-simple.ps1
Write-Host "🚀 Creating FinTech AI Platform..." -ForegroundColor Green

# Create main directories
$dirs = @(
    "api-gateway",
    "ml-service",
    "frontend", 
    "go-service",
    "java-service",
    "data",
    "docs",
    "tests",
    "terraform",
    "k8s",
    "monitoring"
)

Write-Host "📁 Creating main directories..." -ForegroundColor Yellow
foreach ($dir in $dirs) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force
        Write-Host "✓ Created $dir" -ForegroundColor Green
    }
}

# Create subdirectories
Write-Host "📁 Creating subdirectories..." -ForegroundColor Yellow

# API Gateway
New-Item -ItemType Directory -Path "api-gateway/app" -Force
New-Item -ItemType Directory -Path "api-gateway/tests" -Force

# ML Service  
New-Item -ItemType Directory -Path "ml-service/app" -Force
New-Item -ItemType Directory -Path "ml-service/models" -Force
New-Item -ItemType Directory -Path "ml-service/tests" -Force

# Frontend
New-Item -ItemType Directory -Path "frontend/src" -Force
New-Item -ItemType Directory -Path "frontend/public" -Force

# Data
New-Item -ItemType Directory -Path "data/sample_documents" -Force

Write-Host "📝 Creating files..." -ForegroundColor Yellow

# Create README.md
@"
# FinTech AI Platform

Enterprise document analysis platform with AI/ML capabilities.

## Quick Start

1. Copy .env.example to .env
2. Run: docker-compose up -d
3. Visit: http://localhost:8000/docs

## Services

- API Gateway: http://localhost:8000
- ML Service: http://localhost:8001  
- Frontend: http://localhost:3000
- Grafana: http://localhost:3001

## Technologies

- Python (FastAPI, PyTorch, Transformers)
- React (Frontend)
- PostgreSQL, Redis, Kafka
- Docker, Kubernetes
- Prometheus, Grafana

Ready for enterprise deployment!
"@ | Out-File -FilePath "README.md" -Encoding UTF8

# Create .gitignore
@"
node_modules/
__pycache__/
*.pyc
venv/
.env
dist/
build/
*.log
.DS_Store
*.tfstate
.terraform/
"@ | Out-File -FilePath ".gitignore" -Encoding UTF8

# Create docker-compose.yml
@"
version: '3.8'
services:
  api-gateway:
    build: ./api-gateway
    ports:
      - "8000:8000"
    depends_on:
      - postgres
      - redis

  ml-service:
    build: ./ml-service
    ports:
      - "8001:8001"

  frontend:
    build: ./frontend
    ports:
      - "3000:3000"

  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: fintech
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3001:3000"
    environment:
      GF_SECURITY_ADMIN_PASSWORD: admin

volumes:
  postgres_data:
"@ | Out-File -FilePath "docker-compose.yml" -Encoding UTF8

# Create .env.example
@"
DATABASE_URL=postgresql://postgres:password@localhost:5432/fintech
REDIS_URL=redis://localhost:6379
JWT_SECRET_KEY=your-secret-key
OPENAI_API_KEY=your-openai-key
"@ | Out-File -FilePath ".env.example" -Encoding UTF8

# Create API Gateway files
@"
from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

app = FastAPI(title="FinTech AI Platform API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def root():
    return {"message": "FinTech AI Platform API", "status": "operational"}

@app.get("/health")
def health():
    return {"status": "healthy"}

@app.post("/api/v1/documents/analyze")
def analyze_document(file: UploadFile = File(...)):
    return {"message": f"Processing {file.filename}", "status": "queued"}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
"@ | Out-File -FilePath "api-gateway/main.py" -Encoding UTF8

@"
fastapi==0.104.1
uvicorn[standard]==0.24.0
python-multipart==0.0.6
python-dotenv==1.0.0
"@ | Out-File -FilePath "api-gateway/requirements.txt" -Encoding UTF8

# Create ML Service files
@"
from fastapi import FastAPI
import uvicorn

app = FastAPI(title="FinTech AI ML Service", version="1.0.0")

@app.get("/health")
def health():
    return {"status": "healthy", "service": "ml-service"}

@app.post("/api/v1/ml/process")
def process_document(request: dict):
    return {"status": "processed", "confidence": 0.95}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8001, reload=True)
"@ | Out-File -FilePath "ml-service/main.py" -Encoding UTF8

@"
fastapi==0.104.1
uvicorn[standard]==0.24.0
torch==2.1.1
transformers==4.36.2
"@ | Out-File -FilePath "ml-service/requirements.txt" -Encoding UTF8

# Create Dockerfiles
@"
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
EXPOSE 8000
CMD ["python", "main.py"]
"@ | Out-File -FilePath "api-gateway/Dockerfile" -Encoding UTF8

@"
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
EXPOSE 8001
CMD ["python", "main.py"]
"@ | Out-File -FilePath "ml-service/Dockerfile" -Encoding UTF8

# Create sample data
@"
FINANCIAL REPORT Q3 2024
Revenue: $2.4B (up 8.7% YoY)
Net Income: $294M
Profit Margin: 12.3%
"@ | Out-File -FilePath "data/sample_documents/sample_report.txt" -Encoding UTF8

Write-Host ""
Write-Host "✅ FinTech AI Platform created successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. cp .env.example .env" -ForegroundColor White
Write-Host "2. docker-compose up -d" -ForegroundColor White
Write-Host ""
Write-Host "Access points:" -ForegroundColor Cyan
Write-Host "- API: http://localhost:8000/docs" -ForegroundColor White
Write-Host "- Frontend: http://localhost:3000" -ForegroundColor White
Write-Host "- Grafana: http://localhost:3001" -ForegroundColor White
Write-Host ""
Write-Host "🎯 Ready to go!" -ForegroundColor Green