#!/bin/bash

echo "🚀 FinTech AI Platform - Monitoring Quick Start"
echo "=============================================="

# Check dependencies
check_dependencies() {
  echo "🔍 Checking dependencies..."
  
  commands=("docker" "docker-compose" "curl")
  missing=()
  
  for cmd in "${commands[@]}"; do
    if ! command -v $cmd &> /dev/null; then
      missing+=($cmd)
    fi
  done
  
  if [ ${#missing[@]} -ne 0 ]; then
    echo "❌ Missing dependencies: ${missing[*]}"
    echo "Please install: ${missing[*]}"
    exit 1
  fi
  
  echo "✅ All dependencies found"
}

# Quick setup
quick_setup() {
  echo "⚡ Quick monitoring setup..."
  
  # Create directories
  mkdir -p monitoring/{prometheus,grafana,loki,alertmanager}
  
  # Start minimal monitoring stack
  docker-compose -f docker-compose.monitoring.yml up -d prometheus grafana
  
  # Wait for services
  echo "⏳ Waiting for services to start..."
  sleep 20
  
  # Open dashboards
  if command -v open &> /dev/null; then
    open http://localhost:9090  # Prometheus
    open http://localhost:3001  # Grafana
  elif command -v xdg-open &> /dev/null; then
    xdg-open http://localhost:9090
    xdg-open http://localhost:3001
  fi
  
  echo "✅ Quick setup complete!"
  echo "📊 Prometheus: http://localhost:9090"
  echo "📈 Grafana: http://localhost:3001 (admin/admin)"
}

# Main execution
check_dependencies
quick_setup

echo ""
echo "🎯 Next steps:"
echo "1. Upload a document to generate metrics"
echo "2. Check Grafana dashboards"
echo "3. Set up alerts: ./scripts/setup-alerts.sh <slack_webhook>"
echo "4. Full setup: ./scripts/setup-monitoring.sh kubernetes" 