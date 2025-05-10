# Direct deployment script for Azure Container Apps
# This script bypasses azd hooks and directly handles the deployment process

param (
    [switch]$skipProvision = $false,
    [string]$location = "eastus"
)

Write-Host "Starting direct deployment to Azure Container Apps..." -ForegroundColor Cyan

# Check if Azure CLI is installed
try {
    $azVersion = az version
    Write-Host "Azure CLI is installed." -ForegroundColor Green
} catch {
    Write-Host "Error: Azure CLI is not installed or not in PATH." -ForegroundColor Red
    Write-Host "Please install Azure CLI: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli" -ForegroundColor Yellow
    exit 1
}

# Check if logged in to Azure
Write-Host "Checking Azure login status..." -ForegroundColor Cyan
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Host "Not logged in to Azure. Logging in now..." -ForegroundColor Yellow
    az login
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to log in to Azure." -ForegroundColor Red
        exit 1
    }
}
Write-Host "Logged in to Azure as $($account.user.name)" -ForegroundColor Green

# Get or set environment name
if (Test-Path ".azure/config") {
    $configContent = Get-Content -Path ".azure/config" -ErrorAction Stop
    $ENV_NAME = ($configContent | Where-Object { $_ -match "name\s+=\s+(.*)" } | ForEach-Object { $matches[1] })
    
    if (-not $ENV_NAME) {
        $ENV_NAME = "concert-booking-app"
        Write-Host "Environment name not found. Using default: $ENV_NAME" -ForegroundColor Yellow
    } else {
        Write-Host "Using environment name from config: $ENV_NAME" -ForegroundColor Cyan
    }
} else {
    $ENV_NAME = "concert-booking-app"
    Write-Host "No .azure/config found. Using default environment name: $ENV_NAME" -ForegroundColor Yellow
    
    # Create .azure directory and config file
    if (-not (Test-Path ".azure")) {
        New-Item -ItemType Directory -Path ".azure" | Out-Null
    }
    
    @"
[defaults]
location = $location

[environment]
name = $ENV_NAME
"@ | Out-File -FilePath ".azure/config" -Encoding utf8
}

# Set resource group name
$resourceGroup = "rg$ENV_NAME"

# Check if resource group exists
$rgExists = az group exists --name $resourceGroup
if ($rgExists -eq "false") {
    if (-not $skipProvision) {
        Write-Host "Resource group $resourceGroup does not exist. Creating..." -ForegroundColor Yellow
        az group create --name $resourceGroup --location $location
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Failed to create resource group." -ForegroundColor Red
            exit 1
        }
        Write-Host "Resource group created." -ForegroundColor Green
    } else {
        Write-Host "Resource group $resourceGroup does not exist and skipProvision is set. Cannot continue." -ForegroundColor Red
        exit 1
    }
}

# Provision infrastructure if not skipped
if (-not $skipProvision) {
    Write-Host "Provisioning Azure resources..." -ForegroundColor Cyan
    Write-Host "This may take several minutes..." -ForegroundColor Yellow
    
    # Deploy main infrastructure
    Write-Host "Deploying main infrastructure..." -ForegroundColor Cyan
    az deployment group create `
        --resource-group $resourceGroup `
        --template-file ./infra/resources.bicep `
        --parameters `
            environmentName=$ENV_NAME `
            location=$location `
            tags="{ 'azd-env-name': '$ENV_NAME' }"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to provision infrastructure." -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Infrastructure provisioned successfully." -ForegroundColor Green
}

# Generate a unique tag using timestamp
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$imageTag = "v1-$timestamp"
Write-Host "Using image tag: $imageTag" -ForegroundColor Cyan

# Build the Docker image
Write-Host "Building Docker image..." -ForegroundColor Cyan
docker build -t concert-booking-app:$imageTag .
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Docker build failed!" -ForegroundColor Red
    exit 1
}

# Get Container Registry information using Azure CLI
Write-Host "Getting Azure Container Registry credentials..." -ForegroundColor Cyan

try {
    # Get container registry name
    $registryInfo = az acr list --resource-group $resourceGroup --query "[0]" | ConvertFrom-Json
    if (-not $registryInfo) {
        throw "Could not find Azure Container Registry in resource group $resourceGroup"
    }
    
    $REGISTRY_URL = $registryInfo.loginServer
    $REGISTRY_NAME = $registryInfo.name
    
    # Get container registry credentials
    $credentials = az acr credential show --name $REGISTRY_NAME | ConvertFrom-Json
    $REGISTRY_USERNAME = $credentials.username
    $REGISTRY_PASSWORD = $credentials.passwords[0].value
    
    # Get Container Apps Environment ID
    $envInfo = az containerapp env list --resource-group $resourceGroup --query "[0]" | ConvertFrom-Json
    $CONTAINER_APPS_ENVIRONMENT_ID = $envInfo.id
    
    # Get location if not specified
    if (-not $location -or $location -eq "") {
        $location = $registryInfo.location
    }
    
    if (-not $REGISTRY_URL -or -not $REGISTRY_USERNAME -or -not $REGISTRY_PASSWORD -or -not $CONTAINER_APPS_ENVIRONMENT_ID) {
        throw "Missing required values from Azure resources"
    }
} catch {
    Write-Host "Error: Failed to get Azure Container Registry credentials: $_" -ForegroundColor Red
    Write-Host "Make sure you're logged in to Azure and have provisioned the infrastructure." -ForegroundColor Red
    exit 1
}

