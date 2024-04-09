param applicationInsightsId string
param containerRegistryId string
param hubWorkspaceName string
param workspaceName string
param keyVaultId string
param location string
param openAiName string
param searchName string
param cosmosAccountName string
param storageAccountId string
param tags object = {}

// In ai.azure.com: Azure AI Resource
resource hub 'Microsoft.MachineLearningServices/workspaces@2024-01-01-preview' = {
  name: hubWorkspaceName
  location: location
  tags: tags
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  kind: 'Hub'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: hubWorkspaceName
    storageAccount: storageAccountId
    keyVault: keyVaultId
    applicationInsights: applicationInsightsId
    hbiWorkspace: false
    managedNetwork: {
      isolationMode: 'Disabled'
    }
    v1LegacyMode: false
    containerRegistry: containerRegistryId
    publicNetworkAccess: 'Enabled'
    discoveryUrl: 'https://${location}.api.azureml.ms/discovery'
  }

  resource openAiDefaultEndpoint 'endpoints' = {
    name: 'Azure.OpenAI'
    properties: {
      name: 'Azure.OpenAI'
      endpointType: 'Azure.OpenAI'
      associatedResourceId: openai.id
    }
  }

  resource contentSafetyDefaultEndpoint 'endpoints' = {
    name: 'Azure.ContentSafety'
    properties: {
      name: 'Azure.ContentSafety'
      endpointType: 'Azure.ContentSafety'
      associatedResourceId: openai.id
    }
  }

  resource openAiConnection 'connections' = {
    name: 'aoai-connection'
    properties: {
      category: 'AzureOpenAI'
      authType: 'ApiKey'
      isSharedToAll: true
      target: openai.properties.endpoint
      metadata: {
        ApiVersion: '2023-07-01-preview'
        ApiType: 'azure'
        ResourceId: openai.id
      }
      credentials: {
        key: openai.listKeys().key1
      }
    }
  }

  resource searchConnection 'connections' = {
    name: 'products-search'
    properties: {
      category: 'CognitiveSearch'
      authType: 'ApiKey'
      isSharedToAll: true
      target: 'https://${search.name}.search.windows.net/'
      credentials: {
        key: search.listAdminKeys().primaryKey
      }
    }
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
        key: cosmos.listKeys().primaryMasterKey
      }
    }
    metadata: {
      endpoint: cosmos.properties.documentEndpoint
      databaseId: 'products'
      containerId: 'customers'
      'azureml.flow.connection_type': 'Custom'
      'azureml.flow.module': 'promptflow.connections'
    }
  }
}

// In ai.azure.com: Azure AI Project
resource workspace 'Microsoft.MachineLearningServices/workspaces@2023-10-01' = {
  name: workspaceName
  location: location
  tags: tags
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  kind: 'Project'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: workspaceName
    hbiWorkspace: false
    v1LegacyMode: false
    publicNetworkAccess: 'Enabled'
    discoveryUrl: 'https://${location}.api.azureml.ms/discovery'
    // most properties are not allowed for a project workspace: "Project workspace shouldn't define ..."
    hubResourceId: hub.id
  }
}

resource openai 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: openAiName
}

resource search 'Microsoft.Search/searchServices@2021-04-01-preview' existing = {
  name: searchName
}

resource cosmos 'Microsoft.DocumentDB/databaseAccounts@2022-08-15' existing = {
  name: cosmosAccountName
}

output hubWorkspaceName string = hub.name
output workspaceName string = workspace.name
output principalId string = workspace.identity.principalId
