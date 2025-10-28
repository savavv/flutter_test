#!/usr/bin/env python3
"""
Database initialization script
Создание таблиц и начальных данных
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(__file__)))

from sqlalchemy.orm import Session
from app.core.database import SessionLocal, engine
from app.models import Base, User, Chat, ChatParticipant, Message, PhoneVerification
from app.core.security import get_password_hash
from datetime import datetime

def init_db():
    """Initialize database with tables and sample data"""
    
    # Create all tables
    print("Creating database tables...")
    Base.metadata.create_all(bind=engine)
    
    # Create database session
    db = SessionLocal()
    
    try:
        # Check if users already exist
        if db.query(User).first():
            print("Database already initialized!")
            return
        
        print("Creating sample data...")
        
        # Create sample users
        users_data = [
            {
                "phone_number": "+79914036115",
                "username": "admin",
                "first_name": "Admin",
                "last_name": "User",
                "bio": "System administrator",
                "is_verified": True,
                "is_online": True
            },
            {
                "phone_number": "+79912345678",
                "username": "alice",
                "first_name": "Alice",
                "last_name": "Johnson",
                "bio": "Hello! I'm Alice",
                "is_verified": True,
                "is_online": True
            },
            {
                "phone_number": "+79987654321",
                "username": "bob",
                "first_name": "Bob",
                "last_name": "Smith",
                "bio": "Nice to meet you!",
                "is_verified": True,
                "is_online": False
            },
            {
                "phone_number": "+79911111111",
                "username": "charlie",
                "first_name": "Charlie",
                "last_name": "Brown",
                "bio": "Developer",
                "is_verified": True,
                "is_online": True
            }
        ]
        
        users = []
        for user_data in users_data:
            user = User(**user_data)
            db.add(user)
            users.append(user)
        
        db.commit()
        
        # Create sample chats
        chats_data = [
            {
                "name": "General Chat",
                "description": "Main group chat",
                "chat_type": "group",
                "owner_id": users[0].id
            },
            {
                "name": "Development Team",
                "description": "Development discussions",
                "chat_type": "group",
                "owner_id": users[0].id
            }
        ]
        
        chats = []
        for chat_data in chats_data:
            chat = Chat(**chat_data)
            db.add(chat)
            chats.append(chat)
        
        db.commit()
        
        # Add participants to chats
        # General Chat - all users
        for user in users:
            participant = ChatParticipant(
                chat_id=chats[0].id,
                user_id=user.id,
                role="member" if user.id != users[0].id else "owner"
            )
            db.add(participant)
        
        # Development Team - first 3 users
        for user in users[:3]:
            participant = ChatParticipant(
                chat_id=chats[1].id,
                user_id=user.id,
                role="member" if user.id != users[0].id else "owner"
            )
            db.add(participant)
        
        db.commit()
        
        # Create sample messages
        messages_data = [
            {
                "chat_id": chats[0].id,
                "sender_id": users[0].id,
                "content": "Welcome to the general chat!",
                "message_type": "text"
            },
            {
                "chat_id": chats[0].id,
                "sender_id": users[1].id,
                "content": "Hello everyone! 👋",
                "message_type": "text"
            },
            {
                "chat_id": chats[0].id,
                "sender_id": users[2].id,
                "content": "Nice to be here!",
                "message_type": "text"
            },
            {
                "chat_id": chats[1].id,
                "sender_id": users[0].id,
                "content": "Let's discuss the new features",
                "message_type": "text"
            },
            {
                "chat_id": chats[1].id,
                "sender_id": users[1].id,
                "content": "I think we should focus on the mobile app first",
                "message_type": "text"
            }
        ]
        
        for message_data in messages_data:
            message = Message(**message_data)
            db.add(message)
        
        db.commit()
        
        print("✅ Database initialized successfully!")
        print(f"Created {len(users)} users")
        print(f"Created {len(chats)} chats")
        print(f"Created {len(messages_data)} messages")
        
    except Exception as e:
        print(f"❌ Error initializing database: {e}")
        db.rollback()
        raise
    finally:
        db.close()

if __name__ == "__main__":
    init_db()
