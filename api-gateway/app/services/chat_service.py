from typing import Optional, List, Dict, Any
from datetime import datetime
import uuid
import httpx
import logging

from ..models.chat import ChatResponse, ConversationHistory, ConversationListResponse
from ..config import settings

logger = logging.getLogger(__name__)

class ChatService:
    def __init__(self):
        self.ml_service_url = settings.ml_service_url
        
    async def process_message(
        self,
        user_id: str,
        message: str,
        context: Optional[Dict[str, Any]] = None,
        document_ids: Optional[List[str]] = None,
        conversation_id: Optional[str] = None
    ) -> ChatResponse:
        """Process a chat message using AI services"""
        try:
            # Generate conversation ID if not provided
            if not conversation_id:
                conversation_id = str(uuid.uuid4())
            
            # Call ML service for AI processing
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    f"{self.ml_service_url}/api/v1/chat",
                    json={
                        "message": message,
                        "context": context or {},
                        "document_ids": document_ids or [],
                        "conversation_id": conversation_id
                    }
                )
                response.raise_for_status()
                data = response.json()
            
            return ChatResponse(
                message=data.get("response", "I'm sorry, I couldn't process your request."),
                conversation_id=conversation_id,
                timestamp=datetime.utcnow(),
                confidence_score=data.get("confidence_score"),
                sources=data.get("sources"),
                processing_time=data.get("processing_time")
            )
            
        except Exception as e:
            logger.error(f"Failed to process message: {e}")
            # Return a fallback response
            return ChatResponse(
                message="I'm sorry, I'm experiencing technical difficulties. Please try again later.",
                conversation_id=conversation_id or str(uuid.uuid4()),
                timestamp=datetime.utcnow(),
                confidence_score=0.0
            )
    
    async def list_conversations(
        self,
        user_id: str,
        page: int = 1,
        page_size: int = 10
    ) -> ConversationListResponse:
        """List user's conversations"""
        try:
            # In a real implementation, this would query the database
            # For now, return mock data
            conversations = [
                ConversationHistory(
                    conversation_id=str(uuid.uuid4()),
                    messages=[],
                    created_at=datetime.utcnow(),
                    updated_at=datetime.utcnow(),
                    document_context=[]
                )
                for _ in range(3)
            ]
            
            return ConversationListResponse(
                conversations=conversations,
                total_count=len(conversations),
                page=page,
                page_size=page_size
            )
            
        except Exception as e:
            logger.error(f"Failed to list conversations: {e}")
            raise
    
    async def get_conversation(
        self,
        conversation_id: str,
        user_id: str
    ) -> Optional[ConversationHistory]:
        """Get conversation history"""
        try:
            # In a real implementation, this would query the database
            # For now, return mock data
            return ConversationHistory(
                conversation_id=conversation_id,
                messages=[],
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow(),
                document_context=[]
            )
            
        except Exception as e:
            logger.error(f"Failed to get conversation: {e}")
            return None
    
    async def delete_conversation(
        self,
        conversation_id: str,
        user_id: str
    ) -> bool:
        """Delete a conversation"""
        try:
            # In a real implementation, this would delete from database
            logger.info(f"Deleted conversation {conversation_id} for user {user_id}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to delete conversation: {e}")
            return False 