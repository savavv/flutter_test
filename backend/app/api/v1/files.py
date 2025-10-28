from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from typing import Optional
import os
import uuid
import aiofiles
from datetime import datetime
from app.core.database import get_db
from app.api.dependencies import get_current_active_user
from app.models.user import User
from app.core.config import settings
from PIL import Image
import shutil

router = APIRouter(prefix="/files", tags=["files"])

# Allowed file types
ALLOWED_IMAGE_TYPES = {"image/jpeg", "image/png", "image/gif", "image/webp"}
ALLOWED_VIDEO_TYPES = {"video/mp4", "video/avi", "video/mov", "video/webm"}
ALLOWED_AUDIO_TYPES = {"audio/mp3", "audio/wav", "audio/ogg", "audio/m4a"}
ALLOWED_DOCUMENT_TYPES = {
    "application/pdf", "application/msword", 
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    "text/plain", "application/zip", "application/x-rar-compressed"
}

# File size limits (in bytes)
MAX_IMAGE_SIZE = 10 * 1024 * 1024  # 10MB
MAX_VIDEO_SIZE = 100 * 1024 * 1024  # 100MB
MAX_AUDIO_SIZE = 50 * 1024 * 1024  # 50MB
MAX_DOCUMENT_SIZE = 50 * 1024 * 1024  # 50MB


@router.post("/upload")
async def upload_file(
    file: UploadFile = File(...),
    file_type: str = Form(...),  # image, video, audio, document
    current_user: User = Depends(get_current_active_user)
):
    """Upload a file"""
    
    # Validate file type
    if file_type not in ["image", "video", "audio", "document"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid file type"
        )
    
    # Check file size
    file_size = 0
    content = await file.read()
    file_size = len(content)
    
    # Validate file size based on type
    if file_type == "image" and file_size > MAX_IMAGE_SIZE:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Image file too large"
        )
    elif file_type == "video" and file_size > MAX_VIDEO_SIZE:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Video file too large"
        )
    elif file_type == "audio" and file_size > MAX_AUDIO_SIZE:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Audio file too large"
        )
    elif file_type == "document" and file_size > MAX_DOCUMENT_SIZE:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Document file too large"
        )
    
    # Validate MIME type
    if file_type == "image" and file.content_type not in ALLOWED_IMAGE_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid image format"
        )
    elif file_type == "video" and file.content_type not in ALLOWED_VIDEO_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid video format"
        )
    elif file_type == "audio" and file.content_type not in ALLOWED_AUDIO_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid audio format"
        )
    elif file_type == "document" and file.content_type not in ALLOWED_DOCUMENT_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid document format"
        )
    
    # Generate unique filename
    file_extension = os.path.splitext(file.filename)[1]
    unique_filename = f"{uuid.uuid4()}{file_extension}"
    
    # Create directory if it doesn't exist
    upload_dir = os.path.join(settings.upload_dir, file_type)
    os.makedirs(upload_dir, exist_ok=True)
    
    # Save file
    file_path = os.path.join(upload_dir, unique_filename)
    
    async with aiofiles.open(file_path, 'wb') as f:
        await f.write(content)
    
    # Generate thumbnail for images
    thumbnail_url = None
    if file_type == "image":
        try:
            thumbnail_url = await generate_image_thumbnail(file_path, upload_dir)
        except Exception as e:
            print(f"Error generating thumbnail: {e}")
    
    # Return file info
    return {
        "file_id": unique_filename,
        "filename": file.filename,
        "file_type": file_type,
        "file_size": file_size,
        "mime_type": file.content_type,
        "url": f"/files/{file_type}/{unique_filename}",
        "thumbnail_url": thumbnail_url,
        "uploaded_at": datetime.utcnow().isoformat()
    }


@router.get("/{file_type}/{filename}")
async def get_file(file_type: str, filename: str):
    """Get uploaded file"""
    
    if file_type not in ["image", "video", "audio", "document"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid file type"
        )
    
    file_path = os.path.join(settings.upload_dir, file_type, filename)
    
    if not os.path.exists(file_path):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="File not found"
        )
    
    return FileResponse(file_path)


@router.get("/{file_type}/{filename}/thumbnail")
async def get_thumbnail(file_type: str, filename: str):
    """Get file thumbnail"""
    
    if file_type != "image":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Thumbnails only available for images"
        )
    
    file_path = os.path.join(settings.upload_dir, file_type, filename)
    thumbnail_path = os.path.join(settings.upload_dir, file_type, "thumbnails", filename)
    
    if not os.path.exists(file_path):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="File not found"
        )
    
    if not os.path.exists(thumbnail_path):
        # Generate thumbnail if it doesn't exist
        try:
            await generate_image_thumbnail(file_path, os.path.join(settings.upload_dir, file_type))
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Error generating thumbnail"
            )
    
    return FileResponse(thumbnail_path)


@router.delete("/{file_type}/{filename}")
async def delete_file(
    file_type: str,
    filename: str,
    current_user: User = Depends(get_current_active_user)
):
    """Delete uploaded file"""
    
    if file_type not in ["image", "video", "audio", "document"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid file type"
        )
    
    file_path = os.path.join(settings.upload_dir, file_type, filename)
    thumbnail_path = os.path.join(settings.upload_dir, file_type, "thumbnails", filename)
    
    if not os.path.exists(file_path):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="File not found"
        )
    
    # Delete file
    os.remove(file_path)
    
    # Delete thumbnail if exists
    if os.path.exists(thumbnail_path):
        os.remove(thumbnail_path)
    
    return {"message": "File deleted successfully"}


async def generate_image_thumbnail(file_path: str, upload_dir: str) -> str:
    """Generate thumbnail for image"""
    try:
        # Create thumbnails directory
        thumbnails_dir = os.path.join(upload_dir, "thumbnails")
        os.makedirs(thumbnails_dir, exist_ok=True)
        
        # Open image
        with Image.open(file_path) as img:
            # Create thumbnail (max 300x300)
            img.thumbnail((300, 300), Image.Resampling.LANCZOS)
            
            # Save thumbnail
            thumbnail_path = os.path.join(thumbnails_dir, os.path.basename(file_path))
            img.save(thumbnail_path, optimize=True, quality=85)
            
            return f"/files/{os.path.basename(upload_dir)}/thumbnails/{os.path.basename(file_path)}"
            
    except Exception as e:
        print(f"Error generating thumbnail: {e}")
        return None
