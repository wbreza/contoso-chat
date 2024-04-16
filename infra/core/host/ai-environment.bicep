import { resourceReference } from '../types.bicep'

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
param existingResources aiDependentResourceMap = {}

@description('A map of existing resources to use for the AI Hub')
@export()
type aiDependentResourceMap = {
  hub: resourceReference?
  project: resourceReference?
  keyVault: resourceReference?
  storageAccount: resourceReference?
  logAnalyticsWorkspace: resourceReference?
  applicationInsights: resourceReference?
  containerRegistry: resourceReference?
  openAi: resourceReference?
  search: resourceReference?
}

var hasHub = !empty(existingResources.hub) && !empty(existingResources.hub.name)
var hasProject = !empty(existingResources.project) && !empty(existingResources.project.name)
var hasKeyVault = !empty(existingResources.keyVault) && !empty(existingResources.keyVault.name)
var hasStorageAccount = !empty(existingResources.storageAccount) && !empty(existingResources.storageAccount.name)
var hasLogAnalytics = !empty(existingResources.logAnalyticsWorkspace) && !empty(existingResources.logAnalyticsWorkspace.name)
var hasAppInsights = !empty(existingResources.applicationInsights) && !empty(existingResources.applicationInsights.name)
var hasContainerRegistry = !empty(existingResources.containerRegistry) && !empty(existingResources.containerRegistry.name)
var hasOpenAi = !empty(existingResources.openAi) && !empty(existingResources.openAi.name)
var hasSearch = !empty(existingResources.search) && !empty(existingResources.search.name)

module hub '../ai/hub.bicep' =
  if (!hasHub) {
    name: 'hub'
    params: {
      location: location
      tags: tags
      name: hubName
      displayName: hubName
      keyVaultName: hasKeyVault ? existingResources.keyVault.name : keyVaultName
      storageAccountName: hasStorageAccount ? existingResources.storageAccount.name : storageAccountName
      appInsightsName: hasAppInsights ? existingResources.applicationInsights.name : appInsightsName
      containerRegistryName: hasContainerRegistry ? existingResources.containerRegistry.name : containerRegistryName
      openAiName: hasOpenAi ? existingResources.openAi.name : openAiName
      aiSearchName: hasSearch ? existingResources.search.name : searchName
    }
  }

module project '../ai/project.bicep' =
  if (!hasProject) {
    name: 'project'
    params: {
      location: location
      tags: tags
      name: projectName
      displayName: projectName
      hubName: hasHub ? existingHub.name : hub.outputs.name
    }
  }

module keyVault '../security/keyvault.bicep' =
  if (!hasHub && !hasKeyVault) {
    name: 'keyvault'
    params: {
      location: location
      tags: tags
      name: keyVaultName
    }
  }

