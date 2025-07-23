from fastapi import APIRouter, UploadFile, File, Depends, HTTPException, status
from fastapi.responses import StreamingResponse
from typing import List, Optional
import uuid
from datetime import datetime

from ..models.document import (
    DocumentResponse, 
    DocumentAnalysisRequest, 
    DocumentAnalysisResponse,
    DocumentListResponse,
    DocumentStatus
)
from ..services.document_service import DocumentService
from ..utils.security import get_current_user

router = APIRouter(prefix="/api/v1/documents", tags=["documents"])

@router.post("/upload", response_model=DocumentResponse)
async def upload_document(
    file: UploadFile = File(...),
    description: Optional[str] = None,
    current_user = Depends(get_current_user),
    document_service: DocumentService = Depends()
):
    """
    Upload a document for processing
    """
    try:
        # Validate file type
        allowed_types = ["application/pdf", "image/jpeg", "image/png", "text/plain", 
                        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                        "application/vnd.openxmlformats-officedocument.wordprocessingml.document"]
        
        if file.content_type not in allowed_types:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"File type {file.content_type} not supported"
            )
        
        # Create document record
        document_id = str(uuid.uuid4())
        document = await document_service.create_document(
            document_id=document_id,
            file_name=file.filename,
            file_type=file.content_type,
            file_size=file.size,
            description=description,
            user_id=current_user.id
        )
        
        # Process document asynchronously
        await document_service.process_document(document_id)
        
        return document
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to upload document: {str(e)}"
        )

@router.get("/", response_model=DocumentListResponse)
async def list_documents(
    page: int = 1,
    page_size: int = 10,
    status_filter: Optional[DocumentStatus] = None,
    current_user = Depends(get_current_user),
    document_service: DocumentService = Depends()
):
    """
    List user's documents with pagination
    """
    try:
        documents = await document_service.list_documents(
            user_id=current_user.id,
            page=page,
            page_size=page_size,
            status_filter=status_filter
        )
        return documents
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to list documents: {str(e)}"
        )

@router.get("/{document_id}", response_model=DocumentResponse)
async def get_document(
    document_id: str,
    current_user = Depends(get_current_user),
    document_service: DocumentService = Depends()
):
    """
    Get document details
    """
    try:
        document = await document_service.get_document(document_id, current_user.id)
        if not document:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Document not found"
            )
        return document
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get document: {str(e)}"
        )

@router.post("/{document_id}/analyze", response_model=DocumentAnalysisResponse)
async def analyze_document(
    document_id: str,
    analysis_request: DocumentAnalysisRequest,
    current_user = Depends(get_current_user),
    document_service: DocumentService = Depends()
):
    """
    Analyze a document using AI/ML services
    """
    try:
        # Verify document ownership
        document = await document_service.get_document(document_id, current_user.id)
        if not document:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Document not found"
            )
        
        # Start analysis
        analysis = await document_service.analyze_document(
            document_id=document_id,
            analysis_type=analysis_request.analysis_type,
            parameters=analysis_request.parameters
        )
        
        return analysis
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to analyze document: {str(e)}"
        )

@router.get("/{document_id}/analysis/{analysis_id}", response_model=DocumentAnalysisResponse)
async def get_analysis_result(
    document_id: str,
    analysis_id: str,
    current_user = Depends(get_current_user),
    document_service: DocumentService = Depends()
):
    """
    Get analysis results for a document
    """
    try:
        analysis = await document_service.get_analysis_result(
            document_id=document_id,
            analysis_id=analysis_id,
            user_id=current_user.id
        )
        
        if not analysis:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Analysis not found"
            )
        
        return analysis
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get analysis: {str(e)}"
        )

@router.delete("/{document_id}")
async def delete_document(
    document_id: str,
    current_user = Depends(get_current_user),
    document_service: DocumentService = Depends()
):
    """
    Delete a document
    """
    try:
        success = await document_service.delete_document(document_id, current_user.id)
        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Document not found"
            )
        
        return {"message": "Document deleted successfully"}
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete document: {str(e)}"
        ) 