from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import and_, or_, desc
from typing import List, Optional
from datetime import datetime
from app.core.database import get_db
from app.api.dependencies import get_current_active_user
from app.models.user import User
from app.models.chat import Chat, ChatParticipant
from app.models.message import Message, MessageType
from app.schemas.message import MessageCreate, MessageUpdate, MessageResponse
from app.core.websocket import manager
import json

router = APIRouter(prefix="/messages", tags=["messages"])


@router.get("/chat/{chat_id}", response_model=List[MessageResponse])
async def get_chat_messages(
    chat_id: int,
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get messages from a chat"""
    # Check if user is participant
    participant = db.query(ChatParticipant).filter(
        ChatParticipant.chat_id == chat_id,
        ChatParticipant.user_id == current_user.id,
        ChatParticipant.is_active == True
    ).first()
    
    if not participant:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Chat not found or access denied"
        )
    
    # Get messages
    messages = db.query(Message).filter(
        Message.chat_id == chat_id,
        Message.is_deleted == False
    ).options(
        joinedload(Message.sender),
        joinedload(Message.receiver),
        joinedload(Message.reply_to)
    ).order_by(desc(Message.created_at)).offset(offset).limit(limit).all()
    
    return messages


@router.post("/", response_model=MessageResponse)
async def send_message(
    message_data: MessageCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Send a message to a chat"""
    # Check if user is participant
    participant = db.query(ChatParticipant).filter(
        ChatParticipant.chat_id == message_data.chat_id,
        ChatParticipant.user_id == current_user.id,
        ChatParticipant.is_active == True
    ).first()
    
    if not participant:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Chat not found or access denied"
        )
    
    # For private chats, set receiver_id
    chat = db.query(Chat).filter(Chat.id == message_data.chat_id).first()
    receiver_id = None
    
    if chat and chat.chat_type.value == "private":
        # Find the other participant
        other_participant = db.query(ChatParticipant).filter(
            ChatParticipant.chat_id == message_data.chat_id,
            ChatParticipant.user_id != current_user.id,
            ChatParticipant.is_active == True
        ).first()
        
        if other_participant:
            receiver_id = other_participant.user_id
    
    # Create message
    message = Message(
        chat_id=message_data.chat_id,
        sender_id=current_user.id,
        receiver_id=receiver_id or message_data.receiver_id,
        content=message_data.content,
        message_type=message_data.message_type,
        reply_to_id=message_data.reply_to_id
    )
    
    db.add(message)
    db.commit()
    db.refresh(message)
    
    # Update chat's last activity
    chat.updated_at = datetime.utcnow()
    db.commit()
    
    # Notify chat participants via WebSocket
    try:
        payload = json.dumps({
            "type": "message",
            "data": {
                "id": message.id,
                "chat_id": message.chat_id,
                "sender_id": message.sender_id,
                "content": message.content,
                "message_type": message.message_type.value if hasattr(message.message_type, "value") else str(message.message_type),
                "created_at": message.created_at.isoformat(),
            }
        })
        participants = db.query(ChatParticipant).filter(
            ChatParticipant.chat_id == message.chat_id,
            ChatParticipant.is_active == True
        ).all()
        for p in participants:
            await manager.send_personal_message(payload, p.user_id)
    except Exception:
        # Don't break the request if WS delivery fails
        pass
    
    return message


@router.get("/{message_id}", response_model=MessageResponse)
async def get_message(
    message_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get a specific message"""
    message = db.query(Message).filter(
        Message.id == message_id,
        Message.is_deleted == False
    ).options(
        joinedload(Message.sender),
        joinedload(Message.receiver),
        joinedload(Message.reply_to)
    ).first()
    
    if not message:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Message not found"
        )
    
    # Check if user has access to this message (is participant in the chat)
    participant = db.query(ChatParticipant).filter(
        ChatParticipant.chat_id == message.chat_id,
        ChatParticipant.user_id == current_user.id,
        ChatParticipant.is_active == True
    ).first()
    
    if not participant:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Message not found or access denied"
        )
    
    return message


@router.put("/{message_id}", response_model=MessageResponse)
async def update_message(
    message_id: int,
    message_update: MessageUpdate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Update a message (only by sender)"""
    message = db.query(Message).filter(
        Message.id == message_id,
        Message.sender_id == current_user.id,
        Message.is_deleted == False
    ).first()
    
    if not message:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Message not found or access denied"
        )
    
    # Update message
    update_data = message_update.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(message, field, value)
    
    message.is_edited = True
    message.edited_at = datetime.utcnow()
    message.updated_at = datetime.utcnow()
    
    db.commit()
    db.refresh(message)
    
    return message


@router.delete("/{message_id}")
async def delete_message(
    message_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Delete a message (soft delete)"""
    message = db.query(Message).filter(
        Message.id == message_id,
        Message.sender_id == current_user.id,
        Message.is_deleted == False
    ).first()
    
    if not message:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Message not found or access denied"
        )
    
    # Soft delete
    message.is_deleted = True
    message.deleted_at = datetime.utcnow()
    message.updated_at = datetime.utcnow()
    
    db.commit()
    
    return {"message": "Message deleted successfully"}


@router.get("/search/{chat_id}", response_model=List[MessageResponse])
async def search_messages(
    chat_id: int,
    query: str = Query(..., min_length=1),
    limit: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Search messages in a chat"""
    # Check if user is participant
    participant = db.query(ChatParticipant).filter(
        ChatParticipant.chat_id == chat_id,
        ChatParticipant.user_id == current_user.id,
        ChatParticipant.is_active == True
    ).first()
    
    if not participant:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Chat not found or access denied"
        )
    
    # Search messages
    messages = db.query(Message).filter(
        Message.chat_id == chat_id,
        Message.is_deleted == False,
        Message.content.contains(query)
    ).options(
        joinedload(Message.sender),
        joinedload(Message.receiver),
        joinedload(Message.reply_to)
    ).order_by(desc(Message.created_at)).limit(limit).all()
    
    return messages


@router.get("/unread/count")
async def get_unread_count(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get unread messages count for current user"""
    # This would require a more complex implementation with message read status
    # For now, return 0
    return {"unread_count": 0}


@router.post("/{message_id}/read")
async def mark_message_read(
    message_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Mark message as read"""
    # This would require a message read status table
    # For now, just return success
    return {"message": "Message marked as read"}
