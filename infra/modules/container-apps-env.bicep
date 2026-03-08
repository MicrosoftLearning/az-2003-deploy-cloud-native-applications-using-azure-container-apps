// Azure Container Apps Environment
// Serverless container platform with built-in Dapr, KEDA scaling, and observability
// KEY DIFFERENTIATOR: No cluster management, no node pools, no Kubernetes complexity

@description('Name of the Container Apps Environment')
param name string

@description('Location for all resources')
param location string

@description('Tags to apply to all resources')
param tags object = {}

@description('Log Analytics Workspace Customer ID')
param logAnalyticsWorkspaceCustomerId string

@description('Log Analytics Workspace Shared Key')
@secure()
param logAnalyticsWorkspaceSharedKey string

@description('Service Bus connection string for Dapr pub/sub')
@secure()
param serviceBusConnectionString string = ''

@description('Service Bus namespace host for managed identity auth (e.g., namespace.servicebus.windows.net)')
param serviceBusNamespaceHost string = ''

@description('Service Bus queue name')
param serviceBusQueueName string = 'telemetry'

@description('Enable Dapr components (requires connection strings)')
param enableDaprComponents bool = false

@description('Use managed identity for Service Bus authentication')
param useServiceBusManagedIdentity bool = false

@description('Client ID of the managed identity for Dapr components')
param managedIdentityClientId string = ''

// ============================================================================
// Container Apps Environment
// This is the serverless equivalent of an AKS cluster - but fully managed!
// ============================================================================

resource containerAppsEnv 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    // Consumption workload profile enables scale-to-zero and pay-per-use
    workloadProfiles: [
      {
        name: 'Consumption'
        workloadProfileType: 'Consumption'
      }
    ]
    // Integrated logging - no additional configuration needed!
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspaceCustomerId
        sharedKey: logAnalyticsWorkspaceSharedKey
      }
    }
    // Enable peer-to-peer encryption for security
    peerTrafficConfiguration: {
      encryption: {
        enabled: true
      }
    }
  }
}

// ============================================================================
// Dapr Component: Pub/Sub (using Azure Service Bus)
// KEY DIFFERENTIATOR: Dapr is native to Container Apps, no Helm installation needed
// Supports both connection string and managed identity authentication
// ============================================================================

// Pub/Sub with managed identity (for Service Bus)
resource daprPubSubManagedIdentity 'Microsoft.App/managedEnvironments/daprComponents@2024-03-01' = if (enableDaprComponents && useServiceBusManagedIdentity && !empty(serviceBusNamespaceHost)) {
  name: 'pubsub'
  parent: containerAppsEnv
  properties: {
    componentType: 'pubsub.azure.servicebus.queues'
    version: 'v1'
    metadata: [
      {
        // Use full FQDN for managed identity auth
        name: 'namespaceName'
        value: contains(serviceBusNamespaceHost, '.servicebus.windows.net') ? serviceBusNamespaceHost : '${serviceBusNamespaceHost}.servicebus.windows.net'
      }
      {
        name: 'azureClientId'
        value: managedIdentityClientId
      }
    ]
    scopes: [
      'ingestion-service'
      'processor-service'
    ]
  }
}

// Pub/Sub with connection string (legacy)
resource daprPubSub 'Microsoft.App/managedEnvironments/daprComponents@2024-03-01' = if (enableDaprComponents && !useServiceBusManagedIdentity && !empty(serviceBusConnectionString)) {
  name: 'pubsub'
  parent: containerAppsEnv
  properties: {
    componentType: 'pubsub.azure.servicebus.queues'
    version: 'v1'
    metadata: [
      {
        name: 'connectionString'
        secretRef: 'servicebus-connection'
      }
    ]
    scopes: [
      'ingestion-service'
      'processor-service'
    ]
    secrets: [
      {
        name: 'servicebus-connection'
        value: serviceBusConnectionString
      }
    ]
  }
}

// ============================================================================
// Outputs
// ============================================================================

output id string = containerAppsEnv.id
output name string = containerAppsEnv.name
output defaultDomain string = containerAppsEnv.properties.defaultDomain
