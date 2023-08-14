@description('Virtual machine name. Do not include numerical identifier.')
@maxLength(14)
param virtualMachineNameSuffix string

@description('Virtual machine location.')
param location string = resourceGroup().location

@description('Resource Id of Subnet to place VM into.')
param subnetId string

@description('Private IP address')
param privateIpAddress string = ''

param privateIPAllocationMethod string = 'dynamic'

@description('Object containing resource tags.')
param tags object = {}



resource staticNic 'Microsoft.Network/networkInterfaces@2021-02-01' =  {
  name: '${virtualMachineNameSuffix}-nic01'
  location: location
  tags: !empty(tags) ? tags : json('null')
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: privateIPAllocationMethod
          privateIPAddress:(privateIPAllocationMethod =='Dynamic') ? null: privateIpAddress
        }
      }
    ]
  }
}

output nicId string = staticNic.id
output nicName string = staticNic.name
output ipAddress string = staticNic.properties.ipConfigurations[0].properties.privateIPAddress
