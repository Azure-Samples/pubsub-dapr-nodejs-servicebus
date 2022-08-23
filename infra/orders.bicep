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

@description('The Subscribing app, Orders')
module appSubscriber 'br/public:app/dapr-containerapp:1.0.1' = {
  name: 'dapr-containerapp-subscriber'
  params: {
    location: location
    containerAppEnvName: containerAppEnvironmentName
    containerAppName: '${name}orders'
    containerImage:  imageName
    azureContainerRegistry: containerRegistryName
    environmentVariables: pubSubAppEnvVars
    targetPort: 5001
    tags: union(tags, {
      'azd-service-name': 'orders'
    })
  }
}

@description('We need to assign the application identity permission to access Key Vault secrets')
module keyVaultAccessPolicyApp './keyvaultpolicies.bicep' = {
  name: 'keyvault-access-app-orders'
  params: {
    keyVaultName: keyVaultName
    principalId: appSubscriber.outputs.userAssignedIdPrincipalId

  }
}

output ORDERS_URI string = 'https://${appSubscriber.outputs.containerAppFQDN}' 
