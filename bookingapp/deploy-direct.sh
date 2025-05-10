#!/bin/bash

# Direct deployment script for Azure Container Apps
# This script bypasses azd hooks and directly handles the deployment process

# Default parameters
location="eastus"
skip_provision=false

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --location) location="$2"; shift ;;
        --skip-provision) skip_provision=true ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

echo -e "\033[0;36mStarting direct deployment to Azure Container Apps...\033[0m"

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "\033[0;31mError: Azure CLI is not installed or not in PATH.\033[0m"
    echo -e "\033[0;33mPlease install Azure CLI: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli\033[0m"
    exit 1
fi
echo -e "\033[0;32mAzure CLI is installed.\033[0m"

# Check if jq is installed (needed for JSON parsing)
if ! command -v jq &> /dev/null; then
    echo -e "\033[0;31mError: jq is not installed or not in PATH.\033[0m"
    echo -e "\033[0;33mPlease install jq: https://stedolan.github.io/jq/download/\033[0m"
    exit 1
fi
echo -e "\033[0;32mjq is installed.\033[0m"

# Check if logged in to Azure
echo -e "\033[0;36mChecking Azure login status...\033[0m"
account=$(az account show 2>/dev/null)
if [ $? -ne 0 ]; then
    echo -e "\033[0;33mNot logged in to Azure. Logging in now...\033[0m"
    az login
    if [ $? -ne 0 ]; then
        echo -e "\033[0;31mFailed to log in to Azure.\033[0m"
        exit 1
    fi
fi
user_name=$(echo $account | jq -r '.user.name')
echo -e "\033[0;32mLogged in to Azure as $user_name\033[0m"

# Get or set environment name
if [ -f ".azure/config" ]; then
    ENV_NAME=$(grep "name" .azure/config | awk '{print $3}')
    
    if [ -z "$ENV_NAME" ]; then
        ENV_NAME="concert-booking-app"
        echo -e "\033[0;33mEnvironment name not found. Using default: $ENV_NAME\033[0m"
    else
        echo -e "\033[0;36mUsing environment name from config: $ENV_NAME\033[0m"
    fi
else
    ENV_NAME="concert-booking-app"
    echo -e "\033[0;33mNo .azure/config found. Using default environment name: $ENV_NAME\033[0m"
    
    # Create .azure directory and config file
    if [ ! -d ".azure" ]; then
        mkdir -p ".azure"
    fi
    
    cat > .azure/config << EOF
[defaults]
location = $location

[environment]
name = $ENV_NAME
EOF
fi

# Set resource group name
RESOURCE_GROUP="rg$ENV_NAME"

# Check if resource group exists
rg_exists=$(az group exists --name $RESOURCE_GROUP)
if [ "$rg_exists" == "false" ]; then
    if [ "$skip_provision" == false ]; then
        echo -e "\033[0;33mResource group $RESOURCE_GROUP does not exist. Creating...\033[0m"
        az group create --name $RESOURCE_GROUP --location $location
        if [ $? -ne 0 ]; then
            echo -e "\033[0;31mFailed to create resource group.\033[0m"
            exit 1
        fi
        echo -e "\033[0;32mResource group created.\033[0m"
    else
        echo -e "\033[0;31mResource group $RESOURCE_GROUP does not exist and skip_provision is set. Cannot continue.\033[0m"
        exit 1
    fi
fi

# Provision infrastructure if not skipped
if [ "$skip_provision" == false ]; then
    echo -e "\033[0;36mProvisioning Azure resources...\033[0m"
    echo -e "\033[0;33mThis may take several minutes...\033[0m"
    
    # Deploy main infrastructure
    echo -e "\033[0;36mDeploying main infrastructure...\033[0m"
    az deployment group create \
        --resource-group $RESOURCE_GROUP \
        --template-file ./infra/resources.bicep \
        --parameters \
            environmentName=$ENV_NAME \
            location=$location \
            tags="{ 'azd-env-name': '$ENV_NAME' }"
    
    if [ $? -ne 0 ]; then
        echo -e "\033[0;31mFailed to provision infrastructure.\033[0m"
        exit 1
    fi
    
    echo -e "\033[0;32mInfrastructure provisioned successfully.\033[0m"
fi

# Generate a unique tag using timestamp
timestamp=$(date +%Y%m%d%H%M%S)
imageTag="v1-$timestamp"
echo -e "\033[0;36mUsing image tag: $imageTag\033[0m"

# Build the Docker image
echo -e "\033[0;36mBuilding Docker image...\033[0m"
docker build -t concert-booking-app:$imageTag .
if [ $? -ne 0 ]; then
    echo -e "\033[0;31mError: Docker build failed!\033[0m"
    exit 1
fi

# Get Container Registry information using Azure CLI
echo -e "\033[0;36mGetting Azure Container Registry credentials...\033[0m"

# Get container registry name
REGISTRY_INFO=$(az acr list --resource-group $RESOURCE_GROUP --query "[0]" -o json)
if [ -z "$REGISTRY_INFO" ] || [ "$REGISTRY_INFO" == "null" ]; then
    echo -e "\033[0;31mError: Could not find Azure Container Registry in resource group $RESOURCE_GROUP\033[0m"
    exit 1
fi

REGISTRY_URL=$(echo $REGISTRY_INFO | jq -r '.loginServer')
REGISTRY_NAME=$(echo $REGISTRY_INFO | jq -r '.name')

