output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.main.arn
}

output "ecr_repositories" {
  description = "ECR repository URLs"
  value = {
    for k, v in aws_ecr_repository.main : k => v.repository_url
  }
}

output "node_group_arns" {
  description = "EKS node group ARNs"
  value = {
    for k, v in aws_eks_node_group.main : k => v.arn
  }
} 