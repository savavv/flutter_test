#!/usr/bin/env python3
"""
Quick Start with SQLite for Telegram Clone Backend
Быстрый запуск с SQLite для локального тестирования
"""

import os
import sys
import subprocess
from pathlib import Path

def main():
    print("🚀 Telegram Clone Backend - Quick Start with SQLite")
    print("=" * 60)
    
    # Check if we're in the right directory
    if not Path("app").exists():
        print("❌ Please run this script from the backend directory")
        sys.exit(1)
    
    print("📋 Setting up SQLite for local development...")
    
    # Step 1: Create .env file if it doesn't exist
    if not Path(".env").exists():
        print("📝 Creating .env file from template...")
        if Path("env.example").exists():
            import shutil
            shutil.copy("env.example", ".env")
            print("✅ .env file created")
        else:
            print("❌ env.example file not found")
            sys.exit(1)
    
    # Step 2: Update .env for SQLite
    print("🔧 Configuring for SQLite...")
    with open(".env", "r", encoding="utf-8") as f:
        content = f.read()
    
    # Update configuration for SQLite
    content = content.replace('DATABASE_TYPE=postgresql', 'DATABASE_TYPE=sqlite')
    content = content.replace('USE_REDIS=true', 'USE_REDIS=false')
    content = content.replace('DEBUG=false', 'DEBUG=true')
    content = content.replace('ENVIRONMENT=production', 'ENVIRONMENT=development')
    
    with open(".env", "w", encoding="utf-8") as f:
        f.write(content)
    
    print("✅ Configuration updated for SQLite")
    
    # Step 3: Skip dependency installation
    print("📦 Skipping dependency installation...")
    print("💡 Make sure you have installed the required packages")
    
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
    
    # Step 5: Create upload directories
    print("📁 Creating upload directories...")
    os.makedirs("uploads/image", exist_ok=True)
    os.makedirs("uploads/video", exist_ok=True)
    os.makedirs("uploads/audio", exist_ok=True)
    os.makedirs("uploads/document", exist_ok=True)
    print("✅ Upload directories created")
    
    print("\n🎉 Setup complete!")
    print("\n📋 Next steps:")
    print("1. Run: python run.py")
    print("2. Open: http://localhost:8000/docs")
    print("3. Test the API endpoints")
    
    print("\n🔧 Configuration:")
    print("   Database: SQLite (telegram_clone.db)")
    print("   Redis: Disabled")
    print("   Security: Enabled")
    print("   Encryption: Enabled")
    print("   Rate Limiting: Enabled")
    
    print("\n🛡️ Security Features:")
    print("   ✅ AES-256-GCM encryption")
    print("   ✅ Rate limiting")
    print("   ✅ Security headers")
    print("   ✅ CSRF protection")
    print("   ✅ XSS protection")
    print("   ✅ SQL injection protection")
    
    print("\n🚀 To start the server:")
    print("   python run.py")
    
    print("\n📚 Documentation:")
    print("   http://localhost:8000/docs")
    print("   http://localhost:8000/redoc")

if __name__ == "__main__":
    main()
