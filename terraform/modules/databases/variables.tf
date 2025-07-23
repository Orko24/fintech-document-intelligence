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

variable "subnet_id" {
  description = "Azure subnet ID for database"
  type        = string
  default     = ""
}

variable "postgresql_config" {
  description = "Azure PostgreSQL configuration"
  type = object({
    sku_name   = string
    storage_mb = number
    version    = string
  })
  default = null
}

variable "cosmos_db_config" {
  description = "Azure Cosmos DB configuration"
  type = object({
    offer_type = string
    consistency_level = string
  })
  default = null
}

# AWS-specific variables
variable "vpc_id" {
  description = "AWS VPC ID"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "AWS subnet IDs for database"
  type        = list(string)
  default     = []
}

variable "eks_security_group_ids" {
  description = "AWS EKS security group IDs"
  type        = list(string)
  default     = []
}

variable "rds_config" {
  description = "AWS RDS configuration"
  type = object({
    engine          = string
    engine_version  = string
    instance_class  = string
    allocated_storage = number
  })
  default = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
} 