"""
Metrics utilities for ML Service
"""
import time
from typing import Dict, Any
import redis.asyncio as redis
from app.config import settings


async def record_prediction_metric(
    model_type: str,
    processing_time: float,
    success: bool,
    additional_metrics: Dict[str, Any] = None
):
    """Record prediction metrics"""
    try:
        redis_client = redis.from_url(settings.redis_url, db=settings.redis_db)
        
        metric_data = {
            "model_type": model_type,
            "processing_time": processing_time,
            "success": success,
            "timestamp": time.time(),
            "additional_metrics": additional_metrics or {}
        }
        
        # Store in Redis for Prometheus scraping
        await redis_client.lpush(
            f"metrics:prediction:{model_type}",
            str(metric_data)
        )
        
        # Keep only last 1000 metrics
        await redis_client.ltrim(f"metrics:prediction:{model_type}", 0, 999)
        
    except Exception as e:
        # Log error but don't fail the request
        print(f"Failed to record metric: {e}")


async def get_prediction_metrics(model_type: str = None, limit: int = 100):
    """Get prediction metrics"""
    try:
        redis_client = redis.from_url(settings.redis_url, db=settings.redis_db)
        
        if model_type:
            metrics = await redis_client.lrange(f"metrics:prediction:{model_type}", 0, limit - 1)
        else:
            # Get metrics for all model types
            keys = await redis_client.keys("metrics:prediction:*")
            metrics = []
            for key in keys[:limit]:
                model_metrics = await redis_client.lrange(key, 0, 10)
                metrics.extend(model_metrics)
        
        return [eval(metric) for metric in metrics]
        
    except Exception as e:
        print(f"Failed to get metrics: {e}")
        return [] 