#!/bin/bash

# =============================================================================
# TERRAFORM APPLY SCRIPT
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

# Function to confirm deployment
confirm_deployment() {
    local env=$1
    
    print_warning "You are about to deploy infrastructure to the $env environment."
    print_warning "This will create/modify cloud resources and may incur costs."
    
    if [[ "$env" == "prod" ]]; then
        print_error "PRODUCTION DEPLOYMENT WARNING:"
        echo "  - This will deploy to PRODUCTION environment"
        echo "  - All changes will be live and affect real users"
        echo "  - Ensure you have reviewed the plan thoroughly"
        echo ""
        read -p "Are you absolutely sure you want to deploy to PRODUCTION? (type 'yes' to confirm): " -r
        if [[ ! $REPLY =~ ^yes$ ]]; then
            print_error "Production deployment cancelled."
            exit 1
        fi
    else
        read -p "Do you want to continue with the deployment? (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_error "Deployment cancelled."
            exit 1
        fi
    fi
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

# Function to apply infrastructure
apply_infrastructure() {
    local env=$1
    
    print_status "Applying Terraform infrastructure for environment: $env"
    
    # Check if plan file exists
    local plan_file="plans/$env.tfplan"
    if [[ ! -f "$plan_file" ]]; then
        print_warning "No plan file found. Creating a new plan..."
        ./scripts/plan.sh "$env"
    fi
    
    # Apply the plan
    print_status "Applying infrastructure changes..."
    terraform apply -auto-approve "$plan_file"
    
    print_success "Infrastructure deployment completed successfully!"
}

# Function to save outputs
save_outputs() {
    local env=$1
    
    print_status "Saving Terraform outputs..."
    
    # Create outputs directory if it doesn't exist
    mkdir -p outputs
    
    # Save outputs to file
    terraform output -json > "outputs/$env-outputs.json"
    
    # Save sensitive outputs separately (without values)
    terraform output > "outputs/$env-outputs.txt"
    
    print_success "Outputs saved to outputs/$env-outputs.json and outputs/$env-outputs.txt"
}

# Function to display deployment summary
show_deployment_summary() {
    local env=$1
    
    print_success "Deployment completed successfully!"
    print_status "Deployment Summary:"
    echo "  Environment: $env"
    echo "  Timestamp: $(date)"
    echo "  Outputs: outputs/$env-outputs.json"
    echo ""
    print_status "Next steps:"
    echo "  1. Review the outputs in outputs/$env-outputs.json"
    echo "  2. Configure your applications with the new endpoints"
    echo "  3. Deploy your applications to the new infrastructure"
    echo "  4. Run: ./scripts/destroy.sh $env (if you need to clean up)"
}

# Function to send notifications
send_notifications() {
    local env=$1
    
    print_status "Sending deployment notifications..."
    
    # You can add notification logic here (Slack, email, etc.)
    # Example for Slack:
    # curl -X POST -H 'Content-type: application/json' \
    #   --data "{\"text\":\"Infrastructure deployment completed for $env environment\"}" \
    #   $SLACK_WEBHOOK_URL
    
    print_success "Notifications sent"
}

# Main function
main() {
    local env=${1:-dev}
    
    print_status "Starting Terraform apply for environment: $env"
    
    # Validate environment
    validate_environment "$env"
    
    # Confirm deployment
    confirm_deployment "$env"
    
    # Setup environment variables
    setup_environment "$env"
    
    # Apply infrastructure
    apply_infrastructure "$env"
    
    # Save outputs
    save_outputs "$env"
    
    # Send notifications
    send_notifications "$env"
    
    # Show deployment summary
    show_deployment_summary "$env"
}

# Check if environment argument is provided
if [[ $# -eq 0 ]]; then
    print_warning "No environment specified. Using 'dev' as default."
    main "dev"
else
    main "$1"
fi 