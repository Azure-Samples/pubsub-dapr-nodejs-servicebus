param location string
param name string
param containerAppEnvironmentName string
param containerRegistryName string
param appInsightsInstrumentationKey string
param keyVaultName string
param imageName string
param tags object = {}

@description('These same environment variables are used by both Publisher and subscriber applications')
var pubSubAppEnvVars = [
  {
    name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
    value: appInsightsInstrumentationKey
  }
  {
    name: 'AZURE_KEY_VAULT_ENDPOINT'
    value: keyVault.properties.vaultUri
  }
]

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

@description('The Publishing app, Checkout')
module appPublisher 'br/public:app/dapr-containerapp:1.0.1' = {
  name: 'dapr-containerapp-publisher'
  params: {
    location: location
    containerAppEnvName: containerAppEnvironmentName
    containerAppName: '${name}checkout'
    containerImage: imageName
    azureContainerRegistry: containerRegistryName
    environmentVariables: pubSubAppEnvVars
    enableIngress: false
    tags: union(tags, {
      'azd-service-name': 'checkout'
    })
  }
}

@description('We need to assign the application identity permission to access Key Vault secrets')
module keyVaultAccessPolicyApp './keyvaultpolicies.bicep' = {
  name: 'keyvault-access-app-checkout'
  params: {
    keyVaultName: keyVaultName
    principalId: appPublisher.outputs.userAssignedIdPrincipalId

  }
}

output CHECKOUT_URI string = appPublisher.outputs.containerAppFQDN
