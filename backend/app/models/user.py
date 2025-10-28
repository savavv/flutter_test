from sqlalchemy import Column, Integer, String, Boolean, DateTime, Text, LargeBinary
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    phone_number = Column(String(20), unique=True, index=True, nullable=False)
    username = Column(String(50), unique=True, index=True, nullable=True)
    first_name = Column(String(100), nullable=False)
    last_name = Column(String(100), nullable=True)
    bio = Column(Text, nullable=True)
    avatar_url = Column(String(500), nullable=True)
    is_online = Column(Boolean, default=False)
    last_seen = Column(DateTime, default=func.now())
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())

    # Relationships
    sent_messages = relationship("Message", foreign_keys="Message.sender_id", back_populates="sender")
    received_messages = relationship("Message", foreign_keys="Message.receiver_id", back_populates="receiver")
    chat_participants = relationship("ChatParticipant", back_populates="user")
    owned_chats = relationship("Chat", foreign_keys="Chat.owner_id", back_populates="owner")

    def __repr__(self):
        return f"<User(id={self.id}, phone={self.phone_number}, username={self.username})>"
