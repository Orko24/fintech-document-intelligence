#!/usr/bin/env python3
"""
FinTech AI Platform - Security Hardening Module

This module provides comprehensive security features for the FinTech AI Platform:
- Input validation and sanitization
- Rate limiting and DDoS protection
- Encryption and key management
- Audit logging and compliance
- Vulnerability scanning
- Security monitoring and alerting

Author: FinTech AI Security Team
Date: 2024
"""

import os
import sys
import logging
import hashlib
import hmac
import base64
import json
import time
import uuid
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional, Union, Tuple
from dataclasses import dataclass, asdict
from pathlib import Path
import secrets
import re
import ipaddress
from functools import wraps
import jwt
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa, padding
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
import redis
import prometheus_client
from prometheus_client import Counter, Histogram, Gauge

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Security metrics
SECURITY_EVENTS = Counter('security_events_total', 'Total security events', ['event_type', 'severity'])
AUTHENTICATION_ATTEMPTS = Counter('authentication_attempts_total', 'Authentication attempts', ['status'])
RATE_LIMIT_VIOLATIONS = Counter('rate_limit_violations_total', 'Rate limit violations', ['endpoint'])
ENCRYPTION_OPERATIONS = Counter('encryption_operations_total', 'Encryption operations', ['operation'])
VULNERABILITY_SCANS = Counter('vulnerability_scans_total', 'Vulnerability scans', ['status'])

@dataclass
class SecurityConfig:
    """Security configuration settings."""
    # Authentication
    jwt_secret: str = "your-super-secret-jwt-key-change-this"
    jwt_algorithm: str = "HS256"
    jwt_expiration_hours: int = 24
    refresh_token_expiration_days: int = 30
    
    # Rate Limiting
    rate_limit_requests: int = 100
    rate_limit_window: int = 60  # seconds
    burst_limit: int = 200
    
    # Encryption
    encryption_key: str = None
    key_rotation_days: int = 90
    
    # Input Validation
    max_file_size: int = 50 * 1024 * 1024  # 50MB
    allowed_file_types: List[str] = None
    max_text_length: int = 10000
    
    # Network Security
    allowed_ips: List[str] = None
    blocked_ips: List[str] = None
    geo_restrictions: List[str] = None
    
    # Audit Logging
    audit_log_path: str = "/var/log/fintech-ai/audit.log"
    log_retention_days: int = 365
    
    # Compliance
    gdpr_enabled: bool = True
    sox_compliance: bool = True
    pci_dss_enabled: bool = True
    
    def __post_init__(self):
        if self.allowed_file_types is None:
            self.allowed_file_types = ['.pdf', '.docx', '.xlsx', '.txt', '.csv']
        if self.allowed_ips is None:
            self.allowed_ips = []
        if self.blocked_ips is None:
            self.blocked_ips = []
        if self.geo_restrictions is None:
            self.geo_restrictions = []
        if self.encryption_key is None:
            self.encryption_key = Fernet.generate_key()

