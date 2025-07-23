output "cluster_name" {
  description = "GKE cluster name"
  value       = google_container_cluster.main.name
}

output "cluster_id" {
  description = "GKE cluster ID"
  value       = google_container_cluster.main.id
}

output "cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = google_container_cluster.main.endpoint
}

output "cluster_ca_certificate" {
  description = "GKE cluster CA certificate"
  value       = google_container_cluster.main.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "location" {
  description = "GKE cluster location"
  value       = google_container_cluster.main.location
}

output "project_id" {
  description = "GCP project ID"
  value       = google_container_cluster.main.project
}

output "network" {
  description = "GKE cluster network"
  value       = google_container_cluster.main.network
}

output "subnetwork" {
  description = "GKE cluster subnetwork"
  value       = google_container_cluster.main.subnetwork
}

output "artifact_registry_repositories" {
  description = "Artifact Registry repository URLs"
  value = {
    for k, v in google_artifact_registry_repository.main : k => v.name
  }
}

output "storage_bucket_name" {
  description = "Cloud Storage bucket name for ML models"
  value       = google_storage_bucket.ml_models.name
}

output "workload_pool" {
  description = "GKE workload identity pool"
  value       = google_container_cluster.main.workload_pool_config[0].workload_pool
} 