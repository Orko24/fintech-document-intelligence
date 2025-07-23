#!/bin/bash

# =============================================================================
# TERRAFORM INITIALIZATION SCRIPT
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to validate environment
validate_environment() {
    local env=$1
    
    if [[ ! "$env" =~ ^(dev|staging|prod)$ ]]; then
        print_error "Invalid environment: $env. Must be dev, staging, or prod."
        exit 1
    fi
    
    print_success "Environment validation passed: $env"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
    # Check Terraform version
    local tf_version=$(terraform version -json | jq -r '.terraform_version')
    print_status "Terraform version: $tf_version"
    
    # Check if required tools are installed
    local required_tools=("jq" "aws" "az" "gcloud")
    for tool in "${required_tools[@]}"; do
        if ! command -v $tool &> /dev/null; then
            print_warning "$tool is not installed. Some features may not work."
        else
            print_status "$tool is available"
        fi
    done
    
    print_success "Prerequisites check completed"
}

# Function to setup cloud providers
setup_cloud_providers() {
    local env=$1
    
    print_status "Setting up cloud provider authentication for $env environment..."
    
    # Azure setup
    print_status "Setting up Azure authentication..."
    if command -v az &> /dev/null; then
        if az account show &> /dev/null; then
            local az_account=$(az account show --query name -o tsv)
            print_success "Azure authenticated as: $az_account"
        else
            print_warning "Azure not authenticated. Run 'az login' to authenticate."
        fi
    fi
    
    # AWS setup
    print_status "Setting up AWS authentication..."
    if command -v aws &> /dev/null; then
        if aws sts get-caller-identity &> /dev/null; then
            local aws_account=$(aws sts get-caller-identity --query Account --output text)
            local aws_user=$(aws sts get-caller-identity --query Arn --output text)
            print_success "AWS authenticated as: $aws_user (Account: $aws_account)"
        else
            print_warning "AWS not authenticated. Run 'aws configure' to authenticate."
        fi
    fi
    
    # GCP setup
    print_status "Setting up GCP authentication..."
    if command -v gcloud &> /dev/null; then
        if gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
            local gcp_account=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -1)
            print_success "GCP authenticated as: $gcp_account"
        else
            print_warning "GCP not authenticated. Run 'gcloud auth login' to authenticate."
        fi
    fi
    
    print_success "Cloud provider setup completed"
}

# Function to setup environment variables
setup_environment() {
    local env=$1
    
    print_status "Setting up environment variables for $env..."
    
    # Source environment-specific variables
    if [[ -f "../environments/$env/terraform.tfvars" ]]; then
        print_status "Loading environment variables from ../environments/$env/terraform.tfvars"
        export TF_VAR_environment="$env"
    else
        print_error "No terraform.tfvars found for environment $env"
        print_error "Please create ../environments/$env/terraform.tfvars"
        exit 1
    fi
    
    # Set common environment variables
    export TF_VAR_project_name="fintech-ai-platform"
    export TF_VAR_environment="$env"
    
    print_success "Environment variables configured"
}

# Function to initialize Terraform
initialize_terraform() {
    local env=$1
    
    print_status "Initializing Terraform for environment: $env"
    
    # Create backend configuration directory
    mkdir -p .terraform
    
    # Initialize Terraform
    terraform init \
        -backend-config="key=$env/terraform.tfstate" \
        -backend-config="bucket=fintech-ai-platform-terraform-state" \
        -backend-config="region=us-east-1" \
        -reconfigure
    
    if [[ $? -eq 0 ]]; then
        print_success "Terraform initialized successfully"
    else
        print_error "Terraform initialization failed"
        exit 1
    fi
}

# Function to validate Terraform configuration
validate_configuration() {
    local env=$1
    
    print_status "Validating Terraform configuration for $env..."
    
    # Validate syntax
    terraform validate
    
    if [[ $? -eq 0 ]]; then
        print_success "Terraform configuration is valid"
    else
        print_error "Terraform configuration validation failed"
        exit 1
    fi
    
    # Format check
    print_status "Checking Terraform formatting..."
    terraform fmt -check -recursive
    
    if [[ $? -eq 0 ]]; then
        print_success "Terraform formatting is correct"
    else
        print_warning "Terraform formatting issues found. Run 'terraform fmt -recursive' to fix."
    fi
}

# Function to show next steps
show_next_steps() {
    local env=$1
    
    print_success "Initialization completed successfully!"
    echo ""
    print_status "Next steps:"
    echo "  1. Review the configuration: ../environments/$env/terraform.tfvars"
    echo "  2. Create a plan: ./scripts/plan.sh $env"
    echo "  3. Apply the infrastructure: ./scripts/apply.sh $env"
    echo ""
    print_status "Useful commands:"
    echo "  - View current state: terraform show"
    echo "  - List resources: terraform state list"
    echo "  - Destroy infrastructure: terraform destroy -var-file=../environments/$env/terraform.tfvars"
    echo ""
}

# Main execution
main() {
    local env=${1:-}
    
    if [[ -z "$env" ]]; then
        print_error "Usage: $0 <environment>"
        print_error "Environments: dev, staging, prod"
        exit 1
    fi
    
    print_status "Starting Terraform initialization for environment: $env"
    echo ""
    
    # Validate environment
    validate_environment "$env"
    
    # Check prerequisites
    check_prerequisites
    
    # Setup cloud providers
    setup_cloud_providers "$env"
    
    # Setup environment variables
    setup_environment "$env"
    
    # Initialize Terraform
    initialize_terraform "$env"
    
    # Validate configuration
    validate_configuration "$env"
    
    # Show next steps
    show_next_steps "$env"
}

# Run main function with all arguments
main "$@" 