class InputValidator:
    """Comprehensive input validation and sanitization."""
    
    def __init__(self, config: SecurityConfig):
        self.config = config
        self.xss_patterns = [
            r'<script[^>]*>.*?</script>',
            r'javascript:',
            r'on\w+\s*=',
            r'<iframe[^>]*>',
            r'<object[^>]*>',
            r'<embed[^>]*>',
            r'<form[^>]*>',
            r'<input[^>]*>',
            r'<textarea[^>]*>',
            r'<select[^>]*>'
        ]
        self.sql_injection_patterns = [
            r'(\b(union|select|insert|update|delete|drop|create|alter)\b)',
            r'(\b(or|and)\b\s+\d+\s*=\s*\d+)',
            r'(\b(union|select|insert|update|delete|drop|create|alter)\b.*\b(union|select|insert|update|delete|drop|create|alter)\b)',
            r'(\b(union|select|insert|update|delete|drop|create|alter)\b.*\b(union|select|insert|update|delete|drop|create|alter)\b.*\b(union|select|insert|update|delete|drop|create|alter)\b)'
        ]
        self.path_traversal_patterns = [
            r'\.\./',
            r'\.\.\\',
            r'%2e%2e%2f',
            r'%2e%2e%5c',
            r'..%2f',
            r'..%5c'
        ]
    
    def validate_text(self, text: str, max_length: Optional[int] = None) -> Tuple[bool, str]:
        """Validate and sanitize text input."""
        if not isinstance(text, str):
            return False, "Input must be a string"
        
        if max_length is None:
            max_length = self.config.max_text_length
        
        if len(text) > max_length:
            return False, f"Text exceeds maximum length of {max_length} characters"
        
        # Check for XSS patterns
        for pattern in self.xss_patterns:
            if re.search(pattern, text, re.IGNORECASE):
                SECURITY_EVENTS.labels(event_type='xss_attempt', severity='high').inc()
                return False, "Potentially malicious content detected"
        
        # Check for SQL injection patterns
        for pattern in self.sql_injection_patterns:
            if re.search(pattern, text, re.IGNORECASE):
                SECURITY_EVENTS.labels(event_type='sql_injection_attempt', severity='critical').inc()
                return False, "Potentially malicious SQL content detected"
        
        # Check for path traversal patterns
        for pattern in self.path_traversal_patterns:
            if re.search(pattern, text, re.IGNORECASE):
                SECURITY_EVENTS.labels(event_type='path_traversal_attempt', severity='high').inc()
                return False, "Path traversal attempt detected"
        
        # Sanitize text
        sanitized = self._sanitize_text(text)
        
        return True, sanitized
    
    def validate_file(self, file_content: bytes, filename: str) -> Tuple[bool, str]:
        """Validate uploaded file."""
        # Check file size
        if len(file_content) > self.config.max_file_size:
            return False, f"File size exceeds maximum limit of {self.config.max_file_size} bytes"
        
        # Check file extension
        file_ext = Path(filename).suffix.lower()
        if file_ext not in self.config.allowed_file_types:
            return False, f"File type {file_ext} is not allowed"
        
        # Check for malicious content in file
        if self._contains_malicious_content(file_content):
            SECURITY_EVENTS.labels(event_type='malicious_file_upload', severity='critical').inc()
            return False, "File contains potentially malicious content"
        
        return True, "File validation passed"
    
    def validate_email(self, email: str) -> Tuple[bool, str]:
        """Validate email address."""
        email_pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        if not re.match(email_pattern, email):
            return False, "Invalid email format"
        
        # Check for disposable email domains
        disposable_domains = ['tempmail.com', 'throwaway.com', '10minutemail.com']
        domain = email.split('@')[1].lower()
        if domain in disposable_domains:
            return False, "Disposable email addresses are not allowed"
        
        return True, email
    
    def validate_ip(self, ip: str) -> Tuple[bool, str]:
        """Validate IP address and check restrictions."""
        try:
            ip_obj = ipaddress.ip_address(ip)
            
            # Check if IP is blocked
            if str(ip_obj) in self.config.blocked_ips:
                return False, "IP address is blocked"
            
            # Check if IP is in allowed list (if restrictions exist)
            if self.config.allowed_ips and str(ip_obj) not in self.config.allowed_ips:
                return False, "IP address not in allowed list"
            
            return True, str(ip_obj)
        
        except ValueError:
            return False, "Invalid IP address format"
    
    def _sanitize_text(self, text: str) -> str:
        """Sanitize text input."""
        # Remove null bytes
        text = text.replace('\x00', '')
        
        # Normalize whitespace
        text = ' '.join(text.split())
        
        # Remove control characters
        text = ''.join(char for char in text if ord(char) >= 32 or char in '\n\r\t')
        
        return text
    
    def _contains_malicious_content(self, file_content: bytes) -> bool:
        """Check if file contains malicious content."""
        content_str = file_content.decode('utf-8', errors='ignore').lower()
        
        # Check for executable content
        executable_patterns = [
            b'<script', b'javascript:', b'vbscript:', b'<iframe',
            b'<object', b'<embed', b'<form', b'<input', b'<textarea'
        ]
        
        for pattern in executable_patterns:
            if pattern in file_content.lower():
                return True
        
        # Check for shell commands
        shell_patterns = [
            'cmd.exe', 'powershell', 'bash', 'sh', 'exec', 'system',
            'eval', 'exec', 'os.system', 'subprocess'
        ]
        
        for pattern in shell_patterns:
            if pattern in content_str:
                return True
        
        return False

