#!/bin/bash

# FinTech AI Platform Deployment Script
# This script deploys the entire platform to Kubernetes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="fintech-platform"
PLATFORM_NAME="fintech-ai-platform"
REGISTRY="ghcr.io"

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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    local missing_tools=()
    
    if ! command_exists kubectl; then
        missing_tools+=("kubectl")
    fi
    
    if ! command_exists docker; then
        missing_tools+=("docker")
    fi
    
    if ! command_exists helm; then
        missing_tools+=("helm")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        print_error "Please install the missing tools and try again."
        exit 1
    fi
    
    print_success "All prerequisites are installed"
}

# Function to check Kubernetes cluster
check_k8s_cluster() {
    print_status "Checking Kubernetes cluster..."
    
    if ! kubectl cluster-info >/dev/null 2>&1; then
        print_error "Cannot connect to Kubernetes cluster"
        print_error "Please ensure kubectl is configured correctly"
        exit 1
    fi
    
    print_success "Kubernetes cluster is accessible"
}

# Function to create namespace
create_namespace() {
    print_status "Creating namespace: $NAMESPACE"
    
    if kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
        print_warning "Namespace $NAMESPACE already exists"
    else
        kubectl create namespace "$NAMESPACE"
        print_success "Namespace $NAMESPACE created"
    fi
}

# Function to deploy infrastructure services
deploy_infrastructure() {
    print_status "Deploying infrastructure services..."
    
    # Deploy PostgreSQL
    print_status "Deploying PostgreSQL..."
    kubectl apply -f k8s/infrastructure/postgres.yaml -n "$NAMESPACE"
    
    # Deploy Redis
    print_status "Deploying Redis..."
    kubectl apply -f k8s/infrastructure/redis.yaml -n "$NAMESPACE"
    
    # Deploy Kafka and Zookeeper
    print_status "Deploying Kafka and Zookeeper..."
    kubectl apply -f k8s/infrastructure/kafka.yaml -n "$NAMESPACE"
    
    print_success "Infrastructure services deployed"
}

# Function to wait for infrastructure to be ready
wait_for_infrastructure() {
    print_status "Waiting for infrastructure services to be ready..."
    
    # Wait for PostgreSQL
    print_status "Waiting for PostgreSQL..."
    kubectl wait --for=condition=ready pod -l app=postgres -n "$NAMESPACE" --timeout=300s
    
    # Wait for Redis
    print_status "Waiting for Redis..."
    kubectl wait --for=condition=ready pod -l app=redis -n "$NAMESPACE" --timeout=300s
    
    # Wait for Zookeeper
    print_status "Waiting for Zookeeper..."
    kubectl wait --for=condition=ready pod -l app=zookeeper -n "$NAMESPACE" --timeout=300s
    
    # Wait for Kafka
    print_status "Waiting for Kafka..."
    kubectl wait --for=condition=ready pod -l app=kafka -n "$NAMESPACE" --timeout=300s
    
    print_success "Infrastructure services are ready"
}

# Function to deploy application services
deploy_application_services() {
    print_status "Deploying application services..."
    
    # Deploy API Gateway
    print_status "Deploying API Gateway..."
    kubectl apply -f k8s/deployments/api-gateway.yaml -n "$NAMESPACE"
    
    # Deploy ML Service
    print_status "Deploying ML Service..."
    kubectl apply -f k8s/deployments/ml-service.yaml -n "$NAMESPACE"
    
    # Deploy Go Service
    print_status "Deploying Go Service..."
    kubectl apply -f k8s/deployments/go-service.yaml -n "$NAMESPACE"
    
    # Deploy Java Service
    print_status "Deploying Java Service..."
    kubectl apply -f k8s/deployments/java-service.yaml -n "$NAMESPACE"
    
    # Deploy OCR Service
    print_status "Deploying OCR Service..."
    kubectl apply -f k8s/deployments/ocr-service.yaml -n "$NAMESPACE"
    
    # Deploy Frontend
    print_status "Deploying Frontend..."
    kubectl apply -f k8s/deployments/frontend.yaml -n "$NAMESPACE"
    
    print_success "Application services deployed"
}

# Function to deploy ingress
deploy_ingress() {
    print_status "Deploying ingress configuration..."
    
    kubectl apply -f k8s/ingress/nginx-ingress.yaml -n "$NAMESPACE"
    
    print_success "Ingress configuration deployed"
}

# Function to deploy monitoring
deploy_monitoring() {
    print_status "Deploying monitoring stack..."
    
    # Create monitoring namespace
    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
    
    # Deploy Prometheus
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
    
    helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
        --namespace monitoring \
        --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
        --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false \
        --set prometheus.prometheusSpec.ruleSelectorNilUsesHelmValues=false \
        --set grafana.enabled=true \
        --set grafana.adminPassword=admin123 \
        --set grafana.persistence.enabled=true \
        --set grafana.persistence.size=10Gi
    
    # Deploy Grafana dashboards
    kubectl apply -f monitoring/grafana/dashboards/ -n monitoring
    
    print_success "Monitoring stack deployed"
}

