using '../main.bicep'

param workloadName = 'customer-service-api'
param environmentSuffix = 'dev'
param appInsightsConnectionStringSecretUri = 'https://bw-ais-loc-kv.vault.azure.net/secrets/appInsightsConnectionString'
param appInsightsInstrumentationKeySecretUri = 'https://bw-ais-loc-kv.vault.azure.net/secrets/appInsightsInstrumentationKey'
param blobDnsZoneResourceId = '/subscriptions/e1f57a36-4892-4716-9a3f-661432b39dbe/resourceGroups/bw-ais/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net'
param fileDnsZoneResourceId = '/subscriptions/e1f57a36-4892-4716-9a3f-661432b39dbe/resourceGroups/bw-ais/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net'
param keyVaultName = 'bw-ais-loc-kv'
param logAnalyticsWorkspaceId = '/subscriptions/e1f57a36-4892-4716-9a3f-661432b39dbe/resourceGroups/BW-AIS/providers/Microsoft.OperationalInsights/workspaces/bw-ais-loc-laws'
param queueDnsZoneResourceId = '/subscriptions/e1f57a36-4892-4716-9a3f-661432b39dbe/resourceGroups/bw-ais/providers/Microsoft.Network/privateDnsZones/privatelink.queue.core.windows.net'
param region = 'eastus2'
param storageAccountConfiguration = {
  accessTier: 'Hot'
  addConnectionStringToKeyVault: true
  tables: []
  blobContainers: []
  fileShares: []
  queues: []
  sku: 'Standard_LRS'
}
param aseResourceId = '/subscriptions/e1f57a36-4892-4716-9a3f-661432b39dbe/resourceGroups/BW-AIS/providers/Microsoft.Web/hostingEnvironments/bw-ais-loc-ase'
param appServicePlanResourceId = '/subscriptions/e1f57a36-4892-4716-9a3f-661432b39dbe/resourceGroups/BW-AIS-CUSTSVC-DEV/providers/Microsoft.Web/serverFarms/bw-ais-loc-custsvc-asp'
param storageSubnetResourceId = '/subscriptions/e1f57a36-4892-4716-9a3f-661432b39dbe/resourceGroups/BW-AIS/providers/Microsoft.Network/virtualNetworks/bw-ais-loc-vnet/subnets/services'
param tags = {
  Cost_Center: 'IT-0234-AJQ'
  Environment: 'dev'
  Project: 'Customer Service API'
  Department: 'IT'
  Contact: 'custsvcdevs@contoso.net'
}
param tableDnsZoneResourceId = '/subscriptions/e1f57a36-4892-4716-9a3f-661432b39dbe/resourceGroups/bw-ais/providers/Microsoft.Network/privateDnsZones/privatelink.table.core.windows.net'
param sharedResourceGroupName = 'BW-AIS'
