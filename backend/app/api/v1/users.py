from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import or_
from typing import List, Optional
from datetime import datetime
from app.core.database import get_db
from app.api.dependencies import get_current_active_user
from app.models.user import User
from app.models.contact import Contact
from app.schemas.user import UserResponse, UserUpdate, UserProfile, PublicKeyUpdate
from app.schemas.auth import Token

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/me", response_model=UserResponse)
async def get_current_user_profile(
    current_user: User = Depends(get_current_active_user)
):
    """Get current user profile"""
    return current_user


@router.put("/me", response_model=UserResponse)
async def update_current_user_profile(
    user_update: UserUpdate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Update current user profile"""
    # Check if username is being updated and if it's unique
    if user_update.username and user_update.username != current_user.username:
        existing_user = db.query(User).filter(
            User.username == user_update.username,
            User.id != current_user.id
        ).first()
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Username already taken"
            )
    
    # Update user fields
    update_data = user_update.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(current_user, field, value)
    
    current_user.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(current_user)
    
    return current_user


@router.put("/me/public-key")
async def update_public_key(
    payload: PublicKeyUpdate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Set or update current user's public key used for E2EE."""
    current_user.public_key = payload.public_key
    current_user.updated_at = datetime.utcnow()
    db.commit()
    return {"message": "Public key updated"}


@router.get("/{user_id}/public-key")
async def get_user_public_key(
    user_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get another user's public key for E2EE."""
    user = db.query(User).filter(User.id == user_id, User.is_active == True).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return {"user_id": user.id, "public_key": user.public_key}


@router.get("/search", response_model=List[UserProfile])
async def search_users(
    query: str = Query(..., min_length=1, description="Search query"),
    limit: int = Query(20, ge=1, le=100, description="Number of results"),
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Search users by phone number, username, or name"""
    if len(query) < 1:
        return []
    
    # Search by phone number, username, first name, or last name
    users = db.query(User).filter(
        User.id != current_user.id,  # Exclude current user
        User.is_active == True,
        or_(
            User.phone_number.contains(query),
            User.username.contains(query),
            User.first_name.contains(query),
            User.last_name.contains(query)
        )
    ).limit(limit).all()
    
    return users


@router.get("/contacts", response_model=List[UserProfile])
async def get_user_contacts(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get user's contacts"""
    contact_links = db.query(Contact).filter(Contact.user_id == current_user.id).all()
    contact_ids = [c.contact_user_id for c in contact_links]
    if not contact_ids:
        return []
    users = db.query(User).filter(User.id.in_(contact_ids), User.is_active == True).all()
    return users


@router.post("/contacts/{contact_user_id}")
async def add_contact(
    contact_user_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Add a user to current user's contacts."""
    if contact_user_id == current_user.id:
        raise HTTPException(status_code=400, detail="Cannot add yourself")
    target = db.query(User).filter(User.id == contact_user_id, User.is_active == True).first()
    if not target:
        raise HTTPException(status_code=404, detail="User not found")
    existing = db.query(Contact).filter(
        Contact.user_id == current_user.id,
        Contact.contact_user_id == contact_user_id
    ).first()
    if existing:
        return {"message": "Already in contacts"}
    db.add(Contact(user_id=current_user.id, contact_user_id=contact_user_id))
    db.commit()
    return {"message": "Contact added"}


@router.delete("/contacts/{contact_user_id}")
async def remove_contact(
    contact_user_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Remove a user from current user's contacts."""
    deleted = db.query(Contact).filter(
        Contact.user_id == current_user.id,
        Contact.contact_user_id == contact_user_id
    ).delete()
    db.commit()
    if deleted == 0:
        raise HTTPException(status_code=404, detail="Contact not found")
    return {"message": "Contact removed"}


@router.get("/{user_id}", response_model=UserProfile)
async def get_user_by_id(
    user_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get user profile by ID"""
    user = db.query(User).filter(User.id == user_id, User.is_active == True).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    return user


@router.get("/by-username/{username}", response_model=UserProfile)
async def get_user_by_username(
    username: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get user profile by username"""
    user = db.query(User).filter(
        User.username == username,
        User.is_active == True
    ).first()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    return user


@router.get("/by-phone", response_model=UserProfile)
async def get_user_by_phone(
    phone_number: str = Query(..., min_length=5, description="Phone number to lookup"),
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get user profile by phone number"""
    normalized = phone_number.replace(" ", "").replace("(", "").replace(")", "")
    user = db.query(User).filter(
        User.phone_number == normalized,
        User.is_active == True
    ).first()

    if not user:
        # try contains as a fallback (e.g., with country code formatting differences)
        user = db.query(User).filter(
            User.phone_number.contains(normalized),
            User.is_active == True
        ).first()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    return user

@router.post("/me/online")
async def set_user_online(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Set user as online"""
    current_user.is_online = True
    current_user.last_seen = datetime.utcnow()
    db.commit()
    
    return {"message": "User is now online"}


@router.post("/me/offline")
async def set_user_offline(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Set user as offline"""
    current_user.is_online = False
    current_user.last_seen = datetime.utcnow()
    db.commit()
    
    return {"message": "User is now offline"}


@router.delete("/me")
async def deactivate_account(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Deactivate user account"""
    current_user.is_active = False
    current_user.is_online = False
    current_user.updated_at = datetime.utcnow()
    db.commit()
    
    return {"message": "Account deactivated successfully"}
