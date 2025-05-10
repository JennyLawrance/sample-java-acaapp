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

// Container App resource
resource containerApp 'Microsoft.App/containerApps@2022-03-01' = {
  name: 'ca-${environmentName}'
  location: location
  tags: tags
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    configuration: {
      ingress: {
        external: true
        targetPort: 8080
        allowInsecure: false
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
      }
      registries: [
        {
          server: containerRegistry.properties.loginServer
          username: containerRegistry.name
          passwordSecretRef: 'registry-password'
        }
      ]
      secrets: [
        {
          name: 'registry-password'
          value: containerRegistry.listCredentials().passwords[0].value
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'concert-booking-app'
          image: '${containerRegistry.properties.loginServer}/concert-booking-app:latest'
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 3
      }
    }
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

output CONTAINER_APP_URL string = 'https://${containerApp.properties.configuration.ingress.fqdn}'
output CONTAINER_REGISTRY_URL string = containerRegistry.properties.loginServer
output CONTAINER_REGISTRY_USERNAME string = containerRegistry.name
output CONTAINER_REGISTRY_PASSWORD string = containerRegistry.listCredentials().passwords[0].value 