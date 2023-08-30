param appName string = 'ract'

param env string = 'dev'

param desc string = 'backup'

param region string = 'syd'

@allowed([
  'Standard_LRS'
])
param storageSKU string = 'Standard_LRS'

param location string = resourceGroup().location

var functionWorkerRuntime = 'node'

param functionAppName string = '${appName}-${region}-${env}-func-${desc}'
param hostingPlanName string = '${appName}-${region}-${env}-plan-${desc}'

resource functionAppManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: '${appName}-${region}-${env}-funcapp'
  location: location
}

resource hostingPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: hostingPlanName
  location: location
  sku: {
    name: 'Y1'
  }
  properties: {}
}

param storageAccountName string = 'st${env}${desc}'

param backupAccountName string = 'bk${env}${desc}'

resource backupStorageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: backupAccountName
  location: location
  sku: {
    name: storageSKU
  }
  kind: 'Storage'
}

resource blobStorageRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: backupStorageAccount
  name: guid(resourceGroup().id, functionAppManagedIdentity.id, blobStorageRoleDefinition.id, env, backupStorageAccount.id)
  properties: {
    roleDefinitionId: blobStorageRoleDefinition.id
    principalId: functionAppManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource functionApp 'Microsoft.Web/sites@2022-03-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${functionAppManagedIdentity.id}': {}
    }
  }
  properties: {
    keyVaultReferenceIdentity: functionAppManagedIdentity.id
    serverFarmId: hostingPlan.id
    httpsOnly: true
    siteConfig: {
      use32BitWorkerProcess: false
      minTlsVersion: '1.2'
      appSettings: [
          {
            name: 'AzureWebJobsStorage'
            value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
          }
          {
            name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
            value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
          }
          {
            name: 'FUNCTIONS_EXTENSION_VERSION'
            value: '~4'
          }
          {
            name: 'WEBSITE_NODE_DEFAULT_VERSION'
            value: '~16'
          }
          {
            name: 'FUNCTIONS_WORKER_RUNTIME'
            value: functionWorkerRuntime
          }
          {
            name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
            value: applicationInsights.properties.InstrumentationKey
          }
          {
            name: 'BLOB_STORAGE_URL'
            value: 'https://${backupStorageAccount.name}.blob.${environment().suffixes.storage}'
          }
        ]
    }
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${appName}-${region}-${env}-${desc}Insights'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
  }
}


output storageEndpoint object = storageAccount.properties.primaryEndpoints
