"""
Authentication utilities for ML Service
"""
from fastapi import HTTPException, Header
from typing import Optional
import jwt
from app.config import settings


async def verify_api_key(x_api_key: Optional[str] = Header(None)) -> str:
    """Verify API key from header"""
    if not x_api_key:
        raise HTTPException(status_code=401, detail="API key required")
    
    # In production, validate against database or external service
    if x_api_key != "ml-service-key":
        raise HTTPException(status_code=401, detail="Invalid API key")
    
    return x_api_key


async def verify_jwt_token(authorization: Optional[str] = Header(None)) -> dict:
    """Verify JWT token"""
    if not authorization:
        raise HTTPException(status_code=401, detail="Authorization header required")
    
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Invalid authorization header")
    
    token = authorization.split(" ")[1]
    
    try:
        if not settings.jwt_secret:
            raise HTTPException(status_code=500, detail="JWT secret not configured")
        
        payload = jwt.decode(token, settings.jwt_secret, algorithms=["HS256"])
        return payload
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token") 