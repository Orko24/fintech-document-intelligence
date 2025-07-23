"""
Pytest configuration and fixtures for ML Service tests
"""
import pytest
from fastapi.testclient import TestClient
from unittest.mock import Mock, patch
import os
import sys

# Add the app directory to the Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'app'))

from main import app
from app.config import settings


@pytest.fixture
def client():
    """Test client for FastAPI app"""
    return TestClient(app)


@pytest.fixture
def mock_openai():
    """Mock OpenAI API"""
    with patch('app.services.prediction_service.openai') as mock:
        yield mock


@pytest.fixture
def mock_redis():
    """Mock Redis connection"""
    with patch('app.utils.metrics.redis') as mock:
        mock_client = Mock()
        mock.from_url.return_value = mock_client
        yield mock_client


@pytest.fixture
def mock_db():
    """Mock database connection"""
    with patch('app.database.connection.get_db') as mock:
        mock_session = Mock()
        mock.return_value = mock_session
        yield mock_session


@pytest.fixture
def sample_document():
    """Sample document for testing"""
    return {
        "id": "test-doc-123",
        "filename": "test_document.pdf",
        "content": "This is a test document content for OCR processing.",
        "file_size": 1024,
        "upload_date": "2024-01-01T00:00:00Z"
    }


@pytest.fixture
def sample_prediction_request():
    """Sample prediction request for testing"""
    return {
        "document_id": "test-doc-123",
        "model_type": "sentiment_analysis",
        "parameters": {
            "confidence_threshold": 0.8
        }
    }


@pytest.fixture
def sample_prediction_response():
    """Sample prediction response for testing"""
    return {
        "prediction_id": "pred-123",
        "document_id": "test-doc-123",
        "model_type": "sentiment_analysis",
        "result": {
            "sentiment": "positive",
            "confidence": 0.95,
            "score": 0.85
        },
        "processing_time": 1.23,
        "timestamp": "2024-01-01T00:00:00Z"
    }


@pytest.fixture
def auth_headers():
    """Authentication headers for testing"""
    return {
        "Authorization": "Bearer test-jwt-token",
        "X-API-Key": "test-api-key"
    }


@pytest.fixture
def test_settings():
    """Test settings override"""
    original_debug = settings.debug
    settings.debug = True
    yield settings
    settings.debug = original_debug 