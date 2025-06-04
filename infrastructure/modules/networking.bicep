@sys.description('The Azure Region to deploy the resources into.')
param location string

@sys.description('The name of the Azure Bastion Host.')
@sys.minLength(1)
@sys.maxLength(80)
param bastionHostName string

@sys.description('The name of the Public IP Address to connect the Bastion Host to.')
@sys.minLength(1)
@sys.maxLength(80)
param bastionHostPublicIpAddressName string

@sys.description('The name of the Azure NAT Gateway.')
@sys.minLength(1)
@sys.maxLength(80)
param natGatewayName string

@sys.description('The name of the Public IP Address to connect the NAT Gateway to.')
@sys.minLength(1)
@sys.maxLength(80)
param natGatewayPublicIpAddressName string

@sys.description('The name of the Azure Network Security Group.')
@sys.minLength(1)
@sys.maxLength(80)
param networkSecurityGroupName string

@sys.description('The length of the Public IP Prefix.')
@sys.minValue(24)
@sys.maxValue(30)
param publicIpPrefixLength int

@sys.description('The name of the Azure Public IP Prefix.')
@sys.minLength(1)
@sys.maxLength(80)
param publicIpPrefixName string

@sys.description('The Public IP Address used to access Azure Virtual Machines via SSH.')
@sys.minLength(7)
@sys.maxLength(15)
param sshIpAddress string

@sys.description('IPv4 Address Space (CIDR) for the Virtual Network.')
@sys.minLength(9)
@sys.maxLength(18)
param virtualNetworkAddressSpace string

@sys.description('The name of the Azure Virtual Network.')
@sys.minLength(2)
@sys.maxLength(64)
param virtualNetworkName string

var bastionSubnetAddressPrefix = cidrSubnet(virtualNetworkAddressSpace, 27, 1)
var defaultSubnetAddressPrefix = cidrSubnet(virtualNetworkAddressSpace, 27, 2)

module bastionHost 'br/public:avm/res/network/bastion-host:0.6.1' = {
  params: {
    enableTelemetry: false
    location: location
    name: bastionHostName

    skuName: 'Developer'
    virtualNetworkResourceId: virtualNetwork.outputs.resourceId
  }
}

module bastionHostPublicIpAddress 'br/public:avm/res/network/public-ip-address:0.8.0' = {
  params: {
    enableTelemetry: false
    location: location
    name: bastionHostPublicIpAddressName
    publicIpPrefixResourceId: publicIpPrefix.outputs.resourceId
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    skuName: 'Standard'
    skuTier: 'Regional'
    zones: [
      1
      2
      3
    ]
  }
}

module natGateway 'br/public:avm/res/network/nat-gateway:1.2.2' = {
  params: {
    enableTelemetry: false
    location: location
    name: natGatewayName
    publicIpResourceIds: [
      natGatewayPublicIpAddress.outputs.resourceId
    ]
    zone: 0
  }
}

module natGatewayPublicIpAddress 'br/public:avm/res/network/public-ip-address:0.8.0' = {
  params: {
    enableTelemetry: false
    location: location
    name: natGatewayPublicIpAddressName
    publicIpPrefixResourceId: publicIpPrefix.outputs.resourceId
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    skuName: 'Standard'
    skuTier: 'Regional'
    zones: [
      1
      2
      3
    ]
  }
}

module networkSecurityGroup 'br/public:avm/res/network/network-security-group:0.5.1' = {
  params: {
    enableTelemetry: false
    location: location
    name: networkSecurityGroupName
    securityRules: [
      {
        name: 'Allow-SSH'
        properties: {
          access: 'Allow'
          destinationPortRange: '22'
          direction: 'Inbound'
          priority: 105
          protocol: 'Tcp'
          sourceAddressPrefix: sshIpAddress
          sourcePortRange: '*'
          destinationAddressPrefix: defaultSubnetAddressPrefix
      }
    }
      {
        name: 'Allow-CounterStrike-TCP'
        properties: {
          access: 'Allow'
          destinationPortRange: '27015'
          direction: 'Inbound'
          priority: 110
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: defaultSubnetAddressPrefix
        }
      }
      {
        name: 'Allow-CounterStrike-UDP'
        properties: {
          access: 'Allow'
          destinationPortRange: '27015'
          direction: 'Inbound'
          priority: 111
          protocol: 'Udp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: defaultSubnetAddressPrefix
        }
      }
      {
        name: 'Allow-CounterStrikeTV-UDP'
        properties: {
          access: 'Allow'
          destinationPortRange: '27020'
          direction: 'Inbound'
          priority: 112
          protocol: 'Udp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: defaultSubnetAddressPrefix
        }
      }
    ]
  }
}

module publicIpPrefix 'br/public:avm/res/network/public-ip-prefix:0.6.0' = {
  params: {
    enableTelemetry: false
    location: location
    name: publicIpPrefixName
    prefixLength: publicIpPrefixLength
    publicIPAddressVersion: 'IPv4'
    tier: 'Regional'
    zones: [
      1
      2
      3
    ]
  }
}

module virtualNetwork 'br/public:avm/res/network/virtual-network:0.6.1' = {
  params: {
    addressPrefixes: [virtualNetworkAddressSpace]
    enableTelemetry: false
    location: location
    name: virtualNetworkName
    subnets: [
      {
        addressPrefix: bastionSubnetAddressPrefix
        name: 'AzureBastionSubnet'
      }
      {
        addressPrefix: defaultSubnetAddressPrefix
        name: 'snet-default'
        natGatewayResourceId: natGateway.outputs.resourceId
        networkSecurityGroupResourceId: networkSecurityGroup.outputs.resourceId
      }
    ]
  }
}

output virtualMachineSubnetId string = virtualNetwork.outputs.subnetResourceIds[1]
