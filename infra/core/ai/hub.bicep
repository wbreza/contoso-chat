param name string
param displayName string = name
param location string = resourceGroup().location
param storageAccountName string
param keyVaultName string
param openAiName string
param appInsightsName string = ''
param containerRegistryName string = ''
param aiSearchName string = ''
param tags object = {}

resource hub 'Microsoft.MachineLearningServices/workspaces@2024-01-01-preview' = {
  name: name
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
    friendlyName: displayName
    storageAccount: storageAccount.id
    keyVault: keyVault.id
    applicationInsights: empty(appInsightsName) ? '' : appInsights.id
    containerRegistry: empty(containerRegistryName) ? '' : containerRegistry.id
    hbiWorkspace: false
    managedNetwork: {
      isolationMode: 'Disabled'
    }
    v1LegacyMode: false
    publicNetworkAccess: 'Enabled'
    discoveryUrl: 'https://${location}.api.azureml.ms/discovery'
  }

  resource openAiDefaultEndpoint 'endpoints' = {
    name: 'Azure.OpenAI'
    properties: {
      name: 'Azure.OpenAI'
      endpointType: 'Azure.OpenAI'
      associatedResourceId: openAi.id
    }
  }

  resource contentSafetyDefaultEndpoint 'endpoints' = {
    name: 'Azure.ContentSafety'
    properties: {
      name: 'Azure.ContentSafety'
      endpointType: 'Azure.ContentSafety'
      associatedResourceId: openAi.id
    }
  }

  resource openAiConnection 'connections' = {
    name: 'aoai-connection'
    properties: {
      category: 'AzureOpenAI'
      authType: 'ApiKey'
      isSharedToAll: true
      target: openAi.properties.endpoint
      metadata: {
        ApiVersion: '2023-07-01-preview'
        ApiType: 'azure'
        ResourceId: openAi.id
      }
      credentials: {
        key: openAi.listKeys().key1
      }
    }
  }

  resource searchConnection 'connections' =
    if (!empty(aiSearchName)) {
      name: 'search-connection'
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

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing =
  if (!empty(appInsightsName)) {
    name: appInsightsName
  }

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' existing =
  if (!empty(containerRegistryName)) {
    name: containerRegistryName
  }

resource openAi 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: openAiName
}

resource search 'Microsoft.Search/searchServices@2021-04-01-preview' existing =
  if (!empty(aiSearchName)) {
    name: aiSearchName
  }

output name string = hub.name
output id string = hub.id
output principalId string = hub.identity.principalId
