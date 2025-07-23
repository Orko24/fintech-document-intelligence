"""
Prediction models for ML Service
"""
from typing import List, Dict, Any, Optional
from pydantic import BaseModel, Field
from datetime import datetime
from enum import Enum


class ModelType(str, Enum):
    """Supported model types"""
    DOCUMENT_CLASSIFICATION = "document_classification"
    SENTIMENT_ANALYSIS = "sentiment_analysis"
    FRAUD_DETECTION = "fraud_detection"
    RISK_ASSESSMENT = "risk_assessment"
    TEXT_EXTRACTION = "text_extraction"
    IMAGE_ANALYSIS = "image_analysis"


class PredictionRequest(BaseModel):
    """Request model for predictions"""
    model_type: ModelType
    input_data: Dict[str, Any]
    user_id: Optional[str] = None
    session_id: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None


class PredictionResponse(BaseModel):
    """Response model for predictions"""
    prediction_id: str
    model_type: ModelType
    prediction: Dict[str, Any]
    confidence: float = Field(ge=0.0, le=1.0)
    processing_time: float
    timestamp: datetime
    metadata: Optional[Dict[str, Any]] = None


class ModelInfo(BaseModel):
    """Model information"""
    model_id: str
    model_type: ModelType
    version: str
    accuracy: float
    last_updated: datetime
    is_active: bool
    parameters: Dict[str, Any]


class BatchPredictionRequest(BaseModel):
    """Batch prediction request"""
    model_type: ModelType
    inputs: List[Dict[str, Any]]
    user_id: Optional[str] = None
    batch_id: Optional[str] = None


class BatchPredictionResponse(BaseModel):
    """Batch prediction response"""
    batch_id: str
    predictions: List[PredictionResponse]
    total_processing_time: float
    success_count: int
    error_count: int
    errors: List[Dict[str, Any]] = [] 