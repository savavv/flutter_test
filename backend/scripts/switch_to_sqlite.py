#!/usr/bin/env python3
"""
Switch to SQLite for local development
Переключение на SQLite для локальной разработки
"""

import os
import sys
import shutil
from pathlib import Path

# Add the app directory to the Python path
sys.path.append(os.path.dirname(os.path.dirname(__file__)))

from app.core.config import settings
from app.core.database import create_tables, drop_tables
from app.core.encryption import encryption_manager


def switch_to_sqlite():
    """Switch database to SQLite"""
    print("🔄 Switching to SQLite for local development...")
    
    # Update environment variables
    env_file = Path(".env")
    if env_file.exists():
        print("📝 Updating .env file...")
        
        # Read current .env file
        with open(env_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Update database configuration
        content = content.replace('DATABASE_TYPE=postgresql', 'DATABASE_TYPE=sqlite')
        content = content.replace('USE_REDIS=true', 'USE_REDIS=false')
        content = content.replace('DEBUG=false', 'DEBUG=true')
        
        # Write updated .env file
        with open(env_file, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print("✅ .env file updated")
    else:
        print("⚠️  .env file not found, creating from template...")
        shutil.copy('env.example', '.env')
    
    # Create SQLite database
    print("🗄️  Creating SQLite database...")
    create_tables()
    print("✅ SQLite database created")
    
    # Initialize with sample data
    print("📊 Initializing with sample data...")
    try:
        from scripts.init_db import init_db
        init_db()
        print("✅ Sample data loaded")
    except Exception as e:
        print(f"⚠️  Could not load sample data: {e}")
    
    print("\n🎉 Successfully switched to SQLite!")
    print("\n📋 Next steps:")
    print("1. Run: python run.py")
    print("2. Open: http://localhost:8000/docs")
    print("3. Test the API endpoints")
    
    print("\n🔧 SQLite Configuration:")
    print(f"   Database: {settings.sqlite_database_path}")
    print(f"   Test Database: {settings.sqlite_test_database_path}")
    print(f"   Encryption: {'Enabled' if settings.encrypt_personal_data else 'Disabled'}")
    print(f"   Security Headers: {'Enabled' if settings.enable_security_headers else 'Disabled'}")


def switch_to_postgresql():
    """Switch database to PostgreSQL"""
    print("🔄 Switching to PostgreSQL...")
    
    env_file = Path(".env")
    if env_file.exists():
        print("📝 Updating .env file...")
        
        # Read current .env file
        with open(env_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Update database configuration
        content = content.replace('DATABASE_TYPE=sqlite', 'DATABASE_TYPE=postgresql')
        content = content.replace('USE_REDIS=false', 'USE_REDIS=true')
        
        # Write updated .env file
        with open(env_file, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print("✅ .env file updated")
    
    print("\n🎉 Successfully switched to PostgreSQL!")
    print("\n📋 Next steps:")
    print("1. Make sure PostgreSQL is running")
    print("2. Create database: createdb telegram_clone")
    print("3. Run: python run.py")


def show_status():
    """Show current database configuration"""
    print("📊 Current Database Configuration:")
    print(f"   Type: {settings.database_type}")
    print(f"   URL: {settings.database_url_final}")
    print(f"   Redis: {'Enabled' if settings.use_redis else 'Disabled'}")
    print(f"   Environment: {settings.environment}")
    print(f"   Debug: {settings.debug}")
    print(f"   Security Headers: {'Enabled' if settings.enable_security_headers else 'Disabled'}")
    print(f"   Encryption: {'Enabled' if settings.encrypt_personal_data else 'Disabled'}")


if __name__ == "__main__":
    if len(sys.argv) > 1:
        command = sys.argv[1].lower()
        
        if command == "sqlite":
            switch_to_sqlite()
        elif command == "postgresql":
            switch_to_postgresql()
        elif command == "status":
            show_status()
        else:
            print("❌ Unknown command. Use: sqlite, postgresql, or status")
    else:
        print("🔧 Database Configuration Tool")
        print("\nUsage:")
        print("  python scripts/switch_to_sqlite.py sqlite      # Switch to SQLite")
        print("  python scripts/switch_to_sqlite.py postgresql  # Switch to PostgreSQL")
        print("  python scripts/switch_to_sqlite.py status      # Show current status")
        print("\nCurrent status:")
        show_status()
