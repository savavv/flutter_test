from sqlalchemy import Column, Integer, String, DateTime, Boolean
from sqlalchemy.sql import func
from app.core.database import Base


class PhoneVerification(Base):
    __tablename__ = "phone_verifications"

    id = Column(Integer, primary_key=True, index=True)
    phone_number = Column(String(20), nullable=False, index=True)
    verification_code = Column(String(10), nullable=False)
    is_verified = Column(Boolean, default=False)
    attempts = Column(Integer, default=0)
    max_attempts = Column(Integer, default=3)
    expires_at = Column(DateTime, nullable=False)
    created_at = Column(DateTime, default=func.now())
    verified_at = Column(DateTime, nullable=True)

    def __repr__(self):
        return f"<PhoneVerification(phone={self.phone_number}, verified={self.is_verified})>"
