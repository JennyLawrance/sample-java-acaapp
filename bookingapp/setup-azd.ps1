# This script sets up the Azure Developer CLI environment
param(
    [string]$location = "eastus", 
    [string]$environment = "concert-booking-app", 
    [switch]$skipLogin
)

Write-Host "Setting up Azure Developer CLI environment..." -ForegroundColor Cyan

# Create .azure directory if it doesn't exist
if (-not (Test-Path ".azure")) {
    New-Item -ItemType Directory -Path ".azure" | Out-Null
}

# Create config file with default location
$configContent = @"
[defaults]
location = $location

[environment]
name = $environment
"@
Set-Content -Path ".azure/config" -Value $configContent

# Login to Azure if not skipped
if (-not $skipLogin) {
    Write-Host "Logging in to Azure..." -ForegroundColor Yellow
    az login
}

# Initialize azd environment
Write-Host "Initializing azd environment..." -ForegroundColor Yellow
azd env new -n $environment --no-prompt

# Set default location
Write-Host "Setting default location to $location..." -ForegroundColor Yellow
azd env set AZURE_LOCATION $location

Write-Host "Environment setup complete!" -ForegroundColor Green
Write-Host "You can now run 'azd up' to deploy the application" -ForegroundColor Green 