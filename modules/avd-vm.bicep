param namingStructure string
param hostPoolRegistrationToken string
param location string
param deploymentNameStructure string
param avdVmHostNameStructure string
param hostPoolName string
param avdSubnetId string

param vmCount int = 1

// Use the same VM templates as used by the Add VM to hostpool process
var nestedTemplatesLocation = 'https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/armtemplates/Hostpool_12-9-2021/nestedTemplates/'
var vmTemplateUri = '${nestedTemplatesLocation}managedDisks-galleryvm.json'

var rdshPrefix = '${avdVmHostNameStructure}-'

resource availabilitySet 'Microsoft.Compute/availabilitySets@2021-11-01' = {
  name: replace(namingStructure, '{rtype}', 'avail')
  location: location
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 5
  }
  sku: {
    name: 'Aligned'
  }
}

// Deploy the session host VMs just like the Add VM to hostpool process would
resource vmDeployment 'Microsoft.Resources/deployments@2021-04-01' = {
  name: replace(deploymentNameStructure, '{rtype}', 'avdvm')
  properties: {
    mode: 'Incremental'
    templateLink: {
      uri: vmTemplateUri
      contentVersion: '1.0.0.0'
    }
    parameters: {
      artifactsLocation: {
        value: 'https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_02-23-2022.zip'
      }
      availabilityOption: {
        value: 'AvailabilitySet'
      }
      availabilitySetName: {
        value: availabilitySet.name
      }
      vmGalleryImageOffer: {
        value: 'office-365'
      }
      vmGalleryImagePublisher: {
        value: 'microsoftwindowsdesktop'
      }
      vmGalleryImageHasPlan: {
        value: false
      }
      vmGalleryImageSKU: {
        value: 'win11-21h2-avd-m365'
      }
      rdshPrefix: {
        value: rdshPrefix
      }
      rdshNumberOfInstances: {
        value: vmCount
      }
      rdshVMDiskType: {
        value: 'StandardSSD_LRS'
      }
      rdshVmSize: {
        value: 'Standard_D2s_v3'
      }
      enableAcceleratedNetworking: {
        value: true
      }
      vmAdministratorAccountUsername: {
        value: 'AzureUser'
      }
      vmAdministratorAccountPassword: {
        value: 'Test1234'
      }
      administratorAccountUsername: {
        value: ''
      }
      administratorAccountPassword: {
        value: ''
      }
      'subnet-id': {
        value: avdSubnetId
      }
      vhds: {
        value: 'vhds/${rdshPrefix}'
      }
      location: {
        value: location
      }
      createNetworkSecurityGroup: {
        value: false
      }
      vmInitialNumber: {
        value: 0
      }
      hostpoolName: {
        value: hostPoolName
      }
      hostpoolToken: {
        value: hostPoolRegistrationToken
      }
      aadJoin: {
        value: true
      }
      intune: {
        value: true
      }
      securityType: {
        value: 'TrustedLaunch'
      }
      secureBoot: {
        value: true
      }
      vTPM: {
        value: true
      }
      vmImageVhdUri: {
        value: ''
      }
    }
  }
}

resource shutdownSchedule 'Microsoft.DevTestLab/schedules@2018-09-15' = [for i in range(0, vmCount): {
  name: 'shutdown-computevm-${avdVmHostNameStructure}-${i}'
  location: location
  dependsOn: [
    vmDeployment
  ]
  properties: {
    targetResourceId: resourceId('Microsoft.Compute/virtualMachines', '${avdVmHostNameStructure}-${i}')
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: {
      time: '0000'
    }
    timeZoneId: 'Eastern Standard Time'
    notificationSettings: {
      status: 'Disabled'
    }
    status: 'Enabled'
  }
}]
