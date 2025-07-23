# Azure outputs
output "application_insights_key" {
  description = "Azure Application Insights instrumentation key"
  value       = var.cloud_provider == "azure" ? azurerm_application_insights.main[0].instrumentation_key : null
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Azure Application Insights connection string"
  value       = var.cloud_provider == "azure" ? azurerm_application_insights.main[0].connection_string : null
  sensitive   = true
}

output "prometheus_url" {
  description = "Prometheus URL"
  value       = var.cloud_provider == "azure" ? "http://${azurerm_container_group.prometheus[0].fqdn}:9090" : null
}

output "grafana_url" {
  description = "Grafana URL"
  value       = var.cloud_provider == "azure" ? "http://${azurerm_container_group.grafana[0].fqdn}:3000" : null
}

output "action_group_id" {
  description = "Azure Monitor action group ID"
  value       = var.cloud_provider == "azure" ? azurerm_monitor_action_group.main[0].id : null
}

# AWS outputs
output "cloudwatch_dashboard_url" {
  description = "AWS CloudWatch dashboard URL"
  value = var.cloud_provider == "aws" ? "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${var.name_prefix}-dashboard" : null
}

output "sns_topic_arn" {
  description = "AWS SNS topic ARN for alerts"
  value       = var.cloud_provider == "aws" ? aws_sns_topic.alerts[0].arn : null
}

# Common outputs
output "monitoring_endpoints" {
  description = "All monitoring endpoints"
  value = {
    prometheus = var.cloud_provider == "azure" ? "http://${azurerm_container_group.prometheus[0].fqdn}:9090" : "AWS CloudWatch"
    grafana    = var.cloud_provider == "azure" ? "http://${azurerm_container_group.grafana[0].fqdn}:3000" : "AWS CloudWatch"
    alerts     = var.cloud_provider == "azure" ? "Azure Monitor" : "AWS SNS"
  }
} 