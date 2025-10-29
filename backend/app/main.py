from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import JSONResponse
from starlette.middleware.trustedhost import TrustedHostMiddleware
import os
import logging
from app.core.config import settings
from app.core.database import engine, Base, create_tables
from app.core.security_headers import get_security_middleware
from app.api.v1 import auth, users, chats, messages, websocket, files
from fastapi.openapi.docs import get_swagger_ui_html, get_redoc_html
import requests

# Configure logging
logging.basicConfig(
    level=getattr(logging, settings.log_level),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def download_swagger_files():
    """Download Swagger UI files for offline use"""
    files = {
        "swagger-ui-bundle.js": "https://cdn.jsdelivr.net/npm/swagger-ui-dist@5.9.0/swagger-ui-bundle.js",
        "swagger-ui-standalone-preset.js": "https://cdn.jsdelivr.net/npm/swagger-ui-dist@5.9.0/swagger-ui-standalone-preset.js", 
        "swagger-ui.css": "https://cdn.jsdelivr.net/npm/swagger-ui-dist@5.9.0/swagger-ui.css",
        "favicon-32x32.png": "https://fastapi.tiangolo.com/img/favicon-32x32.png"
    }
    
    os.makedirs("static/docs", exist_ok=True)
    
    for filename, url in files.items():
        try:
            response = requests.get(url)
            with open(f"static/docs/{filename}", "wb") as f:
                f.write(response.content)
            logger.info(f"Downloaded: {filename}")
        except Exception as e:
            logger.error(f"Error downloading {filename}: {e}")

# Download Swagger files on startup
download_swagger_files()

# Create database tables
create_tables()

# Create FastAPI app with disabled default docs
app = FastAPI(
    title="KS54 Messanger API",
    description="Backend API for messaging application with advanced security",
    version="1.0.0",
    docs_url=None,  # Disable default docs
    redoc_url=None, # Disable default redoc
    openapi_url="/openapi.json"
)

# CORS middleware - ДОЛЖЕН БЫТЬ ПЕРВЫМ!
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://127.0.0.1:3000", 
        "http://localhost:8000",
        "http://127.0.0.1:8000",
        "http://localhost:52300",
        "http://127.0.0.1:54035",
        "http://localhost:54035",  # Dart VM
        "http://127.0.0.1:54341",
        "http://localhost:9101",
        "http://127.0.0.1:9101",
        "http://localhost",
        "http://127.0.0.1",
        "*"
    ],
    allow_credentials=True,
    allow_methods=["*"],  # Разрешаем все методы
    allow_headers=["*"],  # Разрешаем все заголовки
    expose_headers=["*"],
    max_age=600,
)

# Временно отключаем security middleware для разработки
# if settings.enable_security_headers:
#     for middleware_class in get_security_middleware():
#         app.add_middleware(middleware_class)

# Trusted host middleware - временно разрешаем все хосты
app.add_middleware(
    TrustedHostMiddleware,
    allowed_hosts=["*"]
)

# Create upload directory
os.makedirs(settings.upload_dir, exist_ok=True)
os.makedirs(os.path.join(settings.upload_dir, "image"), exist_ok=True)
os.makedirs(os.path.join(settings.upload_dir, "video"), exist_ok=True)
os.makedirs(os.path.join(settings.upload_dir, "audio"), exist_ok=True)
os.makedirs(os.path.join(settings.upload_dir, "document"), exist_ok=True)

# Mount static files
app.mount("/static", StaticFiles(directory="static"), name="static")
app.mount("/files", StaticFiles(directory=settings.upload_dir), name="files")

# Include routers
app.include_router(auth.router, prefix="/api/v1")
app.include_router(users.router, prefix="/api/v1")
app.include_router(chats.router, prefix="/api/v1")
app.include_router(messages.router, prefix="/api/v1")
app.include_router(websocket.router, prefix="/api/v1")
app.include_router(files.router, prefix="/api/v1")

# Custom OPTIONS handler for CORS preflight
@app.options("/api/v1/{path:path}")
async def options_handler(path: str):
    """Handle OPTIONS requests for CORS preflight"""
    return JSONResponse(
        status_code=200,
        content={"message": "CORS preflight successful"},
        headers={
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
            "Access-Control-Allow-Headers": "*",
        }
    )

# Custom docs endpoints
@app.get("/docs", include_in_schema=False)
async def custom_swagger_ui_html():
    return get_swagger_ui_html(
        openapi_url=app.openapi_url,
        title=app.title + " - Swagger UI",
        oauth2_redirect_url=app.swagger_ui_oauth2_redirect_url,
        swagger_js_url="/static/docs/swagger-ui-bundle.js",
        swagger_css_url="/static/docs/swagger-ui.css",
        swagger_favicon_url="/static/docs/favicon-32x32.png",
    )

@app.get("/redoc", include_in_schema=False)
async def custom_redoc_html():
    return get_redoc_html(
        openapi_url=app.openapi_url,
        title=app.title + " - ReDoc",
        redoc_js_url="/static/docs/swagger-ui-bundle.js",
    )

@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "Telegram Clone API",
        "version": "1.0.0",
        "environment": settings.environment,
        "docs": "/docs",
        "redoc": "/redoc",
        "openapi": "/openapi.json"
    }

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy", 
        "environment": settings.environment,
        "debug": settings.debug
    }

@app.get("/cors-test")
async def cors_test():
    """Endpoint to test CORS configuration"""
    return {
        "message": "CORS test successful",
        "cors_enabled": True,
        "timestamp": "2024-01-01T00:00:00Z"
    }

@app.get("/debug/routes")
async def debug_routes():
    """Debug endpoint to see all registered routes"""
    routes = []
    for route in app.routes:
        route_info = {
            "path": getattr(route, "path", None),
            "name": getattr(route, "name", None),
            "methods": getattr(route, "methods", None)
        }
        routes.append(route_info)
    return {"routes": routes}

@app.get("/openapi.json", include_in_schema=False)
async def get_openapi():
    """Direct OpenAPI schema endpoint"""
    return JSONResponse(app.openapi())

# Global exception handler with CORS headers
@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    """Global HTTP exception handler"""
    logger.error(f"HTTP error {exc.status_code}: {exc.detail}")
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "detail": exc.detail,
            "status_code": exc.status_code
        },
        headers={
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
            "Access-Control-Allow-Headers": "*",
        }
    )

@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    """Global exception handler"""
    logger.error(f"Internal server error: {str(exc)}")
    return JSONResponse(
        status_code=500,
        content={
            "detail": "Internal server error",
            "status_code": 500
        },
        headers={
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
            "Access-Control-Allow-Headers": "*",
        }
    )

@app.on_event("startup")
async def startup_event():
    """Run on application startup"""
    logger.info("Application starting up...")
    logger.info(f"Environment: {settings.environment}")
    logger.info(f"Debug mode: {settings.debug}")
    logger.info(f"Database URL: {settings.database_url}")
    logger.info("CORS configured for development")

@app.on_event("shutdown")
async def shutdown_event():
    """Run on application shutdown"""
    logger.info("Application shutting down...")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.debug,
        log_level=settings.log_level.lower()
    )