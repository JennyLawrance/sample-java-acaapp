#!/bin/bash

# This script runs after infrastructure provisioning
# Import the image to Azure Container Registry

echo "Importing the Docker image to Azure Container Registry..."

# Build the Docker image
docker build -t concert-booking-app:latest .

# Get Container Registry information from azd environment
REGISTRY_URL=$(azd env get-values | grep CONTAINER_REGISTRY_URL | awk '{print $2}')
REGISTRY_USERNAME=$(azd env get-values | grep CONTAINER_REGISTRY_USERNAME | awk '{print $2}')
REGISTRY_PASSWORD=$(azd env get-values | grep CONTAINER_REGISTRY_PASSWORD | awk '{print $2}')

# Log in to Azure Container Registry
echo "Logging in to Azure Container Registry..."
echo $REGISTRY_PASSWORD | docker login $REGISTRY_URL -u $REGISTRY_USERNAME --password-stdin

# Tag and push the image
docker tag concert-booking-app:latest $REGISTRY_URL/concert-booking-app:latest
docker push $REGISTRY_URL/concert-booking-app:latest

echo "Image pushed to Azure Container Registry successfully." 