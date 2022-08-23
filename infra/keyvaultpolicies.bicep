param keyVaultName string
param principalId string

resource keyVaultAccessPolicies 'Microsoft.KeyVault/vaults/accessPolicies@2022-07-01' = if (!empty(principalId)) {
  name: '${keyVaultName}/add'
  properties: {
    accessPolicies: [
      {
        objectId: principalId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
        tenantId: subscription().tenantId
      }
    ]
  }
}
