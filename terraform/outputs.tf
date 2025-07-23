# =============================================================================
# OUTPUTS
# =============================================================================

output "cluster_credentials" {
  description = "Kubernetes cluster credentials"
  value = {
    azure_aks = {
      cluster_name        = module.azure_aks.cluster_name
      resource_group_name = azurerm_resource_group.main.name
      location           = azurerm_resource_group.main.location
    }
    aws_eks = {
      cluster_name     = module.aws_eks.cluster_name
      cluster_endpoint = module.aws_eks.cluster_endpoint
      region          = var.aws_region
    }
    gcp_gke = {
      cluster_name = module.gcp_gke.cluster_name
      location     = module.gcp_gke.location
      project_id   = var.gcp_project_id
    }
  }
}

output "database_endpoints" {
  description = "Database connection endpoints"
  value = {
    postgresql_server = module.azure_databases.postgresql_server_name
    cosmos_db_endpoint = module.azure_databases.cosmos_db_endpoint
    rds_endpoint      = module.aws_databases.rds_endpoint
    bigquery_dataset  = google_bigquery_dataset.fintech_analytics.dataset_id
  }
}

output "networking_info" {
  description = "Network configuration details"
  value = {
    azure_vnet_id = module.azure_networking.vnet_id
    aws_vpc_id    = module.aws_networking.vpc_id
    subnet_ids = {
      azure = module.azure_networking.subnet_ids
      aws   = module.aws_networking.private_subnet_ids
    }
  }
}

output "monitoring_dashboards" {
  description = "Monitoring dashboard URLs"
  value = {
    grafana_url    = module.monitoring.grafana_url
    prometheus_url = module.monitoring.prometheus_url
    azure_monitor  = "https://portal.azure.com/#@/resource${azurerm_resource_group.main.id}/overview"
  }
}

output "api_endpoints" {
  description = "API service endpoints"
  value = {
    api_gateway_url = "https://${module.azure_aks.cluster_name}-api.${var.azure_location}.cloudapp.azure.com"
    ml_service_url  = "https://${module.azure_aks.cluster_name}-ml.${var.azure_location}.cloudapp.azure.com"
    frontend_url    = "https://${module.azure_aks.cluster_name}-app.${var.azure_location}.cloudapp.azure.com"
  }
}

output "storage_accounts" {
  description = "Storage account information"
  value = {
    azure_storage_account = module.azure_databases.storage_account_name
    aws_s3_bucket        = module.aws_databases.s3_bucket_name
    gcp_storage_bucket   = module.gcp_gke.storage_bucket_name
  }
}

output "container_registries" {
  description = "Container registry information"
  value = {
    azure_acr = module.azure_aks.container_registry_url
    aws_ecr   = module.aws_eks.ecr_repositories
  }
}

output "deployment_commands" {
  description = "Commands to connect to clusters"
  value = {
    azure_aks = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${module.azure_aks.cluster_name}"
    aws_eks   = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.aws_eks.cluster_name}"
    gcp_gke   = "gcloud container clusters get-credentials ${module.gcp_gke.cluster_name} --region ${var.gcp_region} --project ${var.gcp_project_id}"
  }
}

output "cost_estimation" {
  description = "Estimated monthly costs"
  value = {
    azure_resources = "~$500-800/month (includes AKS, databases, monitoring)"
    aws_resources   = "~$200-300/month (includes EKS, RDS, backup)"
    gcp_resources   = "~$100-150/month (includes GKE, BigQuery, analytics)"
    total_estimate  = "~$800-1250/month for full multi-cloud setup"
  }
}

output "security_info" {
  description = "Security configuration details"
  value = {
    private_clusters_enabled = var.enable_private_clusters
    network_policies_enabled = var.enable_network_policies
    backup_enabled          = var.enable_backup
    monitoring_enabled      = var.enable_monitoring
  }
} 