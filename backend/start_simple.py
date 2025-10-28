#!/usr/bin/env python3
"""
Simple startup script for Telegram Clone Backend
Упрощенный скрипт запуска бекенда
"""

import os
import sys
import subprocess
from pathlib import Path

def main():
    print("🚀 Telegram Clone Backend - Simple Start")
    print("=" * 50)
    
    # Check if we're in the right directory
    if not Path("app").exists():
        print("❌ Please run this script from the backend directory")
        sys.exit(1)
    
    print("📋 Setting up for local development...")
    
    # Step 1: Create .env file if it doesn't exist
    if not Path(".env").exists():
        print("📝 Creating .env file...")
        env_content = """# Database Configuration
DATABASE_TYPE=sqlite
SQLITE_DATABASE_PATH=telegram_clone.db
USE_REDIS=false

# Security & Encryption
SECRET_KEY=dev-secret-key-change-in-production
ENCRYPTION_KEY=dev-encryption-key-change-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7

# Security Headers
ENABLE_SECURITY_HEADERS=true
ENABLE_CSRF_PROTECTION=false
ENABLE_HELMET=true

# Rate Limiting
RATE_LIMIT_REQUESTS=1000
RATE_LIMIT_WINDOW=60
RATE_LIMIT_SMS=10
RATE_LIMIT_LOGIN=20

# Environment
ENVIRONMENT=development
DEBUG=true
LOG_LEVEL=INFO

# Data Encryption
ENCRYPT_PERSONAL_DATA=false
ENCRYPT_MESSAGES=false
ENCRYPT_FILES=false

# CORS & Security
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080,http://localhost:8000
ALLOWED_HOSTS=localhost,127.0.0.1

# File Storage
UPLOAD_DIR=uploads
MAX_FILE_SIZE=10485760
"""
        
        with open(".env", "w", encoding="utf-8") as f:
            f.write(env_content)
        print("✅ .env file created")
    
    # Step 2: Skip dependency installation (assume they are already installed)
    print("📦 Skipping dependency installation...")
    print("💡 Make sure you have installed: pip install fastapi uvicorn sqlalchemy")
    
    # Step 3: Create upload directories
    print("📁 Creating upload directories...")
    os.makedirs("uploads/image", exist_ok=True)
    os.makedirs("uploads/video", exist_ok=True)
    os.makedirs("uploads/audio", exist_ok=True)
    os.makedirs("uploads/document", exist_ok=True)
    print("✅ Upload directories created")
    
    # Step 4: Initialize database
    print("🗄️ Initializing SQLite database...")
    try:
        # Import and run database initialization
        sys.path.append(os.getcwd())
        from app.core.database import create_tables
        from scripts.init_db import init_db
        
        create_tables()
        init_db()
        print("✅ Database initialized with sample data")
    except Exception as e:
        print(f"⚠️ Database initialization failed: {e}")
        print("   You can still run the server, but without sample data")
    
    print("\n🎉 Setup complete!")
    print("\n📋 Next steps:")
    print("1. Run: python run.py")
    print("2. Open: http://localhost:8000/docs")
    print("3. Test the API endpoints")
    
    print("\n🔧 Configuration:")
    print("   Database: SQLite (telegram_clone.db)")
    print("   Redis: Disabled")
    print("   Security: Basic (development mode)")
    print("   Encryption: Disabled (for development)")
    
    print("\n🚀 To start the server:")
    print("   python run.py")
    
    print("\n📚 Documentation:")
    print("   http://localhost:8000/docs")
    print("   http://localhost:8000/redoc")

if __name__ == "__main__":
    main()
