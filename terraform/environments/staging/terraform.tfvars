# =============================================================================
# STAGING ENVIRONMENT CONFIGURATION
# =============================================================================

# Environment
environment = "staging"

# Project Configuration
project_name = "fintech-ai-platform"

# Azure Configuration
azure_location = "East US 2"  # Same as production for consistency

# AWS Configuration
aws_region = "us-east-1"

# GCP Configuration
gcp_region     = "us-central1"
gcp_project_id = "your-gcp-project-id-staging"

# Kubernetes Configuration
kubernetes_version = "1.28.3"

# Monitoring Configuration
enable_monitoring = true
enable_logging    = true

# Cost Optimization
use_spot_instances = true  # Enabled for staging cost savings
enable_auto_scaling = true

# Security Configuration
enable_private_clusters = true   # Enabled for staging security testing
enable_network_policies = true

# Backup Configuration
enable_backup = true
backup_retention_days = 14  # Moderate retention for staging

# Grafana Configuration
grafana_admin_password = "staging-admin-2024!"

# API Keys (use environment variables in production)
# These should be set via environment variables or secure key management
openai_api_key = ""
anthropic_api_key = ""
huggingface_token = ""
azure_openai_key = ""
azure_openai_endpoint = ""

# Database Configuration
postgresql_admin_username = "postgres"
postgresql_admin_password = "staging-db-password-2024!"

# Staging-specific overrides
# Medium instance sizes for testing performance
# Moderate node counts for availability testing
# Production-like security configurations for testing
# Single-zone deployment for cost optimization
# Enhanced monitoring for testing observability 