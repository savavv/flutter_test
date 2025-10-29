from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime


class UserBase(BaseModel):
    phone_number: str
    username: Optional[str] = None
    first_name: str
    last_name: Optional[str] = None
    bio: Optional[str] = None


class UserCreate(UserBase):
    pass


class UserUpdate(BaseModel):
    username: Optional[str] = None
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    bio: Optional[str] = None
    avatar_url: Optional[str] = None


class UserProfile(BaseModel):
    id: int
    phone_number: str
    username: Optional[str]
    first_name: str
    last_name: Optional[str]
    bio: Optional[str]
    avatar_url: Optional[str]
    is_online: bool
    last_seen: datetime
    is_verified: bool
    public_key: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


class UserResponse(UserProfile):
    pass


class PublicKeyUpdate(BaseModel):
    public_key: str
