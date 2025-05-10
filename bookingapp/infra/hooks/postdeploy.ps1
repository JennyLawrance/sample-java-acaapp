# This script runs after deployment to verify the application is running

Write-Host "Deployment completed! Verifying the application..." -ForegroundColor Cyan

# Get the Container App URL
$env_values = azd env get-values
$CONTAINER_APP_URL = ($env_values | Select-String "CONTAINER_APP_URL").ToString().Split(' ')[1]

Write-Host "Application URL: $CONTAINER_APP_URL" -ForegroundColor Yellow
Write-Host "Checking if the application is responding..." -ForegroundColor Cyan

# Wait a bit for the app to start
Start-Sleep -Seconds 10

# Check if the app is responding
try {
    $response = Invoke-WebRequest -Uri $CONTAINER_APP_URL -UseBasicParsing
    $status_code = $response.StatusCode
    
    if ($status_code -eq 200) {
        Write-Host "Application is running successfully! Status code: $status_code" -ForegroundColor Green
    } else {
        Write-Host "Application check received non-200 status. Status code: $status_code" -ForegroundColor Yellow
        Write-Host "Please check the logs for more information." -ForegroundColor Yellow
    }
} catch {
    Write-Host "Application check failed. Error: $_" -ForegroundColor Red
    Write-Host "Please check the logs for more information." -ForegroundColor Yellow
}

Write-Host "You can now access your application at: $CONTAINER_APP_URL" -ForegroundColor Green 