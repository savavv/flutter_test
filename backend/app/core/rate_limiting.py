"""
Advanced rate limiting system for Telegram Clone
Provides multiple rate limiting strategies for different endpoints
"""

from fastapi import Request, HTTPException, status
from fastapi.responses import JSONResponse
import time
import hashlib
from typing import Dict, Optional, Tuple
from collections import defaultdict, deque
from datetime import datetime, timedelta
import asyncio
from app.core.config import settings


class RateLimiter:
    """Advanced rate limiter with multiple strategies"""
    
    def __init__(self):
        # In-memory storage for rate limiting
        self.requests: Dict[str, deque] = defaultdict(deque)
        self.blocked_ips: Dict[str, float] = {}
        self.failed_attempts: Dict[str, int] = defaultdict(int)
        
        # Rate limiting rules
        self.rules = {
            'general': {
                'requests': settings.rate_limit_requests,
                'window': settings.rate_limit_window,
                'block_duration': 300  # 5 minutes
            },
            'sms': {
                'requests': settings.rate_limit_sms,
                'window': 3600,  # 1 hour
                'block_duration': 1800  # 30 minutes
            },
            'login': {
                'requests': settings.rate_limit_login,
                'window': 3600,  # 1 hour
                'block_duration': 3600  # 1 hour
            },
            'upload': {
                'requests': 10,
                'window': 300,  # 5 minutes
                'block_duration': 600  # 10 minutes
            },
            'message': {
                'requests': 100,
                'window': 60,  # 1 minute
                'block_duration': 300  # 5 minutes
            }
        }
    
    def _get_client_ip(self, request: Request) -> str:
        """Extract client IP address"""
        # Check for forwarded headers first
        forwarded_for = request.headers.get('X-Forwarded-For')
        if forwarded_for:
            return forwarded_for.split(',')[0].strip()
        
        real_ip = request.headers.get('X-Real-IP')
        if real_ip:
            return real_ip
        
        # Fallback to direct connection
        return request.client.host if request.client else 'unknown'
    
    def _get_rate_limit_key(self, request: Request, rule_type: str, user_id: Optional[str] = None) -> str:
        """Generate rate limit key"""
        client_ip = self._get_client_ip(request)
        
        if user_id:
            # User-based rate limiting
            return f"user:{user_id}:{rule_type}"
        else:
            # IP-based rate limiting
            return f"ip:{client_ip}:{rule_type}"
    
    def _cleanup_old_requests(self, key: str, window: int):
        """Clean up old requests outside the window"""
        current_time = time.time()
        cutoff_time = current_time - window
        
        # Remove old requests
        while self.requests[key] and self.requests[key][0] < cutoff_time:
            self.requests[key].popleft()
    
    def _is_blocked(self, key: str) -> bool:
        """Check if key is currently blocked"""
        if key in self.blocked_ips:
            if time.time() < self.blocked_ips[key]:
                return True
            else:
                # Remove expired block
                del self.blocked_ips[key]
        return False
    
    def _block_key(self, key: str, duration: int):
        """Block key for specified duration"""
        self.blocked_ips[key] = time.time() + duration
    
    def _increment_failed_attempts(self, key: str):
        """Increment failed attempts counter"""
        self.failed_attempts[key] += 1
    
    def _reset_failed_attempts(self, key: str):
        """Reset failed attempts counter"""
        self.failed_attempts[key] = 0
    
    def check_rate_limit(self, request: Request, rule_type: str, user_id: Optional[str] = None) -> Tuple[bool, Dict]:
        """Check if request is within rate limits"""
        if rule_type not in self.rules:
            return True, {}
        
        rule = self.rules[rule_type]
        key = self._get_rate_limit_key(request, rule_type, user_id)
        
        # Check if currently blocked
        if self._is_blocked(key):
            return False, {
                'error': 'Rate limit exceeded',
                'retry_after': int(self.blocked_ips[key] - time.time()),
                'blocked': True
            }
        
        # Clean up old requests
        self._cleanup_old_requests(key, rule['window'])
        
        # Check current request count
        current_requests = len(self.requests[key])
        
        if current_requests >= rule['requests']:
            # Rate limit exceeded
            self._block_key(key, rule['block_duration'])
            self._increment_failed_attempts(key)
            
            return False, {
                'error': 'Rate limit exceeded',
                'retry_after': rule['block_duration'],
                'blocked': True,
                'failed_attempts': self.failed_attempts[key]
            }
        
        # Add current request
        self.requests[key].append(time.time())
        
        # Calculate remaining requests
        remaining = rule['requests'] - current_requests - 1
        
        return True, {
            'remaining': remaining,
            'reset_time': time.time() + rule['window'],
            'failed_attempts': self.failed_attempts[key]
        }
    
    def get_rate_limit_headers(self, request: Request, rule_type: str, user_id: Optional[str] = None) -> Dict[str, str]:
        """Get rate limit headers for response"""
        if rule_type not in self.rules:
            return {}
        
        rule = self.rules[rule_type]
        key = self._get_rate_limit_key(request, rule_type, user_id)
        
        # Clean up old requests
        self._cleanup_old_requests(key, rule['window'])
        
        current_requests = len(self.requests[key])
        remaining = max(0, rule['requests'] - current_requests)
        
        return {
            'X-RateLimit-Limit': str(rule['requests']),
            'X-RateLimit-Remaining': str(remaining),
            'X-RateLimit-Reset': str(int(time.time() + rule['window'])),
            'X-RateLimit-Window': str(rule['window'])
        }


