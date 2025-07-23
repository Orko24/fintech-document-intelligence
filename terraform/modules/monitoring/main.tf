# =============================================================================
# MONITORING MODULE
# =============================================================================

# Azure Application Insights
resource "azurerm_application_insights" "main" {
  count = var.cloud_provider == "azure" ? 1 : 0

  name                = "${var.name_prefix}-appinsights"
  resource_group_name = var.resource_group_name
  location            = var.location
  application_type    = "web"

  tags = var.tags
}

# Azure Monitor Action Group
resource "azurerm_monitor_action_group" "main" {
  count = var.cloud_provider == "azure" ? 1 : 0

  name                = "${var.name_prefix}-action-group"
  resource_group_name = var.resource_group_name
  short_name          = "fintech"

  email_receiver {
    name                    = "admin"
    email_address          = var.admin_email
    use_common_alert_schema = true
  }

  tags = var.tags
}

# Azure Monitor Alert Rule
resource "azurerm_monitor_metric_alert" "aks_cpu" {
  count = var.cloud_provider == "azure" ? 1 : 0

  name                = "${var.name_prefix}-aks-cpu-alert"
  resource_group_name = var.resource_group_name
  scopes               = [var.aks_cluster_id]
  description          = "Alert when AKS CPU usage is high"

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_cpu_usage_percentage"
    aggregation      = "Average"
    operator          = "GreaterThan"
    threshold         = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }

  tags = var.tags
}

# Prometheus Server (Azure Container Instance for demo)
resource "azurerm_container_group" "prometheus" {
  count = var.cloud_provider == "azure" ? 1 : 0

  name                = "${var.name_prefix}-prometheus"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  restart_policy      = "Always"

  container {
    name   = "prometheus"
    image  = "prom/prometheus:latest"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 9090
      protocol = "TCP"
    }

    volume {
      name       = "prometheus-config"
      mount_path = "/etc/prometheus"
      read_only  = true
      share_name = "prometheus-config"

      storage_account_name = azurerm_storage_account.monitoring[0].name
      storage_account_key  = azurerm_storage_account.monitoring[0].primary_access_key
    }

    volume {
      name       = "prometheus-data"
      mount_path = "/prometheus"
      share_name = "prometheus-data"

      storage_account_name = azurerm_storage_account.monitoring[0].name
      storage_account_key  = azurerm_storage_account.monitoring[0].primary_access_key
    }
  }

  tags = var.tags
}

# Grafana Server (Azure Container Instance for demo)
resource "azurerm_container_group" "grafana" {
  count = var.cloud_provider == "azure" ? 1 : 0

  name                = "${var.name_prefix}-grafana"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  restart_policy      = "Always"

  container {
    name   = "grafana"
    image  = "grafana/grafana:latest"
    cpu    = "0.5"
    memory = "1.0"

    environment_variables = {
      GF_SECURITY_ADMIN_PASSWORD = var.grafana_config.admin_password
      GF_INSTALL_PLUGINS        = join(",", var.grafana_config.plugins)
    }

    ports {
      port     = 3000
      protocol = "TCP"
    }

    volume {
      name       = "grafana-data"
      mount_path = "/var/lib/grafana"
      share_name = "grafana-data"

      storage_account_name = azurerm_storage_account.monitoring[0].name
      storage_account_key  = azurerm_storage_account.monitoring[0].primary_access_key
    }
  }

  tags = var.tags
}

# Azure Storage Account for monitoring data
resource "azurerm_storage_account" "monitoring" {
  count = var.cloud_provider == "azure" ? 1 : 0

  name                     = "${replace(var.name_prefix, "-", "")}monitoring"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  tags = var.tags
}

# Azure File Shares for monitoring
resource "azurerm_storage_share" "prometheus_config" {
  count = var.cloud_provider == "azure" ? 1 : 0

  name                 = "prometheus-config"
  storage_account_name = azurerm_storage_account.monitoring[0].name
  quota                = 1
}

resource "azurerm_storage_share" "prometheus_data" {
  count = var.cloud_provider == "azure" ? 1 : 0

  name                 = "prometheus-data"
  storage_account_name = azurerm_storage_account.monitoring[0].name
  quota                = 50
}

resource "azurerm_storage_share" "grafana_data" {
  count = var.cloud_provider == "azure" ? 1 : 0

  name                 = "grafana-data"
  storage_account_name = azurerm_storage_account.monitoring[0].name
  quota                = 10
}

# AWS CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  count = var.cloud_provider == "aws" ? 1 : 0

  dashboard_name = "${var.name_prefix}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/EKS", "cluster_failed_node_count", "ClusterName", var.aws_eks_cluster_name],
            [".", "cluster_node_count", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "EKS Cluster Metrics"
        }
      }
    ]
  })
}

# AWS SNS Topic for alerts
resource "aws_sns_topic" "alerts" {
  count = var.cloud_provider == "aws" ? 1 : 0

  name = "${var.name_prefix}-alerts"

  tags = var.tags
}

# AWS SNS Topic Subscription
resource "aws_sns_topic_subscription" "email" {
  count = var.cloud_provider == "aws" ? 1 : 0

  topic_arn = aws_sns_topic.alerts[0].arn
  protocol  = "email"
  endpoint  = var.admin_email
}

# AWS CloudWatch Alarm
resource "aws_cloudwatch_metric_alarm" "eks_cpu" {
  count = var.cloud_provider == "aws" ? 1 : 0

  alarm_name          = "${var.name_prefix}-eks-cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EKS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors EKS CPU utilization"
  alarm_actions       = [aws_sns_topic.alerts[0].arn]

  dimensions = {
    ClusterName = var.aws_eks_cluster_name
  }

  tags = var.tags
} 