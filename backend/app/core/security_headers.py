"""
Advanced security headers middleware for Telegram Clone
Provides comprehensive security headers and protection
"""

from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.middleware.base import RequestResponseEndpoint
from starlette.responses import Response as StarletteResponse
import time
from typing import Dict, List
from app.core.config import settings


class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    """Advanced security headers middleware"""
    
    def __init__(self, app):
        super().__init__(app)
        self.security_headers = self._get_security_headers()
    
    def _get_security_headers(self) -> Dict[str, str]:
        """Get comprehensive security headers"""
        headers = {}
        
        if settings.enable_security_headers:
            # Content Security Policy
            headers['Content-Security-Policy'] = (
                "default-src 'self'; "
                "script-src 'self' 'unsafe-inline' 'unsafe-eval'; "
                "style-src 'self' 'unsafe-inline'; "
                "img-src 'self' data: https:; "
                "font-src 'self' data:; "
                "connect-src 'self' wss: ws:; "
                "frame-ancestors 'none'; "
                "base-uri 'self'; "
                "form-action 'self'"
            )
            
            # X-Frame-Options
            headers['X-Frame-Options'] = 'DENY'
            
            # X-Content-Type-Options
            headers['X-Content-Type-Options'] = 'nosniff'
            
            # X-XSS-Protection
            headers['X-XSS-Protection'] = '1; mode=block'
            
            # Referrer Policy
            headers['Referrer-Policy'] = 'strict-origin-when-cross-origin'
            
            # Permissions Policy
            headers['Permissions-Policy'] = (
                "geolocation=(), "
                "microphone=(), "
                "camera=(), "
                "payment=(), "
                "usb=(), "
                "magnetometer=(), "
                "gyroscope=(), "
                "speaker=()"
            )
            
            # Strict Transport Security (HTTPS only)
            if settings.is_production():
                headers['Strict-Transport-Security'] = (
                    'max-age=31536000; '
                    'includeSubDomains; '
                    'preload'
                )
            
            # Cross-Origin Policies
            headers['Cross-Origin-Embedder-Policy'] = 'require-corp'
            headers['Cross-Origin-Opener-Policy'] = 'same-origin'
            headers['Cross-Origin-Resource-Policy'] = 'same-origin'
            
            # Additional security headers
            headers['X-Permitted-Cross-Domain-Policies'] = 'none'
            headers['X-Download-Options'] = 'noopen'
            headers['X-DNS-Prefetch-Control'] = 'off'
            
            # Server information hiding
            headers['Server'] = 'Telegram Clone API'
            
            # Cache control for sensitive endpoints
            headers['Cache-Control'] = 'no-store, no-cache, must-revalidate, proxy-revalidate'
            headers['Pragma'] = 'no-cache'
            headers['Expires'] = '0'
        
        return headers
    
    async def dispatch(self, request: Request, call_next: RequestResponseEndpoint) -> StarletteResponse:
        """Process request and add security headers"""
        start_time = time.time()
        
        # Add security headers to response
        response = await call_next(request)
        
        # Add all security headers
        for header, value in self.security_headers.items():
            response.headers[header] = value
        
        # Add timing headers
        process_time = time.time() - start_time
        response.headers['X-Process-Time'] = str(process_time)
        
        # Add request ID for tracking
        request_id = getattr(request.state, 'request_id', None)
        if request_id:
            response.headers['X-Request-ID'] = request_id
        
        return response


class CSRFProtectionMiddleware(BaseHTTPMiddleware):
    """CSRF protection middleware"""
    
    def __init__(self, app):
        super().__init__(app)
        self.csrf_token_header = 'X-CSRF-Token'
        self.csrf_cookie_name = 'csrf_token'
    
    async def dispatch(self, request: Request, call_next: RequestResponseEndpoint) -> StarletteResponse:
        """Process request with CSRF protection"""
        if settings.enable_csrf_protection:
            # Skip CSRF for safe methods
            if request.method in ['GET', 'HEAD', 'OPTIONS']:
                response = await call_next(request)
                return response
            
            # Check CSRF token for state-changing methods
            if request.method in ['POST', 'PUT', 'PATCH', 'DELETE']:
                csrf_token = request.headers.get(self.csrf_token_header)
                if not csrf_token:
                    return StarletteResponse(
                        content='CSRF token missing',
                        status_code=403
                    )
                
                # In production, validate CSRF token
                # For now, just check if it exists
                if not self._validate_csrf_token(csrf_token):
                    return StarletteResponse(
                        content='Invalid CSRF token',
                        status_code=403
                    )
        
        response = await call_next(request)
        return response
    
    def _validate_csrf_token(self, token: str) -> bool:
        """Validate CSRF token"""
        # In production, implement proper CSRF token validation
        # For now, just check if token exists and is not empty
        return bool(token and len(token) > 10)


