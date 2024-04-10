param name string
param displayName string = name
param hubName string
param location string = resourceGroup().location

param tags object = {}

resource project 'Microsoft.MachineLearningServices/workspaces@2024-01-01-preview' = {
  name: name
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
    friendlyName: displayName
    hbiWorkspace: false
    v1LegacyMode: false
    publicNetworkAccess: 'Enabled'
    discoveryUrl: 'https://${location}.api.azureml.ms/discovery'
    // most properties are not allowed for a project workspace: "Project workspace shouldn't define ..."
    hubResourceId: hub.id
  }
}

resource hub 'Microsoft.MachineLearningServices/workspaces@2024-01-01-preview' existing = {
  name: hubName
}

output id string = project.id
output name string = project.name
output principalId string = project.identity.principalId
