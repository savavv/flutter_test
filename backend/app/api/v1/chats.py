from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session, joinedload, aliased
from sqlalchemy import and_, or_
from typing import List, Optional
from datetime import datetime
from app.core.database import get_db
from app.api.dependencies import get_current_active_user
from app.models.user import User
from app.models.chat import Chat, ChatParticipant, ChatType
from app.schemas.chat import ChatCreate, ChatUpdate, ChatResponse, ChatParticipantResponse
from app.schemas.user import UserProfile

router = APIRouter(prefix="/chats", tags=["chats"])


@router.get("/", response_model=List[ChatResponse])
async def get_user_chats(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get all chats for current user"""
    # Get chats where user is a participant
    chats = db.query(Chat).join(ChatParticipant).filter(
        ChatParticipant.user_id == current_user.id,
        ChatParticipant.is_active == True,
        Chat.is_active == True
    ).options(
        joinedload(Chat.participants).joinedload(ChatParticipant.user),
        joinedload(Chat.owner)
    ).all()
    
    return chats


@router.post("/", response_model=ChatResponse)
async def create_chat(
    chat_data: ChatCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Create a new chat"""
    # For private chats, check if chat already exists between users
    if chat_data.chat_type == ChatType.PRIVATE:
        if len(chat_data.participant_ids) != 1:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Private chat must have exactly one participant"
            )
        
        other_user_id = chat_data.participant_ids[0]
        
        # Check if private chat already exists between current_user and other_user
        cp1 = aliased(ChatParticipant)
        cp2 = aliased(ChatParticipant)
        existing_chat = (
            db.query(Chat)
            .join(cp1, cp1.chat_id == Chat.id)
            .join(cp2, cp2.chat_id == Chat.id)
            .filter(
                Chat.chat_type == ChatType.PRIVATE,
                Chat.is_active == True,
                cp1.user_id == current_user.id,
                cp2.user_id == other_user_id,
                cp1.is_active == True,
                cp2.is_active == True,
            )
            .first()
        )
        
        if existing_chat:
            return existing_chat
    
    # Create new chat
    chat = Chat(
        name=chat_data.name,
        description=chat_data.description,
        avatar_url=chat_data.avatar_url,
        chat_type=chat_data.chat_type,
        owner_id=current_user.id if chat_data.chat_type != ChatType.PRIVATE else None
    )
    
    db.add(chat)
    db.flush()  # Get the chat ID
    
    # Add current user as participant
    current_user_participant = ChatParticipant(
        chat_id=chat.id,
        user_id=current_user.id,
        role="owner" if chat_data.chat_type != ChatType.PRIVATE else "member"
    )
    db.add(current_user_participant)
    
    # Add other participants
    for participant_id in chat_data.participant_ids:
        if participant_id != current_user.id:  # Don't add current user twice
            # Check if user exists
            user = db.query(User).filter(User.id == participant_id, User.is_active == True).first()
            if not user:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"User with ID {participant_id} not found"
                )
            
            participant = ChatParticipant(
                chat_id=chat.id,
                user_id=participant_id,
                role="member"
            )
            db.add(participant)
    
    db.commit()
    db.refresh(chat)
    
    return chat


@router.get("/{chat_id}", response_model=ChatResponse)
async def get_chat(
    chat_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get chat by ID"""
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
    
    chat = db.query(Chat).filter(
        Chat.id == chat_id,
        Chat.is_active == True
    ).options(
        joinedload(Chat.participants).joinedload(ChatParticipant.user),
        joinedload(Chat.owner)
    ).first()
    
    if not chat:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Chat not found"
        )
    
    return chat


@router.put("/{chat_id}", response_model=ChatResponse)
async def update_chat(
    chat_id: int,
    chat_update: ChatUpdate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Update chat"""
    # Check if user is participant and has permission to update
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
    
    # Check if user has permission to update (owner or admin)
    if participant.role not in ["owner", "admin"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Insufficient permissions"
        )
    
    chat = db.query(Chat).filter(Chat.id == chat_id, Chat.is_active == True).first()
    if not chat:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Chat not found"
        )
    
    # Update chat fields
    update_data = chat_update.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(chat, field, value)
    
    chat.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(chat)
    
    return chat


@router.delete("/{chat_id}")
async def delete_chat(
    chat_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Delete chat (only owner can delete)"""
    # Check if user is owner
    participant = db.query(ChatParticipant).filter(
        ChatParticipant.chat_id == chat_id,
        ChatParticipant.user_id == current_user.id,
        ChatParticipant.role == "owner",
        ChatParticipant.is_active == True
    ).first()
    
    if not participant:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Chat not found or insufficient permissions"
        )
    
    chat = db.query(Chat).filter(Chat.id == chat_id).first()
    if not chat:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Chat not found"
        )
    
    # Soft delete
    chat.is_active = False
    chat.updated_at = datetime.utcnow()
    
    # Deactivate all participants
    db.query(ChatParticipant).filter(
        ChatParticipant.chat_id == chat_id
    ).update({"is_active": False})
    
    db.commit()
    
    return {"message": "Chat deleted successfully"}


@router.post("/{chat_id}/participants/{user_id}")
async def add_participant(
    chat_id: int,
    user_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Add participant to chat"""
    # Check if current user has permission
    participant = db.query(ChatParticipant).filter(
        ChatParticipant.chat_id == chat_id,
        ChatParticipant.user_id == current_user.id,
        ChatParticipant.role.in_(["owner", "admin"]),
        ChatParticipant.is_active == True
    ).first()
    
    if not participant:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Insufficient permissions"
        )
    
    # Check if user exists
    user = db.query(User).filter(User.id == user_id, User.is_active == True).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Check if user is already a participant
    existing_participant = db.query(ChatParticipant).filter(
        ChatParticipant.chat_id == chat_id,
        ChatParticipant.user_id == user_id
    ).first()
    
    if existing_participant:
        if existing_participant.is_active:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="User is already a participant"
            )
        else:
            # Reactivate participant
            existing_participant.is_active = True
            existing_participant.joined_at = datetime.utcnow()
    else:
        # Add new participant
        new_participant = ChatParticipant(
            chat_id=chat_id,
            user_id=user_id,
            role="member"
        )
        db.add(new_participant)
    
    db.commit()
    
    return {"message": "Participant added successfully"}


@router.delete("/{chat_id}/participants/{user_id}")
async def remove_participant(
    chat_id: int,
    user_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Remove participant from chat"""
    # Check if current user has permission
    participant = db.query(ChatParticipant).filter(
        ChatParticipant.chat_id == chat_id,
        ChatParticipant.user_id == current_user.id,
        ChatParticipant.role.in_(["owner", "admin"]),
        ChatParticipant.is_active == True
    ).first()
    
    if not participant:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Insufficient permissions"
        )
    
    # Find participant to remove
    target_participant = db.query(ChatParticipant).filter(
        ChatParticipant.chat_id == chat_id,
        ChatParticipant.user_id == user_id,
        ChatParticipant.is_active == True
    ).first()
    
    if not target_participant:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Participant not found"
        )
    
    # Don't allow removing owner
    if target_participant.role == "owner":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot remove chat owner"
        )
    
    # Deactivate participant
    target_participant.is_active = False
    db.commit()
    
    return {"message": "Participant removed successfully"}
