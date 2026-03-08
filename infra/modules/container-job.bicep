// Azure Container Apps Job Module
// Demonstrates scheduled and manual jobs without Kubernetes CronJob complexity

@description('Name of the Container Apps Job')
param name string

@description('Location for all resources')
param location string

@description('Tags to apply to all resources')
param tags object = {}

@description('Container Apps Environment ID')
param containerAppsEnvironmentId string

@description('Container Registry name')
param containerRegistryName string

@description('Container image to run')
param containerImage string

@description('Job trigger type: Manual, Schedule, or Event')
@allowed(['Manual', 'Schedule', 'Event'])
param triggerType string = 'Manual'

@description('Cron expression for scheduled jobs (e.g., "*/2 * * * *" for every 2 minutes)')
param cronExpression string = ''

@description('Number of parallel replicas to run')
@minValue(1)
@maxValue(10)
param parallelism int = 1

@description('Number of times to retry a failed job')
@minValue(0)
@maxValue(5)
param replicaRetryLimit int = 1

@description('Timeout in seconds for the job')
param replicaTimeout int = 300

@description('Environment variables')
param env array = []

// Reference to Container Registry
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' existing = {
  name: containerRegistryName
}

// Container Apps Job
resource job 'Microsoft.App/jobs@2024-03-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    environmentId: containerAppsEnvironmentId
    workloadProfileName: 'Consumption'
    
    configuration: {
      triggerType: triggerType
      
      // Schedule configuration (only for Schedule trigger type)
      scheduleTriggerConfig: triggerType == 'Schedule' ? {
        cronExpression: cronExpression
        parallelism: parallelism
        replicaCompletionCount: parallelism
      } : null
      
      // Manual trigger configuration
      manualTriggerConfig: triggerType == 'Manual' ? {
        parallelism: parallelism
        replicaCompletionCount: parallelism
      } : null
      
      replicaRetryLimit: replicaRetryLimit
      replicaTimeout: replicaTimeout
      
      // Registry authentication
      registries: [
        {
          server: containerRegistry.properties.loginServer
          username: containerRegistry.listCredentials().username
          passwordSecretRef: 'registry-password'
        }
      ]
      
      secrets: [
        {
          name: 'registry-password'
          value: containerRegistry.listCredentials().passwords[0].value
        }
      ]
    }
    
    template: {
      containers: [
        {
          name: name
          image: containerImage
          resources: {
            cpu: json('0.25')
            memory: '0.5Gi'
          }
          env: union([
            {
              name: 'JOB_NAME'
              value: name
            }
          ], env)
        }
      ]
    }
  }
}

output id string = job.id
output name string = job.name
