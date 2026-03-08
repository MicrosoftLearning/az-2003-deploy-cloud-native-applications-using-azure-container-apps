// Log Analytics Workspace for Container Apps monitoring
// Provides integrated logging without additional configuration

@description('Name of the Log Analytics workspace')
param name string

@description('Location for all resources')
param location string

@description('Tags to apply to all resources')
param tags object = {}

@description('Retention period in days')
@minValue(30)
@maxValue(730)
param retentionInDays int = 30

// ============================================================================
// Log Analytics Workspace
// ============================================================================

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: retentionInDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: 1 // Limit for demo purposes
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// ============================================================================
// Outputs
// ============================================================================

output id string = logAnalytics.id
output name string = logAnalytics.name
output customerId string = logAnalytics.properties.customerId

#disable-next-line outputs-should-not-contain-secrets // Used internally for Container Apps Environment
output primarySharedKey string = logAnalytics.listKeys().primarySharedKey
