from fastapi import APIRouter, Depends, HTTPException, status
from typing import Dict, Any, List
import time

from ..utils.security import require_admin, User
from ..services.admin_service import AdminService

router = APIRouter(prefix="/api/v1/admin", tags=["admin"])

@router.get("/stats")
async def get_system_stats(
    current_user: User = Depends(require_admin),
    admin_service: AdminService = Depends()
):
    """
    Get system statistics (admin only)
    """
    try:
        stats = await admin_service.get_system_stats()
        return stats
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get system stats: {str(e)}"
        )

@router.get("/users")
async def list_users(
    page: int = 1,
    page_size: int = 10,
    current_user: User = Depends(require_admin),
    admin_service: AdminService = Depends()
):
    """
    List all users (admin only)
    """
    try:
        users = await admin_service.list_users(page=page, page_size=page_size)
        return users
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to list users: {str(e)}"
        )

@router.get("/documents")
async def list_all_documents(
    page: int = 1,
    page_size: int = 10,
    current_user: User = Depends(require_admin),
    admin_service: AdminService = Depends()
):
    """
    List all documents (admin only)
    """
    try:
        documents = await admin_service.list_all_documents(page=page, page_size=page_size)
        return documents
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to list documents: {str(e)}"
        )

@router.post("/maintenance")
async def trigger_maintenance(
    maintenance_type: str,
    current_user: User = Depends(require_admin),
    admin_service: AdminService = Depends()
):
    """
    Trigger maintenance tasks (admin only)
    """
    try:
        result = await admin_service.trigger_maintenance(maintenance_type)
        return {"message": f"Maintenance task '{maintenance_type}' triggered successfully", "result": result}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to trigger maintenance: {str(e)}"
        )

@router.get("/logs")
async def get_system_logs(
    level: str = "INFO",
    limit: int = 100,
    current_user: User = Depends(require_admin),
    admin_service: AdminService = Depends()
):
    """
    Get system logs (admin only)
    """
    try:
        logs = await admin_service.get_system_logs(level=level, limit=limit)
        return logs
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get logs: {str(e)}"
        )

@router.post("/cache/clear")
async def clear_cache(
    cache_type: str = "all",
    current_user: User = Depends(require_admin),
    admin_service: AdminService = Depends()
):
    """
    Clear cache (admin only)
    """
    try:
        result = await admin_service.clear_cache(cache_type)
        return {"message": f"Cache '{cache_type}' cleared successfully", "result": result}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to clear cache: {str(e)}"
        ) 