// User-Assigned Managed Identity
// Enables secure, passwordless authentication to Azure services

@description('Name of the managed identity')
param name string

@description('Location for all resources')
param location string

@description('Tags to apply to all resources')
param tags object = {}

// ============================================================================
// User-Assigned Managed Identity
// ============================================================================

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: name
  location: location
  tags: tags
}

// ============================================================================
// Outputs
// ============================================================================

output id string = managedIdentity.id
output name string = managedIdentity.name
output principalId string = managedIdentity.properties.principalId
output clientId string = managedIdentity.properties.clientId
