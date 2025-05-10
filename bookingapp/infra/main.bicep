targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of the resource names')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
@allowed([
  'eastus'
  'eastus2'
  'westus'
  'westus2'
  'westus3'
  'centralus'
  'southcentralus'
  'northcentralus'
  'westeurope'
  'northeurope'
  'eastasia'
  'southeastasia'
  'japaneast'
  'japanwest'
  'australiaeast'
  'australiasoutheast'
  'brazilsouth'
  'southindia'
  'centralindia'
  'uksouth'
  'ukwest'
  'canadacentral'
  'canadaeast'
  'koreacentral'
  'francecentral'
])
param location string

@description('Id of the user or app to assign application roles')
param principalId string = ''

var tags = { 'azd-env-name': environmentName }
var abbrs = loadJsonContent('./abbreviations.json')

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

module resources 'resources.bicep' = {
  name: 'resources'
  scope: resourceGroup
  params: {
    environmentName: environmentName
    location: location
    tags: tags
    principalId: principalId
  }
}

output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output CONTAINER_APP_URL string = resources.outputs.CONTAINER_APP_URL 