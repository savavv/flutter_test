from sqlalchemy import create_engine, event
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from app.core.config import settings
import os

# Create base class for models
Base = declarative_base()

# Database engine configuration
def create_database_engine():
    """Create database engine based on configuration"""
    database_url = settings.database_url_final
    
    if settings.database_type == "sqlite":
        # SQLite configuration
        engine_kwargs = {
            "echo": settings.debug,
            "connect_args": {"check_same_thread": False},
            "poolclass": StaticPool,
            "pool_pre_ping": True,
        }
    else:
        # PostgreSQL configuration
        engine_kwargs = {
            "echo": settings.debug,
            "pool_pre_ping": True,
            "pool_recycle": settings.db_pool_recycle,
            "pool_size": settings.db_pool_size,
            "max_overflow": settings.db_max_overflow,
            "pool_timeout": settings.db_pool_timeout,
        }
    
    engine = create_engine(database_url, **engine_kwargs)
    
    # SQLite specific optimizations
    if settings.database_type == "sqlite":
        @event.listens_for(engine, "connect")
        def set_sqlite_pragma(dbapi_connection, connection_record):
            cursor = dbapi_connection.cursor()
            # Enable foreign keys
            cursor.execute("PRAGMA foreign_keys=ON")
            # Set WAL mode for better concurrency
            cursor.execute("PRAGMA journal_mode=WAL")
            # Set synchronous mode for better performance
            cursor.execute("PRAGMA synchronous=NORMAL")
            # Set cache size
            cursor.execute("PRAGMA cache_size=10000")
            # Set temp store to memory
            cursor.execute("PRAGMA temp_store=MEMORY")
            cursor.close()
    
    return engine

# Create database engine
engine = create_database_engine()

# Create session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    """Dependency to get database session"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def create_tables():
    """Create all database tables"""
    Base.metadata.create_all(bind=engine)

def drop_tables():
    """Drop all database tables"""
    Base.metadata.drop_all(bind=engine)
