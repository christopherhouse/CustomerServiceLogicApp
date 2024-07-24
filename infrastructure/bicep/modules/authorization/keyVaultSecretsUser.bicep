param targetPrincipalIds string[]

param keyVaultName string

var keyVaultSecretsUserRoleId = '4633458b-17de-408a-b874-0445c86b69e6'

resource kv 'Microsoft.KeyVault/vaults@2024-04-01-preview' existing = {
  name: keyVaultName
  scope: resourceGroup()
}

resource roleDef 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: keyVaultSecretsUserRoleId
  scope: subscription()
}

resource rbacAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for targetPrincipalId in targetPrincipalIds: {
  name: guid(kv.id, targetPrincipalId, roleDef.id)
  scope: kv
  properties: {
    principalId: targetPrincipalId
    roleDefinitionId: roleDef.id
    principalType: 'ServicePrincipal'
  }
}]
