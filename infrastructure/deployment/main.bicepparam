using './main.bicep'

param location = 'eastus'
param locationShortName = 'use'

param uniqueSuffix = 'dev'
param sshPublicKey = ''
param sshIpAddress = ''

// $Params = @{
//   Location              = 'eastus'
//   Name                  = 'CS2-Servers'
//   ResourceGroupName     = ''
//   TemplateFile          = 'main.bicep'
//   TemplateParameterFile = 'main.bicepparam'
// }
// New-AzResourceGroupDeployment @Params -Verbose
