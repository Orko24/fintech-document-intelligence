# =============================================================================
# MAIN TERRAFORM CONFIGURATION
# =============================================================================

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.20"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 4.84"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # Remote state storage (uncomment for production)
  # backend "azurerm" {
  #   resource_group_name  = "terraform-state-rg"
  #   storage_account_name = "terraformstate"
  #   container_name       = "tfstate"
  #   key                  = "fintech-ai-platform.tfstate"
  # }
}

# Configure the Azure Provider
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "FinTech-AI-Platform"
      Environment = var.environment
      Owner       = "DevOps-Team"
      CreatedBy   = "Terraform"
    }
  }
}

# Configure the Google Cloud Provider
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# Local values for common tags and naming
locals {
  common_tags = {
    Project     = "FinTech-AI-Platform"
    Environment = var.environment
    Owner       = "DevOps-Team"
    CreatedBy   = "Terraform"
  }
  
  name_prefix = "${var.project_name}-${var.environment}"
}

# =============================================================================
# AZURE RESOURCES (PRIMARY CLOUD)
# =============================================================================

# Azure Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${local.name_prefix}-rg"
  location = var.azure_location
  tags     = local.common_tags
}

# Azure Networking Module
module "azure_networking" {
  source = "./modules/networking"
  
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  environment        = var.environment
  name_prefix        = local.name_prefix
  
  vnet_address_space = ["10.0.0.0/16"]
  subnet_configs = {
    aks_subnet = {
      address_prefixes = ["10.0.1.0/24"]
      service_endpoints = ["Microsoft.ContainerRegistry", "Microsoft.KeyVault"]
    }
    db_subnet = {
      address_prefixes = ["10.0.2.0/24"]
      service_endpoints = ["Microsoft.Sql"]
    }
    app_gateway_subnet = {
      address_prefixes = ["10.0.3.0/24"]
    }
  }
  
  tags = local.common_tags
}

# Azure Kubernetes Service Module
module "azure_aks" {
  source = "./modules/aks"
  
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  environment        = var.environment
  name_prefix        = local.name_prefix
  
  kubernetes_version = "1.28.3"
  subnet_id         = module.azure_networking.subnet_ids["aks_subnet"]
  
  default_node_pool = {
    name       = "default"
    node_count = 3
    vm_size    = "Standard_DS2_v2"
    min_count  = 1
    max_count  = 10
  }
  
  additional_node_pools = {
    gpu_pool = {
      name       = "gpu"
      node_count = 2
      vm_size    = "Standard_NC6s_v3"
      min_count  = 0
      max_count  = 5
      taints     = ["gpu=true:NoSchedule"]
    }
  }
  
  tags = local.common_tags
}

# Azure Database Module
module "azure_databases" {
  source = "./modules/databases"
  
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  environment        = var.environment
  name_prefix        = local.name_prefix
  
  postgresql_config = {
    sku_name   = "GP_Standard_D2s_v3"
    storage_mb = 32768
    version    = "13"
  }
  
  cosmos_db_config = {
    offer_type = "Standard"
    consistency_level = "Session"
  }
  
  subnet_id = module.azure_networking.subnet_ids["db_subnet"]
  tags      = local.common_tags
}

# =============================================================================
# AWS RESOURCES (DISASTER RECOVERY)
# =============================================================================

# AWS VPC for EKS
module "aws_networking" {
  source = "./modules/networking"
  
  providers = {
    aws = aws
  }
  
  environment = var.environment
  name_prefix = "${local.name_prefix}-aws"
  
  vpc_cidr = "10.1.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  
  public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  private_subnet_cidrs = ["10.1.101.0/24", "10.1.102.0/24", "10.1.103.0/24"]
  
  enable_nat_gateway = true
  enable_vpn_gateway = false
  
  tags = local.common_tags
}

# AWS EKS Module
module "aws_eks" {
  source = "./modules/eks"
  
  providers = {
    aws = aws
  }
  
  environment = var.environment
  name_prefix = "${local.name_prefix}-aws"
  
  kubernetes_version = "1.28"
  vpc_id            = module.aws_networking.vpc_id
  subnet_ids        = module.aws_networking.private_subnet_ids
  
  node_groups = {
    general = {
      desired_capacity = 2
      max_capacity     = 5
      min_capacity     = 1
      instance_types   = ["t3.medium"]
    }
  }
  
  tags = local.common_tags
}

# AWS RDS for backup
module "aws_databases" {
  source = "./modules/databases"
  
  providers = {
    aws = aws
  }
  
  environment = var.environment
  name_prefix = "${local.name_prefix}-aws"
  
  vpc_id     = module.aws_networking.vpc_id
  subnet_ids = module.aws_networking.private_subnet_ids
  
  rds_config = {
    engine          = "postgres"
    engine_version  = "13.13"
    instance_class  = "db.t3.micro"
    allocated_storage = 20
  }
  
  tags = local.common_tags
}

# =============================================================================
# GOOGLE CLOUD RESOURCES (ANALYTICS)
# =============================================================================

# GCP GKE Module
module "gcp_gke" {
  source = "./modules/gke"
  
  providers = {
    google = google
  }
  
  project_id  = var.gcp_project_id
  region      = var.gcp_region
  environment = var.environment
  name_prefix = "${local.name_prefix}-gcp"
  
  kubernetes_version = "1.28.3-gke.1286000"
  
  node_pools = {
    default = {
      node_count = 2
      machine_type = "e2-medium"
      disk_size_gb = 30
    }
  }
}

# BigQuery for analytics
resource "google_bigquery_dataset" "fintech_analytics" {
  dataset_id                  = "fintech_analytics"
  friendly_name              = "FinTech Analytics"
  description                = "Analytics dataset for FinTech AI Platform"
  location                   = var.gcp_region
  default_table_expiration_ms = 3600000

  labels = {
    env = var.environment
    project = "fintech-ai-platform"
  }
}

# =============================================================================
# MONITORING MODULE
# =============================================================================

module "monitoring" {
  source = "./modules/monitoring"
  
  environment = var.environment
  name_prefix = local.name_prefix
  
  # Azure monitoring
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  aks_cluster_id     = module.azure_aks.cluster_id
  
  # Monitoring configuration
  prometheus_config = {
    retention_days = 30
    storage_size   = "50Gi"
  }
  
  grafana_config = {
    admin_password = var.grafana_admin_password
    plugins       = ["grafana-kubernetes-app", "grafana-azure-monitor-datasource"]
  }
  
  tags = local.common_tags
  
  depends_on = [
    module.azure_aks,
    module.aws_eks,
    module.gcp_gke
  ]
}
