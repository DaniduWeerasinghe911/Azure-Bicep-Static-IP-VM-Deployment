@description('Virtual machine name. Do not include numerical identifier.')
@maxLength(14)
param virtualMachineNameSuffix string

@description('Virtual machine location.')
param location string = resourceGroup().location

@description('Virtual machine size, e.g. Standard_D2_v3, Standard_DS3, etc.')
param virtualMachineSize string

@description('Operating system disk type. E.g. If your VM is a standard size you must use a standard disk type.')
@allowed([
  'Standard_LRS'
  'StandardSSD_LRS'
  'Premium_LRS'
  'UltraSSD_LRS'
])
param osDiskType string

@description('Array of objects defining data disks, including diskType and size')
@metadata({
  note: 'Sample input'
  dataDisksDefinition: [
    {
      diskType: 'StandardSSD_LRS'
      diskSize: 64
      caching: 'none'
    } 
  ]
})
param dataDisksDefinition array

@description('Virtual machine Windows operating system.')
@allowed([
  '2016-Nano-Server'
  '2016-Datacenter-with-Containers'
  '2016-Datacenter'
  '2022-Datacenter'
  '2019-Datacenter'
  '2019-Datacenter-Core'
  '2019-Datacenter-Core-smalldisk'
  '2019-Datacenter-Core-with-Containers'
  '2019-Datacenter-Core-with-Containers-smalldisk'
  '2019-Datacenter-smalldisk'
  '2019-Datacenter-with-Containers'
  '2019-Datacenter-with-Containers-smalldisk'
])
param operatingSystem string = '2022-Datacenter'

@description('Enable if want to use Hybrid Benefit Licensing.')
param enableHybridBenefit bool

@description('Virtual machine local administrator username.')
param adminUsername string

@description('Local administrator password.')
@secure()
param adminPassword string

@description('Resource Id of Subnet to place VM into.')
param subnetId string

@description('Time Zone setting for Virtual Machine')
param timeZone string = 'AUS Eastern Standard Time'

@description('Private IP address')
param privateIpAddress string = ''
 
@description('Object containing resource tags.')
param tags object = {}


// resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' =  {
//   name: '${virtualMachineNameSuffix}-nic01'
//   location: location
//   tags: !empty(tags) ? tags : json('null')
//   properties: {
//     ipConfigurations: [
//       {
//         name: 'ipconfig1'
//         properties: {
//           subnet: {
//             id: subnetId
//           }
//           privateIPAllocationMethod: (privateIpAddress !='') ? 'Static':'Dynamic'
//           privateIPAddress:(privateIpAddress!='')?privateIpAddress:null
//         }
//       }
//     ]
//   }
// }

// var ipAddress = nic.properties.ipConfigurations[0].properties.privateIPAddress

// resource staticNic 'Microsoft.Network/networkInterfaces@2021-02-01' =  {
//   name: '${virtualMachineNameSuffix}-nic01'
//   location: location
//   tags: !empty(tags) ? tags : json('null')
//   properties: {
//     ipConfigurations: [
//       {
//         name: 'ipconfig1'
//         properties: {
//           subnet: {
//             id: subnetId
//           }
//           privateIPAllocationMethod: 'Static'
//           privateIPAddress:ipAddress
//         }
//       }
//     ]
//   }
// }

module nic 'virtual-machine-nic.bicep' = {
  name: '${virtualMachineNameSuffix}-nic01-deployment'
  params: {
    location: location
    subnetId: subnetId
    virtualMachineNameSuffix: virtualMachineNameSuffix
    privateIPAllocationMethod:'Dynamic'
  }
}

module nicStaticIp 'virtual-machine-nic.bicep' = {
  name: '${virtualMachineNameSuffix}-nic01-deployment-static'
  params: {
    location: location
    subnetId: subnetId
    virtualMachineNameSuffix: virtualMachineNameSuffix
    privateIPAllocationMethod:'Static'
    privateIpAddress:nic.outputs.ipAddress
  }
}




resource vm 'Microsoft.Compute/virtualMachines@2021-04-01' = {
  name: virtualMachineNameSuffix
  location: location
  tags: !empty(tags) ? tags : json('null')
  properties: {
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${virtualMachineNameSuffix}-nic01')
        }
      ]
    }
    osProfile: {
      computerName: virtualMachineNameSuffix
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
        timeZone: timeZone
      }
    }
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: operatingSystem
        version: 'latest'
      }
      osDisk: {
        name: '${virtualMachineNameSuffix}_osdisk'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      dataDisks: [for (item, j) in dataDisksDefinition: {
        name: '${virtualMachineNameSuffix}_datadisk_${j}'
        diskSizeGB: item.diskSize
        lun: j
        caching: item.caching
        createOption: 'Empty'
        managedDisk: {
          storageAccountType: item.diskType
        }
      }]
    }
    // diagnosticsProfile: {
    //   bootDiagnostics: {
    //     enabled: true
    //     storageUri:storageId
    //   }
    // }
    licenseType: (enableHybridBenefit ? 'Windows_Server' : json('null'))
  }
  dependsOn: [
    nic
  ]
}



resource extension_depAgent 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = {
  parent: vm
  name: 'DependencyAgentWindows'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitoring.DependencyAgent'
    type: 'DependencyAgentWindows'
    typeHandlerVersion: '9.5'
    autoUpgradeMinorVersion: true
  }
  dependsOn: [
  ]
}

// resource extension_guesthealth 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' =  {
//   parent: vm
//   name: 'GuestHealthWindowsAgent'
//   location: location
//   properties: {
//     publisher: 'Microsoft.Azure.Monitor.VirtualMachines.GuestHealth'
//     type: 'GuestHealthWindowsAgent'
//     typeHandlerVersion: '1.0'
//     autoUpgradeMinorVersion: true
//   }
//   dependsOn: [
//     extension_depAgent
//     extension_monitoring
//     extension_domainJoin
//   ]
// }

output vmName string = vm.name
