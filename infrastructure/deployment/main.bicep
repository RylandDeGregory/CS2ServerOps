@sys.description('The name of the Azure Bastion Host. Default: bas-cs2gs-$<locationShortName>-$<uniqueSuffix>')
@sys.minLength(1)
@sys.maxLength(80)
param bastionHostName string = 'bas-cs2gs-${locationShortName}-${uniqueSuffix}'

@sys.description('The name of the Public IP Address to connect the Bastion Host to. Default: pip-bas-cs2gs-$<locationShortName>-$<uniqueSuffix>')
@sys.minLength(1)
@sys.maxLength(80)
param bastionHostPublicIpAddressName string = 'pip-bas-cs2gs-${locationShortName}-${uniqueSuffix}'

@sys.description('The Azure Region to deploy the resources into.')
@sys.allowed([
  'centralus'
  'eastus'
  'eastus2'
  'northcentralus'
  'southcentralus'
  'westus'
  'westus2'
  'westus3'
  'westcentralus'
])
param location string

@sys.description('Short Name of the Azure Region to deploy the resources into.')
@sys.allowed([
  'usc'
  'use'
  'use2'
  'usnc'
  'ussc'
  'usw'
  'usw2'
  'usw3'
  'uswc'
])
param locationShortName string = 'use2'

@sys.description('The name of the Azure NAT Gateway. Default: ng-cs2gs-$<locationShortName>-$<uniqueSuffix>')
@sys.minLength(1)
@sys.maxLength(80)
param natGatewayName string = 'ng-cs2gs-${locationShortName}-${uniqueSuffix}'

@sys.description('The name of the Public IP Address to connect the NAT Gateway to. Default: pip-ng-cs2gs-$<locationShortName>-$<environment>')
@sys.minLength(1)
@sys.maxLength(80)
param natGatewayPublicIpAddressName string = 'pip-ng-cs2gs-${locationShortName}-${uniqueSuffix}'

@sys.description('The name of the Azure Network Security Group. Default: nsg-cs2gs-$<locationShortName>-$<uniqueSuffix>')
@sys.minLength(1)
@sys.maxLength(80)
param networkSecurityGroupName string = 'nsg-cs2gs-${locationShortName}-${uniqueSuffix}'

@sys.description('The length of the Public IP Prefix. Default: 29')
@sys.minValue(24)
@sys.maxValue(30)
param publicIpPrefixLength int = 29

@sys.description('The name of the Azure Public IP Prefix. Default: ippre-cs2gs-$<locationShortName>-$<uniqueSuffix>')
@sys.minLength(1)
@sys.maxLength(80)
param publicIpPrefixName string = 'ippre-cs2gs-${locationShortName}-${uniqueSuffix}'

@sys.description('The Public IP Address used to access Azure Virtual Machines via SSH.')
@sys.minLength(7)
@sys.maxLength(15)
param sshIpAddress string

@sys.description('The SSH Public Key used to access the Azure Virtual Machines.')
param sshPublicKey string

@sys.description('The number of Azure Virtual Machines to create. Default: 1')
@sys.minValue(1)
@sys.maxValue(25)
param virtualMachineCount int = 4

@sys.description('The name of the Azure Virtual Machine Operating System Disk. Default: osdisk-cs2gs-$<locationShortName>-$<uniqueSuffix>')
@sys.minLength(1)
@sys.maxLength(80)
param virtualMachineDiskName string = 'osdisk-cs2gs-${locationShortName}-${uniqueSuffix}'

@sys.description('The name of the Azure Virtual Machine. Default: vm-cs2gs-$<locationShortName>-$<uniqueSuffix>')
@sys.minLength(1)
@sys.maxLength(64)
param virtualMachineName string = 'vm-cs2gs-${locationShortName}-${uniqueSuffix}'

@sys.description('The name of the Azure Virtual Machine Network Interface. Default: nic-cs2gs-$<locationShortName>-$<uniqueSuffix>')
@sys.minLength(1)
@sys.maxLength(80)
param virtualMachineNetworkInterfaceName string = 'nic-cs2gs-${locationShortName}-${uniqueSuffix}'

@sys.description('The name of the Public IP Address to connect the Virtual Machine to. Default: pip-vm-cs2gs-$<locationShortName>-$<uniqueSuffix>')
@sys.minLength(1)
@sys.maxLength(80)
param virtualMachinePublicIpAddressName string = 'pip-vm-cs2gs-${locationShortName}-${uniqueSuffix}'

@sys.description('The name of the Azure Virtual Machine SKU. Default: Standard_F2as_v6')
param virtualMachineSku string = 'Standard_F2as_v6'

@sys.description('IPv4 Address Space (CIDR) for the Virtual Network. Default: 10.100.0.0/24')
@sys.minLength(9)
@sys.maxLength(18)
param virtualNetworkAddressSpace string = '10.100.0.0/24'

@sys.description('The name of the Azure Virtual Network. Default: vnet-cs2gs-$<locationShortName>-$<uniqueSuffix>')
@sys.minLength(2)
@sys.maxLength(64)
param virtualNetworkName string = 'vnet-cs2gs-${locationShortName}-${uniqueSuffix}'

@sys.description('A unique string to add as a suffix to all resources. Default: substring(uniqueString(resourceGroup().id), 0, 5)')
@sys.maxLength(5)
param uniqueSuffix string = substring(uniqueString(resourceGroup().id), 0, 5)

module networking '../modules/networking.bicep' = {
  name: 'Networking'
  params: {
    bastionHostName: bastionHostName
    bastionHostPublicIpAddressName: bastionHostPublicIpAddressName
    location: location
    natGatewayName: natGatewayName
    natGatewayPublicIpAddressName: natGatewayPublicIpAddressName
    networkSecurityGroupName: networkSecurityGroupName
    publicIpPrefixLength: publicIpPrefixLength
    publicIpPrefixName: publicIpPrefixName
    sshIpAddress: sshIpAddress
    virtualNetworkAddressSpace: virtualNetworkAddressSpace
    virtualNetworkName: virtualNetworkName
  }
}

module virtualMachine '../modules/vm.bicep' = [
  for i in range(0, virtualMachineCount): {
    name: 'VirtualMachine-${i}'
    params: {
      location: location
      publicIpPrefixId: networking.outputs.publicIpPrefixId
      sshPublicKey: sshPublicKey
      virtualMachineDiskName: '${virtualMachineDiskName}-${format('{0:0#}', i + 1)}'
      virtualMachineName: '${virtualMachineName}-${format('{0:0#}', i + 1)}'
      virtualMachineNetworkInterfaceName: '${virtualMachineNetworkInterfaceName}-${format('{0:0#}', i + 1)}'
      virtualMachinePublicIpAddressName: '${virtualMachinePublicIpAddressName}-${format('{0:0#}', i + 1)}'
      virtualMachineSku: virtualMachineSku
      virtualNetworkSubnetId: networking.outputs.virtualMachineSubnetId
    }
  }
]

output virtualMachines array = [
  for i in range(0, virtualMachineCount): {
    name: virtualMachine[i].outputs.vmName
    ipAddress: virtualMachine[i].outputs.vmPublicIpAddress
  }
]
