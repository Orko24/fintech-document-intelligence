from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime

class ChatMessage(BaseModel):
    role: str = Field(..., description="Role of the message sender (user, assistant, system)")
    content: str = Field(..., description="Content of the message")
    timestamp: Optional[datetime] = None

class ChatRequest(BaseModel):
    message: str = Field(..., description="User message")
    context: Optional[Dict[str, Any]] = None
    document_ids: Optional[List[str]] = None
    conversation_id: Optional[str] = None

class ChatResponse(BaseModel):
    message: str
    conversation_id: str
    timestamp: datetime
    confidence_score: Optional[float] = None
    sources: Optional[List[Dict[str, Any]]] = None
    processing_time: Optional[float] = None

class ConversationHistory(BaseModel):
    conversation_id: str
    messages: List[ChatMessage]
    created_at: datetime
    updated_at: datetime
    document_context: Optional[List[str]] = None

class ConversationListResponse(BaseModel):
    conversations: List[ConversationHistory]
    total_count: int
    page: int
    page_size: int 