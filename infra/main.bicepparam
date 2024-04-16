using './main.bicep'

param environmentName = readEnvironmentVariable('AZURE_ENV_NAME', 'MY_ENV')

param location = readEnvironmentVariable('AZURE_LOCATION', 'eastus2')

param principalId = readEnvironmentVariable('AZURE_PRINCIPAL_ID', '')

param aiResourceGroupName = readEnvironmentVariable('AZUREML_RESOURCE_GROUP', '')
param aiHubName = readEnvironmentVariable('MY_AI_HUB_NAME', '')
param aiProjectName = readEnvironmentVariable('MY_AI_PROJECT_NAME', '')
param endpointName = readEnvironmentVariable('AZUREML_ENDPOINT_NAME', '')

param openAiName = readEnvironmentVariable('AZURE_OPENAI_NAME', '')
param searchServiceName = readEnvironmentVariable('AZURE_SEARCH_NAME', '')

param existingResources = {
  hub: {
    name: readEnvironmentVariable('AZUREML_AI_HUB_NAME', '')
    resourceGroup: readEnvironmentVariable('AZUREML_RESOURCE_GROUP', '')
  }
  project: {
    name: readEnvironmentVariable('AZUREML_AI_PROJECT_NAME', '')
    resourceGroup: readEnvironmentVariable('AZUREML_RESOURCE_GROUP', '')
  }
  openAi: {
    name: readEnvironmentVariable('AZURE_OPENAI_NAME', '')
    resourceGroup: readEnvironmentVariable('AZUREML_RESOURCE_GROUP', '')
  }
  search: {
    name: readEnvironmentVariable('AZURE_SEARCH_NAME', '')
    resourceGroup: readEnvironmentVariable('AZUREML_RESOURCE_GROUP', '')
  }
  containerRegistry: {
    name: readEnvironmentVariable('AZURE_CONTAINER_REGISTRY_NAME', '')
    resourceGroup: readEnvironmentVariable('AZUREML_RESOURCE_GROUP', '')
  }
  keyVault: {
    name: readEnvironmentVariable('AZURE_KEYVAULT_NAME', '')
    resourceGroup: readEnvironmentVariable('AZUREML_RESOURCE_GROUP', '')
  }
  applicationInsights: {
    name: readEnvironmentVariable('AZURE_APPINSIGHTS_NAME', '')
    resourceGroup: readEnvironmentVariable('AZUREML_RESOURCE_GROUP', '')
  }
  storageAccount: {
    name: readEnvironmentVariable('AZURE_STORAGE_ACCOUNT_NAME', '')
    resourceGroup: readEnvironmentVariable('AZUREML_RESOURCE_GROUP', '')
  }
  logAnalyticsWorkspace: {
    name: readEnvironmentVariable('AZURE_LOG_ANALYTICS_WORKSPACE_NAME', '')
    resourceGroup: readEnvironmentVariable('AZUREML_RESOURCE_GROUP', '')
  }
}
