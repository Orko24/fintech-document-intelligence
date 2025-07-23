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

variable "vnet_address_space" {
  description = "Azure VNet address space"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_configs" {
  description = "Azure subnet configurations"
  type = map(object({
    address_prefixes = list(string)
    service_endpoints = optional(list(string), [])
  }))
  default = {}
}

# AWS-specific variables
variable "vpc_cidr" {
  description = "AWS VPC CIDR block"
  type        = string
  default     = "10.1.0.0/16"
}

variable "availability_zones" {
  description = "AWS availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "public_subnet_cidrs" {
  description = "AWS public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "AWS private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.1.101.0/24", "10.1.102.0/24", "10.1.103.0/24"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for AWS"
  type        = bool
  default     = true
}

variable "enable_vpn_gateway" {
  description = "Enable VPN Gateway for AWS"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
} 