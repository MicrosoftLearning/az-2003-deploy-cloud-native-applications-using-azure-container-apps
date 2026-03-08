// Azure Container App
// Individual microservice deployment with built-in scaling, Dapr, and traffic management
// Uses Key Vault references for secure secret management with managed identity
// KEY DIFFERENTIATOR: Scale-to-zero, event-driven scaling, zero Kubernetes YAML

@description('Name of the Container App')
param name string

@description('Location for all resources')
param location string

@description('Tags to apply to all resources')
param tags object = {}

@description('Container Apps Environment ID')
param containerAppsEnvironmentId string

@description('Container Registry name')
param containerRegistryName string

@description('Container image to deploy')
param containerImage string

@description('Target port for the container')
param targetPort int = 8080

@description('Minimum replicas (0 enables scale-to-zero)')
@minValue(0)
param minReplicas int = 0

@description('Maximum replicas')
@minValue(1)
param maxReplicas int = 100

@description('Enable Dapr sidecar')
param daprEnabled bool = false

@description('Dapr App ID')
param daprAppId string = ''

@description('Enable external ingress')
param ingressExternal bool = true

@description('Environment variables')
param env array = []

@description('Secrets')
param secrets array = []

@description('Custom scale rules (KEDA scalers)')
param scaleRules array = []

@description('User-assigned managed identity ID for Key Vault access')
param userAssignedIdentityId string = ''

@description('Service name for azd deployment (must match azure.yaml service name)')
param serviceName string = ''

// ============================================================================
// Reference to Container Registry
// ============================================================================

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' existing = {
  name: containerRegistryName
}

// ============================================================================
// Container App
// KEY DIFFERENTIATOR: Built-in scale rules, no KEDA installation required
// ============================================================================

resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: name
  location: location
  tags: union(tags, !empty(serviceName) ? { 'azd-service-name': serviceName } : {})
  identity: !empty(userAssignedIdentityId) ? {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  } : {
    type: 'None'
  }
  properties: {
    managedEnvironmentId: containerAppsEnvironmentId
    workloadProfileName: 'Consumption' // Pay-per-use model
    
    configuration: {
      // Enable ingress for HTTP traffic
      ingress: {
        external: ingressExternal
        targetPort: targetPort
        transport: 'http'
        allowInsecure: false
        // Built-in traffic splitting for blue-green deployments
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
        // CORS configuration for frontend apps
        corsPolicy: {
          allowedOrigins: ['*']
          allowedMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS']
          allowedHeaders: ['*']
        }
      }
      
      // Dapr configuration - KEY DIFFERENTIATOR: One-click enable
      dapr: daprEnabled ? {
        enabled: true
        appId: daprAppId
        appPort: targetPort
        appProtocol: 'http'
        enableApiLogging: true
      } : null
      
      // Container Registry authentication
      registries: [
        {
          server: containerRegistry.properties.loginServer
          username: containerRegistry.listCredentials().username
          passwordSecretRef: 'registry-password'
        }
      ]
      
      // Secrets - supports Key Vault references via managed identity
      secrets: union([
        {
          name: 'registry-password'
          value: containerRegistry.listCredentials().passwords[0].value
        }
      ], secrets)
      
      // Single revision mode - only one active revision at a time
      // Use 'Multiple' if you need traffic splitting for blue-green deployments
      activeRevisionsMode: 'Single'
    }
    
    template: {
      containers: [
        {
          name: name
          image: containerImage
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          env: env
          // Health probes for reliability
          probes: [
            {
              type: 'Liveness'
              httpGet: {
                path: '/health'
                port: targetPort
              }
              initialDelaySeconds: 10
              periodSeconds: 10
            }
            {
              type: 'Readiness'
              httpGet: {
                path: '/ready'
                port: targetPort
              }
              initialDelaySeconds: 5
              periodSeconds: 5
            }
          ]
        }
      ]
      
      // Scale configuration - KEY DIFFERENTIATOR: Built-in KEDA integration
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
        rules: length(scaleRules) > 0 ? scaleRules : [
          // Default HTTP scaling rule
          {
            name: 'http-requests'
            http: {
              metadata: {
                concurrentRequests: '100'
              }
            }
          }
        ]
      }
    }
  }
}

// ============================================================================
// Outputs
// ============================================================================

output id string = containerApp.id
output name string = containerApp.name
output fqdn string = containerApp.properties.configuration.ingress.fqdn
output latestRevisionName string = containerApp.properties.latestRevisionName
