@description('The name of the Key Vault to be created')
param keyVaultName string

@description('The region where the Key Vault will be created')
param region string

@description('The resource id of the log analytics workspace to send logs to')
param logAnalyticsWorkspaceResourceId string

@description('The tags to associate with the API Center resource')
param tags object = {}

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  tags: tags
  location: region
  properties: {
    sku: {
      name: 'standard'
      family: 'A'
    }
    tenantId: subscription().tenantId
    softDeleteRetentionInDays: 90
    enableRbacAuthorization: true
    publicNetworkAccess: 'Disabled'
    enableSoftDelete: true
    enablePurgeProtection: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: []
    }
    enabledForTemplateDeployment: true
  }
}

resource laws 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'laws'
  scope: kv
  properties: {
    workspaceId: logAnalyticsWorkspaceResourceId
    logs: [
      {
        category: 'AuditEvent'
        enabled: true
      }
      {
        category: 'AzurePolicyEvaluationDetails'
        enabled: true
      }
    ]
  }
}

output id string = kv.id
output name string = kv.name