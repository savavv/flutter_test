from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from app.models.message import MessageType


class MessageBase(BaseModel):
    content: Optional[str] = None
    message_type: MessageType = MessageType.TEXT
    reply_to_id: Optional[int] = None


class MessageCreate(MessageBase):
    chat_id: int
    receiver_id: Optional[int] = None


class MessageUpdate(BaseModel):
    content: Optional[str] = None


class MessageResponse(MessageBase):
    id: int
    chat_id: int
    sender_id: int
    receiver_id: Optional[int]
    file_url: Optional[str]
    file_size: Optional[int]
    file_name: Optional[str]
    is_edited: bool
    edited_at: Optional[datetime]
    is_deleted: bool
    deleted_at: Optional[datetime]
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
