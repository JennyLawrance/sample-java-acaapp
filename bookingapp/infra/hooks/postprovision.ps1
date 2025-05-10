# This script runs after infrastructure provisioning
# Import the image to Azure Container Registry

Write-Host "Importing the Docker image to Azure Container Registry..." -ForegroundColor Cyan

# Build the Docker image
docker build -t concert-booking-app:latest .

# Get Container Registry information from azd environment
$env_values = azd env get-values
$REGISTRY_URL = ($env_values | Select-String "CONTAINER_REGISTRY_URL").ToString().Split(' ')[1]
$REGISTRY_USERNAME = ($env_values | Select-String "CONTAINER_REGISTRY_USERNAME").ToString().Split(' ')[1]
$REGISTRY_PASSWORD = ($env_values | Select-String "CONTAINER_REGISTRY_PASSWORD").ToString().Split(' ')[1]

# Log in to Azure Container Registry
Write-Host "Logging in to Azure Container Registry..." -ForegroundColor Cyan
echo $REGISTRY_PASSWORD | docker login $REGISTRY_URL -u $REGISTRY_USERNAME --password-stdin

# Tag and push the image
docker tag concert-booking-app:latest "$REGISTRY_URL/concert-booking-app:latest"
docker push "$REGISTRY_URL/concert-booking-app:latest"

Write-Host "Image pushed to Azure Container Registry successfully." -ForegroundColor Green 