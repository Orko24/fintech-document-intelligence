# 🔌 FinTech AI Platform API Documentation

## 📋 Table of Contents
- [Overview](#overview)
- [Authentication](#authentication)
- [Base URLs](#base-urls)
- [API Endpoints](#api-endpoints)
- [Data Models](#data-models)
- [Error Handling](#error-handling)
- [Rate Limiting](#rate-limiting)
- [Examples](#examples)
- [SDKs & Libraries](#sdks--libraries)

## 🌟 Overview

The FinTech AI Platform API provides enterprise-grade document intelligence capabilities for financial institutions. This RESTful API enables you to:

- **Upload and analyze** financial documents (PDFs, Word docs, Excel files)
- **Extract key information** including financial metrics, risks, and insights
- **Query documents** using natural language (RAG system)
- **Monitor processing** status and results
- **Manage users** and access controls

### **API Versioning**
- **Current Version**: `v1`
- **Base URL**: `https://api.fintech-ai-platform.com/v1`
- **Format**: JSON
- **Encoding**: UTF-8

## 🔐 Authentication

The API uses **JWT (JSON Web Tokens)** for authentication.

### **Getting an Access Token**

```bash
curl -X POST "https://api.fintech-ai-platform.com/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "your_username",
    "password": "your_password"
  }'
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 3600,
  "refresh_token": "refresh_token_here"
}
```

### **Using the Access Token**

Include the token in the `Authorization` header:

```bash
curl -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  https://api.fintech-ai-platform.com/v1/documents
```

## 🌐 Base URLs

| Environment | Base URL | Description |
|-------------|----------|-------------|
| Production | `https://api.fintech-ai-platform.com/v1` | Live production API |
| Staging | `https://staging-api.fintech-ai-platform.com/v1` | Pre-production testing |
| Development | `http://localhost:8000/v1` | Local development |

## 🔗 API Endpoints

### **Document Management**

#### **Upload Document**
```http
POST /documents/upload
```

**Description:** Upload a financial document for analysis.

**Request:**
```bash
curl -X POST "https://api.fintech-ai-platform.com/v1/documents/upload" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@earnings_report.pdf" \
  -F "metadata={\"document_type\":\"earnings_report\",\"company\":\"AAPL\"}"
```

**Response:**
```json
{
  "document_id": "doc_abc123",
  "status": "uploaded",
  "filename": "earnings_report.pdf",
  "file_size": 2048576,
  "uploaded_at": "2024-01-15T10:30:00Z",
  "estimated_processing_time": 30
}
```

#### **Analyze Document**
```http
POST /documents/{document_id}/analyze
```

**Description:** Trigger AI analysis of an uploaded document.

**Request:**
```bash
curl -X POST "https://api.fintech-ai-platform.com/v1/documents/doc_abc123/analyze" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "analysis_type": "comprehensive",
    "extract_entities": true,
    "sentiment_analysis": true,
    "risk_assessment": true
  }'
```

**Response:**
```json
{
  "analysis_id": "analysis_xyz789",
  "status": "processing",
  "estimated_completion": "2024-01-15T10:35:00Z"
}
```

#### **Get Analysis Results**
```http
GET /documents/{document_id}/analysis/{analysis_id}
```

**Description:** Retrieve analysis results for a document.

**Response:**
```json
{
  "analysis_id": "analysis_xyz789",
  "status": "completed",
  "completed_at": "2024-01-15T10:32:15Z",
  "results": {
    "confidence_score": 0.94,
    "extracted_entities": [
      {
        "type": "financial_metric",
        "value": "89.5B",
        "label": "Revenue",
        "confidence": 0.98
      },
      {
        "type": "company",
        "value": "Apple Inc.",
        "label": "Company Name",
        "confidence": 0.99
      }
    ],
    "sentiment": {
      "overall": "positive",
      "score": 0.75,
      "key_phrases": ["strong growth", "record revenue"]
    },
    "risk_assessment": {
      "overall_risk": "LOW",
      "risk_factors": [
        {
          "factor": "supply_chain",
          "severity": "MEDIUM",
          "description": "Potential supply chain disruptions"
        }
      ]
    },
    "summary": "Apple reported strong Q3 results with record revenue of $89.5B...",
    "key_insights": [
      "Revenue growth of 8% year-over-year",
      "Services segment showing strong momentum",
      "iPhone sales declined but offset by services"
    ]
  }
}
```

#### **List Documents**
```http
GET /documents
```

**Query Parameters:**
- `page` (int): Page number (default: 1)
- `limit` (int): Items per page (default: 20, max: 100)
- `status` (string): Filter by status (uploaded, processing, completed, failed)
- `document_type` (string): Filter by document type
- `date_from` (string): Filter from date (ISO 8601)
- `date_to` (string): Filter to date (ISO 8601)

**Response:**
```json
{
  "documents": [
    {
      "document_id": "doc_abc123",
      "filename": "earnings_report.pdf",
      "status": "completed",
      "document_type": "earnings_report",
      "uploaded_at": "2024-01-15T10:30:00Z",
      "file_size": 2048576,
      "analysis_count": 1
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 150,
    "pages": 8
  }
}
```

### **Query System (RAG)**

#### **Ask Question**
```http
POST /query/ask
```

**Description:** Ask natural language questions about uploaded documents.

**Request:**
```bash
curl -X POST "https://api.fintech-ai-platform.com/v1/query/ask" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "question": "What was Apple revenue in Q3?",
    "document_ids": ["doc_abc123"],
    "include_sources": true,
    "max_results": 5
  }'
```

**Response:**
```json
{
  "answer": "Apple reported revenue of $89.5 billion in Q3 2024, representing 8% growth year-over-year.",
  "confidence": 0.92,
  "sources": [
    {
      "document_id": "doc_abc123",
      "filename": "earnings_report.pdf",
      "page": 5,
      "text_snippet": "Revenue for the quarter ended September 30, 2024 was $89.5 billion...",
      "relevance_score": 0.95
    }
  ],
  "related_questions": [
    "What was the iPhone revenue in Q3?",
    "How did services perform in Q3?",
    "What are the key risks mentioned?"
  ]
}
```

#### **Search Documents**
```http
POST /query/search
```

**Description:** Search for documents using semantic search.

**Request:**
```bash
curl -X POST "https://api.fintech-ai-platform.com/v1/query/search" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "revenue growth earnings",
    "filters": {
      "document_type": ["earnings_report", "sec_filing"],
      "date_range": {
        "from": "2024-01-01",
        "to": "2024-12-31"
      }
    },
    "limit": 10
  }'
```

### **User Management**

#### **Get User Profile**
```http
GET /users/profile
```

#### **Update User Profile**
```http
PUT /users/profile
```

#### **List Users (Admin)**
```http
GET /admin/users
```

### **System Health**

#### **Health Check**
```http
GET /health
```

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00Z",
  "version": "1.0.0",
  "services": {
    "api_gateway": "healthy",
    "ml_service": "healthy",
    "database": "healthy",
    "redis": "healthy"
  }
}
```

## 📊 Data Models

### **Document**
```json
{
  "document_id": "string",
  "filename": "string",
  "file_size": "integer",
  "document_type": "string",
  "status": "string",
  "uploaded_at": "datetime",
  "processed_at": "datetime",
  "metadata": "object"
}
```

### **Analysis Request**
```json
{
  "analysis_type": "string",
  "extract_entities": "boolean",
  "sentiment_analysis": "boolean",
  "risk_assessment": "boolean",
  "custom_parameters": "object"
}
```

### **Analysis Result**
```json
{
  "analysis_id": "string",
  "status": "string",
  "confidence_score": "float",
  "extracted_entities": "array",
  "sentiment": "object",
  "risk_assessment": "object",
  "summary": "string",
  "key_insights": "array",
  "processing_time": "integer"
}
```

### **Query Request**
```json
{
  "question": "string",
  "document_ids": "array",
  "include_sources": "boolean",
  "max_results": "integer"
}
```

## ❌ Error Handling

### **Error Response Format**
```json
{
  "error": {
    "code": "string",
    "message": "string",
    "details": "object",
    "timestamp": "datetime",
    "request_id": "string"
  }
}
```

### **Common Error Codes**

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `AUTHENTICATION_FAILED` | 401 | Invalid or expired token |
| `PERMISSION_DENIED` | 403 | Insufficient permissions |
| `RESOURCE_NOT_FOUND` | 404 | Document or analysis not found |
| `VALIDATION_ERROR` | 422 | Invalid request parameters |
| `PROCESSING_ERROR` | 500 | Internal processing error |
| `RATE_LIMIT_EXCEEDED` | 429 | Too many requests |

### **Example Error Response**
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid document format. Supported formats: PDF, DOCX, XLSX",
    "details": {
      "field": "file",
      "supported_formats": ["pdf", "docx", "xlsx"],
      "provided_format": "txt"
    },
    "timestamp": "2024-01-15T10:30:00Z",
    "request_id": "req_123456"
  }
}
```

## ⚡ Rate Limiting

The API implements rate limiting to ensure fair usage:

- **Standard Plan**: 100 requests/minute
- **Professional Plan**: 1,000 requests/minute
- **Enterprise Plan**: 10,000 requests/minute

### **Rate Limit Headers**
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1642234567
```

## 💡 Examples

### **Complete Document Analysis Workflow**

```python
import requests
import json

# 1. Authenticate
auth_response = requests.post(
    "https://api.fintech-ai-platform.com/v1/auth/login",
    json={"username": "your_username", "password": "your_password"}
)
token = auth_response.json()["access_token"]
headers = {"Authorization": f"Bearer {token}"}

# 2. Upload document
with open("earnings_report.pdf", "rb") as f:
    files = {"file": f}
    data = {"metadata": json.dumps({"document_type": "earnings_report"})}
    upload_response = requests.post(
        "https://api.fintech-ai-platform.com/v1/documents/upload",
        headers=headers,
        files=files,
        data=data
    )
document_id = upload_response.json()["document_id"]

# 3. Start analysis
analysis_response = requests.post(
    f"https://api.fintech-ai-platform.com/v1/documents/{document_id}/analyze",
    headers=headers,
    json={
        "analysis_type": "comprehensive",
        "extract_entities": True,
        "sentiment_analysis": True,
        "risk_assessment": True
    }
)
analysis_id = analysis_response.json()["analysis_id"]

# 4. Poll for results
import time
while True:
    results_response = requests.get(
        f"https://api.fintech-ai-platform.com/v1/documents/{document_id}/analysis/{analysis_id}",
        headers=headers
    )
    status = results_response.json()["status"]
    if status == "completed":
        results = results_response.json()["results"]
        print(f"Analysis completed! Confidence: {results['confidence_score']}")
        break
    elif status == "failed":
        print("Analysis failed!")
        break
    time.sleep(5)

# 5. Ask questions about the document
query_response = requests.post(
    "https://api.fintech-ai-platform.com/v1/query/ask",
    headers=headers,
    json={
        "question": "What was the revenue and what are the key risks?",
        "document_ids": [document_id],
        "include_sources": True
    }
)
answer = query_response.json()
print(f"Answer: {answer['answer']}")
```

### **JavaScript/TypeScript Example**

```typescript
class FinTechAIClient {
  private baseUrl: string;
  private token: string;

  constructor(baseUrl: string, token: string) {
    this.baseUrl = baseUrl;
    this.token = token;
  }

  async uploadDocument(file: File, metadata: any): Promise<any> {
    const formData = new FormData();
    formData.append('file', file);
    formData.append('metadata', JSON.stringify(metadata));

    const response = await fetch(`${this.baseUrl}/documents/upload`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${this.token}`
      },
      body: formData
    });

    return response.json();
  }

  async analyzeDocument(documentId: string, options: any): Promise<any> {
    const response = await fetch(`${this.baseUrl}/documents/${documentId}/analyze`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${this.token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(options)
    });

    return response.json();
  }

  async getAnalysisResults(documentId: string, analysisId: string): Promise<any> {
    const response = await fetch(`${this.baseUrl}/documents/${documentId}/analysis/${analysisId}`, {
      headers: {
        'Authorization': `Bearer ${this.token}`
      }
    });

    return response.json();
  }
}

// Usage
const client = new FinTechAIClient('https://api.fintech-ai-platform.com/v1', 'your_token');

// Upload and analyze document
const uploadResult = await client.uploadDocument(file, { document_type: 'earnings_report' });
const analysisResult = await client.analyzeDocument(uploadResult.document_id, {
  analysis_type: 'comprehensive'
});
```

## 📚 SDKs & Libraries

### **Official SDKs**
- **Python**: `pip install fintech-ai-sdk`
- **JavaScript**: `npm install @fintech-ai/sdk`
- **Go**: `go get github.com/fintech-ai/go-sdk`

### **Community Libraries**
- **R**: `install.packages("fintechAI")`
- **Java**: Maven dependency available
- **C#**: NuGet package available

### **Postman Collection**
Download our Postman collection for easy API testing:
[FinTech AI Platform API Collection](https://api.fintech-ai-platform.com/postman-collection.json)

---

**Need Help?** Check out our [API Support](https://docs.fintech-ai-platform.com/support) or contact us at api-support@fintech-ai-platform.com 