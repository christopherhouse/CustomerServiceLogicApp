import * as udt from '../../../types.bicep'

param logicAppName string
param region string
param blobDnsZoneResourceId string
param tableDnsZoneResourceId string
param queueDnsZoneResourceId string
param fileDnsZoneResourceId string
param storageSubnetResourceId string
param uamiResourceId string
param uamiPrincipalId string
param keyVaultName string
param appInsightsInstrumentationKeySecretUri string
param appInsightsConnectionStringSecretUri string
param logAnalyticsWorkspaceId string
param storageAccountConfiguration udt.storageAccountConfigurationType
param aseResourceId string
param appServicePlanResourceId string
param tags object
param sharedResourceGroupName string

var storageAccountBaseName = '${toLower(replace(logicAppName, '-', ''))}sa'
var storageAccountTrimmedName = length(storageAccountBaseName) > 24 ? substring(storageAccountBaseName, 0, 24) : storageAccountBaseName
var storageAccountConnectionStringSecretName = '${logicAppName}-storage-connection-string'

var keyVaultSecretsUserRoleId = '4633458b-17de-408a-b874-0445c86b69e6'


resource kvSecretsUserRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: subscription()
  name: keyVaultSecretsUserRoleId
}

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
  scope: resourceGroup(sharedResourceGroupName)
}

module kvsr '../../authorization/keyVaultSecretsUser.bicep' = {
  name: '${logicAppName}-kvrbac-${uniqueString(deployment().name)}'
  scope: resourceGroup(sharedResourceGroupName)
  params: {
    keyVaultName: keyVaultName
    targetPrincipalIds: [
      uamiPrincipalId
    ]
  }
}

module storage '../../storage/privateStorageAccount.bicep' = {
  name: '${storageAccountTrimmedName}-${substring(uniqueString(deployment().name), 0, 4)}'
  params: {
    storageAccountName: storageAccountTrimmedName
    region: region
    blobDnsZoneId: blobDnsZoneResourceId
    tableDnsZoneId: tableDnsZoneResourceId
    queueDnsZoneId: queueDnsZoneResourceId
    fileDnsZoneId: fileDnsZoneResourceId
    storageConfiguration: storageAccountConfiguration
    subnetId: storageSubnetResourceId
    keyVaultName: keyVaultName
    storageConnectionStringSecretName: storageAccountConnectionStringSecretName
    tags: tags
    sharedResourceeGroupName: sharedResourceGroupName
  }
}

// Create a Logic Apps Standard resource using Bicep.  The resource
// name should be based on the variable logicAppname.  The resource
// location should be based on the variable location.  The Logic App
// should be deployed to the App Service Environment (ASE) specified
// by the variable aseResourceId.  The App Service Plan should be
// specified by the variable appServicePlanResourceId.
resource logicApp 'Microsoft.Web/sites@2023-01-01' = {
  name: logicAppName
  location: region
  kind: 'functionapp,workflowapp'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uamiResourceId}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlanResourceId
    keyVaultReferenceIdentity: uamiResourceId
    hostingEnvironmentProfile: {
      id: aseResourceId
    }
    siteConfig: {
      alwaysOn: true
    }
    publicNetworkAccess: 'Disabled'
  }
}

resource config 'Microsoft.Web/sites/config@2023-01-01' = {
  name: 'appsettings'
  parent: logicApp
  properties: {
    APP_KIND: 'workflowapp'
    AzureWebJobsStorage: '@Microsoft.KeyVault(SecretUri=${storage.outputs.connectionStringSecretUri})'
    FUNCTIONS_WORKER_RUNTIME: 'node'
    FUNCTIONS_EXTENSION_VERSION: '~4'
    WEBSITE_CONTENTZUREFILESCONNECTIONSTRING: '@Microsoft.KeyVault(SecretUri=${storage.outputs.connectionStringSecretUri})'
    WEBSITE_NODE_DEFAULT_VERSION: '~18'
    WEBSITE_CONTENTOVERVNET: '1'
    vnetrouteallenabled: '1'
    APPINSIGHTS_INSTRUMENTATIONKEY: '@Microsoft.KeyVault(SecretUri=${appInsightsInstrumentationKeySecretUri})'
    APPINSIGHTS_CONNECTION_STRING: '@Microsoft.KeyVault(SecretUri=${appInsightsConnectionStringSecretUri})'
  }
}

resource laws 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'laws'
  scope: logicApp
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'WorkflowRuntime'
        enabled: true
      }
      {
        category: 'FunctionAppLogs'
        enabled: true
      }
    ]
  }
}

output id string = logicApp.id
output name string = logicApp.name
output storageAccountName string = storage.outputs.name
output storageAccountId string = storage.outputs.id
