variable "cloud_provider" {
  description = "Cloud provider (azure or aws)"
  type        = string
  default     = "azure"
  validation {
    condition     = contains(["azure", "aws"], var.cloud_provider)
    error_message = "Cloud provider must be either 'azure' or 'aws'."
  }
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

# Azure-specific variables
variable "resource_group_name" {
  description = "Azure resource group name"
  type        = string
  default     = ""
}

variable "location" {
  description = "Azure location"
  type        = string
  default     = ""
}

variable "aks_cluster_id" {
  description = "Azure AKS cluster ID"
  type        = string
  default     = ""
}

# AWS-specific variables
variable "aws_eks_cluster_name" {
  description = "AWS EKS cluster name"
  type        = string
  default     = ""
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = ""
}

# Common variables
variable "admin_email" {
  description = "Admin email for alerts"
  type        = string
  default     = "admin@fintech-ai-platform.com"
}

variable "grafana_config" {
  description = "Grafana configuration"
  type = object({
    admin_password = string
    plugins       = list(string)
  })
  default = {
    admin_password = "admin123!"
    plugins       = ["grafana-kubernetes-app", "grafana-azure-monitor-datasource"]
  }
}

variable "prometheus_config" {
  description = "Prometheus configuration"
  type = object({
    retention_days = number
    storage_size   = string
  })
  default = {
    retention_days = 30
    storage_size   = "50Gi"
  }
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
} 