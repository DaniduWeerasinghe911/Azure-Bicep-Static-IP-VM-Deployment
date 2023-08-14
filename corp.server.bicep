// Contains the services and workloads components relevant for the Identity Management Subscription / Components
// Dependency on the Network components
// Resources included:
//  - Resource Group

targetScope = 'subscription'

@description('Location of resources.')
param location string = 'australiaeast'
     

@description('Domain Controller Naming Prefix')
param vmPrefix string = 'tempvmtest'

@description('Workload Rg Name')
param rgName string = 'work-rg'

@description('Hub Virtual Network Name')
param vnetName string = 'dckloud'

@description('Shared Platform (Network) Services Resources Group Name')
param networkRgName string = 'hub-rg'

@description('Name of subnet for Application Server')
param subnetName string = 'app'

@description('Private IP address')
param privateIpAddress string = ''

@description('Virtual Machine Size')
param vmSize string = 'Standard_E2ds_v4'

var deploymentName = 'deploy_${vmPrefix}'
var vnetId = resourceId(subscription().subscriptionId, networkRgName, 'Microsoft.Network/virtualNetworks', vnetName)

// Resource Group for Services
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgName
  location:location
  tags:{}
}

module server 'modules/virtual-machine/virtual-machine-windows-individual.bicep' = {
  scope: rg
  name: deploymentName
  params: {
    tags:{}
    location: location
    operatingSystem: '2016-Datacenter'
    adminPassword: 'Pass@123456789'
    adminUsername: 'admin.dancha'
    timeZone:'AUS Eastern Standard Time'
    dataDisksDefinition: []
    enableHybridBenefit: true
    osDiskType: 'Premium_LRS'
    subnetId: '${vnetId}/subnets/${subnetName}'
    privateIpAddress:privateIpAddress
    virtualMachineNameSuffix: vmPrefix
    virtualMachineSize: vmSize
  }
}

