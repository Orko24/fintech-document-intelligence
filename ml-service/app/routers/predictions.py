"""
Predictions router for ML Service
"""
import time
import uuid
from typing import List
from fastapi import APIRouter, HTTPException, Depends, BackgroundTasks
from fastapi.responses import JSONResponse

from app.models.prediction import (
    PredictionRequest, PredictionResponse, BatchPredictionRequest,
    BatchPredictionResponse, ModelInfo, ModelType
)
from app.services.prediction_service import PredictionService
from app.utils.auth import verify_api_key
from app.utils.metrics import record_prediction_metric

router = APIRouter(prefix="/predictions", tags=["predictions"])


@router.post("/predict", response_model=PredictionResponse)
async def predict(
    request: PredictionRequest,
    background_tasks: BackgroundTasks,
    api_key: str = Depends(verify_api_key)
):
    """Make a single prediction"""
    start_time = time.time()
    
    try:
        prediction_service = PredictionService()
        prediction = await prediction_service.predict(request)
        
        processing_time = time.time() - start_time
        
        # Record metrics
        background_tasks.add_task(
            record_prediction_metric,
            model_type=request.model_type,
            processing_time=processing_time,
            success=True
        )
        
        return PredictionResponse(
            prediction_id=str(uuid.uuid4()),
            model_type=request.model_type,
            prediction=prediction,
            confidence=prediction.get("confidence", 0.0),
            processing_time=processing_time,
            timestamp=prediction.get("timestamp"),
            metadata=request.metadata
        )
        
    except Exception as e:
        processing_time = time.time() - start_time
        background_tasks.add_task(
            record_prediction_metric,
            model_type=request.model_type,
            processing_time=processing_time,
            success=False
        )
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/batch", response_model=BatchPredictionResponse)
async def batch_predict(
    request: BatchPredictionRequest,
    background_tasks: BackgroundTasks,
    api_key: str = Depends(verify_api_key)
):
    """Make batch predictions"""
    start_time = time.time()
    batch_id = request.batch_id or str(uuid.uuid4())
    
    try:
        prediction_service = PredictionService()
        predictions = []
        errors = []
        
        for i, input_data in enumerate(request.inputs):
            try:
                pred_request = PredictionRequest(
                    model_type=request.model_type,
                    input_data=input_data,
                    user_id=request.user_id
                )
                prediction = await prediction_service.predict(pred_request)
                
                predictions.append(PredictionResponse(
                    prediction_id=str(uuid.uuid4()),
                    model_type=request.model_type,
                    prediction=prediction,
                    confidence=prediction.get("confidence", 0.0),
                    processing_time=prediction.get("processing_time", 0.0),
                    timestamp=prediction.get("timestamp"),
                    metadata=input_data.get("metadata")
                ))
                
            except Exception as e:
                errors.append({
                    "index": i,
                    "error": str(e),
                    "input_data": input_data
                })
        
        total_processing_time = time.time() - start_time
        
        return BatchPredictionResponse(
            batch_id=batch_id,
            predictions=predictions,
            total_processing_time=total_processing_time,
            success_count=len(predictions),
            error_count=len(errors),
            errors=errors
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/models", response_model=List[ModelInfo])
async def list_models(api_key: str = Depends(verify_api_key)):
    """List available models"""
    try:
        prediction_service = PredictionService()
        return await prediction_service.list_models()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/models/{model_type}", response_model=ModelInfo)
async def get_model_info(
    model_type: ModelType,
    api_key: str = Depends(verify_api_key)
):
    """Get specific model information"""
    try:
        prediction_service = PredictionService()
        model_info = await prediction_service.get_model_info(model_type)
        if not model_info:
            raise HTTPException(status_code=404, detail="Model not found")
        return model_info
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "ml-service"} 