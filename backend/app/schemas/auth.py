from pydantic import BaseModel, Field, validator
from typing import Optional

class PhoneVerificationRequest(BaseModel):
    phone_number: str = Field(..., min_length=10, max_length=20, example="+77001234567")
    
    @validator('phone_number')
    def validate_phone_number(cls, v):
        if not v.startswith('+'):
            raise ValueError('Phone number must start with +')
        return v

class PhoneVerificationResponse(BaseModel):
    success: bool
    message: str
    expires_in: int  # seconds
    code: Optional[str] = None  # For development only

class VerifyCodeRequest(BaseModel):
    phone_number: str = Field(..., min_length=10, max_length=20, example="+77001234567")
    verification_code: str = Field(..., min_length=4, max_length=4, example="1234")
    
    @validator('verification_code')
    def validate_verification_code(cls, v):
        if not v.isdigit():
            raise ValueError('Verification code must contain only digits')
        if len(v) != 4:
            raise ValueError('Verification code must be 4 digits')
        return v

class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"

class TokenData(BaseModel):
    user_id: Optional[int] = None
    phone_number: Optional[str] = None

class RefreshTokenRequest(BaseModel):
    refresh_token: str