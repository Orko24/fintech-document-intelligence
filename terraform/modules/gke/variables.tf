variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28.3-gke.1286000"
}

variable "node_pools" {
  description = "GKE node pool configurations"
  type = map(object({
    node_count    = number
    machine_type  = string
    disk_size_gb  = number
  }))
  default = {
    default = {
      node_count   = 2
      machine_type = "e2-medium"
      disk_size_gb = 30
    }
  }
}

variable "enable_private_cluster" {
  description = "Enable private GKE cluster"
  type        = bool
  default     = true
}

variable "enable_network_policy" {
  description = "Enable network policy"
  type        = bool
  default     = true
}

variable "enable_workload_identity" {
  description = "Enable workload identity"
  type        = bool
  default     = true
}

variable "enable_confidential_nodes" {
  description = "Enable confidential nodes"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
} 