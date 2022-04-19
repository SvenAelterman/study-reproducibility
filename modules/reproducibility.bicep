param namingStructure string
param location string

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: replace(namingStructure, '{rtype}', 'log')
  location: location
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-12-01-preview' = {
  name: replace(replace(namingStructure, '{rtype}', 'cr'), '-', '')
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    adminUserEnabled: true
    networkRuleBypassOptions: 'AzureServices'
    anonymousPullEnabled: false
  }
}

resource auditContainerRegistry 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: containerRegistry
  name: 'audit-${containerRegistry.name}'
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        categoryGroup: 'audit'
        enabled: true
      }
    ]
  }
}

var subnets = [
  {
    name: 'default'
    addressPrefix: '10.21.0.0/26'
  }
  {
    name: 'aci'
    addressPrefix: '10.21.0.128/26'
  }
  {
    name: 'avd'
    addressPrefix: '10.21.0.64/26'
  }
]

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: replace(namingStructure, '{rtype}', 'vnet')
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.21.0.0/24'
      ]
    }
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
        serviceEndpoints: [
          {
            service: 'Microsoft.Storage'
            locations: [
              location
            ]
          }
        ]
        privateEndpointNetworkPolicies: 'Enabled'
        privateLinkServiceNetworkPolicies: 'Enabled'
      }
    }]
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: replace(replace(namingStructure, '{rtype}', 'st'), '-', '')
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    defaultToOAuthAuthentication: false
    minimumTlsVersion: 'TLS1_2'
    isHnsEnabled: true
    supportsHttpsTrafficOnly: true
    networkAcls: {
      defaultAction: 'Deny'
      virtualNetworkRules: [for subnet in subnets: {
        id: '${virtualNetwork.id}/subnets/${subnet.name}'
        action: 'Allow'
      }]
    }
  }
}

resource fileServices 'Microsoft.Storage/storageAccounts/fileServices@2021-08-01' = {
  name: '${storageAccount.name}/default'
  properties: {
    shareDeleteRetentionPolicy: {
      days: 31
      enabled: true
    }
  }
}

resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-08-01' = {
  name: '${fileServices.name}/study-repro'
  properties: {
    accessTier: 'Hot'
    enabledProtocols: 'SMB'
  }
}

module avd 'avd.bicep' = {
  name: 'avd'
  params: {
    location: location
    avdSubnetId: '${virtualNetwork.id}/subnets/${subnets[2].name}'
    namingStructure: namingStructure
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.id
  }
}

output storageAccountKey string = storageAccount.listKeys().keys[0].value
output containerRegistryUrl string = containerRegistry.properties.loginServer
output containerRegistryKey string = containerRegistry.listCredentials().passwords[0].value
output containerRegistryUser string = containerRegistry.listCredentials().username
