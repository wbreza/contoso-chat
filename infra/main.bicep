targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

param appInsightsName string = ''
param openAiName string = ''
param containerRegistryName string = ''
param cosmosAccountName string = ''
param keyVaultName string = ''
param resourceGroupName string = ''
param searchServiceName string = ''
param storageAccountName string = ''
param endpointName string = ''
param aiProjectName string = ''
param aiHubName string = ''
param logAnalyticsName string = ''

@description('Id of the user or app to assign application roles')
param principalId string = ''

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

module cosmos 'core/database/cosmos/sql/cosmos-sql-db.bicep' = {
  name: 'cosmos'
  scope: rg
  params: {
    accountName: !empty(cosmosAccountName) ? cosmosAccountName : '${abbrs.documentDBDatabaseAccounts}${resourceToken}'
    databaseName: 'products'
    location: location
    tags: union(
      tags,
      {
        defaultExperience: 'Core (SQL)'
        'hidden-cosmos-mmspecial': ''
      }
    )
    keyVaultName: ai.outputs.keyVaultName
    containers: [
      {
        name: 'customers'
        id: 'customers'
        partitionKey: '/id'
      }
    ]
  }
}

module ai 'app/ai.bicep' = {
  name: 'ai'
  scope: rg
  params: {
    environmentName: environmentName
    location: location
    tags: tags
    hubName: aiHubName
    projectName: aiProjectName
    appInsightsName: appInsightsName
    containerRegistryName: containerRegistryName
    keyVaultName: keyVaultName
    storageAccountName: storageAccountName
    logAnalyticsName: logAnalyticsName
    openAiName: openAiName
    searchName: searchServiceName
  }
}

module chat 'app/chat.bicep' = {
  name: 'chat'
  scope: rg
  params: {
    location: location
    tags: tags
    aiHubName: ai.outputs.aiHubName
    aiProjectName: ai.outputs.aiProjectName
    endpointName: !empty(endpointName) ? endpointName : 'mloe-${resourceToken}'
    cosmosAccountName: cosmos.outputs.accountName
    keyVaultName: ai.outputs.keyVaultName
  }
}

module keyVaultAccess 'core/security/keyvault-access.bicep' = {
  name: 'keyvault-access'
  scope: rg
  params: {
    keyVaultName: ai.outputs.keyVaultName
    principalId: ai.outputs.aiProjectPrincipalId
  }
}

module userAcrRolePush 'core/security/role.bicep' = {
  name: 'user-acr-role-push'
  scope: rg
  params: {
    principalId: principalId
    roleDefinitionId: '8311e382-0749-4cb8-b61a-304f252e45ec'
    principalType: 'User'
  }
}

module userAcrRolePull 'core/security/role.bicep' = {
  name: 'user-acr-role-pull'
  scope: rg
  params: {
    principalId: principalId
    roleDefinitionId: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
    principalType: 'User'
  }
}

module userRoleDataScientist 'core/security/role.bicep' = {
  name: 'user-role-data-scientist'
  scope: rg
  params: {
    principalId: principalId
    roleDefinitionId: 'f6c7c914-8db3-469d-8ca1-694a8f32e121'
    principalType: 'User'
  }
}

module userRoleSecretsReader 'core/security/role.bicep' = {
  name: 'user-role-secrets-reader'
  scope: rg
  params: {
    principalId: principalId
    roleDefinitionId: 'ea01e6af-a1c1-4350-9563-ad00f8c72ec5'
    principalType: 'User'
  }
}

module mlServiceRoleDataScientist 'core/security/role.bicep' = {
  name: 'ml-service-role-data-scientist'
  scope: rg
  params: {
    principalId: ai.outputs.aiProjectPrincipalId
    roleDefinitionId: 'f6c7c914-8db3-469d-8ca1-694a8f32e121'
    principalType: 'ServicePrincipal'
  }
}

module mlServiceRoleSecretsReader 'core/security/role.bicep' = {
  name: 'ml-service-role-secrets-reader'
  scope: rg
  params: {
    principalId: ai.outputs.aiProjectPrincipalId
    roleDefinitionId: 'ea01e6af-a1c1-4350-9563-ad00f8c72ec5'
    principalType: 'ServicePrincipal'
  }
}

// output the names of the resources
output AZURE_OPENAI_NAME string = ai.outputs.openAiName
output AZURE_COSMOS_NAME string = cosmos.outputs.accountName
output AZURE_SEARCH_NAME string = ai.outputs.searchName
output AZUREML_HUB_WORKSPACE_NAME string = ai.outputs.aiHubName
output AZUREML_WORKSPACE_NAME string = ai.outputs.aiProjectName

output AZURE_RESOURCE_GROUP string = rg.name
output AI_SERVICES_ENDPOINT string = ai.outputs.openAiEndpoint
output COSMOS_ENDPOINT string = cosmos.outputs.endpoint
output SEARCH_ENDPOINT string = ai.outputs.searchEndpoint
output AZURE_CONTAINER_REGISTRY_NAME string = ai.outputs.registryName
output AZURE_KEY_VAULT_NAME string = ai.outputs.keyVaultName
