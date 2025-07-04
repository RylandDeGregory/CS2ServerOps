@sys.description('The Azure Region to deploy the resources into.')
param location string

@sys.description('Azure Resource ID of the Public IP Prefix to connect the Virtual Machine to.')
param publicIpPrefixId string

@sys.description('The SSH Public Key used to access the Azure Virtual Machine.')
param sshPublicKey string

@sys.description('The name of the Azure Virtual Machine Operating System Disk.')
@sys.minLength(1)
@sys.maxLength(80)
param virtualMachineDiskName string

@sys.description('The name of the Azure Virtual Machine.')
@sys.minLength(1)
@sys.maxLength(64)
param virtualMachineName string

@sys.description('The name of the Azure Virtual Machine Network Interface.')
@sys.minLength(1)
@sys.maxLength(80)
param virtualMachineNetworkInterfaceName string

@sys.description('The name of the Public IP Address to connect the Virtual Machine to.')
@sys.minLength(1)
@sys.maxLength(80)
param virtualMachinePublicIpAddressName string

@sys.description('The name of the Azure Virtual Machine SKU.')
param virtualMachineSku string

@sys.description('Azure Resource ID of the Virtual Network Subnet that the Virtual Machine will be connected to.')
param virtualNetworkSubnetId string

module publicIpAddress 'br/public:avm/res/network/public-ip-address:0.8.0' = {
  params: {
    enableTelemetry: false
    location: location
    name: virtualMachinePublicIpAddressName
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    publicIpPrefixResourceId: publicIpPrefixId
    skuName: 'Standard'
    skuTier: 'Regional'
  }
}

module virtualMachine 'br/public:avm/res/compute/virtual-machine:0.15.0' = {
  params: {
    adminUsername: 'azureuser'
    disablePasswordAuthentication: true
    enableTelemetry: false
    customData: loadTextContent('cloud-init-vm.yml')
    imageReference: {
      publisher: 'Canonical'
      offer: 'ubuntu-24_04-lts'
      sku: 'server'
      version: 'latest'
    }
    location: location
    name: virtualMachineName
    nicConfigurations: [
      {
        deleteOption: 'Delete'
        enableTelemetry: false
        ipConfigurations: [
          {
            name: 'ipconfig1'
            privateIPAllocationMethod: 'Dynamic'
            pipConfiguration: {
              publicIPAddressResourceId: publicIpAddress.outputs.resourceId
            }
            subnetResourceId: virtualNetworkSubnetId
          }
        ]
        name: virtualMachineNetworkInterfaceName
      }
    ]
    osDisk: {
      caching: 'ReadWrite'
      createOption: 'FromImage'
      deleteOption: 'Delete'
      diskSizeGB: 512
      managedDisk: {
        storageAccountType: 'Premium_LRS'
      }
      name: virtualMachineDiskName
    }
    osType: 'Linux'
    publicKeys: [
      {
        keyData: sshPublicKey
        path: '/home/azureuser/.ssh/authorized_keys'
      }
    ]
    secureBootEnabled: true
    encryptionAtHost: false
    vmSize: virtualMachineSku
    zone: 0
  }
}

output vmName string = virtualMachine.outputs.name
output vmPublicIpAddress string = publicIpAddress.outputs.ipAddress
