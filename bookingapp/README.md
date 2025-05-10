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

This application can be deployed to Azure Container Apps using either the Azure Developer CLI (azd) or the direct deployment scripts.

### Prerequisites

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Azure Developer CLI](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd) (for azd deployment methods)
- [Docker](https://www.docker.com/products/docker-desktop)
- [PowerShell 7+](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows) (for Windows)
- [jq](https://stedolan.github.io/jq/download/) (for Linux/macOS direct deployment)

### Deployment Methods

#### Method 1: Direct Deployment (Recommended)

This method bypasses the azd hooks and directly handles the deployment process, avoiding issues with azd environment variables.

```powershell
# For Windows
.\deploy-direct.ps1
```

```bash
# For Linux/macOS
./deploy-direct.sh
```

Options:
- `--location <location>` - Azure region to deploy to (default: eastus)
- `--skip-provision` - Skip infrastructure provisioning (use when resources already exist)

#### Method 2: Using the Authentication Setup Script

1. Run the authentication setup script to ensure you're properly logged in:

   ```powershell
   # For Windows
   .\setup-azd-auth.ps1
   ```

   ```bash
   # For Linux/macOS
   ./setup-azd-auth.sh
   ```

2. Deploy with a single command:
   ```
   azd up
   ```

#### Method 3: Using the Setup Script

1. Run the setup script to configure your environment:

   ```powershell
   # For Windows
   .\setup-azd.ps1 -location eastus
   ```

   ```bash
   # For Linux/macOS
   ./setup-azd.sh --location eastus
   ```

2. Deploy with a single command:
   ```
   azd up
   ```

#### Method 4: Manual Setup

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

### Troubleshooting

#### Common Issues

1. **azd env get-values not working within scripts**:
   - Use the direct deployment scripts (`deploy-direct.ps1` or `deploy-direct.sh`) which avoid this issue by using Azure CLI directly.

2. **Authentication errors**:
   - Run the authentication setup script:
     - Windows: `.\setup-azd-auth.ps1`
     - Linux/macOS: `./setup-azd-auth.sh`
   - Or login directly with: `az login`

3. **Image not found errors**:
   - Ensure Docker is running
   - Check that you have permissions to push to Azure Container Registry
   - Try using the direct deployment scripts which handle the entire process

4. **Multiple location prompts**:
   - Use the setup script as described above
   - Manually set the location in your environment:
     ```
     azd env set AZURE_LOCATION eastus
     ```

### Image Versioning

Each deployment creates a uniquely tagged container image in the format `v1-YYYYMMDDHHMMSS`. This ensures:

- Each deployment uses a distinct image version
- No caching issues occur with the same tag
- You can easily roll back to previous versions if needed

The current image tag is stored in the Azure Developer CLI environment as `CONTAINER_IMAGE_TAG`.

## Sample Data

The application comes with sample concerts:
- Summer Festival by The Rock Band
- Jazz Night by The Jazz Quartet
- Pop Extravaganza by Star Pop Group
- Classical Evening by Symphony Orchestra
- Acoustic Unplugged by Indie Artists Collective (sold out)

## Error Handling

The application handles common errors such as:
- Invalid concert ID
- Insufficient seats available
- Invalid input data
- Sold out events 