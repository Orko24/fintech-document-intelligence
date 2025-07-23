#!/bin/bash

# FinTech AI Platform - Local Setup Script
# This script sets up the local development environment

set -e

echo "🚀 Setting up FinTech AI Platform - Local Development Environment"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is installed
check_docker() {
    print_status "Checking Docker installation..."
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker is not running. Please start Docker first."
        exit 1
    fi
    
    print_success "Docker is installed and running"
}

# Check if Docker Compose is installed
check_docker_compose() {
    print_status "Checking Docker Compose installation..."
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    print_success "Docker Compose is installed"
}

# Check if required tools are installed
check_tools() {
    print_status "Checking required tools..."
    
    local missing_tools=()
    
    # Check Python
    if ! command -v python3 &> /dev/null; then
        missing_tools+=("Python 3.9+")
    fi
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        missing_tools+=("Node.js 18+")
    fi
    
    # Check Go
    if ! command -v go &> /dev/null; then
        missing_tools+=("Go 1.21+")
    fi
    
    # Check Java
    if ! command -v java &> /dev/null; then
        missing_tools+=("Java 17+")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_warning "Some recommended tools are missing:"
        for tool in "${missing_tools[@]}"; do
            echo "  - $tool"
        done
        print_warning "You can still run the platform with Docker, but local development may be limited."
    else
        print_success "All recommended tools are installed"
    fi
}

# Create environment file
setup_environment() {
    print_status "Setting up environment variables..."
    
    if [ ! -f .env ]; then
        if [ -f .env.example ]; then
            cp .env.example .env
            print_success "Created .env file from .env.example"
        else
            print_warning "No .env.example found. Creating basic .env file..."
            cat > .env << EOF
# Database Configuration
DATABASE_URL=postgresql://postgres:password@localhost:5432/fintech_ai
POSTGRES_DB=fintech_ai
POSTGRES_USER=postgres
POSTGRES_PASSWORD=password

# Redis Configuration
REDIS_URL=redis://localhost:6379/0
REDIS_PASSWORD=

# Security
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
API_KEY=your-api-key-change-this-in-production

# Kafka Configuration
KAFKA_BROKERS=localhost:9092

# Service URLs
API_GATEWAY_URL=http://localhost:8000
ML_SERVICE_URL=http://localhost:8001
GO_SERVICE_URL=http://localhost:8002
JAVA_SERVICE_URL=http://localhost:8003
OCR_SERVICE_URL=http://localhost:8004

# Frontend Configuration
REACT_APP_API_URL=http://localhost:8000
REACT_APP_WS_URL=ws://localhost:8000

# Monitoring
GRAFANA_PASSWORD=admin
EOF
            print_success "Created basic .env file"
        fi
    else
        print_warning ".env file already exists. Skipping creation."
    fi
}

# Create necessary directories
create_directories() {
    print_status "Creating necessary directories..."
    
    mkdir -p data/sample_documents
    mkdir -p data/schemas/postgresql
    mkdir -p data/schemas/mongodb
    mkdir -p data/schemas/kafka
    mkdir -p logs
    mkdir -p tmp
    
    print_success "Created necessary directories"
}

# Install Python dependencies
install_python_deps() {
    print_status "Installing Python dependencies..."
    
    # Install development dependencies
    if command -v pip3 &> /dev/null; then
        pip3 install -r requirements-dev.txt
        print_success "Installed Python development dependencies"
    else
        print_warning "pip3 not found. Skipping Python dependency installation."
    fi
}

# Install Node.js dependencies
install_node_deps() {
    print_status "Installing Node.js dependencies..."
    
    if command -v npm &> /dev/null; then
        npm install
        cd frontend && npm install && cd ..
        print_success "Installed Node.js dependencies"
    else
        print_warning "npm not found. Skipping Node.js dependency installation."
    fi
}

# Build Docker images
build_images() {
    print_status "Building Docker images..."
    
    docker-compose build
    
    print_success "Docker images built successfully"
}

# Start services
start_services() {
    print_status "Starting services..."
    
    docker-compose up -d
    
    print_success "Services started successfully"
}

# Wait for services to be ready
wait_for_services() {
    print_status "Waiting for services to be ready..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s http://localhost:8000/health > /dev/null 2>&1; then
            print_success "API Gateway is ready"
            break
        fi
        
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    if [ $attempt -gt $max_attempts ]; then
        print_warning "Services may still be starting up. Check logs with: docker-compose logs"
    fi
}

# Display status
show_status() {
    print_status "Platform Status:"
    echo ""
    echo "🌐 Frontend:     http://localhost:3000"
    echo "🔌 API Gateway: http://localhost:8000"
    echo "🤖 ML Service:  http://localhost:8001"
    echo "⚙️  Go Service:  http://localhost:8002"
    echo "☕ Java Service: http://localhost:8003"
    echo "📄 OCR Service: http://localhost:8004"
    echo "📊 Grafana:     http://localhost:3001 (admin/admin)"
    echo "📈 Prometheus:  http://localhost:9090"
    echo ""
    echo "📋 Useful commands:"
    echo "  View logs:     docker-compose logs -f"
    echo "  Stop services: docker-compose down"
    echo "  Restart:       docker-compose restart"
    echo "  Health check:  ./scripts/health-check.sh"
    echo ""
}

# Main execution
main() {
    echo "=========================================="
    echo "  FinTech AI Platform - Local Setup"
    echo "=========================================="
    echo ""
    
    check_docker
    check_docker_compose
    check_tools
    setup_environment
    create_directories
    install_python_deps
    install_node_deps
    build_images
    start_services
    wait_for_services
    show_status
    
    echo ""
    print_success "🎉 FinTech AI Platform setup complete!"
    echo ""
    print_status "Next steps:"
    echo "  1. Visit http://localhost:3000 to access the frontend"
    echo "  2. Check the documentation in the docs/ directory"
    echo "  3. Run tests with: npm test"
    echo "  4. View logs with: docker-compose logs -f"
    echo ""
}

# Run main function
main "$@" 