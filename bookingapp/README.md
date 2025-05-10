# Concert Booking Application

A simple Java 8 Spring Boot application for booking concert tickets.

## Features

- View available concerts
- Book tickets for concerts
- View bookings by concert
- View bookings by customer
- Seat availability checking
- Basic error handling

## Requirements

- Java 8 or higher
- Maven
- Docker (optional)

## How to Build and Run

### Using Maven

1. Clone the repository
2. Navigate to the project directory
3. Build the project using Maven:
   ```
   mvn clean package
   ```
4. Run the application:
   ```
   java -cp target/concert-booking-app-1.0-SNAPSHOT.jar com.concertbooking.Main
   ```

### Using Docker

1. Build the Docker image:
   ```
   docker build -t concert-booking-app .
   ```
2. Run the container:
   ```
   docker run -p 8080:8080 concert-booking-app
   ```

## Deploying to Azure

This application can be deployed to Azure Container Apps using the Azure Developer CLI (azd).

### Prerequisites

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Azure Developer CLI](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd)
- [Docker](https://www.docker.com/products/docker-desktop)
- [PowerShell 7+](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows) (for Windows)

### Deployment Steps

#### Method 1: Using the Setup Script (Recommended)

1. Run the setup script to configure your environment (this will avoid multiple location prompts):

   ```powershell
   # For Windows
   .\setup-azd.ps1 -location eastus
   ```

2. Deploy with a single command:
   ```
   azd up
   ```

#### Method 2: Manual Setup

1. Login to Azure:
   ```
   az login
   ```

2. Initialize your environment:
   ```
   azd init
   ```

3. Create a new environment and set the location:
   ```
   azd env new concert-booking-app
   azd env set AZURE_LOCATION eastus
   ```

4. Provision and deploy the application:
   ```
   azd up
   ```

Both methods will:
- Provision the Azure Container App and other resources
- Build and push the Docker image to Azure Container Registry
- Deploy the application to Azure Container Apps

### Windows-Specific Instructions

If you're deploying from Windows, ensure you have:
- PowerShell 7 or later installed
- Docker Desktop running
- WSL2 enabled (recommended for Docker performance)

The deployment hooks will use PowerShell scripts on Windows systems and Bash scripts on Linux/macOS.

### Managing Your Deployment

- To view environment details:
  ```
  azd env get-values
  ```

- To update your deployment after changes:
  ```
  azd deploy
  ```

- To delete the deployment:
  ```
  azd down
  ```

### Troubleshooting

If deployment fails with image not found errors:
1. Ensure Docker is running
2. Check that you have permissions to push to Azure Container Registry
3. Try running the postprovision script manually:
   - Windows: `pwsh ./infra/hooks/postprovision.ps1`
   - Linux/macOS: `bash ./infra/hooks/postprovision.sh`

If you're getting prompted for location multiple times:
1. Use the setup script as described above
2. Manually set the location in your environment:
   ```
   azd env set AZURE_LOCATION eastus
   ```

## Sample Data

The application comes with two sample concerts:
- Summer Festival by The Rock Band
- Jazz Night by The Jazz Quartet

## Error Handling

The application handles common errors such as:
- Invalid concert ID
- Insufficient seats available
- Invalid input data 