class RateLimiter:
    """Rate limiting implementation with Redis backend."""
    
    def __init__(self, redis_client: redis.Redis, config: SecurityConfig):
        self.redis = redis_client
        self.config = config
    
    def is_allowed(self, identifier: str, endpoint: str = "default") -> Tuple[bool, Dict[str, Any]]:
        """Check if request is allowed based on rate limits."""
        key = f"rate_limit:{identifier}:{endpoint}"
        current_time = int(time.time())
        window_start = current_time - self.config.rate_limit_window
        
        # Get current request count
        pipe = self.redis.pipeline()
        pipe.zremrangebyscore(key, 0, window_start)
        pipe.zadd(key, {str(current_time): current_time})
        pipe.zcard(key)
        pipe.expire(key, self.config.rate_limit_window)
        results = pipe.execute()
        
        request_count = results[2]
        
        # Check burst limit
        if request_count > self.config.burst_limit:
            RATE_LIMIT_VIOLATIONS.labels(endpoint=endpoint).inc()
            return False, {
                "allowed": False,
                "limit": self.config.burst_limit,
                "remaining": 0,
                "reset_time": current_time + self.config.rate_limit_window,
                "reason": "Burst limit exceeded"
            }
        
        # Check regular rate limit
        if request_count > self.config.rate_limit_requests:
            RATE_LIMIT_VIOLATIONS.labels(endpoint=endpoint).inc()
            return False, {
                "allowed": False,
                "limit": self.config.rate_limit_requests,
                "remaining": 0,
                "reset_time": current_time + self.config.rate_limit_window,
                "reason": "Rate limit exceeded"
            }
        
        return True, {
            "allowed": True,
            "limit": self.config.rate_limit_requests,
            "remaining": self.config.rate_limit_requests - request_count,
            "reset_time": current_time + self.config.rate_limit_window
        }

class EncryptionManager:
    """Encryption and key management."""
    
    def __init__(self, config: SecurityConfig):
        self.config = config
        self.fernet = Fernet(config.encryption_key)
        self.key_rotation_date = datetime.now()
    
    def encrypt_data(self, data: Union[str, bytes]) -> str:
        """Encrypt sensitive data."""
        if isinstance(data, str):
            data = data.encode('utf-8')
        
        encrypted = self.fernet.encrypt(data)
        ENCRYPTION_OPERATIONS.labels(operation='encrypt').inc()
        
        return base64.b64encode(encrypted).decode('utf-8')
    
    def decrypt_data(self, encrypted_data: str) -> str:
        """Decrypt sensitive data."""
        try:
            encrypted_bytes = base64.b64decode(encrypted_data.encode('utf-8'))
            decrypted = self.fernet.decrypt(encrypted_bytes)
            ENCRYPTION_OPERATIONS.labels(operation='decrypt').inc()
            
            return decrypted.decode('utf-8')
        
        except Exception as e:
            logger.error(f"Decryption failed: {e}")
            raise ValueError("Failed to decrypt data")
    
    def generate_key_pair(self) -> Tuple[str, str]:
        """Generate RSA key pair for asymmetric encryption."""
        private_key = rsa.generate_private_key(
            public_exponent=65537,
            key_size=2048
        )
        
        public_key = private_key.public_key()
        
        # Serialize keys
        private_pem = private_key.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.PKCS8,
            encryption_algorithm=serialization.NoEncryption()
        )
        
        public_pem = public_key.public_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PublicFormat.SubjectPublicKeyInfo
        )
        
        return private_pem.decode('utf-8'), public_pem.decode('utf-8')
    
    def encrypt_with_public_key(self, data: str, public_key_pem: str) -> str:
        """Encrypt data with RSA public key."""
        public_key = serialization.load_pem_public_key(public_key_pem.encode('utf-8'))
        
        encrypted = public_key.encrypt(
            data.encode('utf-8'),
            padding.OAEP(
                mgf=padding.MGF1(algorithm=hashes.SHA256()),
                algorithm=hashes.SHA256(),
                label=None
            )
        )
        
        return base64.b64encode(encrypted).decode('utf-8')
    
    def should_rotate_keys(self) -> bool:
        """Check if keys should be rotated."""
        days_since_rotation = (datetime.now() - self.key_rotation_date).days
        return days_since_rotation >= self.config.key_rotation_days

