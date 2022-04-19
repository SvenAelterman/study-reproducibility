param namingStructure string
param location string
param avdSubnetId string
param logAnalyticsWorkspaceId string

param environment string = ''
param deploymentNameStructure string = '{rtype}-${utcNow()}'
param baseTime string = utcNow('u')

var avdNamingStructure = replace(namingStructure, '{subwloadname}', 'avd')

resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2021-09-03-preview' = {
  name: replace(avdNamingStructure, '{rtype}', 'hp')
  location: location
  properties: {
    hostPoolType: 'Pooled'
    loadBalancerType: 'BreadthFirst'
    preferredAppGroupType: 'Desktop'
    customRdpProperty: 'drivestoredirect:s:0;audiomode:i:0;videoplaybackmode:i:1;redirectclipboard:i:0;redirectprinters:i:0;devicestoredirect:s:0;redirectcomports:i:0;redirectsmartcards:i:1;usbdevicestoredirect:s:0;enablecredsspsupport:i:1;use multimon:i:1;targetisaadjoined:i:1;'
    friendlyName: '${environment} Research Enclave Access'
    startVMOnConnect: true
    registrationInfo: {
      registrationTokenOperation: 'Update'
      // Expire the new reigstration token in two days
      expirationTime: dateTimeAdd(baseTime, 'P2D')
    }
  }
}

resource applicationGroup 'Microsoft.DesktopVirtualization/applicationGroups@2021-09-03-preview' = {
  name: replace(avdNamingStructure, '{rtype}', 'dag')
  location: location
  properties: {
    hostPoolArmPath: hostPool.id
    applicationGroupType: 'Desktop'
    friendlyName: 'Research Assistant Desktop'
  }
}

resource workspace 'Microsoft.DesktopVirtualization/workspaces@2021-09-03-preview' = {
  name: replace(avdNamingStructure, '{rtype}', 'ws')
  location: location
  properties: {
    friendlyName: 'Reproducibility'
    applicationGroupReferences: [
      applicationGroup.id
    ]
  }
}

module avdVm 'avd-vm.bicep' = {
  name: replace(deploymentNameStructure, '{rtype}', 'avdvm-vms')
  params: {
    namingStructure: namingStructure
    hostPoolRegistrationToken: hostPool.properties.registrationInfo.token
    location: location
    deploymentNameStructure: deploymentNameStructure
    vmCount: 1
    avdVmHostNameStructure: 'vm-avd'
    hostPoolName: hostPool.name
    avdSubnetId: avdSubnetId
  }
}
