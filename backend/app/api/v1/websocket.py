from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.websocket import manager
from app.core.security import verify_token
from app.models.user import User
from app.models.chat import ChatParticipant
import json

router = APIRouter(prefix="/ws", tags=["websocket"])


@router.websocket("/{token}")
async def websocket_endpoint(websocket: WebSocket, token: str):
    """WebSocket endpoint for real-time communication"""
    try:
        # Verify token
        payload = verify_token(token)
        user_id = payload.get("user_id")
        
        if not user_id:
            await websocket.close(code=1008, reason="Invalid token")
            return
        
        # Connect user
        await manager.connect(websocket, user_id)
        
        try:
            while True:
                # Receive message from client
                data = await websocket.receive_text()
                message_data = json.loads(data)
                
                # Handle different message types
                await handle_websocket_message(user_id, message_data)
                
        except WebSocketDisconnect:
            manager.disconnect(websocket, user_id)
            
    except Exception as e:
        await websocket.close(code=1008, reason="Authentication failed")


async def handle_websocket_message(user_id: int, message_data: dict):
    """Handle incoming WebSocket messages"""
    message_type = message_data.get("type")
    
    if message_type == "typing":
        # Handle typing indicator
        chat_id = message_data.get("chat_id")
        is_typing = message_data.get("is_typing", False)
        await manager.send_typing_indicator(chat_id, user_id, is_typing)
        
    elif message_type == "ping":
        # Handle ping/pong for connection health
        await manager.send_personal_message(
            json.dumps({"type": "pong", "timestamp": message_data.get("timestamp")}),
            user_id
        )
        
    elif message_type == "call":
        # Handle call notifications
        call_data = message_data.get("data", {})
        await manager.send_call_notification(call_data)
        
    else:
        # Unknown message type
        pass


@router.websocket("/chat/{chat_id}/{token}")
async def chat_websocket(websocket: WebSocket, chat_id: int, token: str):
    """WebSocket endpoint for specific chat"""
    try:
        # Verify token
        payload = verify_token(token)
        user_id = payload.get("user_id")
        
        if not user_id:
            await websocket.close(code=1008, reason="Invalid token")
            return
        
        # Check if user is participant in the chat
        # This would require database access, but for now we'll skip it
        
        # Connect user
        await manager.connect(websocket, user_id)
        
        try:
            while True:
                # Receive message from client
                data = await websocket.receive_text()
                message_data = json.loads(data)
                
                # Handle chat-specific messages
                await handle_chat_websocket_message(user_id, chat_id, message_data)
                
        except WebSocketDisconnect:
            manager.disconnect(websocket, user_id)
            
    except Exception as e:
        await websocket.close(code=1008, reason="Authentication failed")


async def handle_chat_websocket_message(user_id: int, chat_id: int, message_data: dict):
    """Handle chat-specific WebSocket messages"""
    message_type = message_data.get("type")
    
    if message_type == "typing":
        # Handle typing indicator for this chat
        is_typing = message_data.get("is_typing", False)
        await manager.send_typing_indicator(chat_id, user_id, is_typing)
        
    elif message_type == "message":
        # Handle new message
        await manager.send_message_notification({
            "chat_id": chat_id,
            "sender_id": user_id,
            "content": message_data.get("content"),
            "message_type": message_data.get("message_type", "text")
        })
        
    else:
        # Unknown message type
        pass