Write-Host "Registry URL: $REGISTRY_URL" -ForegroundColor Cyan
Write-Host "Registry Name: $REGISTRY_NAME" -ForegroundColor Cyan

# Log in to Azure Container Registry
Write-Host "Logging in to Azure Container Registry..." -ForegroundColor Cyan
try {
    # Use docker login with credentials
    $REGISTRY_PASSWORD | docker login $REGISTRY_URL -u $REGISTRY_USERNAME --password-stdin
    if ($LASTEXITCODE -ne 0) {
        throw "Docker login failed with exit code $LASTEXITCODE"
    }
} catch {
    Write-Host "Error: Failed to log in to Azure Container Registry: $_" -ForegroundColor Red
    exit 1
}

# Tag and push the image with unique tag
Write-Host "Tagging and pushing the image to Azure Container Registry..." -ForegroundColor Cyan
try {
    docker tag concert-booking-app:$imageTag "$REGISTRY_URL/concert-booking-app:$imageTag"
    docker push "$REGISTRY_URL/concert-booking-app:$imageTag"
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to push image with tag $imageTag"
    }
    
    # Also tag as latest for convenience
    docker tag concert-booking-app:$imageTag "$REGISTRY_URL/concert-booking-app:latest"
    docker push "$REGISTRY_URL/concert-booking-app:latest"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Warning: Failed to push the latest tag to Azure Container Registry!" -ForegroundColor Yellow
        # Continue anyway since the versioned tag was pushed successfully
    }
} catch {
    Write-Host "Error: Failed to push the image to Azure Container Registry: $_" -ForegroundColor Red
    exit 1
}

Write-Host "Image pushed to Azure Container Registry successfully." -ForegroundColor Green

# Deploy the Container App
Write-Host "Deploying Container App..." -ForegroundColor Yellow
$tags = "{ 'azd-env-name': '$ENV_NAME' }"
$deployment_name = "container-app-deployment-$timestamp"

try {
    az deployment group create `
      --resource-group $resourceGroup `
      --name $deployment_name `
      --template-file ./infra/containerapp.bicep `
      --parameters `
        environmentName=$ENV_NAME `
        location=$location `
        tags=$tags `
        containerAppsEnvironmentId=$CONTAINER_APPS_ENVIRONMENT_ID `
        containerRegistryLoginServer=$REGISTRY_URL `
        containerRegistryName=$REGISTRY_USERNAME `
        containerRegistryPasswordSecretValue=$REGISTRY_PASSWORD `
        imageTag=$imageTag
    
    if ($LASTEXITCODE -ne 0) {
        throw "Container App deployment failed with exit code $LASTEXITCODE"
    }
} catch {
    Write-Host "Error: Failed to deploy Container App: $_" -ForegroundColor Red
    exit 1
}

# Get the Container App URL
try {
    $CONTAINER_APP_URL = (az containerapp show --name "ca-$ENV_NAME" --resource-group $resourceGroup --query "properties.configuration.ingress.fqdn" -o tsv)
    if ($LASTEXITCODE -ne 0 -or -not $CONTAINER_APP_URL) {
        throw "Failed to get Container App URL"
    }
    
    # Store values in local .env file
    $envFilePath = ".azure/.env"
    
    # Create or update .env file
    if (-not (Test-Path $envFilePath)) {
        New-Item -Path $envFilePath -ItemType File -Force | Out-Null
    }
    
    # Read existing content
    $envContent = @{}
    if (Test-Path $envFilePath) {
        Get-Content $envFilePath | ForEach-Object {
            if ($_ -match "^([^=]+)=(.*)$") {
                $envContent[$matches[1]] = $matches[2]
            }
        }
    }
    
    # Update values
    $envContent["CONTAINER_APP_URL"] = "https://$CONTAINER_APP_URL"
    $envContent["CONTAINER_IMAGE_TAG"] = $imageTag
    
    # Write back to file
    $envContent.GetEnumerator() | ForEach-Object {
        "$($_.Key)=$($_.Value)"
    } | Out-File -FilePath $envFilePath -Encoding utf8
    
    # Also try azd env set for completeness
    try {
        azd env set CONTAINER_APP_URL "https://$CONTAINER_APP_URL" 2>$null
        azd env set CONTAINER_IMAGE_TAG $imageTag 2>$null
    } catch {
        # Ignore errors here since we've already saved to .env file
    }
    
} catch {
    Write-Host "Warning: Failed to get Container App URL: $_" -ForegroundColor Yellow
    # Continue anyway since the app is deployed
}

Write-Host "`nDeployment completed successfully!" -ForegroundColor Green
Write-Host "You can access your application at: https://$CONTAINER_APP_URL" -ForegroundColor Green
Write-Host "Deployed image tag: $imageTag" -ForegroundColor Green 