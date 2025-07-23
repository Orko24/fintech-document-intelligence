"""
Unit tests for ML Service prediction endpoints
"""
import pytest
from fastapi.testclient import TestClient
from unittest.mock import Mock, patch
import json


class TestPredictionEndpoints:
    """Test cases for prediction endpoints"""

    def test_create_prediction_success(self, client, mock_openai, auth_headers, sample_prediction_request):
        """Test successful prediction creation"""
        # Mock OpenAI response
        mock_openai.ChatCompletion.create.return_value = Mock(
            choices=[Mock(message=Mock(content='{"sentiment": "positive", "confidence": 0.95}'))]
        )

        response = client.post(
            "/predictions/",
            json=sample_prediction_request,
            headers=auth_headers
        )

        assert response.status_code == 201
        data = response.json()
        assert "prediction_id" in data
        assert data["document_id"] == sample_prediction_request["document_id"]
        assert data["model_type"] == sample_prediction_request["model_type"]

    def test_create_prediction_invalid_request(self, client, auth_headers):
        """Test prediction creation with invalid request"""
        invalid_request = {
            "document_id": "",  # Invalid empty document ID
            "model_type": "invalid_model"
        }

        response = client.post(
            "/predictions/",
            json=invalid_request,
            headers=auth_headers
        )

        assert response.status_code == 422

    def test_create_prediction_unauthorized(self, client, sample_prediction_request):
        """Test prediction creation without authentication"""
        response = client.post(
            "/predictions/",
            json=sample_prediction_request
        )

        assert response.status_code == 401

    def test_get_prediction_success(self, client, auth_headers, sample_prediction_response):
        """Test successful prediction retrieval"""
        prediction_id = "pred-123"

        with patch('app.services.prediction_service.get_prediction') as mock_get:
            mock_get.return_value = sample_prediction_response

            response = client.get(
                f"/predictions/{prediction_id}",
                headers=auth_headers
            )

            assert response.status_code == 200
            data = response.json()
            assert data["prediction_id"] == prediction_id

    def test_get_prediction_not_found(self, client, auth_headers):
        """Test prediction retrieval for non-existent prediction"""
        prediction_id = "non-existent"

        with patch('app.services.prediction_service.get_prediction') as mock_get:
            mock_get.return_value = None

            response = client.get(
                f"/predictions/{prediction_id}",
                headers=auth_headers
            )

            assert response.status_code == 404

    def test_list_predictions_success(self, client, auth_headers):
        """Test successful prediction listing"""
        predictions = [
            {"prediction_id": "pred-1", "model_type": "sentiment_analysis"},
            {"prediction_id": "pred-2", "model_type": "entity_extraction"}
        ]

        with patch('app.services.prediction_service.list_predictions') as mock_list:
            mock_list.return_value = predictions

            response = client.get(
                "/predictions/",
                headers=auth_headers
            )

            assert response.status_code == 200
            data = response.json()
            assert len(data) == 2

    def test_list_predictions_with_filters(self, client, auth_headers):
        """Test prediction listing with filters"""
        with patch('app.services.prediction_service.list_predictions') as mock_list:
            mock_list.return_value = []

            response = client.get(
                "/predictions/?model_type=sentiment_analysis&limit=10",
                headers=auth_headers
            )

            assert response.status_code == 200

    def test_delete_prediction_success(self, client, auth_headers):
        """Test successful prediction deletion"""
        prediction_id = "pred-123"

        with patch('app.services.prediction_service.delete_prediction') as mock_delete:
            mock_delete.return_value = True

            response = client.delete(
                f"/predictions/{prediction_id}",
                headers=auth_headers
            )

            assert response.status_code == 204

    def test_delete_prediction_not_found(self, client, auth_headers):
        """Test deletion of non-existent prediction"""
        prediction_id = "non-existent"

        with patch('app.services.prediction_service.delete_prediction') as mock_delete:
            mock_delete.return_value = False

            response = client.delete(
                f"/predictions/{prediction_id}",
                headers=auth_headers
            )

            assert response.status_code == 404


class TestPredictionService:
    """Test cases for prediction service logic"""

    def test_process_document_sentiment(self, mock_openai):
        """Test sentiment analysis processing"""
        from app.services.prediction_service import process_document_sentiment

        mock_openai.ChatCompletion.create.return_value = Mock(
            choices=[Mock(message=Mock(content='{"sentiment": "positive", "confidence": 0.95}'))]
        )

        result = process_document_sentiment("Test document content")

        assert result["sentiment"] == "positive"
        assert result["confidence"] == 0.95

    def test_process_document_entities(self, mock_openai):
        """Test entity extraction processing"""
        from app.services.prediction_service import process_document_entities

        mock_openai.ChatCompletion.create.return_value = Mock(
            choices=[Mock(message=Mock(content='{"entities": [{"name": "John Doe", "type": "PERSON"}]}'))]
        )

        result = process_document_entities("Test document content")

        assert "entities" in result
        assert len(result["entities"]) == 1

    def test_validate_prediction_request(self):
        """Test prediction request validation"""
        from app.services.prediction_service import validate_prediction_request

        valid_request = {
            "document_id": "doc-123",
            "model_type": "sentiment_analysis",
            "parameters": {"confidence_threshold": 0.8}
        }

        result = validate_prediction_request(valid_request)
        assert result is True

        invalid_request = {
            "document_id": "",
            "model_type": "invalid_model"
        }

        with pytest.raises(ValueError):
            validate_prediction_request(invalid_request)


class TestPredictionModels:
    """Test cases for prediction models"""

    def test_prediction_model_creation(self):
        """Test prediction model creation and validation"""
        from app.models.prediction import PredictionCreate, PredictionResponse

        prediction_data = {
            "document_id": "doc-123",
            "model_type": "sentiment_analysis",
            "parameters": {"confidence_threshold": 0.8}
        }

        prediction = PredictionCreate(**prediction_data)
        assert prediction.document_id == "doc-123"
        assert prediction.model_type == "sentiment_analysis"

        response_data = {
            "prediction_id": "pred-123",
            "document_id": "doc-123",
            "model_type": "sentiment_analysis",
            "result": {"sentiment": "positive"},
            "processing_time": 1.23,
            "timestamp": "2024-01-01T00:00:00Z"
        }

        response = PredictionResponse(**response_data)
        assert response.prediction_id == "pred-123"
        assert response.processing_time == 1.23 