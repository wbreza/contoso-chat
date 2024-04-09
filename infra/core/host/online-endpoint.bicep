metadata description = 'Creates an Azure Container Registry.'
param name string
param serviceName string
param location string = resourceGroup().location
param tags object = {}
param workspaceName string
param hubWorkspaceName string
param keyVaultName string

resource endpoint 'Microsoft.MachineLearningServices/workspaces/onlineEndpoints@2023-10-01' = {
  name: name
  location: location
  parent: workspace
  kind: 'Managed'
  tags: union(tags, { 'azd-service-name': serviceName })
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    authMode: 'Key'
  }
}

var azureMLDataScientist = resourceId('Microsoft.Authorization/roleDefinitions', 'f6c7c914-8db3-469d-8ca1-694a8f32e121')

resource azureMLDataScientistRoleHub 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, resourceGroup().id, hubWorkspaceName, name, azureMLDataScientist)
  scope: hubWorkspace
  properties: {
    principalId: endpoint.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: azureMLDataScientist
  }
}

resource azureMLDataScientistRoleWorkspace 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, resourceGroup().id, workspaceName, name, azureMLDataScientist)
  scope: workspace
  properties: {
    principalId: endpoint.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: azureMLDataScientist
  }
}

var azureMLWorkspaceConnectionSecretsReader = resourceId(
  'Microsoft.Authorization/roleDefinitions',
  'ea01e6af-a1c1-4350-9563-ad00f8c72ec5'
)

resource azureMLWorkspaceConnectionSecretsReaderRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, resourceGroup().id, workspaceName, name, azureMLWorkspaceConnectionSecretsReader)
  scope: endpoint
  properties: {
    principalId: endpoint.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: azureMLWorkspaceConnectionSecretsReader
  }
}

module keyVaultAccess '../security/keyvault-access.bicep' = {
  name: '${name}-keyvault-access'
  params: {
    keyVaultName: keyVaultName
    principalId: endpoint.identity.principalId
  }
}

resource hubWorkspace 'Microsoft.MachineLearningServices/workspaces@2023-08-01-preview' existing = {
  name: hubWorkspaceName
}

resource workspace 'Microsoft.MachineLearningServices/workspaces@2023-08-01-preview' existing = {
  name: workspaceName
}

output scoringEndpoint string = endpoint.properties.scoringUri
output swaggerEndpoint string = endpoint.properties.swaggerUri
output principalId string = endpoint.identity.principalId