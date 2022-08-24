param location string
param principalId string = ''
param resourceToken string
param tags object

@description('The container registry is used by azd to store your images')
module registry './containerregistry.bicep' = {
  name: 'container-registry-resources'
  params: {
    location: location
    tags: tags
    resourceToken: resourceToken
  }
}

@description('Key Vault is used by the subscriber application for secrets')
module keyVaultResources './keyvault.bicep' = {
  name: 'keyvault-resources'
  params: {
    location: location
    tags: tags
    resourceToken: resourceToken
  }
}

@description('We also want to grant the developer access to the secrets through the PrincipalId parameter')
module keyVaultAccessPolicyDev './keyvaultpolicies.bicep' = {
  name: 'keyvault-access-dev'
  params: {
    keyVaultName: keyVaultResources.outputs.AZURE_KEY_VAULT_NAME
    principalId: principalId
  }
}

@description('The container apps environment is where the applications will be deployed to')
module containerAppsEnv 'br/public:app/dapr-containerapps-environment:1.0.1' = {
  name: 'caenv-resources'
  params: {
    location: location
    nameseed: resourceToken
    applicationEntityName: 'orders'
    daprComponentName: 'orderpubsub'
    daprComponentType: 'pubsub.azure.servicebus'
    tags: tags
  }
}

output AZURE_COSMOS_CONNECTION_STRING_KEY string = 'AZURE-COSMOS-CONNECTION-STRING'
output AZURE_KEY_VAULT_ENDPOINT string = keyVaultResources.outputs.AZURE_KEY_VAULT_ENDPOINT
output AZURE_KEY_VAULT_NAME string = keyVaultResources.outputs.AZURE_KEY_VAULT_NAME
output APPINSIGHTS_INSTRUMENTATIONKEY string = containerAppsEnv.outputs.appInsightsInstrumentationKey
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = registry.outputs.AZURE_CONTAINER_REGISTRY_ENDPOINT
output AZURE_CONTAINER_REGISTRY_NAME string = registry.outputs.AZURE_CONTAINER_REGISTRY_NAME
output AZURE_CONTAINERAPPS_ENVIRONMENT_NAME string = containerAppsEnv.outputs.containerAppEnvironmentName
