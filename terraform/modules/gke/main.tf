# =============================================================================
# GKE MODULE (Google Kubernetes Engine)
# =============================================================================

# GKE Cluster
resource "google_container_cluster" "main" {
  name     = "${var.name_prefix}-gke"
  location = var.region
  project  = var.project_id

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.main.name
  subnetwork = google_compute_subnetwork.main.name

  # Enable Workload Identity
  workload_pool_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Enable Network Policy
  network_policy {
    enabled = true
  }

  # Enable IP aliasing
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "/16"
    services_ipv4_cidr_block = "/22"
  }

  # Enable private nodes
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  # Enable release channel
  release_channel {
    channel = "regular"
  }

  # Enable monitoring
  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }

  # Enable logging
  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }

  # Enable maintenance window
  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }

  # Enable autoscaling
  cluster_autoscaling {
    enabled = true

    resource_limits {
      resource_type = "cpu"
      minimum       = 1
      maximum       = 10
    }

    resource_limits {
      resource_type = "memory"
      minimum       = 2
      maximum       = 20
    }
  }

  # Enable node auto-repair
  node_config {
    machine_type = "e2-medium"
    disk_size_gb = 30

    # Enable workload identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Enable secure boot
    shielded_instance_config {
      enable_secure_boot = true
    }

    # Enable confidential nodes
    confidential_nodes {
      enabled = true
    }

    # Enable auto-upgrade
    auto_upgrade = true

    # Enable auto-repair
    auto_repair = true

    # Enable metadata
    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only",
    ]
  }

  lifecycle {
    ignore_changes = [
      node_config[0].initial_node_count,
    ]
  }
}

# GKE Node Pools
resource "google_container_node_pool" "main" {
  for_each = var.node_pools

  name       = each.key
  location   = var.region
  project    = var.project_id
  cluster    = google_container_cluster.main.name
  node_count = each.value.node_count

  node_config {
    machine_type = each.value.machine_type
    disk_size_gb = each.value.disk_size_gb

    # Enable workload identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Enable secure boot
    shielded_instance_config {
      enable_secure_boot = true
    }

    # Enable auto-upgrade
    auto_upgrade = true

    # Enable auto-repair
    auto_repair = true

    # Enable metadata
    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only",
    ]

    labels = {
      env = var.environment
    }

    tags = ["gke-node", "${var.name_prefix}-gke-node"]
  }

  autoscaling {
    min_node_count = 1
    max_node_count = each.value.node_count * 2
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  lifecycle {
    ignore_changes = [
      initial_node_count,
    ]
  }
}

# VPC Network
resource "google_compute_network" "main" {
  name                    = "${var.name_prefix}-vpc"
  auto_create_subnetworks = false
  project                 = var.project_id
}

# Subnet
resource "google_compute_subnetwork" "main" {
  name          = "${var.name_prefix}-subnet"
  ip_cidr_range = "10.2.0.0/16"
  region        = var.region
  network       = google_compute_network.main.id
  project       = var.project_id

  # Enable flow logs
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling       = 0.5
    metadata            = "INCLUDE_ALL_METADATA"
  }

  # Enable private Google access
  private_ip_google_access = true
}

# Cloud Router
resource "google_compute_router" "main" {
  name    = "${var.name_prefix}-router"
  region  = var.region
  network = google_compute_network.main.id
  project = var.project_id
}

# Cloud NAT
resource "google_compute_router_nat" "main" {
  name                               = "${var.name_prefix}-nat"
  router                            = google_compute_router.main.name
  region                            = var.region
  project                           = var.project_id
  nat_ip_allocate_option            = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# Firewall rule for GKE
resource "google_compute_firewall" "gke" {
  name    = "${var.name_prefix}-gke-firewall"
  network = google_compute_network.main.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22", "6443", "10250", "10255", "30000-32767"]
  }

  source_ranges = ["10.2.0.0/16"]
  target_tags   = ["gke-node"]
}

# Artifact Registry for container images
resource "google_artifact_registry_repository" "main" {
  for_each = toset(["api-gateway", "ml-service", "frontend", "go-service"])

  location      = var.region
  repository_id = "${var.name_prefix}-${each.key}"
  description   = "Docker repository for ${each.key}"
  format        = "DOCKER"
  project       = var.project_id
}

# Cloud Storage bucket for ML models
resource "google_storage_bucket" "ml_models" {
  name          = "${var.name_prefix}-ml-models"
  location      = var.region
  project       = var.project_id
  force_destroy = true

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "Delete"
    }
  }
}

# IAM binding for GKE to access Artifact Registry
resource "google_project_iam_binding" "gke_artifact_registry" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"

  members = [
    "serviceAccount:${google_container_cluster.main.node_config[0].service_account}",
  ]
} 