param resourceToken string
param location string = resourceGroup().location
param tags object = {}
param keyVaultName string = ''
param storageAccountName string = ''
param containerRegistryName string = ''
param appInsightsName string = ''
param openAiName string = ''
param searchName string = ''

var abbrs = loadJsonContent('../abbreviations.json')

module keyVault '../core/security/keyvault.bicep' =
  if (empty(keyVaultName)) {
    name: 'keyvault'
    params: {
      location: location
      tags: tags
      name: '${abbrs.keyVaultVaults}${resourceToken}'
    }
  }

module storageAccount '../core/storage/storage-account.bicep' =
  if (empty(storageAccountName)) {
    name: 'storageAccount'
    params: {
      location: location
      tags: tags
      name: '${abbrs.storageStorageAccounts}${resourceToken}'
      containers: [
        {
          name: 'default'
        }
      ]
      files: [
        {
          name: 'default'
        }
      ]
      queues: [
        {
          name: 'default'
        }
      ]
      tables: [
        {
          name: 'default'
        }
      ]
      corsRules: [
        {
          allowedOrigins: [
            'https://mlworkspace.azure.ai'
            'https://ml.azure.com'
            'https://*.ml.azure.com'
            'https://ai.azure.com'
            'https://*.ai.azure.com'
            'https://mlworkspacecanary.azure.ai'
            'https://mlworkspace.azureml-test.net'
          ]
          allowedMethods: [
            'GET'
            'HEAD'
            'POST'
            'PUT'
            'DELETE'
            'OPTIONS'
            'PATCH'
          ]
          maxAgeInSeconds: 1800
          exposedHeaders: [
            '*'
          ]
          allowedHeaders: [
            '*'
          ]
        }
      ]
      deleteRetentionPolicy: {
        allowPermanentDelete: false
        enabled: false
      }
      shareDeleteRetentionPolicy: {
        enabled: true
        days: 7
      }
    }
  }

module logAnalytics '../core/monitor/loganalytics.bicep' =
  if (empty(appInsightsName)) {
    name: 'logAnalytics'
    params: {
      location: location
      tags: tags
      name: '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
    }
  }

module appInsights '../core/monitor/applicationinsights.bicep' =
  if (empty(appInsightsName)) {
    name: 'appInsights'
    params: {
      location: location
      tags: tags
      name: '${abbrs.insightsComponents}${resourceToken}'
      logAnalyticsWorkspaceId: empty(appInsightsName) ? logAnalytics.outputs.id : ''
    }
  }

module registry '../core/host/container-registry.bicep' =
  if (empty(containerRegistryName)) {
    name: 'containerRegistry'
    params: {
      location: location
      tags: tags
      name: '${abbrs.containerRegistryRegistries}${resourceToken}'
    }
  }

module openAi '../core/ai/cognitiveservices.bicep' =
  if (empty(openAiName)) {
    name: 'openAi'
    params: {
      location: location
      tags: tags
      name: 'aoai-${resourceToken}'
      kind: 'AIServices'
      deployments: [
        {
          name: 'gpt-35-turbo'
          model: {
            format: 'OpenAI'
            name: 'gpt-35-turbo'
            version: '0613'
          }
          sku: {
            name: 'Standard'
            capacity: 20
          }
        }
        {
          name: 'gpt-4'
          model: {
            format: 'OpenAI'
            name: 'gpt-4'
            version: '0613'
          }
          sku: {
            name: 'Standard'
            capacity: 10
          }
        }
        {
          name: 'text-embedding-ada-002'
          model: {
            format: 'OpenAI'
            name: 'text-embedding-ada-002'
            version: '2'
          }
          sku: {
            name: 'Standard'
            capacity: 20
          }
        }
      ]
    }
  }

module search '../core/search/search-services.bicep' =
  if (empty(searchName)) {
    name: 'search'
    params: {
      location: location
      tags: tags
      name: '${abbrs.searchSearchServices}${resourceToken}'
    }
  }

resource existingKeyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing =
  if (!empty(keyVaultName)) {
    name: keyVaultName
  }

resource existingStorageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing =
  if (!empty(storageAccountName)) {
    name: storageAccountName
  }

resource existingRegistry 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' existing =
  if (!empty(containerRegistryName)) {
    name: containerRegistryName
  }

resource existingLogAnalytics 'Microsoft.OperationalInsights/workspaces@2020-08-01' existing =
  if (!empty(appInsightsName)) {
    name: last(split(existingAppInsights.properties.WorkspaceResourceId, '/'))
  }

resource existingAppInsights 'Microsoft.Insights/components@2020-02-02' existing =
  if (!empty(appInsightsName)) {
    name: appInsightsName
  }

resource existingOpenAi 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' existing =
  if (!empty(openAiName)) {
    name: openAiName
  }

resource existingSearch 'Microsoft.Search/searchServices@2021-04-01-preview' existing =
  if (!empty(searchName)) {
    name: searchName
  }

// Open AI Services
output openAiName string = empty(openAiName) ? openAi.outputs.name : existingOpenAi.name
output openAiEndpoint string = empty(openAiName) ? openAi.outputs.endpoint : existingOpenAi.properties.endpoint

// AI Search
output searchName string = empty(searchName) ? search.outputs.name : existingSearch.name
output searchEndpoint string = empty(searchName)
  ? search.outputs.endpoint
  : 'https://${existingSearch.name}.search.windows.net'

// Key Vault
output keyVaultName string = empty(keyVaultName) ? keyVault.outputs.name : existingKeyVault.name
output keyVaultEndpoint string = empty(keyVaultName)
  ? keyVault.outputs.endpoint
  : 'https://${existingKeyVault.name}/${environment().suffixes.keyvaultDns}'

// Storage Account
output storageAccountName string = empty(storageAccountName) ? storageAccount.outputs.name : existingStorageAccount.name

// Container Registry
output containerRegistryName string = empty(containerRegistryName) ? registry.outputs.name : existingRegistry.name
output containerRegistryEndpoint string = empty(containerRegistryName)
  ? registry.outputs.loginServer
  : 'https://${existingRegistry.name}.${environment().suffixes.acrLoginServer}'

// Monitoring
output appInsightsName string = empty(appInsightsName) ? appInsights.outputs.name : existingAppInsights.name
output logAnalyticsName string = empty(appInsightsName) ? logAnalytics.outputs.name : existingLogAnalytics.name
output logAnalyticsWorkspaceId string = empty(appInsightsName) ? logAnalytics.outputs.id : existingLogAnalytics.id
