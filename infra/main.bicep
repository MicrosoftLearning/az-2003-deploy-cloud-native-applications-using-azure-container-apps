// Contoso Analytics: Event-Driven Microservices with Azure Container Apps
// Main Bicep deployment template
// Uses Key Vault and Managed Identity for secure secret management

targetScope = 'subscription'

// ============================================================================
// Parameters
// ============================================================================

@minLength(1)
@maxLength(64)
@description('Name of the environment (e.g., dev, staging, prod)')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Name of the resource group')
param resourceGroupName string = ''

@description('Tags to apply to all resources')
param tags object = {
  'azd-env-name': environmentName
  SecurityControl: 'Ignore'
}

// Container Apps specific parameters
@description('Minimum replicas for container apps (0 enables scale-to-zero)')
@minValue(0)
@maxValue(30)
param minReplicas int = 0

@description('Maximum replicas for container apps')
@minValue(1)
@maxValue(300)
param maxReplicas int = 100

@description('Principal ID of the deploying user for Key Vault access')
param principalId string = ''

@description('Container image for demo-job (set by azd deploy, uses placeholder during initial provisioning)')
param demoJobImage string = ''

// ============================================================================
// Variables
// ============================================================================

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

// Demo job image - uses provided image or falls back to placeholder for initial provisioning
var resolvedDemoJobImage = !empty(demoJobImage) ? demoJobImage : 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

var defaultTags = union(tags, {
  'azd-env-name': environmentName
  'demo-scenario': 'contoso-analytics'
})

// Resource names
var rgName = !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
var containerRegistryName = '${abbrs.containerRegistryRegistries}${resourceToken}'
var containerAppsEnvName = '${abbrs.appManagedEnvironments}${resourceToken}'
var logAnalyticsName = '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
var serviceBusNamespaceName = '${abbrs.serviceBusNamespaces}${resourceToken}'
var managedIdentityName = '${abbrs.managedIdentityUserAssignedIdentities}${resourceToken}'
var keyVaultName = 'kv-${resourceToken}'

// ============================================================================
// Resource Group
// ============================================================================

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgName
  location: location
  tags: defaultTags
}

// ============================================================================
// Monitoring - Log Analytics Workspace
// ============================================================================

module logAnalytics './modules/log-analytics.bicep' = {
  name: 'log-analytics'
  scope: rg
  params: {
    name: logAnalyticsName
    location: location
    tags: defaultTags
  }
}

// ============================================================================
// User-Assigned Managed Identity (for secure access to Key Vault)
// ============================================================================

module managedIdentity './modules/managed-identity.bicep' = {
  name: 'managed-identity'
  scope: rg
  params: {
    name: managedIdentityName
    location: location
    tags: defaultTags
  }
}

// ============================================================================
// Container Registry (for storing container images)
// ============================================================================

module containerRegistry './modules/container-registry.bicep' = {
  name: 'container-registry'
  scope: rg
  params: {
    name: containerRegistryName
    location: location
    tags: defaultTags
    managedIdentityPrincipalId: managedIdentity.outputs.principalId
  }
}

// ============================================================================
// Container Apps Environment (serverless container platform)
// ============================================================================

module containerAppsEnv './modules/container-apps-env.bicep' = {
  name: 'container-apps-env'
  scope: rg
  params: {
    name: containerAppsEnvName
    location: location
    tags: defaultTags
    logAnalyticsWorkspaceCustomerId: logAnalytics.outputs.customerId
    logAnalyticsWorkspaceSharedKey: logAnalytics.outputs.primarySharedKey
    // Enable Dapr components with managed identity
    enableDaprComponents: true
    managedIdentityClientId: managedIdentity.outputs.clientId
    // Service Bus with managed identity
    useServiceBusManagedIdentity: true
    serviceBusNamespaceHost: serviceBus.outputs.namespaceHost
    serviceBusQueueName: 'telemetry'
  }
}

