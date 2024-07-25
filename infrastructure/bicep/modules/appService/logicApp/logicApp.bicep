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
param customAppSettings udt.appSettingType[] = []

var storageAccountBaseName = '${toLower(replace(logicAppName, '-', ''))}sa'
var storageAccountTrimmedName = length(storageAccountBaseName) > 24 ? substring(storageAccountBaseName, 0, 24) : storageAccountBaseName
var storageAccountConnectionStringSecretName = '${logicAppName}-storage-connection-string'

var defaultAppSettings = [
  {
    name: 'APP_KIND'
    value: 'workflowapp'
  }
  {
    name: 'AzureWebJobsStorage'
    value: '@Microsoft.KeyVault(SecretUri=${storage.outputs.connectionStringSecretUri})'
  }
  {
    name: 'FUNCTIONS_WORKER_RUNTIME'
    value: 'node'
  }
  {
    name: 'FUNCTIONS_EXTENSION_VERSION'
    value: '~4'
  }
  {
    name: 'WEBSITE_CONTENTZUREFILESCONNECTIONSTRING'
    value: '@Microsoft.KeyVault(SecretUri=${storage.outputs.connectionStringSecretUri})'
  }
  {
    name: 'WEBSITE_NODE_DEFAULT_VERSION'
    value: '~20'
  }
  {
    name: 'WEBSITE_CONTENTOVERVNET'
    value: '1'
  }
  {
    name: 'WEBSITE_VNET_ROUTE_ALL'
    value: '1'
  }
  {
    name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
    value: '@Microsoft.KeyVault(SecretUri=${appInsightsInstrumentationKeySecretUri})'
  }
  {
    name: 'APPINSIGHTS_CONNECTION_STRING'
    value: '@Microsoft.KeyVault(SecretUri=${appInsightsConnectionStringSecretUri})'
  }
]

var appSettings = union(defaultAppSettings, customAppSettings)

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
  tags: tags
  kind: 'functionapp,workflowapp'
  identity: {
    type: 'SystemAssigned, UserAssigned'
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
      minTlsVersion: '1.2'
      http20Enabled: true
      appSettings: appSettings
    }
    publicNetworkAccess: 'Enabled'
    httpsOnly: true
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
