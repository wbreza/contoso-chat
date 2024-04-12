import {resourceReference} from '../core/types.bicep'

param resourceToken string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('The AI Hub resource name. If ommited a name will be generated.')
param hubName string = ''
@description('The AI Project resource name. If ommited a name will be generated.')
param projectName string = ''
@description('The Key Vault resource name. If ommited a name will be generated.')
param keyVaultName string = ''
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
param existingResources aiDependentResourceMap?

@description('A map of existing resources to use for the AI Hub')
@export()
type aiDependentResourceMap = {
  keyVault: resourceReference
  storageAccount: resourceReference
  applicationInsights: resourceReference?
  containerRegistry: resourceReference?
  openAi: resourceReference?
  search: resourceReference?
}

@description('Creates or gets the AI dependencies')
module aiHubDependencies 'ai-dependencies.bicep' = {
  name: 'ai-dependencies'
  params: {
    resourceToken: resourceToken
    location: location
    tags: tags
    storageAccountName: empty(hubName)
      ? storageAccountName
      : !empty(existingHub.properties.storageAccount) ? last(split(existingHub.properties.storageAccount, '/')) : ''
    keyVaultName: empty(hubName)
      ? keyVaultName
      : !empty(existingHub.properties.keyVault) ? last(split(existingHub.properties.keyVault, '/')) : ''
    appInsightsName: empty(hubName)
      ? appInsightsName
      : !empty(existingHub.properties.applicationInsights)
          ? last(split(existingHub.properties.applicationInsights, '/'))
          : ''
    containerRegistryName: empty(hubName)
      ? containerRegistryName
      : !empty(existingHub.properties.containerRegistry)
          ? last(split(existingHub.properties.containerRegistry, '/'))
          : ''
    openAiName: openAiName
    searchName: searchName
  }
}

module aiHub '../core/ai/hub.bicep' =
  if (empty(hubName)) {
    name: 'aiHub'
    params: {
      location: location
      tags: tags
      name: !empty(hubName) ? hubName : 'ai-hub-${resourceToken}'
      displayName: !empty(hubName) ? hubName : 'ai-hub-${resourceToken}'
      keyVaultName: aiHubDependencies.outputs.keyVaultName
      storageAccountName: aiHubDependencies.outputs.storageAccountName
      appInsightsName: aiHubDependencies.outputs.appInsightsName
      containerRegistryName: aiHubDependencies.outputs.containerRegistryName
      openAiName: aiHubDependencies.outputs.openAiName
      aiSearchName: aiHubDependencies.outputs.searchName
    }
  }

module aiProject '../core/ai/project.bicep' =
  if (empty(projectName)) {
    name: 'aiProject'
    params: {
      location: location
      tags: tags
      name: !empty(projectName) ? projectName : 'ai-project-${resourceToken}'
      displayName: !empty(projectName) ? projectName : 'ai-project-${resourceToken}'
      hubName: !empty(hubName) ? hubName : aiHub.outputs.name
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

// Core Outputs
output hubName string = !empty(hubName) ? existingHub.name : aiHub.outputs.name
output hubPrincipalId string = !empty(hubName) ? existingHub.identity.principalId : aiHub.outputs.principalId
output projectName string = !empty(projectName) ? existingProject.name : aiProject.outputs.name
output projectPrincipalId string = !empty(projectName)
  ? existingProject.identity.principalId
  : aiProject.outputs.principalId

// Dependency Outputs
output keyVaultName string = aiHubDependencies.outputs.keyVaultName
output keyVaultEndpoint string = aiHubDependencies.outputs.keyVaultEndpoint
output logAnalyticsName string = aiHubDependencies.outputs.logAnalyticsName
output appInsightsName string = aiHubDependencies.outputs.appInsightsName
output containerRegistryName string = aiHubDependencies.outputs.containerRegistryName
output containerRegistryEndpoint string = aiHubDependencies.outputs.containerRegistryEndpoint
output storageAccountName string = aiHubDependencies.outputs.storageAccountName
output openAiName string = aiHubDependencies.outputs.openAiName
output openAiEndpoint string = aiHubDependencies.outputs.openAiEndpoint
output searchName string = aiHubDependencies.outputs.searchName
output searchEndpoint string = aiHubDependencies.outputs.searchEndpoint
