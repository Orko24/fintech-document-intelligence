# Azure outputs
output "postgresql_server_name" {
  description = "Azure PostgreSQL server name"
  value       = var.cloud_provider == "azure" && var.postgresql_config != null ? azurerm_postgresql_flexible_server.main[0].name : null
}

output "postgresql_connection_string" {
  description = "Azure PostgreSQL connection string"
  value = var.cloud_provider == "azure" && var.postgresql_config != null ? "postgresql://postgres:${random_password.db_password.result}@${azurerm_postgresql_flexible_server.main[0].fqdn}:5432/fintech" : null
  sensitive   = true
}

output "cosmos_db_endpoint" {
  description = "Azure Cosmos DB endpoint"
  value       = var.cloud_provider == "azure" && var.cosmos_db_config != null ? azurerm_cosmosdb_account.main[0].endpoint : null
}

output "cosmos_db_connection_string" {
  description = "Azure Cosmos DB connection string"
  value       = var.cloud_provider == "azure" && var.cosmos_db_config != null ? azurerm_cosmosdb_account.main[0].connection_strings[0] : null
  sensitive   = true
}

output "storage_account_name" {
  description = "Azure Storage account name"
  value       = var.cloud_provider == "azure" ? azurerm_storage_account.main[0].name : null
}

output "storage_account_key" {
  description = "Azure Storage account key"
  value       = var.cloud_provider == "azure" ? azurerm_storage_account.main[0].primary_access_key : null
  sensitive   = true
}

# AWS outputs
output "rds_endpoint" {
  description = "AWS RDS endpoint"
  value       = var.cloud_provider == "aws" && var.rds_config != null ? aws_db_instance.main[0].endpoint : null
}

output "rds_connection_string" {
  description = "AWS RDS connection string"
  value = var.cloud_provider == "aws" && var.rds_config != null ? "postgresql://postgres:${random_password.db_password.result}@${aws_db_instance.main[0].endpoint}:5432/fintech" : null
  sensitive   = true
}

output "s3_bucket_name" {
  description = "AWS S3 bucket name"
  value       = var.cloud_provider == "aws" ? aws_s3_bucket.main[0].bucket : null
}

output "s3_bucket_arn" {
  description = "AWS S3 bucket ARN"
  value       = var.cloud_provider == "aws" ? aws_s3_bucket.main[0].arn : null
}

# Common outputs
output "database_password" {
  description = "Database password"
  value       = random_password.db_password.result
  sensitive   = true
} 