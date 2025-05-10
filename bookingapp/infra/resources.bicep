param environmentName string
param location string
param tags object
param principalId string = ''

// Container Apps environment resource
resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2022-03-01' = {
  name: 'cae-${environmentName}'
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
  }
}

// Container Registry resource
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' = {
  name: replace('cr${environmentName}', '-', '')
  location: location
  tags: tags
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
}

// Log Analytics workspace for the Container Apps environment
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: 'law-${environmentName}'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: 1
    }
  }
}

// Output the necessary values for the container app deployment
output CONTAINER_REGISTRY_URL string = containerRegistry.properties.loginServer
output CONTAINER_REGISTRY_USERNAME string = containerRegistry.name
output CONTAINER_REGISTRY_PASSWORD string = containerRegistry.listCredentials().passwords[0].value
output CONTAINER_APPS_ENVIRONMENT_ID string = containerAppsEnvironment.id
output CONTAINER_APP_URL string = 'placeholder-will-be-replaced' 