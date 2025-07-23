from fastapi import APIRouter, Depends
from typing import Dict, Any
import time
import psutil
import httpx

from ..config import settings

router = APIRouter(prefix="/api/v1/health", tags=["health"])

@router.get("/")
async def health_check() -> Dict[str, Any]:
    """
    Basic health check endpoint
    """
    return {
        "status": "healthy",
        "timestamp": time.time(),
        "service": "api-gateway",
        "version": settings.app_version
    }

@router.get("/detailed")
async def detailed_health_check() -> Dict[str, Any]:
    """
    Detailed health check with system metrics
    """
    try:
        # System metrics
        cpu_percent = psutil.cpu_percent(interval=1)
        memory = psutil.virtual_memory()
        disk = psutil.disk_usage('/')
        
        # Service dependencies health
        dependencies = await check_dependencies()
        
        return {
            "status": "healthy",
            "timestamp": time.time(),
            "service": "api-gateway",
            "version": settings.app_version,
            "system": {
                "cpu_percent": cpu_percent,
                "memory_percent": memory.percent,
                "disk_percent": disk.percent
            },
            "dependencies": dependencies
        }
    except Exception as e:
        return {
            "status": "unhealthy",
            "timestamp": time.time(),
            "service": "api-gateway",
            "error": str(e)
        }

async def check_dependencies() -> Dict[str, Any]:
    """
    Check health of dependent services
    """
    dependencies = {}
    
    # Check ML Service
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(f"{settings.ml_service_url}/health")
            dependencies["ml_service"] = {
                "status": "healthy" if response.status_code == 200 else "unhealthy",
                "response_time": response.elapsed.total_seconds()
            }
    except Exception as e:
        dependencies["ml_service"] = {
            "status": "unhealthy",
            "error": str(e)
        }
    
    # Check Go Service
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(f"{settings.go_service_url}/health")
            dependencies["go_service"] = {
                "status": "healthy" if response.status_code == 200 else "unhealthy",
                "response_time": response.elapsed.total_seconds()
            }
    except Exception as e:
        dependencies["go_service"] = {
            "status": "unhealthy",
            "error": str(e)
        }
    
    # Check Java Service
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(f"{settings.java_service_url}/health")
            dependencies["java_service"] = {
                "status": "healthy" if response.status_code == 200 else "unhealthy",
                "response_time": response.elapsed.total_seconds()
            }
    except Exception as e:
        dependencies["java_service"] = {
            "status": "unhealthy",
            "error": str(e)
        }
    
    return dependencies

@router.get("/ready")
async def readiness_check() -> Dict[str, Any]:
    """
    Readiness check for Kubernetes
    """
    try:
        # Check if all critical dependencies are healthy
        dependencies = await check_dependencies()
        
        all_healthy = all(
            dep.get("status") == "healthy" 
            for dep in dependencies.values()
        )
        
        if all_healthy:
            return {
                "status": "ready",
                "timestamp": time.time()
            }
        else:
            return {
                "status": "not_ready",
                "timestamp": time.time(),
                "dependencies": dependencies
            }
    except Exception as e:
        return {
            "status": "not_ready",
            "timestamp": time.time(),
            "error": str(e)
        }

@router.get("/live")
async def liveness_check() -> Dict[str, Any]:
    """
    Liveness check for Kubernetes
    """
    return {
        "status": "alive",
        "timestamp": time.time()
    } 