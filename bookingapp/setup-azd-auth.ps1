# Azure Developer CLI Authentication Setup Script
# This script helps ensure proper authentication before deployment

Write-Host "Setting up Azure authentication for deployment..." -ForegroundColor Cyan

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
Write-Host "Checking if azd environment is initialized..." -ForegroundColor Cyan
if (Test-Path ".azure") {
    Write-Host "Azure Developer CLI environment is initialized." -ForegroundColor Green
    
    # Display environment info
    $envName = (Get-Content -Path ".azure/config" | Where-Object { $_ -match "name\s+=\s+(.*)" } | ForEach-Object { $matches[1] })
    if ($envName) {
        Write-Host "Current environment: $envName" -ForegroundColor Cyan
    }
} else {
    Write-Host "Azure Developer CLI environment is not initialized." -ForegroundColor Yellow
    Write-Host "Initializing environment..." -ForegroundColor Cyan
    
    azd init
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to initialize Azure Developer CLI environment." -ForegroundColor Red
        exit 1
    }
}

Write-Host "`nAuthentication setup complete!" -ForegroundColor Green
Write-Host "You can now run 'azd provision' to provision resources and deploy the application." -ForegroundColor Cyan
Write-Host "Or run 'azd up' to provision, build and deploy in one command." -ForegroundColor Cyan 