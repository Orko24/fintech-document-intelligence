from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from pydantic import BaseModel
from typing import Optional

from ..utils.security import create_access_token, get_current_user, User

router = APIRouter(prefix="/api/v1/auth", tags=["authentication"])

class LoginRequest(BaseModel):
    email: str
    password: str

class RegisterRequest(BaseModel):
    email: str
    password: str
    full_name: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int

@router.post("/login", response_model=TokenResponse)
async def login(login_request: LoginRequest):
    """
    Login user and return access token
    """
    try:
        # In a real implementation, this would validate against database
        # For now, accept any email/password combination
        if not login_request.email or not login_request.password:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email and password are required"
            )
        
        # Create access token
        access_token = create_access_token(
            data={"sub": login_request.email, "email": login_request.email, "role": "user"}
        )
        
        return TokenResponse(
            access_token=access_token,
            expires_in=30 * 60  # 30 minutes
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Login failed: {str(e)}"
        )

@router.post("/register", response_model=TokenResponse)
async def register(register_request: RegisterRequest):
    """
    Register new user and return access token
    """
    try:
        # In a real implementation, this would create user in database
        # For now, just create a token
        access_token = create_access_token(
            data={"sub": register_request.email, "email": register_request.email, "role": "user"}
        )
        
        return TokenResponse(
            access_token=access_token,
            expires_in=30 * 60  # 30 minutes
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Registration failed: {str(e)}"
        )

@router.get("/me")
async def get_current_user_info(current_user: User = Depends(get_current_user)):
    """
    Get current user information
    """
    return {
        "id": current_user.id,
        "email": current_user.email,
        "role": current_user.role
    }

@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(current_user: User = Depends(get_current_user)):
    """
    Refresh access token
    """
    try:
        # Create new access token
        access_token = create_access_token(
            data={"sub": current_user.id, "email": current_user.email, "role": current_user.role}
        )
        
        return TokenResponse(
            access_token=access_token,
            expires_in=30 * 60  # 30 minutes
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Token refresh failed: {str(e)}"
        ) 