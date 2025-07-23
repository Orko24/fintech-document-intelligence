# =============================================================================
# NETWORKING MODULE (Multi-Cloud)
# =============================================================================

# Azure Networking Resources
resource "azurerm_virtual_network" "main" {
  count = var.cloud_provider == "azure" ? 1 : 0

  name                = "${var.name_prefix}-vnet"
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.vnet_address_space

  tags = var.tags
}

resource "azurerm_subnet" "main" {
  for_each = var.cloud_provider == "azure" ? var.subnet_configs : {}

  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main[0].name
  address_prefixes     = each.value.address_prefixes

  dynamic "service_endpoints" {
    for_each = lookup(each.value, "service_endpoints", [])
    content {
      service = service_endpoints.value
    }
  }

  tags = var.tags
}

# AWS Networking Resources
resource "aws_vpc" "main" {
  count = var.cloud_provider == "aws" ? 1 : 0

  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-vpc"
  })
}

resource "aws_subnet" "public" {
  count = var.cloud_provider == "aws" ? length(var.public_subnet_cidrs) : 0

  vpc_id                  = aws_vpc.main[0].id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-${var.availability_zones[count.index]}"
    Tier = "Public"
  })
}

resource "aws_subnet" "private" {
  count = var.cloud_provider == "aws" ? length(var.private_subnet_cidrs) : 0

  vpc_id            = aws_vpc.main[0].id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-${var.availability_zones[count.index]}"
    Tier = "Private"
  })
}

# Internet Gateway for AWS
resource "aws_internet_gateway" "main" {
  count = var.cloud_provider == "aws" ? 1 : 0

  vpc_id = aws_vpc.main[0].id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-igw"
  })
}

# NAT Gateway for AWS
resource "aws_eip" "nat" {
  count = var.cloud_provider == "aws" && var.enable_nat_gateway ? 1 : 0

  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-nat-eip"
  })
}

resource "aws_nat_gateway" "main" {
  count = var.cloud_provider == "aws" && var.enable_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-nat-gateway"
  })

  depends_on = [aws_internet_gateway.main]
}

# Route Tables for AWS
resource "aws_route_table" "public" {
  count = var.cloud_provider == "aws" ? 1 : 0

  vpc_id = aws_vpc.main[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main[0].id
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-rt"
  })
}

resource "aws_route_table" "private" {
  count = var.cloud_provider == "aws" && var.enable_nat_gateway ? 1 : 0

  vpc_id = aws_vpc.main[0].id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[0].id
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-rt"
  })
}

# Route Table Associations for AWS
resource "aws_route_table_association" "public" {
  count = var.cloud_provider == "aws" ? length(aws_subnet.public) : 0

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table_association" "private" {
  count = var.cloud_provider == "aws" && var.enable_nat_gateway ? length(aws_subnet.private) : 0

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[0].id
}

# Security Groups for AWS
resource "aws_security_group" "eks" {
  count = var.cloud_provider == "aws" ? 1 : 0

  name_prefix = "${var.name_prefix}-eks-"
  vpc_id      = aws_vpc.main[0].id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-eks-sg"
  })
}

resource "aws_security_group" "rds" {
  count = var.cloud_provider == "aws" ? 1 : 0

  name_prefix = "${var.name_prefix}-rds-"
  vpc_id      = aws_vpc.main[0].id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.eks[0].id]
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