#!/bin/bash

# Default location
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

echo -e "\033[0;36mSetting up Azure Developer CLI environment for concert-booking-app...\033[0m"

# Check if azd is installed
if ! command -v azd &> /dev/null; then
    echo -e "\033[0;31mError: Azure Developer CLI (azd) is not installed or not in PATH.\033[0m"
    echo -e "\033[0;33mPlease install Azure Developer CLI: https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd\033[0m"
    exit 1
fi

AZD_VERSION=$(azd version)
echo -e "\033[0;32mAzure Developer CLI version: $AZD_VERSION\033[0m"

# Check if already authenticated
echo -e "\033[0;36mChecking Azure authentication status...\033[0m"
azd auth status &> /dev/null
if [ $? -ne 0 ]; then
    echo -e "\033[0;33mYou are not authenticated with Azure. Let's log you in...\033[0m"
    
    # Perform interactive login
    azd auth login
    if [ $? -ne 0 ]; then
        echo -e "\033[0;31mError: Failed to authenticate with Azure.\033[0m"
        exit 1
    fi
else
    echo -e "\033[0;32mYou are already authenticated with Azure.\033[0m"
fi

# Check if environment is initialized
env_initialized=false
if [ -d ".azure" ]; then
    env_initialized=true
    echo -e "\033[0;32mAzure Developer CLI environment is already initialized.\033[0m"
    
    # Display environment info
    if [ -f ".azure/config" ]; then
        ENV_NAME=$(grep "name" .azure/config | awk '{print $3}')
        if [ -n "$ENV_NAME" ]; then
            echo -e "\033[0;36mCurrent environment: $ENV_NAME\033[0m"
        fi
    fi
else
    echo -e "\033[0;36mInitializing Azure Developer CLI environment...\033[0m"
    
    # Initialize azd environment
    azd init --template . --no-prompt
    if [ $? -ne 0 ]; then
        echo -e "\033[0;31mError: Failed to initialize Azure Developer CLI environment.\033[0m"
        exit 1
    fi
    
    # Set environment name to concert-booking-app if not already set
    if [ -f ".azure/config" ]; then
        ENV_NAME=$(grep "name" .azure/config | awk '{print $3}')
        if [ -z "$ENV_NAME" ] || [ "$ENV_NAME" != "concert-booking-app" ]; then
            azd env new concert-booking-app --no-prompt
            if [ $? -ne 0 ]; then
                echo -e "\033[0;31mError: Failed to create environment.\033[0m"
                exit 1
            fi
        fi
    fi
fi

# Set location for resources
echo -e "\033[0;36mSetting Azure location to $location...\033[0m"
azd env set AZURE_LOCATION $location
if [ $? -ne 0 ]; then
    echo -e "\033[0;31mError: Failed to set Azure location.\033[0m"
    exit 1
fi

# Provision infrastructure if not skipped
if [ "$skip_provision" = false ]; then
    echo -e "\033[0;36mProvisioning Azure resources...\033[0m"
    echo -e "\033[0;33mThis may take several minutes...\033[0m"
    
    azd provision
    if [ $? -ne 0 ]; then
        echo -e "\033[0;31mError: Failed to provision Azure resources.\033[0m"
        exit 1
    fi
    
    echo -e "\033[0;32mAzure resources provisioned successfully.\033[0m"
fi

echo -e "\n\033[0;32mSetup complete!\033[0m"
echo -e "\033[0;36mYou can now run 'azd up' to build and deploy the application.\033[0m"
if [ "$skip_provision" = true ]; then
    echo -e "\033[0;36mOr run 'azd provision' to provision Azure resources.\033[0m"
fi 