using './main.bicep'

param environmentName = readEnvironmentVariable('AZURE_ENV_NAME', 'MY_ENV')

param location = readEnvironmentVariable('AZURE_LOCATION', 'eastus2')

param principalId = readEnvironmentVariable('AZURE_PRINCIPAL_ID', '')

param aiResourceGroupName = readEnvironmentVariable('AZUREML_RESOURCE_GROUP', '')
param aiHubName = readEnvironmentVariable('AZUREML_HUB_WORKSPACE_NAME', '')
param aiProjectName = readEnvironmentVariable('AZUREML_WORKSPACE_NAME', '')
param endpointName = readEnvironmentVariable('AZUREML_ENDPOINT_NAME', '')

param openAiName = readEnvironmentVariable('AZURE_OPENAI_NAME', '')
param searchServiceName = readEnvironmentVariable('AZURE_SEARCH_NAME', '')
