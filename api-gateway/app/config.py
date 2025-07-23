import os
from typing import Optional
from pydantic import BaseSettings

class Settings(BaseSettings):
    # Application
    app_name: str = "FinTech AI Platform API Gateway"
    app_version: str = "1.0.0"
    debug: bool = False
    
    # Server
    host: str = "0.0.0.0"
    port: int = 8000
    workers: int = 4
    
    # Database
    database_url: str = "postgresql://postgres:password@localhost:5432/fintech"
    
    # Redis
    redis_url: str = "redis://localhost:6379"
    
    # Kafka
    kafka_bootstrap_servers: str = "localhost:9092"
    
    # Security
    secret_key: str = "your-super-secret-key-change-this-in-production"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    
    # External APIs
    openai_api_key: Optional[str] = None
    anthropic_api_key: Optional[str] = None
    huggingface_token: Optional[str] = None
    
    # Service URLs
    ml_service_url: str = "http://localhost:8001"
    go_service_url: str = "http://localhost:8080"
    java_service_url: str = "http://localhost:8081"
    
    # CORS
    cors_origins: list = ["http://localhost:3000", "http://localhost:8000"]
    
    # Monitoring
    enable_metrics: bool = True
    metrics_port: int = 9090
    
    class Config:
        env_file = ".env"

settings = Settings() 