"""
Shared configuration settings for the FinTech AI Platform.

This module contains common configuration settings that are used
across multiple services in the platform.
"""

import os
from typing import Optional
from pydantic import BaseSettings, Field


class DatabaseSettings(BaseSettings):
    """Database configuration settings."""
    
    host: str = Field(default="localhost", env="DATABASE_HOST")
    port: int = Field(default=5432, env="DATABASE_PORT")
    name: str = Field(default="fintech_ai", env="DATABASE_NAME")
    user: str = Field(default="postgres", env="DATABASE_USER")
    password: str = Field(default="", env="DATABASE_PASSWORD")
    
    @property
    def url(self) -> str:
        """Get the database connection URL."""
        return f"postgresql://{self.user}:{self.password}@{self.host}:{self.port}/{self.name}"
    
    class Config:
        env_prefix = "DATABASE_"


class RedisSettings(BaseSettings):
    """Redis configuration settings."""
    
    host: str = Field(default="localhost", env="REDIS_HOST")
    port: int = Field(default=6379, env="REDIS_PORT")
    password: Optional[str] = Field(default=None, env="REDIS_PASSWORD")
    db: int = Field(default=0, env="REDIS_DB")
    
    @property
    def url(self) -> str:
        """Get the Redis connection URL."""
        if self.password:
            return f"redis://:{self.password}@{self.host}:{self.port}/{self.db}"
        return f"redis://{self.host}:{self.port}/{self.db}"
    
    class Config:
        env_prefix = "REDIS_"


class KafkaSettings(BaseSettings):
    """Kafka configuration settings."""
    
    brokers: str = Field(default="localhost:9092", env="KAFKA_BROKERS")
    topic_prefix: str = Field(default="fintech", env="KAFKA_TOPIC_PREFIX")
    
    @property
    def broker_list(self) -> list[str]:
        """Get the list of Kafka brokers."""
        return self.brokers.split(",")
    
    class Config:
        env_prefix = "KAFKA_"


class SecuritySettings(BaseSettings):
    """Security configuration settings."""
    
    jwt_secret: str = Field(env="JWT_SECRET")
    jwt_algorithm: str = Field(default="HS256", env="JWT_ALGORITHM")
    jwt_expiration: int = Field(default=3600, env="JWT_EXPIRATION")
    api_key: str = Field(env="API_KEY")
    
    class Config:
        env_prefix = "SECURITY_"


class LoggingSettings(BaseSettings):
    """Logging configuration settings."""
    
    level: str = Field(default="INFO", env="LOG_LEVEL")
    format: str = Field(default="json", env="LOG_FORMAT")
    output: str = Field(default="stdout", env="LOG_OUTPUT")
    
    class Config:
        env_prefix = "LOGGING_"


class PlatformSettings(BaseSettings):
    """Main platform configuration settings."""
    
    environment: str = Field(default="development", env="ENVIRONMENT")
    debug: bool = Field(default=False, env="DEBUG")
    api_version: str = Field(default="v1", env="API_VERSION")
    
    # Service URLs
    api_gateway_url: str = Field(default="http://localhost:8000", env="API_GATEWAY_URL")
    ml_service_url: str = Field(default="http://localhost:8001", env="ML_SERVICE_URL")
    go_service_url: str = Field(default="http://localhost:8002", env="GO_SERVICE_URL")
    java_service_url: str = Field(default="http://localhost:8003", env="JAVA_SERVICE_URL")
    ocr_service_url: str = Field(default="http://localhost:8004", env="OCR_SERVICE_URL")
    
    # Sub-configurations
    database: DatabaseSettings = DatabaseSettings()
    redis: RedisSettings = RedisSettings()
    kafka: KafkaSettings = KafkaSettings()
    security: SecuritySettings = SecuritySettings()
    logging: LoggingSettings = LoggingSettings()
    
    class Config:
        env_prefix = "PLATFORM_"


# Global settings instance
settings = PlatformSettings() 