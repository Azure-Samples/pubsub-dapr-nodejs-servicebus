param name string
param location string
param containerAppEnvironmentName string
param containerRegistryName string
param appInsightsInstrumentationKey string
param keyVaultName string
param imageName string

var resourceToken = toLower(uniqueString(subscription().id, name, location))
var tags = { 'azd-env-name': name }
var abbrs = loadJsonContent('abbreviations.json')

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
    //Using prescriptive containerAppName name notation with ref to: https://github.com/Azure/azure-dev/issues/517
    //containerAppName: '${abbrs.appContainerApps}checkout-${resourceToken}'
    containerAppName: '${name}checkout'
    containerImage: imageName
    azureContainerRegistry: containerRegistryName
    environmentVariables: pubSubAppEnvVars
    enableIngress: false
    tags: union(tags, {'azd-service-name': 'checkout'})
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
