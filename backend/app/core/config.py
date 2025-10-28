from pydantic_settings import BaseSettings
from typing import List, Optional
import os
import secrets


class Settings(BaseSettings):
    # Database Configuration
    database_type: str = "postgresql"
    database_url: str = "postgresql://username:password@localhost:5432/telegram_clone"
    database_url_test: str = "postgresql://username:password@localhost:5432/telegram_clone_test"
    sqlite_database_path: str = "telegram_clone.db"
    sqlite_test_database_path: str = "telegram_clone_test.db"
    
    # Redis
    redis_url: str = "redis://localhost:6379"
    use_redis: bool = True
    
    # Security & Encryption
    secret_key: str = secrets.token_urlsafe(32)
    encryption_key: str = secrets.token_urlsafe(32)
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    refresh_token_expire_days: int = 7
    
    # Password Security
    password_min_length: int = 8
    password_require_uppercase: bool = True
    password_require_lowercase: bool = True
    password_require_numbers: bool = True
    password_require_symbols: bool = True
    
    # Rate Limiting
    rate_limit_requests: int = 100
    rate_limit_window: int = 60
    rate_limit_sms: int = 5
    rate_limit_login: int = 10
    
    # Security Headers
    enable_security_headers: bool = False
    enable_csrf_protection: bool = True
    enable_helmet: bool = True
    
    # SMS Service
    sms_api_key: str = ""
    sms_api_url: str = "https://api.sms-service.com"
    sms_rate_limit: int = 5
    
    # File Storage & Security
    upload_dir: str = "uploads"
    max_file_size: int = 10485760
    allowed_file_types: List[str] = [
        "image/jpeg", "image/png", "image/gif", "image/webp",
        "video/mp4", "video/avi", "video/mov", "video/webm",
        "audio/mp3", "audio/wav", "audio/ogg", "audio/m4a",
        "application/pdf", "text/plain"
    ]
    scan_uploads_for_malware: bool = True
    
    # CORS & Security
    allowed_origins: List[str] = [
        "*"
    ]
    
    allowed_hosts: List[str] = ["*"]  # Для разработки
    # Environment
    environment: str = "development"
    debug: bool = True
    log_level: str = "INFO"
    
    # Database Connection Pool
    db_pool_size: int = 10
    db_max_overflow: int = 20
    db_pool_timeout: int = 30
    db_pool_recycle: int = 3600
    
    # Session Security
    session_cookie_secure: bool = False
    session_cookie_httponly: bool = True
    session_cookie_samesite: str = "lax"
    
    # Encryption for sensitive data
    encrypt_personal_data: bool = True
    encrypt_messages: bool = True
    encrypt_files: bool = False
    
    
    class Config:
        env_file = ".env"
        case_sensitive = False
    
    @property
    def database_url_final(self) -> str:
        """Get the final database URL based on configuration"""
        if self.database_type == "sqlite":
            return f"sqlite:///{self.sqlite_database_path}"
        return self.database_url
    
    @property
    def database_url_test_final(self) -> str:
        """Get the final test database URL based on configuration"""
        if self.database_type == "sqlite":
            return f"sqlite:///{self.sqlite_test_database_path}"
        return self.database_url_test
    
    def is_production(self) -> bool:
        """Check if running in production environment"""
        return self.environment.lower() == "production"
    
    def is_development(self) -> bool:
        """Check if running in development environment"""
        return self.environment.lower() == "development"


settings = Settings()