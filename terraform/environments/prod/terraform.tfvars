# =============================================================================
# PRODUCTION ENVIRONMENT CONFIGURATION
# =============================================================================

# Environment
environment = "prod"

# Project Configuration
project_name = "fintech-ai-platform"

# Azure Configuration
azure_location = "East US 2"  # More reliable region for production

# AWS Configuration
aws_region = "us-east-1"

# GCP Configuration
gcp_region     = "us-central1"
gcp_project_id = "your-gcp-project-id-prod"

# Kubernetes Configuration
kubernetes_version = "1.28.3"

# Monitoring Configuration
enable_monitoring = true
enable_logging    = true

# Cost Optimization
use_spot_instances = false  # Disabled for production stability
enable_auto_scaling = true

# Security Configuration
enable_private_clusters = true   # Enabled for production security
enable_network_policies = true

# Backup Configuration
enable_backup = true
backup_retention_days = 30

# Grafana Configuration
grafana_admin_password = "prod-secure-password-2024!"

# API Keys (use environment variables in production)
# These should be set via environment variables or secure key management
openai_api_key = ""
anthropic_api_key = ""
huggingface_token = ""
azure_openai_key = ""
azure_openai_endpoint = ""

# Database Configuration
postgresql_admin_username = "postgres"
postgresql_admin_password = "prod-secure-db-password-2024!"

# Production-specific overrides
# Larger instance sizes for performance
# Higher node counts for availability
# Enhanced security configurations
# Multi-zone deployments for high availability 