class AuditLogger:
    """Comprehensive audit logging for compliance."""
    
    def __init__(self, config: SecurityConfig):
        self.config = config
        self.log_path = Path(config.audit_log_path)
        self.log_path.parent.mkdir(parents=True, exist_ok=True)
    
    def log_event(self, event_type: str, user_id: str, action: str, 
                  details: Dict[str, Any], severity: str = "info", 
                  ip_address: str = None, user_agent: str = None):
        """Log security event for audit purposes."""
        event = {
            "timestamp": datetime.utcnow().isoformat(),
            "event_id": str(uuid.uuid4()),
            "event_type": event_type,
            "user_id": user_id,
            "action": action,
            "details": details,
            "severity": severity,
            "ip_address": ip_address,
            "user_agent": user_agent,
            "session_id": details.get("session_id"),
            "request_id": details.get("request_id")
        }
        
        # Log to file
        with open(self.log_path, 'a') as f:
            f.write(json.dumps(event) + '\n')
        
        # Log to metrics
        SECURITY_EVENTS.labels(event_type=event_type, severity=severity).inc()
        
        # Log to console for high severity events
        if severity in ['high', 'critical']:
            logger.warning(f"Security event: {event_type} - {action} by {user_id}")
    
    def log_authentication(self, user_id: str, success: bool, 
                          ip_address: str = None, user_agent: str = None):
        """Log authentication attempts."""
        event_type = "authentication_success" if success else "authentication_failure"
        action = "login" if success else "login_failed"
        severity = "info" if success else "warning"
        
        self.log_event(
            event_type=event_type,
            user_id=user_id,
            action=action,
            details={"success": success},
            severity=severity,
            ip_address=ip_address,
            user_agent=user_agent
        )
        
        AUTHENTICATION_ATTEMPTS.labels(status="success" if success else "failure").inc()
    
    def log_data_access(self, user_id: str, resource_type: str, resource_id: str,
                       action: str, ip_address: str = None):
        """Log data access events."""
        self.log_event(
            event_type="data_access",
            user_id=user_id,
            action=action,
            details={
                "resource_type": resource_type,
                "resource_id": resource_id,
                "action": action
            },
            severity="info",
            ip_address=ip_address
        )
    
    def log_admin_action(self, admin_id: str, action: str, target: str,
                        details: Dict[str, Any], ip_address: str = None):
        """Log administrative actions."""
        self.log_event(
            event_type="admin_action",
            user_id=admin_id,
            action=action,
            details={
                "target": target,
                "admin_action": True,
                **details
            },
            severity="high",
            ip_address=ip_address
        )
    
    def cleanup_old_logs(self):
        """Clean up old audit logs based on retention policy."""
        cutoff_date = datetime.now() - timedelta(days=self.config.log_retention_days)
        
        if self.log_path.exists():
            with open(self.log_path, 'r') as f:
                lines = f.readlines()
            
            # Filter out old entries
            current_lines = []
            for line in lines:
                try:
                    event = json.loads(line.strip())
                    event_time = datetime.fromisoformat(event['timestamp'])
                    if event_time > cutoff_date:
                        current_lines.append(line)
                except:
                    continue
            
            # Write back filtered logs
            with open(self.log_path, 'w') as f:
                f.writelines(current_lines)