# Get container registry credentials
CREDENTIALS=$(az acr credential show --name $REGISTRY_NAME -o json)
REGISTRY_USERNAME=$(echo $CREDENTIALS | jq -r '.username')
REGISTRY_PASSWORD=$(echo $CREDENTIALS | jq -r '.passwords[0].value')

# Get Container Apps Environment ID
ENV_INFO=$(az containerapp env list --resource-group $RESOURCE_GROUP --query "[0]" -o json)
CONTAINER_APPS_ENVIRONMENT_ID=$(echo $ENV_INFO | jq -r '.id')

# Get location if not specified or empty
if [ -z "$location" ]; then
    location=$(echo $REGISTRY_INFO | jq -r '.location')
fi

# Check if we got all required values
if [ -z "$REGISTRY_URL" ] || [ -z "$REGISTRY_USERNAME" ] || [ -z "$REGISTRY_PASSWORD" ] || [ -z "$CONTAINER_APPS_ENVIRONMENT_ID" ]; then
    echo -e "\033[0;31mError: Missing required values from Azure resources\033[0m"
    exit 1
fi

echo -e "\033[0;36mRegistry URL: $REGISTRY_URL\033[0m"
echo -e "\033[0;36mRegistry Name: $REGISTRY_NAME\033[0m"

# Log in to Azure Container Registry
echo -e "\033[0;36mLogging in to Azure Container Registry...\033[0m"
echo $REGISTRY_PASSWORD | docker login $REGISTRY_URL -u $REGISTRY_USERNAME --password-stdin
if [ $? -ne 0 ]; then
    echo -e "\033[0;31mError: Failed to log in to Azure Container Registry!\033[0m"
    exit 1
fi

# Tag and push the image with unique tag
echo -e "\033[0;36mTagging and pushing the image to Azure Container Registry...\033[0m"
docker tag concert-booking-app:$imageTag "$REGISTRY_URL/concert-booking-app:$imageTag"
docker push "$REGISTRY_URL/concert-booking-app:$imageTag"
if [ $? -ne 0 ]; then
    echo -e "\033[0;31mError: Failed to push the image to Azure Container Registry!\033[0m"
    exit 1
fi

# Also tag as latest for convenience
docker tag concert-booking-app:$imageTag "$REGISTRY_URL/concert-booking-app:latest"
docker push "$REGISTRY_URL/concert-booking-app:latest"
if [ $? -ne 0 ]; then
    echo -e "\033[0;33mWarning: Failed to push the latest tag to Azure Container Registry!\033[0m"
    # Continue anyway since the versioned tag was pushed successfully
fi

echo -e "\033[0;32mImage pushed to Azure Container Registry successfully.\033[0m"

# Deploy the Container App
echo -e "\033[0;33mNow deploying the Container App...\033[0m"
TAGS="{ 'azd-env-name': '$ENV_NAME' }"
DEPLOYMENT_NAME="container-app-deployment-$timestamp"

az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --name $DEPLOYMENT_NAME \
  --template-file ./infra/containerapp.bicep \
  --parameters \
    environmentName=$ENV_NAME \
    location=$location \
    tags=$TAGS \
    containerAppsEnvironmentId=$CONTAINER_APPS_ENVIRONMENT_ID \
    containerRegistryLoginServer=$REGISTRY_URL \
    containerRegistryName=$REGISTRY_USERNAME \
    containerRegistryPasswordSecretValue=$REGISTRY_PASSWORD \
    imageTag=$imageTag

if [ $? -ne 0 ]; then
    echo -e "\033[0;31mError: Failed to deploy Container App!\033[0m"
    exit 1
fi

# Get the Container App URL
CONTAINER_APP_URL=$(az containerapp show --name "ca-$ENV_NAME" --resource-group $RESOURCE_GROUP --query "properties.configuration.ingress.fqdn" -o tsv)
if [ $? -ne 0 ] || [ -z "$CONTAINER_APP_URL" ]; then
    echo -e "\033[0;33mWarning: Failed to get Container App URL\033[0m"
else
    # Store values in local .env file
    ENV_FILE=".azure/.env"
    
    # Create or update .env file
    if [ ! -f "$ENV_FILE" ]; then
        touch "$ENV_FILE"
    fi
    
    # Update or add values
    if grep -q "^CONTAINER_APP_URL=" "$ENV_FILE"; then
        sed -i "s|^CONTAINER_APP_URL=.*|CONTAINER_APP_URL=https://$CONTAINER_APP_URL|" "$ENV_FILE"
    else
        echo "CONTAINER_APP_URL=https://$CONTAINER_APP_URL" >> "$ENV_FILE"
    fi
    
    if grep -q "^CONTAINER_IMAGE_TAG=" "$ENV_FILE"; then
        sed -i "s|^CONTAINER_IMAGE_TAG=.*|CONTAINER_IMAGE_TAG=$imageTag|" "$ENV_FILE"
    else
        echo "CONTAINER_IMAGE_TAG=$imageTag" >> "$ENV_FILE"
    fi
    
    # Also try azd env set for completeness
    azd env set CONTAINER_APP_URL "https://$CONTAINER_APP_URL" 2>/dev/null || true
    azd env set CONTAINER_IMAGE_TAG "$imageTag" 2>/dev/null || true
fi

echo -e "\n\033[0;32mDeployment completed successfully!\033[0m"
echo -e "\033[0;32mYou can access your application at: https://$CONTAINER_APP_URL\033[0m"
echo -e "\033[0;32mDeployed image tag: $imageTag\033[0m" 