// ============================================================================
// Service Bus (reliable message queuing)
// ============================================================================

module serviceBus './modules/service-bus.bicep' = {
  name: 'service-bus'
  scope: rg
  params: {
    namespaceName: serviceBusNamespaceName
    location: location
    tags: defaultTags
    managedIdentityPrincipalId: managedIdentity.outputs.principalId
  }
}



// ============================================================================
// Key Vault (secure secret management)
// Stores all connection strings and keys, accessed by Container Apps via managed identity
// ============================================================================

module keyVault './modules/key-vault.bicep' = {
  name: 'key-vault'
  scope: rg
  params: {
    name: keyVaultName
    location: location
    tags: defaultTags
    managedIdentityPrincipalId: managedIdentity.outputs.principalId
    deployingUserPrincipalId: principalId
    serviceBusConnectionString: serviceBus.outputs.connectionString
    logAnalyticsSharedKey: logAnalytics.outputs.primarySharedKey
  }
}

// ============================================================================
// Container Apps (microservices)
// ============================================================================

// Ingestion Service - Consumes messages from Service Bus
module ingestionService './modules/container-app.bicep' = {
  name: 'ingestion-service'
  scope: rg
  params: {
    name: 'ingestion-service'
    location: location
    tags: defaultTags
    serviceName: 'ingestion-service'
    containerAppsEnvironmentId: containerAppsEnv.outputs.id
    containerRegistryName: containerRegistry.outputs.name
    containerImage: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest' // Placeholder
    targetPort: 8080
    minReplicas: 1  // Keep at least 1 replica for continuous message consumption
    maxReplicas: maxReplicas
    daprEnabled: true
    daprAppId: 'ingestion-service'
    userAssignedIdentityId: managedIdentity.outputs.id
    // HTTP scaling rule - low threshold for demo visibility
    scaleRules: [
      {
        name: 'http-scaler'
        http: {
          metadata: {
            concurrentRequests: '2'  // Low threshold to easily trigger scaling in demos
          }
        }
      }
    ]
    env: [
      {
        name: 'SERVICEBUS_NAMESPACE'
        value: serviceBus.outputs.namespaceHost
      }
      {
        name: 'SERVICEBUS_QUEUE_NAME'
        value: 'telemetry'
      }
      {
        name: 'AZURE_CLIENT_ID'
        value: managedIdentity.outputs.clientId
      }
    ]
  }
}

// Dashboard - React frontend
module dashboard './modules/container-app.bicep' = {
  name: 'dashboard'
  scope: rg
  params: {
    name: 'dashboard'
    location: location
    tags: defaultTags
    serviceName: 'dashboard'
    containerAppsEnvironmentId: containerAppsEnv.outputs.id
    containerRegistryName: containerRegistry.outputs.name
    containerImage: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest' // Placeholder
    targetPort: 80
    minReplicas: 1
    maxReplicas: 5
    daprEnabled: false // Static frontend doesn't need Dapr
    ingressExternal: true
    env: [
      {
        name: 'VITE_INGESTION_URL'
        value: 'https://${ingestionService.outputs.fqdn}'
      }
    ]
  }
}

// ============================================================================
// Demo 2: Traffic Splitting - Hello API
// Demonstrates blue-green deployments with traffic splitting
// ============================================================================

module helloApi './modules/container-app.bicep' = {
  name: 'hello-api'
  scope: rg
  params: {
    name: 'hello-api'
    location: location
    tags: union(defaultTags, { 'demo-scenario': 'traffic-splitting' })
    serviceName: 'hello-api'
    containerAppsEnvironmentId: containerAppsEnv.outputs.id
    containerRegistryName: containerRegistry.outputs.name
    containerImage: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest' // Placeholder
    targetPort: 3000
    minReplicas: 1
    maxReplicas: 5
    daprEnabled: false
    ingressExternal: true
    env: [
      {
        name: 'APP_VERSION'
        value: 'v1'
      }
    ]
  }
}

