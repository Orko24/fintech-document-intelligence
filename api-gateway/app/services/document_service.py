from typing import Optional, List, Dict, Any
from datetime import datetime
import uuid
import httpx
import logging

from ..models.document import (
    DocumentResponse, 
    DocumentAnalysisResponse, 
    DocumentListResponse,
    DocumentStatus
)
from ..config import settings

logger = logging.getLogger(__name__)

class DocumentService:
    def __init__(self):
        self.ml_service_url = settings.ml_service_url
        self.go_service_url = settings.go_service_url
        
    async def create_document(
        self,
        document_id: str,
        file_name: str,
        file_type: str,
        file_size: int,
        description: Optional[str] = None,
        user_id: str = None
    ) -> DocumentResponse:
        """Create a new document record"""
        try:
            # In a real implementation, this would save to database
            document = DocumentResponse(
                id=document_id,
                file_name=file_name,
                file_type=file_type,
                status=DocumentStatus.PENDING,
                uploaded_at=datetime.utcnow(),
                file_size=file_size,
                description=description
            )
            
            logger.info(f"Created document {document_id} for user {user_id}")
            return document
            
        except Exception as e:
            logger.error(f"Failed to create document: {e}")
            raise
    
    async def process_document(self, document_id: str) -> bool:
        """Process document using ML service"""
        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    f"{self.ml_service_url}/api/v1/process",
                    json={"document_id": document_id}
                )
                response.raise_for_status()
                
            logger.info(f"Document {document_id} processing initiated")
            return True
            
        except Exception as e:
            logger.error(f"Failed to process document {document_id}: {e}")
            return False
    
    async def get_document(self, document_id: str, user_id: str) -> Optional[DocumentResponse]:
        """Get document by ID"""
        try:
            # In a real implementation, this would query the database
            # For now, return a mock document
            return DocumentResponse(
                id=document_id,
                file_name="sample.pdf",
                file_type="application/pdf",
                status=DocumentStatus.COMPLETED,
                uploaded_at=datetime.utcnow(),
                processed_at=datetime.utcnow(),
                file_size=1024,
                description="Sample document"
            )
            
        except Exception as e:
            logger.error(f"Failed to get document {document_id}: {e}")
            return None
    
    async def list_documents(
        self,
        user_id: str,
        page: int = 1,
        page_size: int = 10,
        status_filter: Optional[DocumentStatus] = None
    ) -> DocumentListResponse:
        """List documents with pagination"""
        try:
            # In a real implementation, this would query the database
            # For now, return mock data
            documents = [
                DocumentResponse(
                    id=str(uuid.uuid4()),
                    file_name=f"document_{i}.pdf",
                    file_type="application/pdf",
                    status=DocumentStatus.COMPLETED,
                    uploaded_at=datetime.utcnow(),
                    processed_at=datetime.utcnow(),
                    file_size=1024 * i,
                    description=f"Document {i}"
                )
                for i in range(1, 6)
            ]
            
            return DocumentListResponse(
                documents=documents,
                total_count=len(documents),
                page=page,
                page_size=page_size,
                has_next=False,
                has_previous=False
            )
            
        except Exception as e:
            logger.error(f"Failed to list documents: {e}")
            raise
    
    async def analyze_document(
        self,
        document_id: str,
        analysis_type: str,
        parameters: Optional[Dict[str, Any]] = None
    ) -> DocumentAnalysisResponse:
        """Analyze document using ML service"""
        try:
            analysis_id = str(uuid.uuid4())
            
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    f"{self.ml_service_url}/api/v1/analyze",
                    json={
                        "document_id": document_id,
                        "analysis_type": analysis_type,
                        "parameters": parameters or {}
                    }
                )
                response.raise_for_status()
                
            return DocumentAnalysisResponse(
                document_id=document_id,
                analysis_id=analysis_id,
                status=DocumentStatus.PROCESSING,
                created_at=datetime.utcnow()
            )
            
        except Exception as e:
            logger.error(f"Failed to analyze document {document_id}: {e}")
            raise
    
    async def get_analysis_result(
        self,
        document_id: str,
        analysis_id: str,
        user_id: str
    ) -> Optional[DocumentAnalysisResponse]:
        """Get analysis results"""
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    f"{self.ml_service_url}/api/v1/analysis/{analysis_id}"
                )
                response.raise_for_status()
                data = response.json()
                
            return DocumentAnalysisResponse(
                document_id=document_id,
                analysis_id=analysis_id,
                status=DocumentStatus.COMPLETED,
                results=data.get("results"),
                confidence_score=data.get("confidence_score"),
                processing_time=data.get("processing_time"),
                created_at=datetime.utcnow(),
                completed_at=datetime.utcnow()
            )
            
        except Exception as e:
            logger.error(f"Failed to get analysis result: {e}")
            return None
    
    async def delete_document(self, document_id: str, user_id: str) -> bool:
        """Delete document"""
        try:
            # In a real implementation, this would delete from database and storage
            logger.info(f"Deleted document {document_id} for user {user_id}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to delete document {document_id}: {e}")
            return False 