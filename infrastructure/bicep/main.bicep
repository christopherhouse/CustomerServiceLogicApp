import * as udt from './types.bicep'

@description('The name of the workload, used to compute resource names in the form of {environmentSuffix}-{workloadName}-{resource type abbreviation}')
param workloadName string

@description('The environment name, used to compute names in the form of {environmentSuffix}-{workloadName}-{resource type abbreviation}')
param environmentSuffix string

@description('The Key Vault Secret URI of the app insights connection string')
param appInsightsConnectionStringSecretUri string

@description('The Key Vault Secret URI of the app insights instrumentation key')
param appInsightsInstrumentationKeySecretUri string

@description('The DNS zone resource ID for blob storage')
param blobDnsZoneResourceId string

@description('The DNS zone resource ID for file storage')
param fileDnsZoneResourceId string

@description('The name of the key vault used for secrets')
param keyVaultName string

@description('The Log Analytics workspace ID')
param logAnalyticsWorkspaceId string

@description('The DNS zone resource ID for queue storage')
param queueDnsZoneResourceId string

@description('The region in which to deploy the resources')
param region string

@description('The storage account configuration object')
param storageAccountConfiguration udt.storageAccountConfigurationType

@description('The tags to apply to all resources')
param tags object

@description('The resuorce ID of the subnet for the storage account')
param storageSubnetResourceId string

@description('The DNS zone resource ID for table storage')
param tableDnsZoneResourceId string

param appServicePlanResourceId string

param aseResourceId string

param sharedResourceGroupName string

// Base name
var baseName = '${workloadName}-${environmentSuffix}'

// User Assigned Managed Identity
var uamiResourceName= '${baseName}-uami'
var uamiDeploymentName = '${uamiResourceName}-${deployment().name}'

var uamiKvSecretsUserAssignmentDeploymentName = '${uamiResourceName}-kv-secrets-user-${deployment().name}'

// Logic App
var logicAppName = '${baseName}-la'
var logicAppDeploymentName = '${logicAppName}-${deployment().name}'

// Storage Account
var storageAccountName = '${baseName}datasa'
var storageAccountDeploymentName = '${storageAccountName}-${deployment().name}'

module uami './modules/managedIdentity/userAssignedManagedIdentity.bicep' = {
  name: uamiDeploymentName
  params: {
    location: region
    managedIdentityName: uamiResourceName
    tags: tags
  }
}

module kvSecretsUser './modules/authorization/keyVaultSecretsUser.bicep' = {
  name: uamiKvSecretsUserAssignmentDeploymentName
  scope: resourceGroup(sharedResourceGroupName)
  params: {
    keyVaultName: keyVaultName
    targetPrincipalIds: [
      uami.outputs.principalId
    ]
  }
}

module logicApp './modules/appService/logicApp/logicApp.bicep' = {
  name: logicAppDeploymentName
  params: {
    tags: tags
    appInsightsConnectionStringSecretUri: appInsightsConnectionStringSecretUri
    appInsightsInstrumentationKeySecretUri: appInsightsInstrumentationKeySecretUri
    blobDnsZoneResourceId: blobDnsZoneResourceId
    fileDnsZoneResourceId: fileDnsZoneResourceId
    keyVaultName: keyVaultName
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    logicAppName: logicAppName
    queueDnsZoneResourceId: queueDnsZoneResourceId
    region: region
    storageAccountConfiguration: storageAccountConfiguration 
    storageSubnetResourceId: storageSubnetResourceId
    tableDnsZoneResourceId: tableDnsZoneResourceId
    uamiPrincipalId: uami.outputs.principalId
    uamiResourceId: uami.outputs.id
    aseResourceId: aseResourceId
    appServicePlanResourceId: appServicePlanResourceId
    sharedResourceGroupName: sharedResourceGroupName
  }
  dependsOn: [
    kvSecretsUser
  ]
}

module data './modules/storage/privateStorageAccount.bicep' = {
  name: storageAccountDeploymentName
  params: {
    tags: tags
    blobDnsZoneId: blobDnsZoneResourceId
    fileDnsZoneId: fileDnsZoneResourceId
    keyVaultName: keyVaultName
    queueDnsZoneId: queueDnsZoneResourceId
    region: region
    sharedResourceeGroupName: sharedResourceGroupName
    storageAccountName: storageAccountName
    storageConfiguration: {
      sku: 'Standard_LRS'
      accessTier: 'Hot'
      addConnectionStringToKeyVault: true
      fileShares: []
      tables: [
        'customersvcreqs'
      ]
      blobContainers: []
    }
    storageConnectionStringSecretName: '${storageAccountName}-cs'
    subnetId: storageSubnetResourceId
    tableDnsZoneId: tableDnsZoneResourceId
  }
}
