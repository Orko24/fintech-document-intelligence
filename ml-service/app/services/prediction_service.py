"""
Prediction Service for ML operations
"""
import asyncio
import json
import pickle
from typing import Dict, Any, List, Optional
from datetime import datetime
import aiohttp
import redis.asyncio as redis
from sklearn.ensemble import RandomForestClassifier
from sklearn.feature_extraction.text import TfidfVectorizer
import numpy as np

from app.config import settings
from app.models.prediction import PredictionRequest, ModelInfo, ModelType


class PredictionService:
    """Service for handling ML predictions"""
    
    def __init__(self):
        self.redis_client = None
        self.models = {}
        self.vectorizers = {}
        
    async def _get_redis_client(self):
        """Get Redis client"""
        if not self.redis_client:
            self.redis_client = redis.from_url(settings.redis_url, db=settings.redis_db)
        return self.redis_client
    
    async def _load_model(self, model_type: ModelType):
        """Load ML model from cache or disk"""
        redis_client = await self._get_redis_client()
        
        # Try to get from Redis cache first
        cached_model = await redis_client.get(f"model:{model_type}")
        if cached_model:
            self.models[model_type] = pickle.loads(cached_model)
            return
        
        # Load from disk or create default model
        if model_type == ModelType.DOCUMENT_CLASSIFICATION:
            self.models[model_type] = RandomForestClassifier(n_estimators=100)
            self.vectorizers[model_type] = TfidfVectorizer(max_features=1000)
        elif model_type == ModelType.SENTIMENT_ANALYSIS:
            self.models[model_type] = RandomForestClassifier(n_estimators=100)
            self.vectorizers[model_type] = TfidfVectorizer(max_features=1000)
        elif model_type == ModelType.FRAUD_DETECTION:
            self.models[model_type] = RandomForestClassifier(n_estimators=200)
        elif model_type == ModelType.RISK_ASSESSMENT:
            self.models[model_type] = RandomForestClassifier(n_estimators=150)
        else:
            # Default model for other types
            self.models[model_type] = RandomForestClassifier(n_estimators=100)
        
        # Cache the model
        await redis_client.setex(
            f"model:{model_type}",
            3600,  # 1 hour cache
            pickle.dumps(self.models[model_type])
        )
    
    async def predict(self, request: PredictionRequest) -> Dict[str, Any]:
        """Make a prediction based on model type"""
        await self._load_model(request.model_type)
        
        if request.model_type == ModelType.DOCUMENT_CLASSIFICATION:
            return await self._classify_document(request.input_data)
        elif request.model_type == ModelType.SENTIMENT_ANALYSIS:
            return await self._analyze_sentiment(request.input_data)
        elif request.model_type == ModelType.FRAUD_DETECTION:
            return await self._detect_fraud(request.input_data)
        elif request.model_type == ModelType.RISK_ASSESSMENT:
            return await self._assess_risk(request.input_data)
        elif request.model_type == ModelType.TEXT_EXTRACTION:
            return await self._extract_text(request.input_data)
        elif request.model_type == ModelType.IMAGE_ANALYSIS:
            return await self._analyze_image(request.input_data)
        else:
            raise ValueError(f"Unsupported model type: {request.model_type}")
    
    async def _classify_document(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Classify document type"""
        text = input_data.get("text", "")
        if not text:
            raise ValueError("Text content required for document classification")
        
        # Simple rule-based classification for demo
        categories = {
            "financial_report": ["revenue", "profit", "loss", "earnings", "financial"],
            "contract": ["agreement", "contract", "terms", "conditions", "party"],
            "invoice": ["invoice", "bill", "payment", "amount", "due"],
            "receipt": ["receipt", "purchase", "total", "tax", "date"]
        }
        
        text_lower = text.lower()
        scores = {}
        
        for category, keywords in categories.items():
            score = sum(1 for keyword in keywords if keyword in text_lower)
            scores[category] = score / len(keywords)
        
        predicted_category = max(scores, key=scores.get)
        confidence = scores[predicted_category]
        
        return {
            "category": predicted_category,
            "confidence": confidence,
            "scores": scores,
            "timestamp": datetime.now(),
            "processing_time": 0.1
        }
    
    async def _analyze_sentiment(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Analyze text sentiment"""
        text = input_data.get("text", "")
        if not text:
            raise ValueError("Text content required for sentiment analysis")
        
        # Simple sentiment analysis for demo
        positive_words = ["good", "great", "excellent", "positive", "happy", "profit", "growth"]
        negative_words = ["bad", "poor", "negative", "loss", "decline", "risk", "problem"]
        
        text_lower = text.lower()
        positive_score = sum(1 for word in positive_words if word in text_lower)
        negative_score = sum(1 for word in negative_words if word in text_lower)
        
        if positive_score > negative_score:
            sentiment = "positive"
            confidence = positive_score / (positive_score + negative_score + 1)
        elif negative_score > positive_score:
            sentiment = "negative"
            confidence = negative_score / (positive_score + negative_score + 1)
        else:
            sentiment = "neutral"
            confidence = 0.5
        
        return {
            "sentiment": sentiment,
            "confidence": confidence,
            "positive_score": positive_score,
            "negative_score": negative_score,
            "timestamp": datetime.now(),
            "processing_time": 0.05
        }
    
    async def _detect_fraud(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Detect fraudulent transactions"""
        amount = input_data.get("amount", 0)
        frequency = input_data.get("frequency", 1)
        location = input_data.get("location", "")
        time_of_day = input_data.get("time_of_day", 12)
        
        # Simple fraud detection rules for demo
        risk_factors = []
        risk_score = 0.0
        
        if amount > 10000:
            risk_factors.append("high_amount")
            risk_score += 0.3
        
        if frequency > 10:
            risk_factors.append("high_frequency")
            risk_score += 0.2
        
        if time_of_day < 6 or time_of_day > 22:
            risk_factors.append("unusual_time")
            risk_score += 0.1
        
        if "international" in location.lower():
            risk_factors.append("international")
            risk_score += 0.2
        
        is_fraudulent = risk_score > 0.5
        
        return {
            "is_fraudulent": is_fraudulent,
            "risk_score": risk_score,
            "risk_factors": risk_factors,
            "confidence": min(risk_score + 0.1, 1.0),
            "timestamp": datetime.now(),
            "processing_time": 0.08
        }
    
    async def _assess_risk(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Assess financial risk"""
        credit_score = input_data.get("credit_score", 700)
        income = input_data.get("income", 50000)
        debt = input_data.get("debt", 0)
        employment_years = input_data.get("employment_years", 2)
        
        # Simple risk assessment for demo
        risk_score = 0.0
        
        if credit_score < 600:
            risk_score += 0.4
        elif credit_score < 700:
            risk_score += 0.2
        
        debt_to_income = debt / income if income > 0 else 1
        if debt_to_income > 0.4:
            risk_score += 0.3
        elif debt_to_income > 0.2:
            risk_score += 0.1
        
        if employment_years < 1:
            risk_score += 0.2
        
        risk_level = "low" if risk_score < 0.3 else "medium" if risk_score < 0.6 else "high"
        
        return {
            "risk_level": risk_level,
            "risk_score": risk_score,
            "debt_to_income_ratio": debt_to_income,
            "confidence": 0.8,
            "timestamp": datetime.now(),
            "processing_time": 0.06
        }
    
    async def _extract_text(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Extract text from documents using OCR service"""
        file_path = input_data.get("file_path", "")
        if not file_path:
            raise ValueError("File path required for text extraction")
        
        # Call OCR service
        async with aiohttp.ClientSession() as session:
            async with session.post(
                f"{settings.ocr_service_url}/extract",
                json={"file_path": file_path},
                timeout=settings.ocr_timeout
            ) as response:
                if response.status == 200:
                    result = await response.json()
                    return {
                        "extracted_text": result.get("text", ""),
                        "confidence": result.get("confidence", 0.8),
                        "timestamp": datetime.now(),
                        "processing_time": result.get("processing_time", 1.0)
                    }
                else:
                    raise Exception(f"OCR service error: {response.status}")
    
    async def _analyze_image(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Analyze image content"""
        image_path = input_data.get("image_path", "")
        if not image_path:
            raise ValueError("Image path required for image analysis")
        
        # Simple image analysis for demo
        return {
            "objects_detected": ["document", "text", "table"],
            "confidence": 0.85,
            "image_type": "document",
            "timestamp": datetime.now(),
            "processing_time": 0.5
        }
    
    async def list_models(self) -> List[ModelInfo]:
        """List available models"""
        models = []
        for model_type in ModelType:
            models.append(ModelInfo(
                model_id=f"{model_type}_v1",
                model_type=model_type,
                version="1.0.0",
                accuracy=0.85,
                last_updated=datetime.now(),
                is_active=True,
                parameters={"n_estimators": 100}
            ))
        return models
    
    async def get_model_info(self, model_type: ModelType) -> Optional[ModelInfo]:
        """Get specific model information"""
        return ModelInfo(
            model_id=f"{model_type}_v1",
            model_type=model_type,
            version="1.0.0",
            accuracy=0.85,
            last_updated=datetime.now(),
            is_active=True,
            parameters={"n_estimators": 100}
        ) 