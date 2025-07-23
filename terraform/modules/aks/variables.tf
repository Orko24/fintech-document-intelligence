variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure location"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28.3"
}

variable "subnet_id" {
  description = "Subnet ID for AKS nodes"
  type        = string
}

variable "app_gateway_subnet_id" {
  description = "Subnet ID for Application Gateway"
  type        = string
  default     = ""
}

variable "default_node_pool" {
  description = "Default node pool configuration"
  type = object({
    name       = string
    node_count = number
    vm_size    = string
    min_count  = number
    max_count  = number
  })
}

variable "additional_node_pools" {
  description = "Additional node pools"
  type = map(object({
    name       = string
    node_count = number
    vm_size    = string
    min_count  = number
    max_count  = number
    taints     = optional(list(string), [])
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
} 