#!/bin/bash

# Deploy Azure Logic App (Consumption) for Customer Sync
# This script deploys the Bicep infrastructure to Azure

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration variables
RESOURCE_GROUP_NAME="${RESOURCE_GROUP_NAME:-rg-customer-sync}"
LOCATION="${LOCATION:-eastus}"
DEPLOYMENT_NAME="logic-app-deployment-$(date +%Y%m%d-%H%M%S)"

print_info "Starting deployment of Customer Sync Logic App..."
echo "=================================================="
echo "Resource Group: $RESOURCE_GROUP_NAME"
echo "Location: $LOCATION"
echo "Deployment Name: $DEPLOYMENT_NAME"
echo "=================================================="

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    print_error "Azure CLI is not installed. Please install it first."
    print_info "Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check if user is logged in
print_info "Checking Azure login status..."
if ! az account show &> /dev/null; then
    print_warning "Not logged in to Azure. Please log in."
    az login
else
    print_info "Already logged in to Azure"
    CURRENT_ACCOUNT=$(az account show --query name -o tsv)
    print_info "Current subscription: $CURRENT_ACCOUNT"
fi

# Prompt for confirmation
read -p "Do you want to continue with deployment? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Deployment cancelled."
    exit 0
fi

# Create resource group if it doesn't exist
print_info "Creating resource group if it doesn't exist..."
if az group exists --name "$RESOURCE_GROUP_NAME" | grep -q "false"; then
    az group create --name "$RESOURCE_GROUP_NAME" --location "$LOCATION"
    print_info "Resource group '$RESOURCE_GROUP_NAME' created."
else
    print_info "Resource group '$RESOURCE_GROUP_NAME' already exists."
fi

# Navigate to infrastructure directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$SCRIPT_DIR/infrastructure"

if [ ! -d "$INFRA_DIR" ]; then
    print_error "Infrastructure directory not found at: $INFRA_DIR"
    exit 1
fi

cd "$INFRA_DIR"

# Check if parameters file exists
if [ ! -f "parameters.json" ]; then
    print_error "parameters.json not found in infrastructure directory"
    print_info "Please create parameters.json with your SQL and Oracle connection details"
    exit 1
fi

# Validate parameters file has been updated
if grep -q "YOUR_SQL_SERVER\|YOUR_DATABASE_NAME\|YOUR_ORACLE_SERVER" parameters.json; then
    print_error "Parameters file contains placeholder values"
    print_info "Please update parameters.json with actual SQL and Oracle connection details"
    exit 1
fi

# Validate Bicep file
print_info "Validating Bicep template..."
if az bicep build --file main.bicep > /dev/null 2>&1; then
    print_info "Bicep template validation successful"
else
    print_error "Bicep template validation failed"
    exit 1
fi

# Deploy Bicep template
print_info "Deploying Bicep template to Azure..."
print_info "This may take a few minutes..."

if az deployment group create \
    --name "$DEPLOYMENT_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --template-file main.bicep \
    --parameters parameters.json \
    --verbose; then
    
    print_info "Deployment successful!"
    
    # Get deployment outputs
    print_info "Retrieving deployment outputs..."
    LOGIC_APP_NAME=$(az deployment group show \
        --name "$DEPLOYMENT_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --query properties.outputs.logicAppName.value -o tsv)
    
    LOGIC_APP_ID=$(az deployment group show \
        --name "$DEPLOYMENT_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --query properties.outputs.logicAppId.value -o tsv)
    
    LOGIC_APP_PRINCIPAL_ID=$(az deployment group show \
        --name "$DEPLOYMENT_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --query properties.outputs.logicAppPrincipalId.value -o tsv)
    
    echo ""
    echo "=================================================="
    print_info "Deployment Summary"
    echo "=================================================="
    echo "Logic App Name: $LOGIC_APP_NAME"
    echo "Logic App ID: $LOGIC_APP_ID"
    echo "Managed Identity Principal ID: $LOGIC_APP_PRINCIPAL_ID"
    echo "Resource Group: $RESOURCE_GROUP_NAME"
    echo ""
    print_info "You can view your Logic App in the Azure Portal:"
    echo "https://portal.azure.com/#@/resource$LOGIC_APP_ID"
    echo ""
    print_info "IMPORTANT: Configure Azure AD Authentication for SQL Database"
    echo "The Logic App now uses Azure AD (Entra ID) authentication via Managed Identity."
    echo ""
    echo "To grant the Logic App access to your SQL Database, run these commands:"
    echo ""
    echo "1. Connect to your SQL Database and execute:"
    echo "   CREATE USER [logic-customer-sync] FROM EXTERNAL PROVIDER;"
    echo "   ALTER ROLE db_datareader ADD MEMBER [logic-customer-sync];"
    echo "   ALTER ROLE db_datawriter ADD MEMBER [logic-customer-sync];"
    echo ""
    echo "2. Ensure your SQL Server has Azure AD authentication enabled."
    echo "3. Ensure your SQL Server firewall allows Azure services."
    echo ""
    print_info "To authorize the Oracle API connection:"
    echo "1. Go to the Azure Portal"
    echo "2. Navigate to the Logic App"
    echo "3. Click on 'API connections' in the left menu"
    echo "4. Authorize the Oracle connection"
    echo "=================================================="
    
else
    print_error "Deployment failed!"
    exit 1
fi

print_info "Deployment completed successfully!"
