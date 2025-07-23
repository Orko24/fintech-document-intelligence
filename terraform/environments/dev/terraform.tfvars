# =============================================================================
# DEVELOPMENT ENVIRONMENT CONFIGURATION
# =============================================================================

# Environment
environment = "dev"

# Project Configuration
project_name = "fintech-ai-platform"

# Azure Configuration
azure_location = "East US"

# AWS Configuration
aws_region = "us-east-1"

# GCP Configuration
gcp_region     = "us-central1"
gcp_project_id = "your-gcp-project-id-dev"

# Kubernetes Configuration
kubernetes_version = "1.28.3"

# Monitoring Configuration
enable_monitoring = true
enable_logging    = true

# Cost Optimization
use_spot_instances = true
enable_auto_scaling = true

# Security Configuration
enable_private_clusters = false  # Disabled for dev for easier access
enable_network_policies = true

# Backup Configuration
enable_backup = true
backup_retention_days = 7

# Grafana Configuration
grafana_admin_password = "dev-admin123!"

# API Keys (use environment variables in production)
openai_api_key = ""
anthropic_api_key = ""
huggingface_token = ""
azure_openai_key = ""
azure_openai_endpoint = ""

# Database Configuration
postgresql_admin_username = "postgres"
postgresql_admin_password = "dev-password-123!"

# Development-specific overrides
# Smaller instance sizes for cost savings
# Reduced node counts for development
# Simplified networking for easier debugging 