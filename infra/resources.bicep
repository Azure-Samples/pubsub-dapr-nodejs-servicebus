param name string
param location string
param principalId string = ''
param resourceToken string
param tags object
param ordersImageName string = ''
param checkoutImageName string = ''

@description('The environment variables are used by both Publisher and subscriber applications')
var pubSubAppEnvVars = [
  {
    name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
    value: containerAppsEnv.outputs.appInsightsInstrumentationKey
  }
  {
    name: 'AZURE_KEY_VAULT_ENDPOINT'
    value: keyVaultResources.outputs.AZURE_KEY_VAULT_ENDPOINT
  }
]

@description('The container registry is used by azd to store your images')
module registry './containerregistry.bicep' = {
  name: 'container-registry'
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

@description('We need to assign the Subscriber application identity permission to access Key Vault secrets')
module keyVaultAccessPolicyApp './keyvaultpolicies.bicep' = {
  name: 'keyvault-access-app'
  params: {
    keyVaultName: keyVaultResources.outputs.AZURE_KEY_VAULT_NAME
    principalId: appSubscriber.outputs.userAssignedIdPrincipalId
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
  name: 'caEnv-resources'
  params: {
    location: location
    nameseed: name
    applicationEntityName: 'orders'
    daprComponentType: 'pubsub.azure.servicebus'
    tags: tags
  }
}

@description('The Publishing app, Checkout')
module appPublisher 'br/public:app/dapr-containerapp:1.0.1' = {
  name: 'publisher'
  params: {
    location: location
    containerAppEnvName: containerAppsEnv.outputs.containerAppEnvironmentName
    containerAppName: 'publisher-checkout'
    containerImage: !empty(checkoutImageName) ? checkoutImageName : 'nginx:latest'
    azureContainerRegistry: registry.outputs.AZURE_CONTAINER_REGISTRY_NAME
    environmentVariables: pubSubAppEnvVars
    enableIngress: false
    tags: union(tags, {
      'azd-service-name': 'checkout'
    })
  }
}

@description('The Subscribing app, Orders')
module appSubscriber 'br/public:app/dapr-containerapp:1.0.1' = {
  name: 'subscriber'
  params: {
    location: location
    containerAppEnvName: containerAppsEnv.outputs.containerAppEnvironmentName
    containerAppName: 'subscriber-orders'
    containerImage:  !empty(ordersImageName) ? ordersImageName : 'nginx:latest'
    azureContainerRegistry: registry.outputs.AZURE_CONTAINER_REGISTRY_NAME
    environmentVariables: pubSubAppEnvVars
    targetPort: 5001
    tags: union(tags, {
      'azd-service-name': 'orders'
    })
  }
}

output AZURE_COSMOS_CONNECTION_STRING_KEY string = 'AZURE-COSMOS-CONNECTION-STRING'
output AZURE_KEY_VAULT_ENDPOINT string = keyVaultResources.outputs.AZURE_KEY_VAULT_ENDPOINT
output APPINSIGHTS_INSTRUMENTATIONKEY string = containerAppsEnv.outputs.appInsightsInstrumentationKey
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = registry.outputs.AZURE_CONTAINER_REGISTRY_ENDPOINT
output AZURE_CONTAINER_REGISTRY_NAME string = registry.outputs.AZURE_CONTAINER_REGISTRY_NAME
output CHECKOUT_APP_URI string = appPublisher.outputs.containerAppFQDN
output ORDERS_APP_URI string = appSubscriber.outputs.containerAppFQDN
