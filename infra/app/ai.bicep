@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('The AI Hub resource name. If ommited a name will be generated.')
param hubName string = ''
@description('The AI Project resource name. If ommited a name will be generated.')
param projectName string = ''
@description('The Key Vault resource name. If ommited a name will be generated.')
param keyVaultName string = ''
@description('The Log Analytics resource name. If ommited a name will be generated.')
param logAnalyticsName string = ''
@description('The Application Insights resource name. If ommited a name will be generated.')
param appInsightsName string = ''
@description('The Container Registry resource name. If ommited a name will be generated.')
param containerRegistryName string = ''
@description('The Open AI resource name. If ommited a name will be generated.')
param storageAccountName string = ''
@description('The Open AI resource name. If ommited a name will be generated.')
param openAiName string = ''
@description('The Azure Search resource name. If ommited a name will be generated.')
param searchName string = ''
param tags object = {}

var abbrs = loadJsonContent('../abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var aiHubName = empty(hubName) ? 'ai-hub-${environmentName}' : hubName
var aiProjectName = empty(projectName) ? 'ai-proj-${environmentName}' : projectName

module aiHub '../core/ai/hub.bicep' =
  if (empty(hubName)) {
    name: 'aiHub'
    params: {
      location: location
      tags: tags
      name: aiHubName
      displayName: aiHubName
      keyVaultName: empty(keyVaultName) ? keyVault.outputs.name : keyVaultName
      storageAccountName: empty(storageAccountName) ? storageAccount.outputs.name : storageAccountName
      appInsightsName: empty(appInsightsName) ? appInsights.outputs.name : appInsightsName
      containerRegistryName: empty(containerRegistryName) ? registry.outputs.name : containerRegistryName
      openAiName: empty(openAiName) ? openAi.outputs.name : openAiName
      aiSearchName: empty(searchName) ? search.outputs.name : searchName
    }
  }

module aiProject '../core/ai/project.bicep' =
  if (empty(projectName)) {
    name: 'aiProject'
    params: {
      location: location
      tags: tags
      name: aiProjectName
      displayName: aiProjectName
      hubName: aiHub.outputs.name
    }
  }

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
  if (empty(logAnalyticsName)) {
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
      logAnalyticsWorkspaceId: empty(logAnalyticsName) ? logAnalytics.outputs.id : existingLogAnalytics.id
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

module registry '../core/host/container-registry.bicep' =
  if (empty(containerRegistryName)) {
    name: 'containerRegistry'
    params: {
      location: location
      tags: tags
      name: '${abbrs.containerRegistryRegistries}${resourceToken}'
    }
  }

resource existingHub 'Microsoft.MachineLearningServices/workspaces@2024-01-01-preview' existing =
  if (!empty(hubName)) {
    name: hubName
  }

resource existingProject 'Microsoft.MachineLearningServices/workspaces@2024-01-01-preview' existing =
  if (!empty(projectName)) {
    name: projectName
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
  if (!empty(logAnalyticsName)) {
    name: logAnalyticsName
  }

resource existingAppInsights 'Microsoft.Insights/components@2020-02-02' existing =
  if (!empty(appInsightsName)) {
    name: appInsightsName
  }

resource existingOpenAi 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' existing =
  if (!empty(openAiName)) {
    name: openAiName
  }

// Hub
output aiHubName string = empty(hubName) ? aiHub.outputs.name : existingHub.name
output aiHubPrincipalId string = empty(hubName) ? aiHub.outputs.principalId : existingHub.identity.principalId
// Project
output aiProjectName string = empty(projectName) ? aiProject.outputs.name : existingProject.name
output aiProjectPrincipalId string = empty(projectName) ? aiProject.outputs.principalId : existingProject.identity.principalId
// Open AI Services
output openAiName string = empty(openAiName) ? openAi.outputs.name : existingOpenAi.name
output openAiEndpoint string = empty(openAiName) ? openAi.outputs.endpoint : existingOpenAi.properties.endpoint
// Key Vault
output keyVaultName string = empty(keyVaultName) ? keyVault.outputs.name : existingKeyVault.name
output keyVaultEndpoint string = empty(keyVaultName) ? keyVault.outputs.endpoint : existingKeyVault.properties.vaultUri
// Storage Account
output storageAccountName string = empty(storageAccountName) ? storageAccount.outputs.name : existingStorageAccount.name
// Container Registry
output registryName string = empty(containerRegistryName) ? registry.outputs.name : existingRegistry.name
output registryEndpoint string = empty(containerRegistryName) ? registry.outputs.loginServer : existingRegistry.properties.loginServer
// Monitoring
output appInsightsName string = empty(appInsightsName) ? appInsights.outputs.name : existingAppInsights.name
output logAnalyticsName string = empty(logAnalyticsName) ? logAnalytics.outputs.name : existingLogAnalytics.name
output logAnalyticsWorkspaceId string = empty(logAnalyticsName) ? logAnalytics.outputs.id : existingLogAnalytics.id
// AI Search
output searchName string = empty(searchName) ? search.outputs.name : search.outputs.name
output searchEndpoint string = empty(searchName) ? search.outputs.endpoint : search.outputs.endpoint
