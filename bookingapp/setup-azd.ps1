# This script sets up the Azure Developer CLI environment
param (
    [string]$location = "eastus",
    [switch]$skipProvision = $false
)

Write-Host "Setting up Azure Developer CLI environment for concert-booking-app..." -ForegroundColor Cyan

# Check if azd is installed
try {
    $azdVersion = azd version
    Write-Host "Azure Developer CLI version: $azdVersion" -ForegroundColor Green
} catch {
    Write-Host "Error: Azure Developer CLI (azd) is not installed or not in PATH." -ForegroundColor Red
    Write-Host "Please install Azure Developer CLI: https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd" -ForegroundColor Yellow
    exit 1
}

# Check if already authenticated
Write-Host "Checking Azure authentication status..." -ForegroundColor Cyan
$authStatus = azd auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "You are not authenticated with Azure. Let's log you in..." -ForegroundColor Yellow
    
    # Perform interactive login
    azd auth login
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to authenticate with Azure." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "You are already authenticated with Azure." -ForegroundColor Green
}

# Check if environment is initialized
$envInitialized = $false
if (Test-Path ".azure") {
    $envInitialized = $true
    Write-Host "Azure Developer CLI environment is already initialized." -ForegroundColor Green
    
    # Display environment info
    $envName = (Get-Content -Path ".azure/config" | Where-Object { $_ -match "name\s+=\s+(.*)" } | ForEach-Object { $matches[1] })
    if ($envName) {
        Write-Host "Current environment: $envName" -ForegroundColor Cyan
    }
} else {
    Write-Host "Initializing Azure Developer CLI environment..." -ForegroundColor Cyan
    
    # Initialize azd environment
    azd init --template . --no-prompt
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to initialize Azure Developer CLI environment." -ForegroundColor Red
        exit 1
    }
    
    # Set environment name to concert-booking-app if not already set
    $envName = (Get-Content -Path ".azure/config" | Where-Object { $_ -match "name\s+=\s+(.*)" } | ForEach-Object { $matches[1] })
    if (-not $envName -or $envName -ne "concert-booking-app") {
        azd env new concert-booking-app --no-prompt
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Error: Failed to create environment." -ForegroundColor Red
            exit 1
        }
    }
}

# Set location for resources
Write-Host "Setting Azure location to $location..." -ForegroundColor Cyan
azd env set AZURE_LOCATION $location
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to set Azure location." -ForegroundColor Red
    exit 1
}

# Provision infrastructure if not skipped
if (-not $skipProvision) {
    Write-Host "Provisioning Azure resources..." -ForegroundColor Cyan
    Write-Host "This may take several minutes..." -ForegroundColor Yellow
    
    azd provision
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to provision Azure resources." -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Azure resources provisioned successfully." -ForegroundColor Green
}

Write-Host "`nSetup complete!" -ForegroundColor Green
Write-Host "You can now run 'azd up' to build and deploy the application." -ForegroundColor Cyan
if ($skipProvision) {
    Write-Host "Or run 'azd provision' to provision Azure resources." -ForegroundColor Cyan
} 