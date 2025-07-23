# FinTech AI Platform - Makefile
# Build and deployment commands for the entire platform

.PHONY: help build test deploy clean setup-local setup-prod

# Default target
help:
	@echo "FinTech AI Platform - Available Commands:"
	@echo ""
	@echo "Setup Commands:"
	@echo "  setup-local     - Set up local development environment"
	@echo "  setup-prod      - Set up production environment"
	@echo "  setup-monitoring - Set up monitoring stack"
	@echo ""
	@echo "Build Commands:"
	@echo "  build           - Build all services"
	@echo "  build-api       - Build API Gateway"
	@echo "  build-ml        - Build ML Service"
	@echo "  build-go        - Build Go Service"
	@echo "  build-java      - Build Java Service"
	@echo "  build-frontend  - Build Frontend"
	@echo ""
	@echo "Development Commands:"
	@echo "  start           - Start all services locally"
	@echo "  stop            - Stop all services"
	@echo "  restart         - Restart all services"
	@echo "  logs            - Show logs for all services"
	@echo ""
	@echo "Testing Commands:"
	@echo "  test            - Run all tests"
	@echo "  test-unit       - Run unit tests"
	@echo "  test-integration - Run integration tests"
	@echo "  test-e2e        - Run end-to-end tests"
	@echo ""
	@echo "Deployment Commands:"
	@echo "  deploy-dev      - Deploy to development"
	@echo "  deploy-staging  - Deploy to staging"
	@echo "  deploy-prod     - Deploy to production"
	@echo ""
	@echo "Utility Commands:"
	@echo "  clean           - Clean build artifacts"
	@echo "  health-check    - Check service health"
	@echo "  backup          - Backup database"
	@echo "  migrate         - Run database migrations"

# Setup Commands
setup-local:
	@echo "Setting up local development environment..."
	cp .env.example .env
	@echo "Please edit .env with your configurations"
	chmod +x scripts/*.sh
	./scripts/setup-local.sh

setup-prod:
	@echo "Setting up production environment..."
	cd terraform/environments/prod
	terraform init
	terraform plan
	@echo "Review the plan and run: make deploy-prod"

setup-monitoring:
	@echo "Setting up monitoring stack..."
	./scripts/setup-monitoring.sh local

# Build Commands
build: build-api build-ml build-go build-java build-frontend
	@echo "All services built successfully!"

build-api:
	@echo "Building API Gateway..."
	cd api-gateway && docker build -t fintech-api-gateway .

build-ml:
	@echo "Building ML Service..."
	cd ml-service && docker build -t fintech-ml-service .

build-go:
	@echo "Building Go Service..."
	cd go-service && docker build -t fintech-go-service .

build-java:
	@echo "Building Java Service..."
	cd java-service && docker build -t fintech-java-service .

build-frontend:
	@echo "Building Frontend..."
	cd frontend && docker build -t fintech-frontend .

# Development Commands
start:
	@echo "Starting all services..."
	docker-compose up -d

stop:
	@echo "Stopping all services..."
	docker-compose down

restart: stop start
	@echo "Services restarted!"

logs:
	@echo "Showing logs for all services..."
	docker-compose logs -f

# Testing Commands
test: test-unit test-integration
	@echo "All tests completed!"

test-unit:
	@echo "Running unit tests..."
	cd api-gateway && python -m pytest tests/unit/ -v
	cd ml-service && python -m pytest tests/unit/ -v
	cd go-service && go test ./... -v
	cd java-service && mvn test

test-integration:
	@echo "Running integration tests..."
	cd tests/integration && python -m pytest -v

test-e2e:
	@echo "Running end-to-end tests..."
	cd tests/e2e && python -m pytest -v

# Deployment Commands
deploy-dev:
	@echo "Deploying to development environment..."
	cd terraform/environments/dev
	terraform apply -auto-approve
	kubectl apply -f ../../../k8s/

deploy-staging:
	@echo "Deploying to staging environment..."
	cd terraform/environments/staging
	terraform apply -auto-approve
	kubectl apply -f ../../../k8s/

deploy-prod:
	@echo "Deploying to production environment..."
	@read -p "Are you sure you want to deploy to PRODUCTION? (y/N): " confirm && [ "$$confirm" = "y" ]
	cd terraform/environments/prod
	terraform apply -auto-approve
	kubectl apply -f ../../../k8s/

# Utility Commands
clean:
	@echo "Cleaning build artifacts..."
	docker system prune -f
	docker volume prune -f
	find . -name "*.pyc" -delete
	find . -name "__pycache__" -delete
	find . -name "node_modules" -exec rm -rf {} +
	find . -name "dist" -exec rm -rf {} +
	find . -name "build" -exec rm -rf {} +

health-check:
	@echo "Checking service health..."
	./scripts/health-check.sh

backup:
	@echo "Creating database backup..."
	./scripts/backup.sh

migrate:
	@echo "Running database migrations..."
	./scripts/migrate.sh

# Monitoring Commands
monitoring-start:
	@echo "Starting monitoring stack..."
	docker-compose -f docker-compose.monitoring.yml up -d

monitoring-stop:
	@echo "Stopping monitoring stack..."
	docker-compose -f docker-compose.monitoring.yml down

monitoring-logs:
	@echo "Showing monitoring logs..."
	docker-compose -f docker-compose.monitoring.yml logs -f

# Performance Testing
perf-test:
	@echo "Running performance tests..."
	cd tests/performance && locust -f locustfile.py --host=http://localhost:8000

# Security Scanning
security-scan:
	@echo "Running security scans..."
	./scripts/security-scan.sh

# Documentation
docs:
	@echo "Generating documentation..."
	cd docs && mkdocs build

docs-serve:
	@echo "Serving documentation..."
	cd docs && mkdocs serve 