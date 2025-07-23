output "cluster_name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.main.name
}

output "cluster_id" {
  description = "AKS cluster ID"
  value       = azurerm_kubernetes_cluster.main.id
}

output "kube_config" {
  description = "Kubernetes configuration"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

output "cluster_fqdn" {
  description = "AKS cluster FQDN"
  value       = azurerm_kubernetes_cluster.main.fqdn
}

output "container_registry_url" {
  description = "Container registry login server"
  value       = azurerm_container_registry.main.login_server
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  value       = azurerm_log_analytics_workspace.main.id
}

output "application_gateway_id" {
  description = "Application Gateway ID"
  value       = azurerm_application_gateway.main.id
}

output "application_gateway_public_ip" {
  description = "Application Gateway public IP"
  value       = azurerm_public_ip.agw.ip_address
} 