#!/bin/bash

set -e

ENVIRONMENT=${1:-local}

echo "🔍 Setting up monitoring stack for $ENVIRONMENT environment..."

case $ENVIRONMENT in
  "local")
    setup_local_monitoring
    ;;
  "kubernetes")
    setup_kubernetes_monitoring
    ;;
  "production")
    setup_production_monitoring
    ;;
  *)
    echo "❌ Unknown environment: $ENVIRONMENT"
    echo "Usage: $0 [local|kubernetes|production]"
    exit 1
    ;;
esac

function setup_local_monitoring() {
  echo "🐳 Setting up local Docker-based monitoring..."
  
  # Create monitoring directories
  mkdir -p monitoring/{prometheus,grafana/{dashboards,provisioning},loki,alertmanager,opentelemetry}
  
  # Copy configuration files
  echo "📋 Copying configuration files..."
  
  # Start monitoring stack
  echo "🚀 Starting monitoring services..."
  docker-compose -f docker-compose.monitoring.yml up -d
  
  # Wait for services to be ready
  echo "⏳ Waiting for services to start..."
  sleep 30
  
  # Verify services
  check_monitoring_health
  
  echo "✅ Local monitoring setup complete!"
  echo "📊 Access points:"
  echo "   Prometheus: http://localhost:9090"
  echo "   Grafana:    http://localhost:3001 (admin/admin)"
  echo "   Jaeger:     http://localhost:16686"
  echo "   Loki:       http://localhost:3100"
  echo "   AlertManager: http://localhost:9093"
}

function setup_kubernetes_monitoring() {
  echo "☸️ Setting up Kubernetes monitoring..."
  
  # Create monitoring namespace
  kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
  
  # Apply all monitoring manifests
  echo "📋 Deploying monitoring components..."
  kubectl apply -f monitoring/k8s/
  
  # Wait for deployments
  echo "⏳ Waiting for deployments to be ready..."
  kubectl wait --for=condition=available --timeout=300s deployment -n monitoring --all
  
  # Get service endpoints
  get_kubernetes_endpoints
  
  echo "✅ Kubernetes monitoring setup complete!"
}

function setup_production_monitoring() {
  echo "🏭 Setting up production monitoring with Terraform..."
  
  # Deploy monitoring module via Terraform
  cd terraform/environments/prod
  terraform apply -target=module.monitoring -auto-approve
  
  # Get cluster credentials
  echo "📋 Getting cluster credentials..."
  az aks get-credentials --resource-group fintech-ai-platform-prod-rg --name fintech-ai-platform-prod-aks
  
  # Apply additional monitoring configs
  kubectl apply -f ../../../monitoring/k8s/
  
  echo "✅ Production monitoring setup complete!"
}

function check_monitoring_health() {
  echo "🏥 Checking monitoring services health..."
  
  services=(
    "Prometheus:http://localhost:9090/-/healthy"
    "Grafana:http://localhost:3001/api/health"
    "Loki:http://localhost:3100/ready"
    "Jaeger:http://localhost:16686/"
    "AlertManager:http://localhost:9093/-/healthy"
  )
  
  for service in "${services[@]}"; do
    name=$(echo $service | cut -d: -f1)
    url=$(echo $service | cut -d: -f2-)
    
    if curl -sf "$url" > /dev/null 2>&1; then
      echo "✅ $name is healthy"
    else
      echo "❌ $name is not responding"
    fi
  done
}

function get_kubernetes_endpoints() {
  echo "📊 Kubernetes monitoring endpoints:"
  
  # Get LoadBalancer IPs
  prometheus_ip=$(kubectl get svc prometheus -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
  grafana_ip=$(kubectl get svc grafana -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
  jaeger_ip=$(kubectl get svc jaeger -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
  alertmanager_ip=$(kubectl get svc alertmanager -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
  
  echo "   Prometheus:   http://$prometheus_ip:9090"
  echo "   Grafana:      http://$grafana_ip:3000"
  echo "   Jaeger:       http://$jaeger_ip:16686"
  echo "   AlertManager: http://$alertmanager_ip:9093"
  
  # Port-forward if LoadBalancer IPs not available
  if [ -z "$grafana_ip" ]; then
    echo "💡 LoadBalancer IPs not available. Use port-forwarding:"
    echo "   kubectl port-forward -n monitoring svc/prometheus 9090:9090"
    echo "   kubectl port-forward -n monitoring svc/grafana 3000:3000"
    echo "   kubectl port-forward -n monitoring svc/jaeger 16686:16686"
  fi
} 