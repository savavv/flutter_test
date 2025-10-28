from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from app.models.chat import ChatType


class ChatParticipantResponse(BaseModel):
    id: int
    user_id: int
    role: str
    joined_at: datetime
    is_active: bool

    class Config:
        from_attributes = True


class ChatBase(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    avatar_url: Optional[str] = None
    chat_type: ChatType = ChatType.PRIVATE


class ChatCreate(ChatBase):
    participant_ids: List[int] = []


class ChatUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    avatar_url: Optional[str] = None


class ChatResponse(ChatBase):
    id: int
    owner_id: Optional[int]
    is_active: bool
    created_at: datetime
    updated_at: datetime
    participants: List[ChatParticipantResponse] = []

    class Config:
        from_attributes = True