# Function to wait for services to be ready
wait_for_services() {
    print_status "Waiting for application services to be ready..."
    
    local services=("api-gateway" "ml-service" "go-service" "java-service" "ocr-service" "frontend")
    
    for service in "${services[@]}"; do
        print_status "Waiting for $service..."
        kubectl wait --for=condition=ready pod -l app="$service" -n "$NAMESPACE" --timeout=300s
    done
    
    print_success "All application services are ready"
}

# Function to run database migrations
run_migrations() {
    print_status "Running database migrations..."
    
    # Get API Gateway pod name
    local api_gateway_pod=$(kubectl get pods -l app=api-gateway -n "$NAMESPACE" -o jsonpath='{.items[0].metadata.name}')
    
    if [ -n "$api_gateway_pod" ]; then
        # Run migrations
        kubectl exec "$api_gateway_pod" -n "$NAMESPACE" -- alembic upgrade head
        print_success "Database migrations completed"
    else
        print_warning "API Gateway pod not found, skipping migrations"
    fi
}

# Function to display deployment status
show_status() {
    print_status "Deployment Status:"
    echo
    
    print_status "Pods:"
    kubectl get pods -n "$NAMESPACE"
    echo
    
    print_status "Services:"
    kubectl get services -n "$NAMESPACE"
    echo
    
    print_status "Ingress:"
    kubectl get ingress -n "$NAMESPACE"
    echo
    
    if kubectl get namespace monitoring >/dev/null 2>&1; then
        print_status "Monitoring Pods:"
        kubectl get pods -n monitoring
        echo
    fi
}

# Function to display access information
show_access_info() {
    print_success "Platform deployment completed!"
    echo
    print_status "Access Information:"
    echo
    
    # Get ingress host
    local ingress_host=$(kubectl get ingress -n "$NAMESPACE" -o jsonpath='{.items[0].spec.rules[0].host}' 2>/dev/null || echo "localhost")
    
    print_status "Frontend: http://$ingress_host"
    print_status "API Gateway: http://$ingress_host/api"
    print_status "Grafana: http://$ingress_host/grafana (admin/admin123)"
    print_status "Prometheus: http://$ingress_host/prometheus"
    echo
    
    print_status "To check logs:"
    print_status "  kubectl logs -f deployment/api-gateway -n $NAMESPACE"
    print_status "  kubectl logs -f deployment/ml-service -n $NAMESPACE"
    echo
    
    print_status "To access services directly:"
    print_status "  kubectl port-forward service/api-gateway 8000:8000 -n $NAMESPACE"
    print_status "  kubectl port-forward service/frontend 3000:3000 -n $NAMESPACE"
}

# Main deployment function
main() {
    print_status "Starting FinTech AI Platform deployment..."
    echo
    
    # Check prerequisites
    check_prerequisites
    
    # Check Kubernetes cluster
    check_k8s_cluster
    
    # Create namespace
    create_namespace
    
    # Deploy infrastructure
    deploy_infrastructure
    
    # Wait for infrastructure
    wait_for_infrastructure
    
    # Deploy application services
    deploy_application_services
    
    # Deploy ingress
    deploy_ingress
    
    # Deploy monitoring
    deploy_monitoring
    
    # Wait for services
    wait_for_services
    
    # Run migrations
    run_migrations
    
    # Show status
    show_status
    
    # Show access information
    show_access_info
}

# Handle script arguments
case "${1:-}" in
    "status")
        show_status
        ;;
    "logs")
        if [ -n "$2" ]; then
            kubectl logs -f deployment/"$2" -n "$NAMESPACE"
        else
            print_error "Please specify a service name (e.g., api-gateway, ml-service)"
            exit 1
        fi
        ;;
    "restart")
        if [ -n "$2" ]; then
            kubectl rollout restart deployment/"$2" -n "$NAMESPACE"
            print_success "Restarted $2"
        else
            print_error "Please specify a service name to restart"
            exit 1
        fi
        ;;
    "cleanup")
        print_warning "This will delete all resources in namespace $NAMESPACE"
        read -p "Are you sure? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            kubectl delete namespace "$NAMESPACE"
            kubectl delete namespace monitoring
            print_success "Cleanup completed"
        else
            print_status "Cleanup cancelled"
        fi
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [command]"
        echo
        echo "Commands:"
        echo "  (no args)  Deploy the entire platform"
        echo "  status     Show deployment status"
        echo "  logs <service>  Show logs for a specific service"
        echo "  restart <service>  Restart a specific service"
        echo "  cleanup    Delete all platform resources"
        echo "  help       Show this help message"
        ;;
    "")
        main
        ;;
    *)
        print_error "Unknown command: $1"
        print_error "Use '$0 help' for usage information"
        exit 1
        ;;
esac 