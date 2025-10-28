from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from app.core.database import get_db
from app.core.security import (
    create_access_token, 
    create_refresh_token, 
    verify_token,
    generate_verification_code
)
from app.models.user import User
from app.models.verification import PhoneVerification
from app.schemas.auth import (
    PhoneVerificationRequest,
    PhoneVerificationResponse,
    VerifyCodeRequest,
    Token,
    RefreshTokenRequest
)
from app.schemas.user import UserCreate, UserResponse
import asyncio

router = APIRouter(prefix="/auth", tags=["authentication"])


@router.post("/send-verification", response_model=PhoneVerificationResponse)
async def send_verification_code(
    request: PhoneVerificationRequest,
    db: Session = Depends(get_db)
):
    """Send verification code to phone number"""
    phone_number = request.phone_number
    
    # Check if user already exists
    existing_user = db.query(User).filter(User.phone_number == phone_number).first()
    
    # Generate verification code
    verification_code = generate_verification_code()
    
    # Create or update verification record
    verification = db.query(PhoneVerification).filter(
        PhoneVerification.phone_number == phone_number
    ).first()
    
    if verification:
        verification.verification_code = verification_code
        verification.is_verified = False
        verification.attempts = 0
        verification.expires_at = datetime.utcnow() + timedelta(minutes=5)
    else:
        verification = PhoneVerification(
            phone_number=phone_number,
            verification_code=verification_code,
            expires_at=datetime.utcnow() + timedelta(minutes=5)
        )
        db.add(verification)
    
    db.commit()
    
    # In production, send SMS here
    # For development, we'll just return the code
    print(f"Verification code for {phone_number}: {verification_code}")
    
    # Return response with code for development
    return {
        "success": True,
        "message": "Verification code sent successfully",
        "expires_in": 300,
        "code": verification_code  # For development only
    }


@router.post("/verify-code", response_model=Token)
async def verify_code(
    request: VerifyCodeRequest,
    db: Session = Depends(get_db)
):
    """Verify phone number with code and create/update user"""
    phone_number = request.phone_number
    verification_code = request.verification_code
    
    # Get verification record
    verification = db.query(PhoneVerification).filter(
        PhoneVerification.phone_number == phone_number
    ).first()
    
    if not verification:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No verification request found for this phone number"
        )
    
    if verification.is_verified:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Phone number already verified"
        )
    
    if verification.attempts >= verification.max_attempts:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Too many attempts. Please request a new code."
        )
    
    if datetime.utcnow() > verification.expires_at:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Verification code expired"
        )
    
    if verification.verification_code != verification_code:
        verification.attempts += 1
        db.commit()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid verification code"
        )
    
    # Mark as verified
    verification.is_verified = True
    verification.verified_at = datetime.utcnow()
    
    # Create or update user
    user = db.query(User).filter(User.phone_number == phone_number).first()
    
    if not user:
        # Check for duplicate phone_number before creating
        existing_user = db.query(User).filter(User.phone_number == phone_number).first()
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="User with this phone number already exists"
            )
        
        # Create new user
        try:
            user = User(
                phone_number=phone_number,
                first_name="User",  # Default name
                is_verified=True
            )
            db.add(user)
            db.flush()  # Get the ID
        except Exception as e:
            db.rollback()
            if "UNIQUE constraint failed" in str(e) or "duplicate key" in str(e).lower():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Номер телефона уже зарегистрирован. Используйте другой номер."
                )
            raise
    
    # Update user verification status
    user.is_verified = True
    user.is_online = True
    user.last_seen = datetime.utcnow()
    
    db.commit()
    
    # Create tokens
    access_token = create_access_token(data={"user_id": user.id, "phone_number": user.phone_number})
    refresh_token = create_refresh_token(data={"user_id": user.id, "phone_number": user.phone_number})
    
    return {
        "success": True,
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer"
    }


@router.post("/refresh-token", response_model=Token)
async def refresh_token(
    request: RefreshTokenRequest,
    db: Session = Depends(get_db)
):
    """Refresh access token using refresh token"""
    try:
        payload = verify_token(request.refresh_token, token_type="refresh")
        user_id = payload.get("user_id")
        
        if user_id is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid refresh token"
            )
        
        user = db.query(User).filter(User.id == user_id).first()
        if not user or not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User not found or inactive"
            )
        
        # Create new tokens
        access_token = create_access_token(data={"user_id": user.id, "phone_number": user.phone_number})
        refresh_token = create_refresh_token(data={"user_id": user.id, "phone_number": user.phone_number})
        
        return Token(
            access_token=access_token,
            refresh_token=refresh_token,
            token_type="bearer"
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token"
        )


@router.post("/logout")
async def logout():
    """Logout user (client should discard tokens)"""
    return {"message": "Successfully logged out"}
