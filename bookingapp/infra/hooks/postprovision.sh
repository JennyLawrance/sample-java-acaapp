#!/bin/bash

# This script runs after infrastructure provisioning
# Import the image to Azure Container Registry

echo -e "\033[0;36mImporting the Docker image to Azure Container Registry...\033[0m"

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

# Get environment name from config file
if [ -f ".azure/config" ]; then
    ENV_NAME=$(grep "name" .azure/config | awk '{print $3}')
    if [ -z "$ENV_NAME" ]; then
        echo -e "\033[0;31mError: Could not find environment name in .azure/config\033[0m"
        exit 1
    fi
else
    echo -e "\033[0;31mError: Could not find .azure/config file\033[0m"
    exit 1
fi

echo -e "\033[0;36mEnvironment name: $ENV_NAME\033[0m"

# Get resource group name
RESOURCE_GROUP="rg$ENV_NAME"
echo -e "\033[0;36mResource group: $RESOURCE_GROUP\033[0m"

# Get Container Registry information using Azure CLI
echo -e "\033[0;36mGetting Azure Container Registry credentials using Azure CLI...\033[0m"

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

# Get location
LOCATION=$(echo $REGISTRY_INFO | jq -r '.location')

# Check if we got all required values
if [ -z "$REGISTRY_URL" ] || [ -z "$REGISTRY_USERNAME" ] || [ -z "$REGISTRY_PASSWORD" ] || [ -z "$CONTAINER_APPS_ENVIRONMENT_ID" ] || [ -z "$LOCATION" ]; then
    echo -e "\033[0;31mError: Missing required values from Azure resources\033[0m"
    echo -e "\033[0;33mMake sure you've provisioned the infrastructure with 'azd provision'.\033[0m"
    exit 1
fi

echo -e "\033[0;32mEnvironment values retrieved successfully.\033[0m"
echo -e "\033[0;36mRegistry URL: $REGISTRY_URL\033[0m"
echo -e "\033[0;36mRegistry Name: $REGISTRY_NAME\033[0m"
echo -e "\033[0;36mLocation: $LOCATION\033[0m"

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
echo -e "\033[0;33mNow deploying the Container App...\033[0m"

# Deploy the Container App using the separate Bicep file
echo -e "\033[0;36mDeploying Container App...\033[0m"
TAGS="{ 'azd-env-name': '$ENV_NAME' }"

DEPLOYMENT_NAME="container-app-deployment-$timestamp"

az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --name $DEPLOYMENT_NAME \
  --template-file ./infra/containerapp.bicep \
  --parameters \
    environmentName=$ENV_NAME \
    location=$LOCATION \
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

# Update the CONTAINER_APP_URL in the environment
CONTAINER_APP_URL=$(az containerapp show --name "ca-$ENV_NAME" --resource-group $RESOURCE_GROUP --query "properties.configuration.ingress.fqdn" -o tsv)
if [ $? -ne 0 ] || [ -z "$CONTAINER_APP_URL" ]; then
    echo -e "\033[0;31mWarning: Failed to get Container App URL\033[0m"
else
    # Use a local .env file since azd env set might have the same issue
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

echo -e "\033[0;32mContainer App deployed successfully!\033[0m"
echo -e "\033[0;32mYou can access your application at: https://$CONTAINER_APP_URL\033[0m"
echo -e "\033[0;32mDeployed image tag: $imageTag\033[0m" 