// ============================================================================
// Demo 3: Container Apps Jobs
// Demonstrates scheduled, manual, and parallel jobs
// ============================================================================

// Scheduled Job - Runs every 2 minutes
module scheduledJob './modules/container-job.bicep' = {
  name: 'scheduled-job'
  scope: rg
  params: {
    name: 'data-processor-scheduled'
    location: location
    tags: union(defaultTags, { 'demo-scenario': 'container-jobs', 'job-type': 'scheduled' })
    containerAppsEnvironmentId: containerAppsEnv.outputs.id
    containerRegistryName: containerRegistry.outputs.name
    containerImage: resolvedDemoJobImage
    triggerType: 'Schedule'
    cronExpression: '*/2 * * * *'
    parallelism: 1
    env: [
      { name: 'JOB_TYPE', value: 'scheduled' }
      { name: 'BATCH_SIZE', value: '100' }
    ]
  }
}

// Manual Job - Triggered on-demand
module manualJob './modules/container-job.bicep' = {
  name: 'manual-job'
  scope: rg
  params: {
    name: 'data-processor-manual'
    location: location
    tags: union(defaultTags, { 'demo-scenario': 'container-jobs', 'job-type': 'manual' })
    containerAppsEnvironmentId: containerAppsEnv.outputs.id
    containerRegistryName: containerRegistry.outputs.name
    containerImage: resolvedDemoJobImage
    triggerType: 'Manual'
    parallelism: 1
    env: [
      { name: 'JOB_TYPE', value: 'manual' }
      { name: 'BATCH_SIZE', value: '50' }
    ]
  }
}

// Parallel Job - Runs multiple instances simultaneously
module parallelJob './modules/container-job.bicep' = {
  name: 'parallel-job'
  scope: rg
  params: {
    name: 'data-processor-parallel'
    location: location
    tags: union(defaultTags, { 'demo-scenario': 'container-jobs', 'job-type': 'parallel' })
    containerAppsEnvironmentId: containerAppsEnv.outputs.id
    containerRegistryName: containerRegistry.outputs.name
    containerImage: resolvedDemoJobImage
    triggerType: 'Manual'
    parallelism: 3
    env: [
      { name: 'JOB_TYPE', value: 'parallel' }
      { name: 'BATCH_SIZE', value: '25' }
    ]
  }
}

// ============================================================================
// Outputs
// ============================================================================

output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_SUBSCRIPTION_ID string = subscription().subscriptionId
output AZURE_RESOURCE_GROUP string = rg.name
output RESOURCE_GROUP_ID string = rg.id
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.outputs.loginServer

// Container Apps outputs
output CONTAINER_APPS_ENVIRONMENT_NAME string = containerAppsEnv.outputs.name
output CONTAINER_REGISTRY_NAME string = containerRegistry.outputs.name
output CONTAINER_REGISTRY_LOGIN_SERVER string = containerRegistry.outputs.loginServer

// Security outputs
output KEY_VAULT_NAME string = keyVault.outputs.name
output MANAGED_IDENTITY_NAME string = managedIdentity.outputs.name
output MANAGED_IDENTITY_CLIENT_ID string = managedIdentity.outputs.clientId

// Demo 1: Auto-Scaling
output INGESTION_SERVICE_URL string = 'https://${ingestionService.outputs.fqdn}'
output DASHBOARD_URL string = 'https://${dashboard.outputs.fqdn}'

// Demo 2: Traffic Splitting
output HELLO_API_URL string = 'https://${helloApi.outputs.fqdn}'

// Demo 3: Container Jobs
output SCHEDULED_JOB_NAME string = scheduledJob.outputs.name
output MANUAL_JOB_NAME string = manualJob.outputs.name
output PARALLEL_JOB_NAME string = parallelJob.outputs.name

// Supporting services
output SERVICEBUS_NAMESPACE string = serviceBus.outputs.namespaceName
