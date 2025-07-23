#!/bin/bash

# =============================================================================
# TERRAFORM PLAN SCRIPT
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

# Function to setup environment variables
setup_environment() {
    local env=$1
    
    print_status "Setting up environment variables for $env..."
    
    # Source environment-specific variables
    if [[ -f "../environments/$env/terraform.tfvars" ]]; then
        print_status "Loading environment variables from ../environments/$env/terraform.tfvars"
        export TF_VAR_environment="$env"
    else
        print_warning "No terraform.tfvars found for environment $env"
    fi
    
    # Set common environment variables
    export TF_VAR_project_name="fintech-ai-platform"
    export TF_VAR_environment="$env"
    
    print_success "Environment variables configured"
}

# Function to create plan
create_plan() {
    local env=$1
    
    print_status "Creating Terraform plan for environment: $env"
    
    # Create plans directory if it doesn't exist
    mkdir -p plans
    
    # Create plan file
    local plan_file="plans/$env.tfplan"
    
    # Run terraform plan
    terraform plan \
        -var-file="../environments/$env/terraform.tfvars" \
        -out="$plan_file" \
        -detailed-exitcode
    
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        print_success "No changes needed. Infrastructure is up to date."
        return 0
    elif [[ $exit_code -eq 1 ]]; then
        print_error "Terraform plan failed"
        exit 1
    elif [[ $exit_code -eq 2 ]]; then
        print_success "Plan created successfully with changes"
        print_status "Plan saved to: $plan_file"
        print_status "To apply the plan, run: ./scripts/apply.sh $env"
        return 0
    fi
}

# Function to show plan summary
show_plan_summary() {
    local env=$1
    local plan_file="plans/$env.tfplan"
    
    if [[ -f "$plan_file" ]]; then
        print_status "Plan summary for environment: $env"
        terraform show -no-color "$plan_file" | grep -E "(Plan:|Terraform will perform the following actions:|No changes)" || true
    fi
}

# Function to estimate costs
estimate_costs() {
    local env=$1
    
    print_status "Estimating costs for environment: $env"
    
    # Check if infracost is installed
    if command -v infracost >/dev/null 2>&1; then
        print_status "Running cost estimation with Infracost..."
        infracost breakdown --path . --format table --out-file "plans/$env-cost-estimate.txt"
        print_success "Cost estimate saved to: plans/$env-cost-estimate.txt"
    else
        print_warning "Infracost not installed. Install it to get cost estimates."
        print_status "Install with: curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh"
    fi
}

# Main function
main() {
    local env=${1:-dev}
    
    print_status "Starting Terraform plan for environment: $env"
    
    # Validate environment
    validate_environment "$env"
    
    # Setup environment variables
    setup_environment "$env"
    
    # Create plan
    create_plan "$env"
    
    # Show plan summary
    show_plan_summary "$env"
    
    # Estimate costs
    estimate_costs "$env"
    
    print_success "Terraform plan completed successfully!"
    print_status "Next steps:"
    echo "  1. Review the plan output above"
    echo "  2. Check cost estimates in plans/$env-cost-estimate.txt"
    echo "  3. If satisfied, run: ./scripts/apply.sh $env"
}

# Check if environment argument is provided
if [[ $# -eq 0 ]]; then
    print_warning "No environment specified. Using 'dev' as default."
    main "dev"
else
    main "$1"
fi 