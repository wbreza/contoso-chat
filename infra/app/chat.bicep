param location string = resourceGroup().location
param aiHubName string
param aiProjectName string
param keyVaultName string
param endpointName string
param cosmosAccountName string
param tags object = {}

module machineLearningEndpoint '../core/host/online-endpoint.bicep' = {
  name: 'endpoint'
  params: {
    name: endpointName
    location: location
    tags: tags
    serviceName: 'chat'
    aiHubName: aiHubName
    aiProjectName: aiProjectName
    keyVaultName: keyVaultName
  }
}

resource cosmosConnection 'Microsoft.MachineLearningServices/workspaces/connections@2024-01-01-preview' = {
  parent: hub
  name: 'products-cosmos'
  properties: {
    authType: 'CustomKeys'
    category: 'CustomKeys'
    isSharedToAll: true
    credentials: {
      keys: {
        key: cosmosAccount.listKeys().primaryMasterKey
      }
    }
    metadata: {
      endpoint: cosmosAccount.properties.documentEndpoint
      databaseId: 'products'
      containerId: 'customers'
      'azureml.flow.connection_type': 'Custom'
      'azureml.flow.module': 'promptflow.connections'
    }
  }
}

resource hub 'Microsoft.MachineLearningServices/workspaces@2024-01-01-preview' existing = {
  name: aiHubName
}

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2022-08-15' existing = {
  name: cosmosAccountName
}

