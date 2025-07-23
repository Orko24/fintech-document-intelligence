# Azure outputs
output "vnet_id" {
  description = "Azure VNet ID"
  value       = var.cloud_provider == "azure" ? azurerm_virtual_network.main[0].id : null
}

output "subnet_ids" {
  description = "Azure subnet IDs"
  value = var.cloud_provider == "azure" ? {
    for k, v in azurerm_subnet.main : k => v.id
  } : {}
}

# AWS outputs
output "vpc_id" {
  description = "AWS VPC ID"
  value       = var.cloud_provider == "aws" ? aws_vpc.main[0].id : null
}

output "public_subnet_ids" {
  description = "AWS public subnet IDs"
  value = var.cloud_provider == "aws" ? aws_subnet.public[*].id : []
}

output "private_subnet_ids" {
  description = "AWS private subnet IDs"
  value = var.cloud_provider == "aws" ? aws_subnet.private[*].id : []
}

output "internet_gateway_id" {
  description = "AWS Internet Gateway ID"
  value       = var.cloud_provider == "aws" ? aws_internet_gateway.main[0].id : null
}

output "nat_gateway_id" {
  description = "AWS NAT Gateway ID"
  value       = var.cloud_provider == "aws" && var.enable_nat_gateway ? aws_nat_gateway.main[0].id : null
}

output "eks_security_group_id" {
  description = "AWS EKS security group ID"
  value       = var.cloud_provider == "aws" ? aws_security_group.eks[0].id : null
}

output "rds_security_group_id" {
  description = "AWS RDS security group ID"
  value       = var.cloud_provider == "aws" ? aws_security_group.rds[0].id : null
} 