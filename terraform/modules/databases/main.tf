# =============================================================================
# DATABASES MODULE (Multi-Cloud)
# =============================================================================

# Random password for databases
resource "random_password" "db_password" {
  length  = 16
  special = true
}

# Azure PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "main" {
  count = var.cloud_provider == "azure" && var.postgresql_config != null ? 1 : 0

  name                   = "${var.name_prefix}-postgres"
  resource_group_name    = var.resource_group_name
  location              = var.location
  version               = var.postgresql_config.version
  delegated_subnet_id   = var.subnet_id
  administrator_login    = "postgres"
  administrator_password = random_password.db_password.result
  zone                  = "1"
  storage_mb            = var.postgresql_config.storage_mb
  sku_name              = var.postgresql_config.sku_name

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  tags = var.tags
}

# Azure Cosmos DB
resource "azurerm_cosmosdb_account" "main" {
  count = var.cloud_provider == "azure" && var.cosmos_db_config != null ? 1 : 0

  name                = "${var.name_prefix}-cosmos"
  location            = var.location
  resource_group_name = var.resource_group_name
  offer_type          = var.cosmos_db_config.offer_type
  kind                = "GlobalDocumentDB"

  enable_automatic_failover = true

  consistency_policy {
    consistency_level = var.cosmos_db_config.consistency_level
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  capabilities {
    name = "EnableMongo"
  }

  tags = var.tags
}

# Azure Cosmos DB MongoDB Database
resource "azurerm_cosmosdb_mongo_database" "main" {
  count = var.cloud_provider == "azure" && var.cosmos_db_config != null ? 1 : 0

  name                = "fintech"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.main[0].name
}

# Azure Storage Account
resource "azurerm_storage_account" "main" {
  count = var.cloud_provider == "azure" ? 1 : 0

  name                     = "${replace(var.name_prefix, "-", "")}storage"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  blob_properties {
    versioning_enabled = true
  }

  tags = var.tags
}

# Azure Storage Container
resource "azurerm_storage_container" "main" {
  count = var.cloud_provider == "azure" ? 1 : 0

  name                  = "documents"
  storage_account_name  = azurerm_storage_account.main[0].name
  container_access_type = "private"
}

# AWS RDS PostgreSQL
resource "aws_db_subnet_group" "main" {
  count = var.cloud_provider == "aws" ? 1 : 0

  name       = "${var.name_prefix}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = var.tags
}

resource "aws_security_group" "rds" {
  count = var.cloud_provider == "aws" ? 1 : 0

  name_prefix = "${var.name_prefix}-rds-"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = var.eks_security_group_ids
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rds-sg"
  })
}

resource "aws_db_instance" "main" {
  count = var.cloud_provider == "aws" && var.rds_config != null ? 1 : 0

  identifier = "${var.name_prefix}-rds"

  engine         = var.rds_config.engine
  engine_version = var.rds_config.engine_version
  instance_class = var.rds_config.instance_class

  allocated_storage     = var.rds_config.allocated_storage
  max_allocated_storage = var.rds_config.allocated_storage * 2
  storage_type          = "gp2"
  storage_encrypted     = true

  db_name  = "fintech"
  username = "postgres"
  password = random_password.db_password.result

  vpc_security_group_ids = [aws_security_group.rds[0].id]
  db_subnet_group_name   = aws_db_subnet_group.main[0].name

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  skip_final_snapshot = true
  deletion_protection = false

  tags = var.tags
}

# AWS S3 Bucket for document storage
resource "aws_s3_bucket" "main" {
  count = var.cloud_provider == "aws" ? 1 : 0

  bucket = "${var.name_prefix}-documents"

  tags = var.tags
}

resource "aws_s3_bucket_versioning" "main" {
  count = var.cloud_provider == "aws" ? 1 : 0

  bucket = aws_s3_bucket.main[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  count = var.cloud_provider == "aws" ? 1 : 0

  bucket = aws_s3_bucket.main[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  count = var.cloud_provider == "aws" ? 1 : 0

  bucket = aws_s3_bucket.main[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
} 