#!/bin/bash

# This script runs after deployment to verify the application is running

echo "Deployment completed! Verifying the application..."

# Get the Container App URL
CONTAINER_APP_URL=$(azd env get-values | grep CONTAINER_APP_URL | awk '{print $2}')

echo "Application URL: $CONTAINER_APP_URL"
echo "Checking if the application is responding..."

# Wait a bit for the app to start
sleep 10

# Check if the app is responding
status_code=$(curl -s -o /dev/null -w "%{http_code}" $CONTAINER_APP_URL || echo "Failed")

if [ "$status_code" == "200" ]; then
  echo "Application is running successfully! Status code: $status_code"
else
  echo "Application check failed. Status code: $status_code"
  echo "Please check the logs for more information."
fi

echo "You can now access your application at: $CONTAINER_APP_URL" 