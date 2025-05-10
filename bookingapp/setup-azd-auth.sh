#!/bin/bash

# Azure Developer CLI Authentication Setup Script
# This script helps ensure proper authentication before deployment

echo -e "\033[0;36mSetting up Azure authentication for deployment...\033[0m"

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
echo -e "\033[0;36mChecking if azd environment is initialized...\033[0m"
if [ -d ".azure" ]; then
    echo -e "\033[0;32mAzure Developer CLI environment is initialized.\033[0m"
    
    # Display environment info
    if [ -f ".azure/config" ]; then
        ENV_NAME=$(grep "name" .azure/config | awk '{print $3}')
        if [ -n "$ENV_NAME" ]; then
            echo -e "\033[0;36mCurrent environment: $ENV_NAME\033[0m"
        fi
    fi
else
    echo -e "\033[0;33mAzure Developer CLI environment is not initialized.\033[0m"
    echo -e "\033[0;36mInitializing environment...\033[0m"
    
    azd init
    if [ $? -ne 0 ]; then
        echo -e "\033[0;31mError: Failed to initialize Azure Developer CLI environment.\033[0m"
        exit 1
    fi
fi

echo -e "\n\033[0;32mAuthentication setup complete!\033[0m"
echo -e "\033[0;36mYou can now run 'azd provision' to provision resources and deploy the application.\033[0m"
echo -e "\033[0;36mOr run 'azd up' to provision, build and deploy in one command.\033[0m" 