class SecurityMonitor:
    """Real-time security monitoring and alerting."""
    
    def __init__(self, config: SecurityConfig):
        self.config = config
        self.threat_patterns = self._load_threat_patterns()
        self.alert_thresholds = {
            "failed_logins": 5,  # per minute
            "rate_limit_violations": 10,  # per minute
            "suspicious_ips": 3,  # per hour
            "file_uploads": 20,  # per minute
        }
        self.event_counters = {}
    
    def _load_threat_patterns(self) -> Dict[str, List[str]]:
        """Load threat detection patterns."""
        return {
            "sql_injection": [
                r"(\b(union|select|insert|update|delete|drop|create|alter)\b)",
                r"(\b(or|and)\b\s+\d+\s*=\s*\d+)",
                r"(\b(union|select|insert|update|delete|drop|create|alter)\b.*\b(union|select|insert|update|delete|drop|create|alter)\b)"
            ],
            "xss": [
                r"<script[^>]*>.*?</script>",
                r"javascript:",
                r"on\w+\s*=",
                r"<iframe[^>]*>",
                r"<object[^>]*>"
            ],
            "path_traversal": [
                r"\.\./",
                r"\.\.\\",
                r"%2e%2e%2f",
                r"%2e%2e%5c"
            ],
            "command_injection": [
                r"(\b(cmd|powershell|bash|sh|exec|system)\b)",
                r"(\b(eval|exec|os\.system|subprocess)\b)",
                r"(\b(rm|del|format|shutdown|reboot)\b)"
            ]
        }
    
    def analyze_request(self, request_data: Dict[str, Any]) -> Dict[str, Any]:
        """Analyze request for security threats."""
        threats = []
        risk_score = 0
        
        # Check for threat patterns in request data
        for threat_type, patterns in self.threat_patterns.items():
            for pattern in patterns:
                if self._check_pattern(request_data, pattern):
                    threats.append(threat_type)
                    risk_score += 10
        
        # Check IP reputation
        ip_address = request_data.get('ip_address')
        if ip_address and self._is_suspicious_ip(ip_address):
            threats.append('suspicious_ip')
            risk_score += 20
        
        # Check user agent anomalies
        user_agent = request_data.get('user_agent')
        if user_agent and self._is_suspicious_user_agent(user_agent):
            threats.append('suspicious_user_agent')
            risk_score += 15
        
        # Check request frequency
        if self._is_high_frequency_request(request_data):
            threats.append('high_frequency')
            risk_score += 25
        
        return {
            "threats": threats,
            "risk_score": risk_score,
            "recommendation": self._get_recommendation(risk_score)
        }
    
    def _check_pattern(self, request_data: Dict[str, Any], pattern: str) -> bool:
        """Check if request data matches threat pattern."""
        for key, value in request_data.items():
            if isinstance(value, str) and re.search(pattern, value, re.IGNORECASE):
                return True
        return False
    
    def _is_suspicious_ip(self, ip_address: str) -> bool:
        """Check if IP address is suspicious."""
        # This would typically integrate with threat intelligence feeds
        suspicious_ips = [
            "192.168.1.100",  # Example suspicious IP
            "10.0.0.50"       # Example suspicious IP
        ]
        return ip_address in suspicious_ips
    
    def _is_suspicious_user_agent(self, user_agent: str) -> bool:
        """Check if user agent is suspicious."""
        suspicious_patterns = [
            r"bot",
            r"crawler",
            r"scraper",
            r"curl",
            r"wget",
            r"python-requests"
        ]
        
        for pattern in suspicious_patterns:
            if re.search(pattern, user_agent, re.IGNORECASE):
                return True
        return False
    
    def _is_high_frequency_request(self, request_data: Dict[str, Any]) -> bool:
        """Check if request is part of high-frequency activity."""
        # This would typically check against rate limiting data
        return False
    
    def _get_recommendation(self, risk_score: int) -> str:
        """Get security recommendation based on risk score."""
        if risk_score >= 50:
            return "BLOCK_REQUEST"
        elif risk_score >= 30:
            return "INCREASE_MONITORING"
        elif risk_score >= 15:
            return "LOG_DETAILED"
        else:
            return "ALLOW_REQUEST"
    
    def generate_security_report(self) -> Dict[str, Any]:
        """Generate security monitoring report."""
        return {
            "timestamp": datetime.utcnow().isoformat(),
            "total_events": SECURITY_EVENTS._value.sum(),
            "authentication_attempts": {
                "success": AUTHENTICATION_ATTEMPTS._value.get(('success',), 0),
                "failure": AUTHENTICATION_ATTEMPTS._value.get(('failure',), 0)
            },
            "rate_limit_violations": RATE_LIMIT_VIOLATIONS._value.sum(),
            "encryption_operations": ENCRYPTION_OPERATIONS._value.sum(),
            "threat_level": self._calculate_threat_level(),
            "recommendations": self._generate_recommendations()
        }
    
    def _calculate_threat_level(self) -> str:
        """Calculate current threat level."""
        total_violations = RATE_LIMIT_VIOLATIONS._value.sum()
        failed_auths = AUTHENTICATION_ATTEMPTS._value.get(('failure',), 0)
        
        if total_violations > 100 or failed_auths > 50:
            return "HIGH"
        elif total_violations > 50 or failed_auths > 20:
            return "MEDIUM"
        else:
            return "LOW"
    
    def _generate_recommendations(self) -> List[str]:
        """Generate security recommendations."""
        recommendations = []
        
        failed_auths = AUTHENTICATION_ATTEMPTS._value.get(('failure',), 0)
        if failed_auths > 20:
            recommendations.append("Consider implementing account lockout after failed attempts")
        
        violations = RATE_LIMIT_VIOLATIONS._value.sum()
        if violations > 50:
            recommendations.append("Review and potentially tighten rate limiting policies")
        
        if not recommendations:
            recommendations.append("Current security posture appears adequate")
        
        return recommendations

