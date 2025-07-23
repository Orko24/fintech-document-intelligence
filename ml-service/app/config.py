"""
Configuration for ML Service
"""
import os
from typing import Optional
from pydantic import BaseSettings


class Settings(BaseSettings):
    """Application settings"""
    
    # Service Configuration
    service_name: str = "ml-service"
    version: str = "1.0.0"
    debug: bool = False
    
    # Server Configuration
    host: str = "0.0.0.0"
    port: int = 8001
    
    # Model Configuration
    model_path: str = "/app/models"
    model_cache_size: int = 10
    prediction_timeout: int = 30
    
    # AI/ML Configuration
    openai_api_key: Optional[str] = None
    openai_model: str = "gpt-4"
    openai_max_tokens: int = 1000
    
    # Document Processing
    max_file_size: int = 50 * 1024 * 1024  # 50MB
    supported_formats: list = ["pdf", "docx", "txt", "png", "jpg", "jpeg"]
    
    # OCR Configuration
    ocr_service_url: str = "http://ocr-service:8002"
    ocr_timeout: int = 60
    
    # Database Configuration
    database_url: str = "postgresql://ml_user:ml_password@postgres:5432/fintech_ml"
    
    # Redis Configuration
    redis_url: str = "redis://redis:6379"
    redis_db: int = 1
    
    # Monitoring
    prometheus_port: int = 9091
    jaeger_endpoint: str = "http://jaeger:14268/api/traces"
    
    # Security
    api_key_header: str = "X-API-Key"
    jwt_secret: Optional[str] = None
    
    # External Services
    api_gateway_url: str = "http://api-gateway:8000"
    go_service_url: str = "http://go-service:8003"
    
    class Config:
        env_file = ".env"
        case_sensitive = False


settings = Settings() 