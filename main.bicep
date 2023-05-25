targetScope = 'subscription'

@allowed([
  'eastus2'
  'eastus'
])
param location string
@allowed([
  'test'
  'demo'
  'prod'
])
param environment string
param workloadName string

// Optional parameters
param tags object = {}
param sequence int = 1
param namingConvention string = '{rtype}-{wloadname}-{env}-{loc}-{seq}'
param deploymentTime string = utcNow()

// Variables
var sequenceFormatted = format('{0:00}', sequence)

// Naming structure only needs the resource type ({rtype}) replaced
var namingStructure = replace(replace(replace(replace(namingConvention, '{env}', environment), '{loc}', location), '{seq}', sequenceFormatted), '{wloadname}', workloadName)

resource workloadResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: replace(namingStructure, '{rtype}', 'rg')
  location: location
  tags: tags
}

module reproducibilityModule 'modules/reproducibility.bicep' = {
  name: 'reproducibility-${deploymentTime}'
  scope: workloadResourceGroup
  params: {
    location: location
    namingStructure: namingStructure
  }
}

output storageAccountKey string = reproducibilityModule.outputs.storageAccountKey
output containerRegistryUrl string = reproducibilityModule.outputs.containerRegistryUrl
output containerRegistryKey string = reproducibilityModule.outputs.containerRegistryKey
output containerRegistryUser string = reproducibilityModule.outputs.containerRegistryUser

output resourceGroupName string = workloadResourceGroup.name

// TODO: Use Log Analytics Workspace for AVD logging
// TODO: RBAC assignments for AVD