class SecurityMiddleware:
    """Security middleware for FastAPI applications."""
    
    def __init__(self, config: SecurityConfig, redis_client: redis.Redis):
        self.config = config
        self.validator = InputValidator(config)
        self.rate_limiter = RateLimiter(redis_client, config)
        self.audit_logger = AuditLogger(config)
        self.security_monitor = SecurityMonitor(config)
    
    def security_decorator(self, endpoint: str = "default"):
        """Decorator for adding security to endpoints."""
        def decorator(func):
            @wraps(func)
            async def wrapper(*args, **kwargs):
                # Extract request information
                request = kwargs.get('request')
                if not request:
                    return await func(*args, **kwargs)
                
                # Get client information
                client_ip = request.client.host if request.client else "unknown"
                user_agent = request.headers.get("user-agent", "unknown")
                
                # Validate IP address
                ip_valid, ip_result = self.validator.validate_ip(client_ip)
                if not ip_valid:
                    self.audit_logger.log_event(
                        event_type="ip_blocked",
                        user_id="anonymous",
                        action="access_denied",
                        details={"reason": ip_result, "endpoint": endpoint},
                        severity="warning",
                        ip_address=client_ip
                    )
                    return {"error": "Access denied", "details": ip_result}
                
                # Rate limiting
                identifier = f"{client_ip}:{endpoint}"
                allowed, rate_info = self.rate_limiter.is_allowed(identifier, endpoint)
                if not allowed:
                    self.audit_logger.log_event(
                        event_type="rate_limit_exceeded",
                        user_id="anonymous",
                        action="rate_limit_violation",
                        details=rate_info,
                        severity="warning",
                        ip_address=client_ip
                    )
                    return {"error": "Rate limit exceeded", "details": rate_info}
                
                # Security monitoring
                request_data = {
                    "ip_address": client_ip,
                    "user_agent": user_agent,
                    "endpoint": endpoint,
                    "method": request.method,
                    "headers": dict(request.headers)
                }
                
                security_analysis = self.security_monitor.analyze_request(request_data)
                if security_analysis["risk_score"] >= 50:
                    self.audit_logger.log_event(
                        event_type="high_risk_request",
                        user_id="anonymous",
                        action="request_blocked",
                        details=security_analysis,
                        severity="high",
                        ip_address=client_ip
                    )
                    return {"error": "Request blocked due to security concerns"}
                
                # Log successful request
                self.audit_logger.log_event(
                    event_type="request_processed",
                    user_id="anonymous",
                    action="endpoint_access",
                    details={"endpoint": endpoint, "risk_score": security_analysis["risk_score"]},
                    severity="info",
                    ip_address=client_ip
                )
                
                return await func(*args, **kwargs)
            
            return wrapper
        return decorator

# Example usage and testing
def main():
    """Example usage of security modules."""
    # Initialize configuration
    config = SecurityConfig()
    
    # Initialize Redis client (for rate limiting)
    redis_client = redis.Redis(host='localhost', port=6379, db=0)
    
    # Initialize security components
    validator = InputValidator(config)
    encryption_manager = EncryptionManager(config)
    audit_logger = AuditLogger(config)
    security_monitor = SecurityMonitor(config)
    
    # Test input validation
    test_text = "<script>alert('xss')</script>"
    is_valid, result = validator.validate_text(test_text)
    print(f"XSS test: {is_valid} - {result}")
    
    # Test encryption
    test_data = "sensitive information"
    encrypted = encryption_manager.encrypt_data(test_data)
    decrypted = encryption_manager.decrypt_data(encrypted)
    print(f"Encryption test: {test_data == decrypted}")
    
    # Test audit logging
    audit_logger.log_authentication("user123", True, "192.168.1.1")
    audit_logger.log_authentication("user456", False, "192.168.1.2")
    
    # Test security monitoring
    request_data = {
        "ip_address": "192.168.1.100",
        "user_agent": "Mozilla/5.0 (compatible; Bot/1.0)",
        "endpoint": "/api/documents"
    }
    
    analysis = security_monitor.analyze_request(request_data)
    print(f"Security analysis: {analysis}")
    
    # Generate security report
    report = security_monitor.generate_security_report()
    print(f"Security report: {json.dumps(report, indent=2)}")

if __name__ == "__main__":
    main() 