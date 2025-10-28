from typing import Dict, List, Set
from fastapi import WebSocket
import asyncio
import json
import logging


logger = logging.getLogger(__name__)


class ConnectionManager:
    """In-memory websocket connection manager keyed by user_id.

    - connect: accepts websocket and registers it under user_id
    - disconnect: removes websocket for user_id
    - send_personal_message: send text to all connections of a user
    - broadcast: send text to all connected users
    - helpers for typing/call notifications used by API layer
    """

    def __init__(self) -> None:
        self._user_id_to_connections: Dict[int, Set[WebSocket]] = {}
        self._lock = asyncio.Lock()

    async def connect(self, websocket: WebSocket, user_id: int) -> None:
        await websocket.accept()
        async with self._lock:
            if user_id not in self._user_id_to_connections:
                self._user_id_to_connections[user_id] = set()
            self._user_id_to_connections[user_id].add(websocket)
        logger.info("WebSocket connected: user_id=%s total_conns=%s", user_id, len(self._user_id_to_connections[user_id]))

    def disconnect(self, websocket: WebSocket, user_id: int) -> None:
        try:
            connections = self._user_id_to_connections.get(user_id)
            if connections and websocket in connections:
                connections.remove(websocket)
                if not connections:
                    self._user_id_to_connections.pop(user_id, None)
            logger.info("WebSocket disconnected: user_id=%s remaining_conns=%s", user_id, len(self._user_id_to_connections.get(user_id, [])))
        except Exception as exc:
            logger.error("Error during disconnect for user_id=%s: %s", user_id, exc)

    async def send_personal_message(self, message_text: str, user_id: int) -> None:
        connections = list(self._user_id_to_connections.get(user_id, []))
        for ws in connections:
            try:
                await ws.send_text(message_text)
            except Exception as exc:
                logger.warning("Failed to send to user_id=%s: %s", user_id, exc)

    async def broadcast(self, message_text: str) -> None:
        all_connections: List[WebSocket] = []
        for conns in self._user_id_to_connections.values():
            all_connections.extend(list(conns))
        for ws in all_connections:
            try:
                await ws.send_text(message_text)
            except Exception as exc:
                logger.warning("Broadcast send failed: %s", exc)

    async def send_typing_indicator(self, chat_id: int, user_id: int, is_typing: bool) -> None:
        payload = {
            "type": "typing_indicator",
            "chat_id": chat_id,
            "user_id": user_id,
            "is_typing": is_typing,
        }
        await self.broadcast(json.dumps(payload))

    async def send_call_notification(self, call_data: dict) -> None:
        payload = {
            "type": "call_notification",
            "data": call_data or {},
        }
        await self.broadcast(json.dumps(payload))


# Export singleton manager
manager = ConnectionManager()