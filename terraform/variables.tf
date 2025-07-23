# =============================================================================
# VARIABLES
# =============================================================================

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "fintech-ai-platform"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "azure_location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "gcp_region" {
  description = "GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "gcp_project_id" {
  description = "GCP project ID"
  type        = string
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
  default     = "admin123!"
}

# API Keys and Secrets
variable "openai_api_key" {
  description = "OpenAI API key for GPT models"
  type        = string
  sensitive   = true
  default     = ""
}

variable "anthropic_api_key" {
  description = "Anthropic API key for Claude"
  type        = string
  sensitive   = true
  default     = ""
}

variable "huggingface_token" {
  description = "Hugging Face API token"
  type        = string
  sensitive   = true
  default     = ""
}

variable "azure_openai_key" {
  description = "Azure OpenAI service key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "azure_openai_endpoint" {
  description = "Azure OpenAI service endpoint"
  type        = string
  default     = ""
}

# Database Configuration
variable "postgresql_admin_username" {
  description = "PostgreSQL admin username"
  type        = string
  default     = "postgres"
}

variable "postgresql_admin_password" {
  description = "PostgreSQL admin password"
  type        = string
  sensitive   = true
  default     = ""
}

# Kubernetes Configuration
variable "kubernetes_version" {
  description = "Kubernetes version for all clusters"
  type        = string
  default     = "1.28.3"
}

# Monitoring Configuration
variable "enable_monitoring" {
  description = "Enable monitoring stack"
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "Enable logging stack"
  type        = bool
  default     = true
}

# Cost Optimization
variable "use_spot_instances" {
  description = "Use spot instances for cost optimization"
  type        = bool
  default     = true
}

variable "enable_auto_scaling" {
  description = "Enable auto-scaling for node pools"
  type        = bool
  default     = true
}

# Security Configuration
variable "enable_private_clusters" {
  description = "Enable private clusters"
  type        = bool
  default     = true
}

variable "enable_network_policies" {
  description = "Enable network policies"
  type        = bool
  default     = true
}

# Backup Configuration
variable "enable_backup" {
  description = "Enable backup for databases"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Backup retention period in days"
  type        = number
  default     = 30
} 