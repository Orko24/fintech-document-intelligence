# 🏦 FinTech AI Platform - Makefile
# Comprehensive build and deployment automation

.PHONY: help install test lint format clean build deploy start stop logs status health-check
.PHONY: setup-local setup-staging setup-production train-models security-scan backup
.PHONY: docker-build docker-push k8s-deploy terraform-apply monitoring-setup

# Configuration
PROJECT_NAME := fintech-ai-platform
VERSION := 1.0.0
DOCKER_REGISTRY := fintech-ai.azurecr.io
KUBERNETES_NAMESPACE := fintech-ai-prod
ENVIRONMENT ?= development

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
PURPLE := \033[0;35m
CYAN := \033[0;36m
WHITE := \033[0;37m
RESET := \033[0m

# Default target
.DEFAULT_GOAL := help

help: ## Show this help message
	@echo "$(CYAN)🏦 FinTech AI Platform - Available Commands$(RESET)"
	@echo ""
	@echo "$(YELLOW)Development Commands:$(RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(RESET) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)Testing Commands:$(RESET)"
	@grep -E '^test-.*:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(RESET) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)Deployment Commands:$(RESET)"
	@grep -E '^(deploy|k8s|terraform|docker).*:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(RESET) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)ML & Security Commands:$(RESET)"
	@grep -E '^(train|security|backup).*:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(RESET) %s\n", $$1, $$2}'

# =============================================================================
# Development Commands
# =============================================================================

install: ## Install all dependencies
	@echo "$(BLUE)Installing dependencies...$(RESET)"
	@pip install -r requirements.txt
	@pip install -r requirements-dev.txt
	@cd frontend && npm install
	@cd go-service && go mod download
	@echo "$(GREEN)✅ Dependencies installed successfully$(RESET)"

setup-local: ## Setup local development environment
	@echo "$(BLUE)Setting up local development environment...$(RESET)"
	@cp .env.example .env
	@echo "$(YELLOW)⚠️  Please edit .env file with your local settings$(RESET)"
	@docker-compose up -d postgres redis kafka
	@echo "$(GREEN)✅ Local environment setup complete$(RESET)"

format: ## Format all code
	@echo "$(BLUE)Formatting code...$(RESET)"
	@black api-gateway/ ml-service/ --line-length 88
	@isort api-gateway/ ml-service/
	@cd frontend && npm run format
	@cd go-service && go fmt ./...
	@echo "$(GREEN)✅ Code formatting complete$(RESET)"

lint: ## Run linting checks
	@echo "$(BLUE)Running linting checks...$(RESET)"
	@flake8 api-gateway/ ml-service/ --max-line-length=88 --ignore=E203,W503
	@mypy api-gateway/ ml-service/ --ignore-missing-imports
	@cd frontend && npm run lint
	@cd go-service && golangci-lint run
	@echo "$(GREEN)✅ Linting checks passed$(RESET)"

# =============================================================================
# Testing Commands
# =============================================================================

test: ## Run all tests
	@echo "$(BLUE)Running all tests...$(RESET)"
	@make test-unit
	@make test-integration
	@make test-e2e
	@echo "$(GREEN)✅ All tests completed$(RESET)"

test-unit: ## Run unit tests
	@echo "$(BLUE)Running unit tests...$(RESET)"
	@pytest tests/unit/ -v --cov=api-gateway --cov=ml-service --cov-report=html
	@cd frontend && npm run test:unit
	@cd go-service && go test ./... -v
	@echo "$(GREEN)✅ Unit tests completed$(RESET)"

test-integration: ## Run integration tests
	@echo "$(BLUE)Running integration tests...$(RESET)"
	@pytest tests/integration/ -v
	@cd frontend && npm run test:integration
	@echo "$(GREEN)✅ Integration tests completed$(RESET)"

test-e2e: ## Run end-to-end tests
	@echo "$(BLUE)Running end-to-end tests...$(RESET)"
	@pytest tests/e2e/ -v
	@cd frontend && npm run test:e2e
	@echo "$(GREEN)✅ End-to-end tests completed$(RESET)"

test-performance: ## Run performance tests
	@echo "$(BLUE)Running performance tests...$(RESET)"
	@locust -f tests/performance/locustfile.py --headless -u 100 -r 10 --run-time 60s
	@echo "$(GREEN)✅ Performance tests completed$(RESET)"

test-security: ## Run security tests
	@echo "$(BLUE)Running security tests...$(RESET)"
	@bandit -r api-gateway/ ml-service/ -f json -o security-report.json
	@npm audit --audit-level=moderate
	@echo "$(GREEN)✅ Security tests completed$(RESET)"

# =============================================================================
# Build Commands
# =============================================================================

build: ## Build all services
	@echo "$(BLUE)Building all services...$(RESET)"
	@make docker-build
	@cd frontend && npm run build
	@echo "$(GREEN)✅ All services built successfully$(RESET)"

docker-build: ## Build Docker images
	@echo "$(BLUE)Building Docker images...$(RESET)"
	@docker build -t $(DOCKER_REGISTRY)/api-gateway:$(VERSION) api-gateway/
	@docker build -t $(DOCKER_REGISTRY)/ml-service:$(VERSION) ml-service/
	@docker build -t $(DOCKER_REGISTRY)/go-service:$(VERSION) go-service/
	@docker build -t $(DOCKER_REGISTRY)/java-service:$(VERSION) java-service/
	@docker build -t $(DOCKER_REGISTRY)/ocr-service:$(VERSION) ocr-service/
	@docker build -t $(DOCKER_REGISTRY)/frontend:$(VERSION) frontend/
	@echo "$(GREEN)✅ Docker images built successfully$(RESET)"

docker-push: ## Push Docker images to registry
	@echo "$(BLUE)Pushing Docker images to registry...$(RESET)"
	@docker push $(DOCKER_REGISTRY)/api-gateway:$(VERSION)
	@docker push $(DOCKER_REGISTRY)/ml-service:$(VERSION)
	@docker push $(DOCKER_REGISTRY)/go-service:$(VERSION)
	@docker push $(DOCKER_REGISTRY)/java-service:$(VERSION)
	@docker push $(DOCKER_REGISTRY)/ocr-service:$(VERSION)
	@docker push $(DOCKER_REGISTRY)/frontend:$(VERSION)
	@echo "$(GREEN)✅ Docker images pushed successfully$(RESET)"

# =============================================================================
# Deployment Commands
# =============================================================================

deploy: ## Deploy to current environment
	@echo "$(BLUE)Deploying to $(ENVIRONMENT)...$(RESET)"
	@make k8s-deploy
	@make health-check
	@echo "$(GREEN)✅ Deployment completed successfully$(RESET)"

deploy-staging: ## Deploy to staging environment
	@echo "$(BLUE)Deploying to staging...$(RESET)"
	@ENVIRONMENT=staging make deploy
	@echo "$(GREEN)✅ Staging deployment completed$(RESET)"

deploy-production: ## Deploy to production environment
	@echo "$(BLUE)Deploying to production...$(RESET)"
	@ENVIRONMENT=production make deploy
	@echo "$(GREEN)✅ Production deployment completed$(RESET)"

k8s-deploy: ## Deploy to Kubernetes
	@echo "$(BLUE)Deploying to Kubernetes...$(RESET)"
	@kubectl apply -f k8s/namespaces/$(ENVIRONMENT).yaml
	@kubectl apply -f k8s/infrastructure/
	@kubectl apply -f k8s/deployments/
	@kubectl apply -f k8s/services/
	@kubectl apply -f k8s/ingress/
	@kubectl apply -f k8s/monitoring/
	@echo "$(GREEN)✅ Kubernetes deployment completed$(RESET)"

terraform-apply: ## Apply Terraform infrastructure
	@echo "$(BLUE)Applying Terraform infrastructure...$(RESET)"
	@cd terraform && terraform init -backend-config=environments/$(ENVIRONMENT)/backend.tf
	@cd terraform && terraform plan -var-file=environments/$(ENVIRONMENT)/terraform.tfvars
	@cd terraform && terraform apply -var-file=environments/$(ENVIRONMENT)/terraform.tfvars -auto-approve
	@echo "$(GREEN)✅ Terraform infrastructure applied$(RESET)"

# =============================================================================
# Service Management Commands
# =============================================================================

start: ## Start all services locally
	@echo "$(BLUE)Starting all services...$(RESET)"
	@docker-compose up -d
	@echo "$(GREEN)✅ All services started$(RESET)"

stop: ## Stop all services
	@echo "$(BLUE)Stopping all services...$(RESET)"
	@docker-compose down
	@echo "$(GREEN)✅ All services stopped$(RESET)"

restart: ## Restart all services
	@echo "$(BLUE)Restarting all services...$(RESET)"
	@make stop
	@make start
	@echo "$(GREEN)✅ All services restarted$(RESET)"

logs: ## Show service logs
	@echo "$(BLUE)Showing service logs...$(RESET)"
	@docker-compose logs -f

status: ## Show service status
	@echo "$(BLUE)Service Status:$(RESET)"
	@docker-compose ps
	@echo ""
	@echo "$(BLUE)Kubernetes Status:$(RESET)"
	@kubectl get pods -n $(KUBERNETES_NAMESPACE)

health-check: ## Check service health
	@echo "$(BLUE)Checking service health...$(RESET)"
	@curl -f http://localhost:8000/health || echo "$(RED)❌ API Gateway unhealthy$(RESET)"
	@curl -f http://localhost:8001/health || echo "$(RED)❌ ML Service unhealthy$(RESET)"
	@curl -f http://localhost:3000/health || echo "$(RED)❌ Frontend unhealthy$(RESET)"
	@echo "$(GREEN)✅ Health checks completed$(RESET)"

# =============================================================================
# ML Training Commands
# =============================================================================

train-models: ## Train all ML models
	@echo "$(BLUE)Training ML models...$(RESET)"
	@cd ml-service && python training/train_models.py --task classification
	@cd ml-service && python training/train_models.py --task ner
	@cd ml-service && python training/train_models.py --task sentiment
	@cd ml-service && python training/train_models.py --task risk
	@echo "$(GREEN)✅ ML models training completed$(RESET)"

train-classification: ## Train document classification model
	@echo "$(BLUE)Training classification model...$(RESET)"
	@cd ml-service && python training/train_models.py --task classification --epochs 15
	@echo "$(GREEN)✅ Classification model training completed$(RESET)"

train-ner: ## Train NER model
	@echo "$(BLUE)Training NER model...$(RESET)"
	@cd ml-service && python training/train_models.py --task ner --epochs 20
	@echo "$(GREEN)✅ NER model training completed$(RESET)"

train-sentiment: ## Train sentiment analysis model
	@echo "$(BLUE)Training sentiment analysis model...$(RESET)"
	@cd ml-service && python training/train_models.py --task sentiment --epochs 10
	@echo "$(GREEN)✅ Sentiment analysis model training completed$(RESET)"

# =============================================================================
# Security Commands
# =============================================================================

security-scan: ## Run comprehensive security scan
	@echo "$(BLUE)Running security scan...$(RESET)"
	@make test-security
	@trivy image $(DOCKER_REGISTRY)/api-gateway:$(VERSION)
	@trivy image $(DOCKER_REGISTRY)/ml-service:$(VERSION)
	@trivy image $(DOCKER_REGISTRY)/frontend:$(VERSION)
	@echo "$(GREEN)✅ Security scan completed$(RESET)"

security-audit: ## Run security audit
	@echo "$(BLUE)Running security audit...$(RESET)"
	@python security/security_hardening.py
	@echo "$(GREEN)✅ Security audit completed$(RESET)"

# =============================================================================
# Monitoring Commands
# =============================================================================

monitoring-setup: ## Setup monitoring stack
	@echo "$(BLUE)Setting up monitoring stack...$(RESET)"
	@kubectl apply -f monitoring/prometheus/
	@kubectl apply -f monitoring/grafana/
	@kubectl apply -f monitoring/alertmanager/
	@kubectl apply -f monitoring/loki/
	@echo "$(GREEN)✅ Monitoring stack setup completed$(RESET)"

monitoring-dashboards: ## Import Grafana dashboards
	@echo "$(BLUE)Importing Grafana dashboards...$(RESET)"
	@kubectl port-forward svc/grafana 3000:3000 -n monitoring &
	@curl -X POST http://admin:admin@localhost:3000/api/dashboards/db \
		-H "Content-Type: application/json" \
		-d @monitoring/grafana/dashboards/fintech-ai-overview.json
	@echo "$(GREEN)✅ Grafana dashboards imported$(RESET)"

# =============================================================================
# Backup and Recovery Commands
# =============================================================================

backup: ## Create backup of all data
	@echo "$(BLUE)Creating backup...$(RESET)"
	@./scripts/backup-database.sh
	@./scripts/backup-application.sh
	@echo "$(GREEN)✅ Backup completed$(RESET)"

backup-database: ## Backup database only
	@echo "$(BLUE)Backing up database...$(RESET)"
	@./scripts/backup-database.sh
	@echo "$(GREEN)✅ Database backup completed$(RESET)"

restore: ## Restore from backup
	@echo "$(BLUE)Restoring from backup...$(RESET)"
	@./scripts/recover-database.sh
	@echo "$(GREEN)✅ Restore completed$(RESET)"

# =============================================================================
# Utility Commands
# =============================================================================

clean: ## Clean up build artifacts
	@echo "$(BLUE)Cleaning up...$(RESET)"
	@find . -type f -name "*.pyc" -delete
	@find . -type d -name "__pycache__" -delete
	@find . -type d -name "*.egg-info" -exec rm -rf {} +
	@rm -rf .pytest_cache/
	@rm -rf htmlcov/
	@rm -rf .coverage
	@cd frontend && npm run clean
	@echo "$(GREEN)✅ Cleanup completed$(RESET)"

clean-docker: ## Clean up Docker resources
	@echo "$(BLUE)Cleaning up Docker resources...$(RESET)"
	@docker system prune -f
	@docker volume prune -f
	@docker network prune -f
	@echo "$(GREEN)✅ Docker cleanup completed$(RESET)"

clean-k8s: ## Clean up Kubernetes resources
	@echo "$(BLUE)Cleaning up Kubernetes resources...$(RESET)"
	@kubectl delete namespace $(KUBERNETES_NAMESPACE) --ignore-not-found=true
	@echo "$(GREEN)✅ Kubernetes cleanup completed$(RESET)"

version: ## Show version information
	@echo "$(CYAN)FinTech AI Platform v$(VERSION)$(RESET)"
	@echo "$(BLUE)Environment: $(ENVIRONMENT)$(RESET)"
	@echo "$(BLUE)Docker Registry: $(DOCKER_REGISTRY)$(RESET)"
	@echo "$(BLUE)Kubernetes Namespace: $(KUBERNETES_NAMESPACE)$(RESET)"

# =============================================================================
# Development Workflow Commands
# =============================================================================

dev-setup: ## Complete development setup
	@echo "$(BLUE)Setting up complete development environment...$(RESET)"
	@make install
	@make setup-local
	@make format
	@make lint
	@make test-unit
	@echo "$(GREEN)✅ Development environment setup completed$(RESET)"

ci-pipeline: ## Run CI pipeline locally
	@echo "$(BLUE)Running CI pipeline...$(RESET)"
	@make format
	@make lint
	@make test
	@make build
	@make security-scan
	@echo "$(GREEN)✅ CI pipeline completed successfully$(RESET)"

release: ## Create a new release
	@echo "$(BLUE)Creating release v$(VERSION)...$(RESET)"
	@git tag -a v$(VERSION) -m "Release v$(VERSION)"
	@git push origin v$(VERSION)
	@make docker-push
	@make deploy-production
	@echo "$(GREEN)✅ Release v$(VERSION) completed$(RESET)"

# =============================================================================
# Documentation Commands
# =============================================================================

docs-build: ## Build documentation
	@echo "$(BLUE)Building documentation...$(RESET)"
	@cd docs && mkdocs build
	@echo "$(GREEN)✅ Documentation built$(RESET)"

docs-serve: ## Serve documentation locally
	@echo "$(BLUE)Serving documentation...$(RESET)"
	@cd docs && mkdocs serve

# =============================================================================
# Database Commands
# =============================================================================

db-migrate: ## Run database migrations
	@echo "$(BLUE)Running database migrations...$(RESET)"
	@cd api-gateway && alembic upgrade head
	@echo "$(GREEN)✅ Database migrations completed$(RESET)"

db-rollback: ## Rollback database migrations
	@echo "$(BLUE)Rolling back database migrations...$(RESET)"
	@cd api-gateway && alembic downgrade -1
	@echo "$(GREEN)✅ Database rollback completed$(RESET)"

db-reset: ## Reset database
	@echo "$(BLUE)Resetting database...$(RESET)"
	@cd api-gateway && alembic downgrade base
	@cd api-gateway && alembic upgrade head
	@echo "$(GREEN)✅ Database reset completed$(RESET)"

# =============================================================================
# Troubleshooting Commands
# =============================================================================

debug-logs: ## Show detailed debug logs
	@echo "$(BLUE)Showing debug logs...$(RESET)"
	@docker-compose logs --tail=100 -f

debug-pods: ## Debug Kubernetes pods
	@echo "$(BLUE)Debugging Kubernetes pods...$(RESET)"
	@kubectl get pods -n $(KUBERNETES_NAMESPACE) -o wide
	@kubectl describe pods -n $(KUBERNETES_NAMESPACE)

debug-network: ## Debug network connectivity
	@echo "$(BLUE)Debugging network connectivity...$(RESET)"
	@kubectl get svc -n $(KUBERNETES_NAMESPACE)
	@kubectl get ingress -n $(KUBERNETES_NAMESPACE)

# =============================================================================
# Performance Commands
# =============================================================================

benchmark: ## Run performance benchmarks
	@echo "$(BLUE)Running performance benchmarks...$(RESET)"
	@ab -n 1000 -c 10 http://localhost:8000/health
	@echo "$(GREEN)✅ Performance benchmarks completed$(RESET)"

stress-test: ## Run stress tests
	@echo "$(BLUE)Running stress tests...$(RESET)"
	@locust -f tests/performance/locustfile.py --headless -u 500 -r 50 --run-time 300s
	@echo "$(GREEN)✅ Stress tests completed$(RESET)"

# =============================================================================
# Compliance Commands
# =============================================================================

compliance-check: ## Run compliance checks
	@echo "$(BLUE)Running compliance checks...$(RESET)"
	@python security/compliance_checker.py
	@echo "$(GREEN)✅ Compliance checks completed$(RESET)"

audit-report: ## Generate audit report
	@echo "$(BLUE)Generating audit report...$(RESET)"
	@python security/audit_reporter.py
	@echo "$(GREEN)✅ Audit report generated$(RESET)"

# =============================================================================
# Environment-specific Commands
# =============================================================================

setup-staging: ## Setup staging environment
	@echo "$(BLUE)Setting up staging environment...$(RESET)"
	@ENVIRONMENT=staging make terraform-apply
	@ENVIRONMENT=staging make k8s-deploy
	@ENVIRONMENT=staging make monitoring-setup
	@echo "$(GREEN)✅ Staging environment setup completed$(RESET)"

setup-production: ## Setup production environment
	@echo "$(BLUE)Setting up production environment...$(RESET)"
	@ENVIRONMENT=production make terraform-apply
	@ENVIRONMENT=production make k8s-deploy
	@ENVIRONMENT=production make monitoring-setup
	@echo "$(GREEN)✅ Production environment setup completed$(RESET)"

# =============================================================================
# Quick Commands
# =============================================================================

quick-start: ## Quick start for development
	@echo "$(BLUE)Quick starting development environment...$(RESET)"
	@make install
	@make setup-local
	@make start
	@echo "$(GREEN)✅ Quick start completed - Services available at:$(RESET)"
	@echo "$(CYAN)  Frontend: http://localhost:3000$(RESET)"
	@echo "$(CYAN)  API Gateway: http://localhost:8000$(RESET)"
	@echo "$(CYAN)  ML Service: http://localhost:8001$(RESET)"
	@echo "$(CYAN)  API Docs: http://localhost:8000/docs$(RESET)"

quick-deploy: ## Quick deploy to current environment
	@echo "$(BLUE)Quick deploying...$(RESET)"
	@make build
	@make docker-push
	@make deploy
	@echo "$(GREEN)✅ Quick deploy completed$(RESET)"

# =============================================================================
# Emergency Commands
# =============================================================================

emergency-stop: ## Emergency stop all services
	@echo "$(RED)🚨 EMERGENCY STOP - Stopping all services...$(RESET)"
	@docker-compose down --remove-orphans
	@kubectl delete namespace $(KUBERNETES_NAMESPACE) --ignore-not-found=true
	@echo "$(GREEN)✅ Emergency stop completed$(RESET)"

emergency-rollback: ## Emergency rollback to previous version
	@echo "$(RED)🚨 EMERGENCY ROLLBACK - Rolling back to previous version...$(RESET)"
	@kubectl rollout undo deployment/api-gateway -n $(KUBERNETES_NAMESPACE)
	@kubectl rollout undo deployment/ml-service -n $(KUBERNETES_NAMESPACE)
	@kubectl rollout undo deployment/frontend -n $(KUBERNETES_NAMESPACE)
	@echo "$(GREEN)✅ Emergency rollback completed$(RESET)"

# =============================================================================
# Information Commands
# =============================================================================

info: ## Show system information
	@echo "$(CYAN)System Information:$(RESET)"
	@echo "$(BLUE)OS:$(RESET) $(shell uname -s)"
	@echo "$(BLUE)Architecture:$(RESET) $(shell uname -m)"
	@echo "$(BLUE)Docker Version:$(RESET) $(shell docker --version)"
	@echo "$(BLUE)Kubectl Version:$(RESET) $(shell kubectl version --client --short)"
	@echo "$(BLUE)Python Version:$(RESET) $(shell python --version)"
	@echo "$(BLUE)Node Version:$(RESET) $(shell node --version)"
	@echo "$(BLUE)Go Version:$(RESET) $(shell go version)"

dependencies: ## Show dependency information
	@echo "$(CYAN)Dependency Information:$(RESET)"
	@echo "$(BLUE)Python Dependencies:$(RESET)"
	@pip list --format=freeze
	@echo "$(BLUE)Node Dependencies:$(RESET)"
	@cd frontend && npm list --depth=0
	@echo "$(BLUE)Go Dependencies:$(RESET)"
	@cd go-service && go list -m all 