class HelmetMiddleware(BaseHTTPMiddleware):
    """Helmet.js equivalent middleware for Python"""
    
    def __init__(self, app):
        super().__init__(app)
        self.helmet_headers = self._get_helmet_headers()
    
    def _get_helmet_headers(self) -> Dict[str, str]:
        """Get Helmet.js equivalent headers"""
        headers = {}
        
        if settings.enable_helmet:
            # DNS Prefetch Control
            headers['X-DNS-Prefetch-Control'] = 'off'
            
            # Hide X-Powered-By
            headers['X-Powered-By'] = ''
            
            # Expect-CT
            if settings.is_production():
                headers['Expect-CT'] = 'max-age=86400, enforce'
            
            # Feature Policy
            headers['Feature-Policy'] = (
                "geolocation 'none'; "
                "microphone 'none'; "
                "camera 'none'; "
                "payment 'none'; "
                "usb 'none'"
            )
        
        return headers
    
    async def dispatch(self, request: Request, call_next: RequestResponseEndpoint) -> StarletteResponse:
        """Process request with Helmet protection"""
        response = await call_next(request)
        
        # Add Helmet headers
        for header, value in self.helmet_headers.items():
            if value:
                response.headers[header] = value
        
        return response


class RequestIDMiddleware(BaseHTTPMiddleware):
    """Add request ID to all requests for tracking"""
    
    def __init__(self, app):
        super().__init__(app)
    
    async def dispatch(self, request: Request, call_next: RequestResponseEndpoint) -> StarletteResponse:
        """Add request ID to request and response"""
        import uuid
        
        # Generate unique request ID
        request_id = str(uuid.uuid4())
        request.state.request_id = request_id
        
        # Process request
        response = await call_next(request)
        
        # Add request ID to response headers
        response.headers['X-Request-ID'] = request_id
        
        return response


class SecurityAuditMiddleware(BaseHTTPMiddleware):
    """Security audit middleware for logging suspicious activity"""
    
    def __init__(self, app):
        super().__init__(app)
        self.suspicious_patterns = [
            'script', 'javascript:', 'vbscript:', 'onload=', 'onerror=',
            'union select', 'drop table', 'delete from', 'insert into',
            '../', '..\\', '/etc/passwd', '/proc/version'
        ]
    
    async def dispatch(self, request: Request, call_next: RequestResponseEndpoint) -> StarletteResponse:
        """Audit request for suspicious activity"""
        # Check for suspicious patterns in URL and headers
        url = str(request.url)
        user_agent = request.headers.get('user-agent', '')
        
        for pattern in self.suspicious_patterns:
            if pattern.lower() in url.lower() or pattern.lower() in user_agent.lower():
                # Log suspicious activity
                self._log_suspicious_activity(request, pattern)
                
                # In production, you might want to block or rate limit
                # For now, just log and continue
                break
        
        response = await call_next(request)
        return response
    
    def _log_suspicious_activity(self, request: Request, pattern: str):
        """Log suspicious activity"""
        import logging
        
        logger = logging.getLogger('security')
        logger.warning(
            f"Suspicious activity detected: {pattern} "
            f"from {request.client.host if request.client else 'unknown'} "
            f"to {request.url}"
        )


def get_security_middleware() -> List[BaseHTTPMiddleware]:
    """Get list of security middleware"""
    return [
        RequestIDMiddleware,
        SecurityHeadersMiddleware,
        CSRFProtectionMiddleware,
        HelmetMiddleware,
        SecurityAuditMiddleware
    ]