module storageAccount '../storage/storage-account.bicep' =
  if (!hasHub && !hasStorageAccount) {
    name: 'storageAccount'
    params: {
      location: location
      tags: tags
      name: storageAccountName
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

module logAnalytics '../monitor/loganalytics.bicep' =
  if (!hasHub && !hasAppInsights && !hasLogAnalytics) {
    name: 'logAnalytics'
    params: {
      location: location
      tags: tags
      name: logAnalyticsName
    }
  }

module appInsights '../monitor/applicationinsights.bicep' =
  if (!hasHub && !hasAppInsights) {
    name: 'appInsights'
    params: {
      location: location
      tags: tags
      name: appInsightsName
      logAnalyticsWorkspaceId: !empty(existingResources.logAnalyticsWorkspace)
        ? existingLogAnalytics.name
        : logAnalytics.outputs.name
    }
  }

module containerRegistry '../host/container-registry.bicep' =
  if (!hasHub && !hasContainerRegistry) {
    name: 'containerRegistry'
    params: {
      location: location
      tags: tags
      name: containerRegistryName
    }
  }

module openAi '../ai/cognitiveservices.bicep' =
  if (!hasOpenAi) {
    name: 'openAi'
    params: {
      location: location
      tags: tags
      name: openAiName
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

module search '../search/search-services.bicep' =
  if (!hasSearch) {
    name: 'search'
    params: {
      location: location
      tags: tags
      name: searchName
      semanticSearch: 'free'
    }
  }

resource existingHub 'Microsoft.MachineLearningServices/workspaces@2024-01-01-preview' existing =
  if (hasHub) {
    name: existingResources.hub.name
    scope: resourceGroup(existingResources.hub.resourceGroup)
  }

resource existingProject 'Microsoft.MachineLearningServices/workspaces@2024-01-01-preview' existing =
  if (hasProject) {
    name: projectName
  }

resource existingKeyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing =
  if (hasHub || hasKeyVault) {
    name: existingResources.keyVault.name
    scope: resourceGroup(existingResources.keyVault.resourceGroup)
  }

resource existingStorageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing =
  if (hasStorageAccount) {
    name: existingResources.storageAccount.name
    scope: resourceGroup(existingResources.storageAccount.resourceGroup)
  }

resource existingContainerRegistry 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' existing =
  if (hasContainerRegistry) {
    name: existingResources.containerRegistry.name
    scope: resourceGroup(existingResources.containerRegistry.resourceGroup)
  }

resource existingLogAnalytics 'Microsoft.OperationalInsights/workspaces@2020-08-01' existing =
  if (hasLogAnalytics) {
    name: existingResources.logAnalyticsWorkspace.name
    scope: resourceGroup(existingResources.logAnalyticsWorkspace.resourceGroup)
  }

resource existingAppInsights 'Microsoft.Insights/components@2020-02-02' existing =
  if (hasAppInsights) {
    name: existingResources.applicationInsights.name
    scope: resourceGroup(existingResources.applicationInsights.resourceGroup)
  }

resource existingOpenAi 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' existing =
  if (hasOpenAi) {
    name: existingResources.openAi.name
    scope: resourceGroup(existingResources.openAi.resourceGroup)
  }

resource existingSearch 'Microsoft.Search/searchServices@2021-04-01-preview' existing =
  if (hasSearch) {
    name: existingResources.search.name
    scope: resourceGroup(existingResources.search.resourceGroup)
  }

// Outputs
// Resource Group
output resourceGroupName string = resourceGroup().name

// Hub
output hubName string = hasHub ? existingHub.name : hub.outputs.name
output hubPrincipalId string = hasHub ? existingHub.identity.principalId : hub.outputs.principalId

// Project
output projectName string = hasProject ? existingProject.name : project.outputs.name
output projectPrincipalId string = hasProject ? existingProject.identity.principalId : project.outputs.principalId

// Key Vault
output keyVaultName string = hasKeyVault ? existingKeyVault.name : keyVault.outputs.name
output keyVaultEndpoint string = hasKeyVault
  ? 'https://${existingKeyVault.name}.${environment().suffixes.acrLoginServer}'
  : keyVault.outputs.endpoint

// Log Analytics
output logAnalyticsName string = hasLogAnalytics ? existingLogAnalytics.name : logAnalytics.outputs.name

// Application Insights
output appInsightsName string = hasAppInsights ? existingAppInsights.name : appInsights.outputs.name

// Container Registry
output containerRegistryName string = hasContainerRegistry
  ? existingContainerRegistry.name
  : containerRegistry.outputs.name
output containerRegistryEndpoint string = hasContainerRegistry
  ? 'https://${existingContainerRegistry.name}.${environment().suffixes.acrLoginServer}'
  : 'https://${containerRegistry.outputs.name}.${environment().suffixes.acrLoginServer}'

// Storage Account
output storageAccountName string = hasStorageAccount ? existingStorageAccount.name : storageAccount.outputs.name

// Open AI
output openAiName string = hasOpenAi ? existingOpenAi.name : openAi.outputs.name
output openAiEndpoint string = !empty(existingResources.openAi)
  ? existingOpenAi.properties.endpoint
  : openAi.outputs.endpoint

// Search
output searchName string = hasSearch ? existingSearch.name : search.outputs.name
output searchEndpoint string = hasSearch ? 'https://${existingSearch.name}.search.windows.net' : search.outputs.endpoint
