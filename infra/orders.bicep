@description('This is the azd environment name')
param name string
param location string
param containerAppEnvironmentName string
param containerRegistryName string
param appInsightsInstrumentationKey string
param keyVaultName string
param imageName string

param appName string = 'orders'

// var resourceToken = toLower(uniqueString(subscription().id, name, location))
// var abbrs = loadJsonContent('abbreviations.json')
var tags = { 'azd-env-name': name }


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

@description('The Subscribing app')
module appSubscriber 'br/public:app/dapr-containerapp:1.0.1' = {
  name: 'dapr-containerapp-subscriber'
  params: {
    location: location
    containerAppEnvName: containerAppEnvironmentName
    //Using prescriptive containerAppName name notation with ref to: https://github.com/Azure/azure-dev/issues/517
    //containerAppName: '${abbrs.appContainerApps}${appName}-${resourceToken}'
    containerAppName: '${name}${appName}'
    containerImage:  imageName
    azureContainerRegistry: containerRegistryName
    environmentVariables: pubSubAppEnvVars
    targetPort: 5001
    tags: union(tags, {'azd-service-name': appName})
  }
}

@description('We need to assign the application identity permission to access Key Vault secrets')
module keyVaultAccessPolicyApp './keyvaultpolicies.bicep' = {
  name: 'keyvault-access-app-${appName}'
  params: {
    keyVaultName: keyVaultName
    principalId: appSubscriber.outputs.userAssignedIdPrincipalId

  }
}

output ORDERS_URI string = 'https://${appSubscriber.outputs.containerAppFQDN}' 