class AdvancedRateLimiter:
    """Advanced rate limiter with Redis support and multiple strategies"""
    
    def __init__(self):
        self.rate_limiter = RateLimiter()
        self.suspicious_ips: Dict[str, int] = defaultdict(int)
        self.geo_blocking: Dict[str, bool] = {}
    
    def check_request(self, request: Request, rule_type: str, user_id: Optional[str] = None) -> Tuple[bool, Dict]:
        """Check if request should be allowed"""
        client_ip = self.rate_limiter._get_client_ip(request)
        
        # Check for suspicious activity
        if self._is_suspicious_ip(client_ip):
            return False, {
                'error': 'Suspicious activity detected',
                'retry_after': 3600,
                'blocked': True
            }
        
        # Check geo-blocking
        if self._is_geo_blocked(client_ip):
            return False, {
                'error': 'Access from this region is not allowed',
                'retry_after': 3600,
                'blocked': True
            }
        
        # Check rate limits
        allowed, info = self.rate_limiter.check_rate_limit(request, rule_type, user_id)
        
        if not allowed:
            # Mark IP as suspicious after multiple failures
            if info.get('failed_attempts', 0) > 5:
                self._mark_suspicious_ip(client_ip)
        
        return allowed, info
    
    def _is_suspicious_ip(self, ip: str) -> bool:
        """Check if IP is marked as suspicious"""
        return self.suspicious_ips.get(ip, 0) > 3
    
    def _mark_suspicious_ip(self, ip: str):
        """Mark IP as suspicious"""
        self.suspicious_ips[ip] += 1
    
    def _is_geo_blocked(self, ip: str) -> bool:
        """Check if IP is geo-blocked"""
        # In production, implement actual geo-blocking
        return False
    
    def get_rate_limit_headers(self, request: Request, rule_type: str, user_id: Optional[str] = None) -> Dict[str, str]:
        """Get rate limit headers"""
        return self.rate_limiter.get_rate_limit_headers(request, rule_type, user_id)


# Global rate limiter instance
rate_limiter = AdvancedRateLimiter()


def rate_limit(rule_type: str, user_based: bool = False):
    """Decorator for rate limiting endpoints"""
    def decorator(func):
        async def wrapper(*args, **kwargs):
            # Extract request from arguments
            request = None
            user_id = None
            
            for arg in args:
                if isinstance(arg, Request):
                    request = arg
                    break
            
            if not request:
                return await func(*args, **kwargs)
            
            # Get user ID if user-based rate limiting
            if user_based:
                # This would need to be implemented based on your auth system
                pass
            
            # Check rate limit
            allowed, info = rate_limiter.check_request(request, rule_type, user_id)
            
            if not allowed:
                headers = rate_limiter.get_rate_limit_headers(request, rule_type, user_id)
                return JSONResponse(
                    status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                    content={
                        'detail': info.get('error', 'Rate limit exceeded'),
                        'retry_after': info.get('retry_after', 60)
                    },
                    headers=headers
                )
            
            # Add rate limit headers to response
            response = await func(*args, **kwargs)
            if hasattr(response, 'headers'):
                headers = rate_limiter.get_rate_limit_headers(request, rule_type, user_id)
                for key, value in headers.items():
                    response.headers[key] = value
            
            return response
        
        return wrapper
    return decorator
