from fastapi import APIRouter, Depends, HTTPException, status
from typing import Optional

from ..models.chat import ChatRequest, ChatResponse, ConversationHistory, ConversationListResponse
from ..services.chat_service import ChatService
from ..utils.security import get_current_user

router = APIRouter(prefix="/api/v1/chat", tags=["chat"])

@router.post("/message", response_model=ChatResponse)
async def send_message(
    chat_request: ChatRequest,
    current_user = Depends(get_current_user),
    chat_service: ChatService = Depends()
):
    """
    Send a message to the AI chat system
    """
    try:
        response = await chat_service.process_message(
            user_id=current_user.id,
            message=chat_request.message,
            context=chat_request.context,
            document_ids=chat_request.document_ids,
            conversation_id=chat_request.conversation_id
        )
        return response
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to process message: {str(e)}"
        )

@router.get("/conversations", response_model=ConversationListResponse)
async def list_conversations(
    page: int = 1,
    page_size: int = 10,
    current_user = Depends(get_current_user),
    chat_service: ChatService = Depends()
):
    """
    List user's chat conversations
    """
    try:
        conversations = await chat_service.list_conversations(
            user_id=current_user.id,
            page=page,
            page_size=page_size
        )
        return conversations
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to list conversations: {str(e)}"
        )

@router.get("/conversations/{conversation_id}", response_model=ConversationHistory)
async def get_conversation(
    conversation_id: str,
    current_user = Depends(get_current_user),
    chat_service: ChatService = Depends()
):
    """
    Get conversation history
    """
    try:
        conversation = await chat_service.get_conversation(
            conversation_id=conversation_id,
            user_id=current_user.id
        )
        if not conversation:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Conversation not found"
            )
        return conversation
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get conversation: {str(e)}"
        )

@router.delete("/conversations/{conversation_id}")
async def delete_conversation(
    conversation_id: str,
    current_user = Depends(get_current_user),
    chat_service: ChatService = Depends()
):
    """
    Delete a conversation
    """
    try:
        success = await chat_service.delete_conversation(
            conversation_id=conversation_id,
            user_id=current_user.id
        )
        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Conversation not found"
            )
        return {"message": "Conversation deleted successfully"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete conversation: {str(e)}"
        ) 