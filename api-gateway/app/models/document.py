from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum

class DocumentStatus(str, Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"

class DocumentType(str, Enum):
    PDF = "pdf"
    IMAGE = "image"
    TEXT = "text"
    EXCEL = "excel"
    WORD = "word"

class DocumentUploadRequest(BaseModel):
    file_type: DocumentType
    file_name: str
    file_size: int
    description: Optional[str] = None

class DocumentResponse(BaseModel):
    id: str
    file_name: str
    file_type: DocumentType
    status: DocumentStatus
    uploaded_at: datetime
    processed_at: Optional[datetime] = None
    file_size: int
    description: Optional[str] = None
    
    class Config:
        from_attributes = True

class DocumentAnalysisRequest(BaseModel):
    document_id: str
    analysis_type: str = Field(..., description="Type of analysis to perform")
    parameters: Optional[Dict[str, Any]] = None

class DocumentAnalysisResponse(BaseModel):
    document_id: str
    analysis_id: str
    status: DocumentStatus
    results: Optional[Dict[str, Any]] = None
    confidence_score: Optional[float] = None
    processing_time: Optional[float] = None
    created_at: datetime
    completed_at: Optional[datetime] = None

class DocumentListResponse(BaseModel):
    documents: List[DocumentResponse]
    total_count: int
    page: int
    page_size: int
    has_next: bool
    has_previous: bool 