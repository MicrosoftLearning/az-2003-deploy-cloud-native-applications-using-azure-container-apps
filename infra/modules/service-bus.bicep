// Azure Service Bus for reliable message queuing
// Replaces Event Hub for message-based event processing

@description('Name of the Service Bus Namespace')
param namespaceName string

@description('Location for all resources')
param location string

@description('Tags to apply to all resources')
param tags object = {}

@description('SKU for the Service Bus Namespace')
@allowed(['Basic', 'Standard', 'Premium'])
param sku string = 'Standard'

@description('Principal ID of the managed identity for Service Bus roles')
param managedIdentityPrincipalId string = ''

// ============================================================================
// Service Bus Namespace
// ============================================================================

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' = {
  name: namespaceName
  location: location
  tags: tags
  sku: {
    name: sku
    tier: sku
  }
  properties: {
    minimumTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false // Using managed identity is recommended for production
  }
}

// ============================================================================
// Queue for Telemetry
// ============================================================================

resource telemetryQueue 'Microsoft.ServiceBus/namespaces/queues@2022-10-01-preview' = {
  name: 'telemetry'
  parent: serviceBusNamespace
  properties: {
    lockDuration: 'PT1M'
    maxSizeInMegabytes: 1024
    requiresDuplicateDetection: false
    requiresSession: false
    defaultMessageTimeToLive: 'P1D'
    deadLetteringOnMessageExpiration: true
    enableBatchedOperations: true
    duplicateDetectionHistoryTimeWindow: 'PT10M'
    maxDeliveryCount: 10
    status: 'Active'
    enablePartitioning: false
  }
}

// ============================================================================
// Authorization Rules
// ============================================================================

resource sendListenRule 'Microsoft.ServiceBus/namespaces/authorizationRules@2022-10-01-preview' = {
  name: 'SendListenPolicy'
  parent: serviceBusNamespace
  properties: {
    rights: [
      'Listen'
      'Send'
    ]
  }
}

// ============================================================================
// RBAC: Service Bus Data Receiver Role for Managed Identity
// Required for Azure Entra ID authentication
// ============================================================================

// Azure Service Bus Data Receiver role
var serviceBusDataReceiverRoleId = '4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0'

resource serviceBusDataReceiverRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(managedIdentityPrincipalId)) {
  name: guid(serviceBusNamespace.id, managedIdentityPrincipalId, serviceBusDataReceiverRoleId)
  scope: serviceBusNamespace
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', serviceBusDataReceiverRoleId)
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Azure Service Bus Data Sender role (for sending messages)
var serviceBusDataSenderRoleId = '69a216fc-b8fb-44d8-bc22-1f3c2cd27a39'

resource serviceBusDataSenderRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(managedIdentityPrincipalId)) {
  name: guid(serviceBusNamespace.id, managedIdentityPrincipalId, serviceBusDataSenderRoleId)
  scope: serviceBusNamespace
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', serviceBusDataSenderRoleId)
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// ============================================================================
// Outputs
// ============================================================================

output namespaceId string = serviceBusNamespace.id
output namespaceName string = serviceBusNamespace.name
output namespaceHost string = '${serviceBusNamespace.name}.servicebus.windows.net'
output telemetryQueueName string = telemetryQueue.name

#disable-next-line outputs-should-not-contain-secrets // Used internally for Container Apps secrets
output connectionString string = sendListenRule.listKeys().primaryConnectionString
