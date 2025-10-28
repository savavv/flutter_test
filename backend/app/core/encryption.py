"""
Advanced encryption module for Telegram Clone
Provides AES-256-GCM encryption for sensitive data
"""

from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
import base64
import secrets
import hashlib
from typing import Union, Optional
import json
from app.core.config import settings


class EncryptionManager:
    """Advanced encryption manager for sensitive data"""
    
    def __init__(self):
        self.encryption_key = self._derive_key(settings.encryption_key)
        self.fernet = Fernet(self._create_fernet_key())
    
    def _derive_key(self, password: str) -> bytes:
        """Derive encryption key from password using PBKDF2"""
        password_bytes = password.encode('utf-8')
        salt = b'telegram_clone_salt'  # In production, use random salt per encryption
        kdf = PBKDF2HMAC(
            algorithm=hashes.SHA256(),
            length=32,
            salt=salt,
            iterations=100000,
        )
        return kdf.derive(password_bytes)
    
    def _create_fernet_key(self) -> bytes:
        """Create Fernet key from derived key"""
        return base64.urlsafe_b64encode(self.encryption_key)
    
    def encrypt_data(self, data: Union[str, dict, bytes]) -> str:
        """Encrypt sensitive data using AES-256-GCM"""
        if isinstance(data, dict):
            data = json.dumps(data, ensure_ascii=False)
        if isinstance(data, str):
            data = data.encode('utf-8')
        
        # Generate random nonce
        nonce = secrets.token_bytes(12)
        
        # Create AESGCM cipher
        aesgcm = AESGCM(self.encryption_key)
        
        # Encrypt data
        encrypted_data = aesgcm.encrypt(nonce, data, None)
        
        # Combine nonce and encrypted data
        combined = nonce + encrypted_data
        
        # Encode to base64
        return base64.urlsafe_b64encode(combined).decode('utf-8')
    
    def decrypt_data(self, encrypted_data: str) -> Union[str, dict]:
        """Decrypt sensitive data"""
        try:
            # Decode from base64
            combined = base64.urlsafe_b64decode(encrypted_data.encode('utf-8'))
            
            # Split nonce and encrypted data
            nonce = combined[:12]
            encrypted = combined[12:]
            
            # Create AESGCM cipher
            aesgcm = AESGCM(self.encryption_key)
            
            # Decrypt data
            decrypted_data = aesgcm.decrypt(nonce, encrypted, None)
            
            # Try to parse as JSON, fallback to string
            try:
                return json.loads(decrypted_data.decode('utf-8'))
            except (json.JSONDecodeError, UnicodeDecodeError):
                return decrypted_data.decode('utf-8')
                
        except Exception as e:
            raise ValueError(f"Failed to decrypt data: {str(e)}")
    
    def encrypt_message(self, message: str) -> str:
        """Encrypt message content"""
        if not settings.encrypt_messages:
            return message
        return self.encrypt_data(message)
    
    def decrypt_message(self, encrypted_message: str) -> str:
        """Decrypt message content"""
        if not settings.encrypt_messages:
            return encrypted_message
        return self.decrypt_data(encrypted_message)
    
    def encrypt_personal_data(self, data: dict) -> dict:
        """Encrypt personal data fields"""
        if not settings.encrypt_personal_data:
            return data
        
        encrypted_data = data.copy()
        sensitive_fields = ['bio', 'first_name', 'last_name']
        
        for field in sensitive_fields:
            if field in encrypted_data and encrypted_data[field]:
                encrypted_data[field] = self.encrypt_data(encrypted_data[field])
        
        return encrypted_data
    
    def decrypt_personal_data(self, data: dict) -> dict:
        """Decrypt personal data fields"""
        if not settings.encrypt_personal_data:
            return data
        
        decrypted_data = data.copy()
        sensitive_fields = ['bio', 'first_name', 'last_name']
        
        for field in sensitive_fields:
            if field in decrypted_data and decrypted_data[field]:
                try:
                    decrypted_data[field] = self.decrypt_data(decrypted_data[field])
                except ValueError:
                    # If decryption fails, keep original value
                    pass
        
        return decrypted_data
    
    def hash_sensitive_data(self, data: str) -> str:
        """Create secure hash of sensitive data"""
        salt = secrets.token_hex(16)
        hash_obj = hashlib.pbkdf2_hmac('sha256', data.encode('utf-8'), salt.encode('utf-8'), 100000)
        return f"{salt}:{hash_obj.hex()}"
    
    def verify_hash(self, data: str, hashed_data: str) -> bool:
        """Verify hash of sensitive data"""
        try:
            salt, hash_hex = hashed_data.split(':')
            hash_obj = hashlib.pbkdf2_hmac('sha256', data.encode('utf-8'), salt.encode('utf-8'), 100000)
            return hash_obj.hex() == hash_hex
        except (ValueError, AttributeError):
            return False


class SecureRandom:
    """Secure random number generator"""
    
    @staticmethod
    def generate_token(length: int = 32) -> str:
        """Generate cryptographically secure random token"""
        return secrets.token_urlsafe(length)
    
    @staticmethod
    def generate_verification_code(length: int = 6) -> str:
        """Generate secure verification code"""
        return ''.join([str(secrets.randbelow(10)) for _ in range(length)])
    
    @staticmethod
    def generate_session_id() -> str:
        """Generate secure session ID"""
        return secrets.token_urlsafe(32)


class DataSanitizer:
    """Data sanitization and validation"""
    
    @staticmethod
    def sanitize_phone_number(phone: str) -> str:
        """Sanitize and validate phone number"""
        # Remove all non-digit characters
        digits = ''.join(filter(str.isdigit, phone))
        
        # Add country code if missing
        if not phone.startswith('+'):
            if digits.startswith('7') and len(digits) == 11:
                return f"+{digits}"
            elif len(digits) == 10:
                return f"+7{digits}"
        
        return phone
    
    @staticmethod
    def sanitize_username(username: str) -> str:
        """Sanitize username"""
        # Remove special characters, keep only alphanumeric and underscore
        sanitized = ''.join(c for c in username if c.isalnum() or c == '_')
        return sanitized.lower()
    
    @staticmethod
    def sanitize_text(text: str, max_length: int = 1000) -> str:
        """Sanitize text input"""
        # Remove null bytes and control characters
        sanitized = ''.join(c for c in text if ord(c) >= 32 or c in '\n\r\t')
        
        # Limit length
        if len(sanitized) > max_length:
            sanitized = sanitized[:max_length]
        
        return sanitized.strip()


# Global encryption manager instance
encryption_manager = EncryptionManager()
secure_random = SecureRandom()
data_sanitizer = DataSanitizer()
