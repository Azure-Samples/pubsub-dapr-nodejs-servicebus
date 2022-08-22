param location string
param nameseed string
param tags object

resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' = {
  name: 'kv${nameseed}${uniqueString(resourceGroup().id, location)}'
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    accessPolicies: []
  }

}

output AZURE_KEY_VAULT_NAME string = keyVault.name
output AZURE_KEY_VAULT_ENDPOINT string = keyVault.properties.vaultUri
