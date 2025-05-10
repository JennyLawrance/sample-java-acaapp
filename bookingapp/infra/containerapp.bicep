param environmentName string
param location string
param tags object
param containerAppsEnvironmentId string
param containerRegistryLoginServer string
param containerRegistryName string
param containerRegistryPasswordSecretValue string
param imageTag string = 'latest'

// Container App resource
resource containerApp 'Microsoft.App/containerApps@2022-03-01' = {
  name: 'ca-${environmentName}'
  location: location
  tags: tags
  properties: {
    managedEnvironmentId: containerAppsEnvironmentId
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
          server: containerRegistryLoginServer
          username: containerRegistryName
          passwordSecretRef: 'registry-password'
        }
      ]
      secrets: [
        {
          name: 'registry-password'
          value: containerRegistryPasswordSecretValue
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'concert-booking-app'
          image: '${containerRegistryLoginServer}/concert-booking-app:${imageTag}'
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

output CONTAINER_APP_URL string = 'https://${containerApp.properties.configuration.ingress.fqdn}'
output CONTAINER_IMAGE_TAG string = imageTag 