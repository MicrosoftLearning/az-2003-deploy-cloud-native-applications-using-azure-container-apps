---
lab:
  title: Deploy and Operate Azure Container Apps
  description: Deploy Azure Container Apps infrastructure using Bicep, build container images, implement auto-scaling, traffic splitting, batch processing jobs, and CI/CD with Azure DevOps
  level: 400
  duration: 150 minutes
  islab: true
  primarytopics:
    - Azure
    - Azure Container Apps
    - Azure DevOps
---

# Deploy and Operate Azure Container Apps

In this exercise you will deploy and operate the **Contoso Analytics** platform, an event-driven microservices application built on Azure Container Apps. You'll work with infrastructure deployment, container image management, HTTP auto-scaling, traffic splitting for blue-green deployments, and Container Apps Jobs for batch processing. Once everything is up-and-running, you will integrate a DevOps strategy using Azure DevOps CI/CD pipelines.

This exercise should take approximately **150** minutes to complete.

---

## Table of Contents

- [Before you start](#before-you-start)
- [Exercise 1: Baseline Scenario Deployment](#exercise-1-baseline-scenario-deployment)
  - [Task 1: Deploy Infrastructure](#task-1-deploy-infrastructure)
- [Exercise 2: Managing & Operating Azure Container Apps](#exercise-2-managing--operating-azure-container-apps)
  - [Task 1: Implement HTTP Auto-Scaling](#task-1-implement-http-auto-scaling)
  - [Task 2: Implement Traffic Splitting](#task-2-implement-traffic-splitting)
  - [Task 3: Work with Container Apps Jobs](#task-3-work-with-container-apps-jobs)
- [Exercise 3: Azure DevOps CI/CD Pipelines](#exercise-3-azure-devops-cicd-pipelines)
  - [Task 1: Deploy with Azure DevOps Pipelines](#task-1-deploy-with-azure-devops-pipelines)
  - [Task 2: Enhance the Pipeline with Traffic Splitting (Optional)](#task-2-enhance-the-pipeline-with-traffic-splitting-optional)

---

## Before you start

Before you can start the exercises, you will need to:

1. An Azure subscription with **Contributor** access
1. **[Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli?view=azure-cli-latest)** version 2.50 or later installed
1. **[Azure Developer CLI - AZD](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd)** installed (for Option B deployment choice)
1. **[Docker Desktop](https://www.docker.com/products/docker-desktop/)** installed and running
1. An **Azure DevOps** Organization and Project with **Contributor** access

1. Verify your tools are ready:

    ```powershell
    # Check Azure CLI version (requires 2.50+)
    az version
    ```

    ```powershell
    # Check Docker is running; if it fails, start Docker Desktop and wait for the GUI to inform you it is ready to run containers
    docker info
    ```

    ```powershell
    # Login to Azure
    az login
    ```

    ```powershell
    # Set your subscription (replace with your subscription ID or name)
    az account set --subscription "<YOUR_SUBSCRIPTION_ID>"
    ```

    ```powershell
    # Verify current subscription
    az account show --query "{Name:name, SubscriptionId:id}" -o table

    ```

1. Clone the repository:

    ```powershell
    # Clone the repository
    git clone https://github.com/MicrosoftLearning/az-2003-deploy-cloud-native-applications-using-azure-container-apps.git
    ```

    ```powershell
    # Navigate to the project directory
    cd .\az-2003-deploy-cloud-native-applications-using-azure-container-apps

    ```

1. Set your environment variables that will be used throughout the exercise:

    ```powershell
    # Set your environment name (use lowercase, no special characters)
    $ENV_NAME = "contapp"  # Example: "john-lab"
    ```
> **Note**: Replace `contapp` with a unique name. This will be used to create globally unique resource names.

    ```powershell
    # Set the Azure region
    $LOCATION = "eastus2" # Choose your Azure region
    ```

    ```powershell
    # Get your user principal ID (for Key Vault access)
    $PRINCIPAL_ID = (az ad signed-in-user show --query id -o tsv)
    ```

    ```powershell
    # Verify the principal ID was retrieved
    Write-Host "Principal ID: $PRINCIPAL_ID"

    ```
---

## Exercise 1: Baseline Scenario Deployment

In this exercise, you will deploy the foundational infrastructure for the Contoso Analytics platform. You'll provision Azure Container Apps Environment, Container Registry, Key Vault, and supporting resources using either Azure CLI with Bicep templates or the Azure Developer CLI (azd). By the end of this exercise, you'll have a fully operational container platform ready for application deployment.

### Task 1: Deploy Infrastructure

In this task, you'll deploy the Azure Container Apps infrastructure. You can choose between two deployment methods:

| Method | Description | Best For |
|--------|-------------|----------|
| **Option A: Azure CLI + Bicep** | Deploy infrastructure step-by-step using Azure CLI and Bicep templates | Learning Bicep, granular control, understanding each component |
| **Option B: Azure Developer CLI (azd)** | One-command deployment of infrastructure AND application code | Quick setup, CI/CD workflows, production scenarios |

> **Important**: Choose **ONE deployment option** below. If you are rather new to Docker and Container Registry tasks such as building, deploying and managing containers, we recommend using **Option A (az cli)**, as it walks through all steps manually. If you are already familiar with Docker, Azure Container Registry and Azure Bicep deployments, choose **Option B (azd)**, since azd builds and deploys the container images automatically.

---

### Option A: Deploy with Azure CLI and Bicep

Use this option if you want to understand the Bicep templates and deploy infrastructure step-by-step.

#### Review the Bicep Template

1. Before deploying, examine the main Bicep template to understand what resources will be created:

    ```powershell
    # Open the main Bicep file to review
    Get-Content .\infra\main.bicep | Select-Object -First 80

    ```

1. Note the resources that will be created by the template:
    - Resource Group
    - Log Analytics Workspace
    - User-Assigned Managed Identity
    - Azure Container Registry
    - Container Apps Environment
    - Azure Service Bus Namespace
    - Azure Key Vault
    - Container Apps (with placeholder images)
    - Container Apps Jobs (with placeholder images)

#### Deploy the Infrastructure

1. Deploy the Bicep template using Azure CLI:

    ```powershell
    # Deploy infrastructure at subscription scope
    az deployment sub create `
        --name "contapp-$ENV_NAME" `
        --location $LOCATION `
        --template-file .\infra\main.bicep `
        --parameters environmentName=$ENV_NAME `
        --parameters location=$LOCATION `
        --parameters principalId=$PRINCIPAL_ID `
        --query "properties.outputs" -o json

    ```

    > **Note**: This deployment takes approximately 5-8 minutes to complete.

#### Capture Deployment Outputs

1. After deployment completes, capture the output values for later use:

    ```powershell
    # Get deployment outputs
    $OUTPUTS = az deployment sub show `
        --name "contapp-$ENV_NAME" `
        --query "properties.outputs" -o json | ConvertFrom-Json
    ```

    ```powershell
    # Extract key values
    $RG = $OUTPUTS.AZURE_RESOURCE_GROUP.value
    $ACR = $OUTPUTS.CONTAINER_REGISTRY_LOGIN_SERVER.value
    $ACR_NAME = $OUTPUTS.CONTAINER_REGISTRY_NAME.value
    $CAE_NAME = $OUTPUTS.CONTAINER_APPS_ENVIRONMENT_NAME.value
    $DASHBOARD_URL = $OUTPUTS.DASHBOARD_URL.value
    $INGESTION_URL = $OUTPUTS.INGESTION_SERVICE_URL.value
    $HELLO_API_URL = $OUTPUTS.HELLO_API_URL.value

    # Display captured values
    Write-Host "========================================="
    Write-Host "Resource Group:        $RG"
    Write-Host "Container Registry:    $ACR"
    Write-Host "Environment:           $CAE_NAME"
    Write-Host "Dashboard URL:         $DASHBOARD_URL"
    Write-Host "Ingestion Service URL: $INGESTION_URL"
    Write-Host "Hello API URL:         $HELLO_API_URL"
    Write-Host "========================================="

    ```

#### Verify Initial Deployment

1. Check that all resources were created:

    ```powershell
    # List all resources in the resource group
    az resource list -g $RG --query "[].{Name:name, Type:type}" -o table
    ```
    ```powershell
    # List Container Apps
    az containerapp list -g $RG --query "[].{Name:name, URL:properties.configuration.ingress.fqdn}" -o table
    ```
    ```powershell
    # List Container Apps Jobs
    az containerapp job list -g $RG --query "[].{Name:name, TriggerType:properties.configuration.triggerType}" -o table

    ```

    > **Note**: You should see 3 Container Apps, ingestion-service, hello-api and dashboard. You should see 3 Container App Jobs, data-processor-parallel, -scheduled and -manual

    > **Note**: At this point, the Container Apps are running with placeholder images (`containerapps-helloworld`). Continue with the **Build Container Images** section below.

#### Build Container Images

In this section, you'll build custom container images and push them to Azure Container Registry.

1. Authenticate to your container registry:

    ```powershell
    # Login to ACR
    az acr login --name $ACR_NAME

    ```

1. Build and push the ingestion service image:

    ```powershell
    # Navigate to the ingestion-service directory
    cd src/ingestion-service
    ```
    ```powershell
    # Build the container image
    docker build -t "$ACR/ingestion-service:v1" .
    ```
    ```powershell
    # Push to Azure Container Registry
    docker push "$ACR/ingestion-service:v1"
    ```
    ```powershell
    # Return to project root
    cd ../..

    ```

1. Build and push the dashboard image:

    ```powershell
    # Navigate to the dashboard directory
    cd src/dashboard
    ```
    ```powershell
    # Build the container image
    docker build -t "$ACR/dashboard:v1" .
    ```
    ```powershell
    # Push to Azure Container Registry
    docker push "$ACR/dashboard:v1"
    ```
    ```powershell
    # Return to project root
    cd ../..

    ```

1. Build and push the Hello API image:

    ```powershell
    # Navigate to the hello-api directory
    cd src/hello-api
    ```
    ```powershell
    # Build v1 of the Hello API (blue version)
    docker build -t "$ACR/hello-api:v1" --build-arg APP_VERSION=v1 .
    ```
    ```powershell
    # Push to Azure Container Registry
    docker push "$ACR/hello-api:v1"
    ```
    ```powershell
    # Return to project root
    cd ../..

    ```

1. Build and push the demo job image:

    ```powershell
    # Navigate to the demo-job directory
    cd src/demo-job
    ```
    ```powershell
    # Build the job image
    docker build -t "$ACR/demo-job:v1" .
    ```
    ```powershell
    # Push to Azure Container Registry
    docker push "$ACR/demo-job:v1"
    ```
    ```powershell
    # Return to project root
    cd ../..

    ```

1. Verify all images are available in the registry:

    ```powershell
    # List all repositories in ACR
    az acr repository list --name $ACR_NAME -o table
    ```
    ```powershell
    # List tags for each repository
    az acr repository show-tags --name $ACR_NAME --repository ingestion-service -o table
    az acr repository show-tags --name $ACR_NAME --repository dashboard -o table
    az acr repository show-tags --name $ACR_NAME --repository hello-api -o table
    az acr repository show-tags --name $ACR_NAME --repository demo-job -o table

    ```

#### Deploy Container Images to Container Apps

Now update the deployed Container Apps to use your custom images.

1. Update the ingestion-service with the custom image:

    ```powershell
    # Update the ingestion-service with the custom image
    az containerapp update `
        --name ingestion-service `
        --resource-group $RG `
        --image "$ACR/ingestion-service:v1"

    # Verify the update
    az containerapp show -n ingestion-service -g $RG `
        --query "{Name:name, Image:properties.template.containers[0].image, Status:properties.runningStatus}" -o table

    ```

1. Update the dashboard with the custom image:

    ```powershell
    # Update the dashboard with the custom image
    az containerapp update `
        --name dashboard `
        --resource-group $RG `
        --image "$ACR/dashboard:v1"
    ```
    ```powershell
    # Verify the update
    az containerapp show -n dashboard -g $RG `
        --query "{Name:name, Image:properties.template.containers[0].image, Status:properties.runningStatus}" -o table

    ```

1. Update the hello-api with the custom image:

    ```powershell
    # Update the hello-api with the custom image
    az containerapp update `
        --name hello-api `
        --resource-group $RG `
        --image "$ACR/hello-api:v1"
    ```
    ```powershell
    # Verify the update
    az containerapp show -n hello-api -g $RG `
        --query "{Name:name, Image:properties.template.containers[0].image, Status:properties.runningStatus}" -o table

    ```

1. Update all three jobs with the demo-job image:

    ```powershell
    # Update all three jobs with the demo-job image
    az containerapp job update -n data-processor-scheduled -g $RG --image "$ACR/demo-job:v1"
    az containerapp job update -n data-processor-manual -g $RG --image "$ACR/demo-job:v1"
    az containerapp job update -n data-processor-parallel -g $RG --image "$ACR/demo-job:v1"
    ```
    ```powershell
    # Verify the updates
    az containerapp job list -g $RG `
        --query "[].{Name:name, Image:properties.template.containers[0].image}" -o table

    ```

1. Verify all services are operational:

    ```powershell
    # Check all Container Apps are running
    az containerapp list -g $RG `
        --query "[].{Name:name, Status:properties.runningStatus, Replicas:properties.template.scale.minReplicas}" -o table
    ```
    ```powershell
    # Test the endpoints
    Write-Host "`nTesting Dashboard..."
    Invoke-RestMethod -Uri "$DASHBOARD_URL/health" -TimeoutSec 30

    Write-Host "`nTesting Ingestion Service..."
    Invoke-RestMethod -Uri "$INGESTION_URL/health" -TimeoutSec 30

    Write-Host "`nTesting Hello API..."
    Invoke-RestMethod -Uri "$HELLO_API_URL/api/version" -TimeoutSec 30

    ```

    > **Note**: You have completed the manual deployment using Azure CLI and Bicep. Proceed to **Exercise 2, Task 1: Implement HTTP Auto-Scaling**.

---

### Option B: Deploy with Azure Developer CLI (azd)

Use this option for a streamlined one-command deployment that handles **everything automatically**:

- Provisions all Azure infrastructure using Bicep templates
- Builds all container images locally using Docker
- Pushes images to Azure Container Registry
- Deploys all services to Container Apps
- Configures Container Apps Jobs

> **Time saver**: If you choose this option, you can skip directly to **Exercise 2, Task 1: Implement HTTP Auto-Scaling** after deployment completes.

#### Prerequisites for azd

1. Ensure Azure Developer CLI is installed:

    ```powershell
    # Check if azd is installed
    azd version
    ```
    ```powershell
    # If not installed, install it (Windows winget)
    winget install microsoft.azd
    ```

    > **Note**: If you are not on Windows or prefer PowerShell instead of Winget, use this command: 
    ```powershell
    powershell -ex AllSigned -c "Invoke-RestMethod 'https://aka.ms/install-azd.ps1' | Invoke-Expression"
    ```

#### Initialize and Deploy with azd

1. Login to Azure with azd:

    ```powershell
    # Login to Azure
    azd auth login

    ```

1. Initialize a new azd environment:

    ```powershell
    # Start from the cloned repo folder
    cd .\az-2003-deploy-cloud-native-applications-using-azure-container-apps

    ```
    ```powershell
    # Create a new environment (use the same name as ENV_NAME)
    azd env new $ENV_NAME

    ```
    ```powershell
    # Set the Azure location
    azd env set AZURE_LOCATION $LOCATION

    ```

1. Deploy everything with a single command:

    ```powershell
    # Deploy infrastructure AND application code
    azd up

    ```

    > **Note**: This command will:
    > - Provision all Azure infrastructure using the Bicep templates
    > - Build all container images locally using Docker
    > - Push images to Azure Container Registry
    > - Deploy all services to Container Apps
    > - Configure Container Apps Jobs
    >
    > The entire process takes approximately 10-15 minutes.

1. When prompted:
    - Select your Azure subscription
    - Confirm the location (or press Enter to accept the default)

#### Capture azd Deployment Outputs

1. After deployment completes, capture the environment variables:

    ```powershell
    # Get all environment values from azd and set them as PowerShell variables
    azd env get-values | ForEach-Object {
        if ($_ -match '^([^=]+)=(.*)$') {
            Set-Variable -Name $matches[1] -Value ($matches[2] -replace '^"|"$', '')
        }
    }
    ```
    ```powershell
    # The variables are now available directly (matching Bicep output names)
    $RG = $AZURE_RESOURCE_GROUP
    $ACR = $CONTAINER_REGISTRY_LOGIN_SERVER
    $ACR_NAME = $CONTAINER_REGISTRY_NAME
    $CAE_NAME = $CONTAINER_APPS_ENVIRONMENT_NAME
    ```
    ```powershell
    # Set aliases to match Option A variable names (for consistency in later tasks)
    $INGESTION_URL = $INGESTION_SERVICE_URL
    ```
    ```powershell
    # Display captured values
    Write-Host "========================================="
    Write-Host "Resource Group:        $RG"
    Write-Host "Container Registry:    $ACR"
    Write-Host "Environment:           $CAE_NAME"
    Write-Host "Dashboard URL:         $DASHBOARD_URL"
    Write-Host "Ingestion Service URL: $INGESTION_URL"
    Write-Host "Hello API URL:         $HELLO_API_URL"
    Write-Host "========================================="

    ```

#### Verify azd Deployment

1. Check the deployed resources:

    ```powershell
    # List all Container Apps (should show your custom images, not placeholders)
    az containerapp list -g $RG --query "[].{Name:name, Image:properties.template.containers[0].image}" -o table
    ```
    ```powershell
    # List Container Apps Jobs
    az containerapp job list -g $RG --query "[].{Name:name, TriggerType:properties.configuration.triggerType}" -o table
    ```
    ```powershell
    # Test the endpoints
    Write-Host "`nTesting Dashboard..."
    Invoke-RestMethod -Uri "$DASHBOARD_URL/health" -TimeoutSec 30

    Write-Host "`nTesting Ingestion Service..."
    Invoke-RestMethod -Uri "$INGESTION_URL/health" -TimeoutSec 30

    ```

    > **Note**: Since azd deployed the actual application images, proceed directly to **Exercise 2, Task 1: Implement HTTP Auto-Scaling**.

---

## Exercise 2: Managing & Operating Azure Container Apps

In this exercise, you will explore the operational capabilities of Azure Container Apps. You'll implement HTTP-based auto-scaling to handle variable traffic loads, configure traffic splitting for blue-green deployments and A/B testing, and work with Container Apps Jobs for batch processing workloads. These tasks demonstrate real-world scenarios for managing production containerized applications.

### Task 1: Implement HTTP Auto-Scaling

In this task, you will observe how Azure Container Apps automatically scales the ingestion-service based on HTTP traffic.

### Check Initial Replica Count

1. Verify the current number of replicas:

    ```powershell
    # Check the current number of replicas
    az containerapp replica list -n ingestion-service -g $RG -o table
    ```

    > **Note**: The output of this command should show 1 replica (minReplicas is set to 1)

### Review Scaling Configuration

1. View the scaling rules configured for the ingestion-service:

    ```powershell
    # View the scaling rules configured for the ingestion-service
    az containerapp show -n ingestion-service -g $RG `
        --query "properties.template.scale" -o json

    ```

    > **Note**: The `concurrentRequests` is set to `2`, meaning the service will scale up when there are more than 2 concurrent requests per replica.

### Open the Dashboard Container App

1. Open the dashboard Container App in your browser:

    ```powershell
    # Display the dashboard URL
    Write-Host "Open this URL in your browser: $DASHBOARD_URL"
    ```
    ```powershell
    # Or open directly (Windows)
    Start-Process $DASHBOARD_URL

    ```

### Trigger Load and Observe Scaling

1. In the dashboard, click the **🔥 Send 100 Events (Heavy Load)** button
1. Watch the status message showing events being sent
1. While the load test is running, monitor the replica count:

    ```powershell
    # Run this command multiple times during the load test to see scaling
    az containerapp replica list -n ingestion-service -g $RG -o table
    ```
    ```powershell
    # Or watch continuously (run in a separate terminal)
    while ($true) {
        $count = (az containerapp replica list -n ingestion-service -g $RG -o json | ConvertFrom-Json).Count
        Write-Host "$(Get-Date -Format 'HH:mm:ss') - Replica count: $count"
        Start-Sleep -Seconds 5
    }

    ```

### Observe Scale-Down

1. After the load test completes, wait for the cooldown period (default 5 minutes) and observe the replicas scaling back down:

    ```powershell
    # Check replica count after load subsides
    az containerapp replica list -n ingestion-service -g $RG -o table

    ```

### View Scaling Metrics in Azure Portal

1. Navigate to the [Azure Portal](https://portal.azure.com) at `https://portal.azure.com`
1. Go to your **Resource Group** and select **ingestion-service**
1. Click on **Metrics**
1. Add the metric **Replica Count**
1. Observe the scaling behavior over time

    > **Note**: You should have observed the ingestion-service scaling from 1 replica up to multiple replicas during load, then back down after the cooldown period.

### Task 2: Implement Traffic Splitting

In this task, you will deploy a second version of the Hello API and implement traffic splitting for a blue-green deployment.

### Verify Version 1 is Running

1. Confirm the current version is deployed:

    ```powershell
    # Open Hello API in browser
    Start-Process $HELLO_API_URL
    ```
    ```powershell
    # Or test via CLI
    Invoke-RestMethod -Uri "$HELLO_API_URL/api/version"

    ```

1. You should see a **blue "v1"** badge on the page.

### Enable Multiple Revision Mode

1. Enable multiple revision mode to split traffic between versions:

    ```powershell
    # Enable multiple revision mode
    az containerapp revision set-mode `
        --name hello-api `
        --resource-group $RG `
        --mode Multiple
    ```
    ```powershell
    # Verify the mode change
    az containerapp show -n hello-api -g $RG `
        --query "properties.configuration.activeRevisionsMode" -o tsv

    ```

### Build and Push Version 2

1. Build and push version 2 of the Hello API:

    ```powershell
    # Navigate to the hello-api directory
    cd src/hello-api
    ```
    ```powershell
    # Build v2 (green version)
    docker build -t "$ACR/hello-api:v2" --build-arg APP_VERSION=v2 .
    ```
    ```powershell
    # Push to ACR
    docker push "$ACR/hello-api:v2"
    ```
    ```powershell
    # Return to project root
    cd ../..

    ```

### Deploy Version 2 as a New Revision

1. Deploy v2 as a new revision with a custom suffix:

    ```powershell
    # Deploy v2 as a new revision with a custom suffix
    az containerapp update `
        --name hello-api `
        --resource-group $RG `
        --image "$ACR/hello-api:v2" `
        --revision-suffix v2 `
        --set-env-vars "APP_VERSION=v2"

    ```

### List All Revisions

1. View all available revisions:

    ```powershell
    # List all revisions of hello-api
    az containerapp revision list -n hello-api -g $RG `
        --query "[].{Name:name, Active:properties.active, TrafficWeight:properties.trafficWeight, Created:properties.createdTime}" -o table

    ```

    > **Note**: At this point, 100% of traffic goes to the latest revision (v2).

### Split and Test Traffic 50/50

From the Azure Portal, configure traffic splitting between versions:

1. Navigate to the Resource Group and select the **hello-Api** Container App
1. Select **Application** / **Revisions and replicas**
1. Notice 2 revisions, **hello-api--v2** and **hello-api--00000**
1. The **hello-api--v2** currently has **100%** traffic load. **Update** this to **50%**
1. **Update** the same **50%** weight for the other revision
1. **Save** your changes
1. Navigate back to the **Overview** section of the **hello-api** Container Apps and **select** the **Application URL**
1. **Refresh** the browser multiple times; you should see the blue and green version alternating  

### Complete the Migration

1. Shift 100% of traffic to v2:

    ```powershell
    # Route all traffic to v2
    az containerapp ingress traffic set `
        --name hello-api `
        --resource-group $RG `
        --revision-weight "hello-api--v2=100"
    ```
    ```powershell
    # Verify
    az containerapp ingress traffic show -n hello-api -g $RG -o table

    ```

### (Optional) Rollback to v1

1. If needed, you can instantly roll back:

    ```powershell
    # Rollback to v1
    az containerapp ingress traffic set `
        --name hello-api `
        --resource-group $RG `
        --revision-weight "$REV_V1=100"

    ```

    > **Note**: You have successfully implemented blue-green deployment with traffic splitting, allowing you to gradually migrate users between versions.

### Task 3: Work with Container Apps Jobs

In this task, you will work with Container Apps Jobs for batch processing tasks.

### List All Jobs

1. View all Container Apps Jobs:

    ```powershell
    # List all Container Apps Jobs
    az containerapp job list -g $RG `
        --query "[].{Name:name, TriggerType:properties.configuration.triggerType, Schedule:properties.configuration.scheduleTriggerConfig.cronExpression}" -o table

    ```

1. You should see three jobs:

    | Name | Trigger Type | Schedule |
    |------|--------------|----------|
    | data-processor-scheduled | Schedule | */2 * * * * |
    | data-processor-manual | Manual | - |
    | data-processor-parallel | Manual | - |

### View Scheduled Job Executions

1. The scheduled job runs every 2 minutes. Check its execution history:

    ```powershell
    # List executions for the scheduled job
    az containerapp job execution list `
        --name data-processor-scheduled `
        --resource-group $RG `
        --query "[].{Name:name, Status:properties.status, StartTime:properties.startTime}" -o table

    ```

    > **Note**: If no executions appear, wait 2 minutes for the first scheduled run. It is possible that some jobs will show as successful and others as failed.

### View Job Logs in the Azure Portal

1. From the Resource Group, select the **data-processor-scheduled** Container Apps
1. From the **Overview** section, **select** the **View** link under **Execution History**
1. If you refresh around every 2 minutes, you will see a new job with status **Running**
1. For any of the Jobs, select the **Console / System** Logs link
1. This shows a **more detailed** log view in **Azure Log Analytics** with a full detail of the job

> **Note**: You can see the same by navigating to **Monitoring** / **Execution History**

### Trigger a Manual Job

1. Start the manual job:

    ```powershell
    # Start the manual job
    $JOB_EXECUTION = az containerapp job start `
        --name data-processor-manual `
        --resource-group $RG `
        --query "name" -o tsv
    ```
    ```powershell
    Write-Host "Started job execution: $JOB_EXECUTION"
    ```
    ```powershell
    # Wait for completion
    Write-Host "Waiting for job to complete..."
    Start-Sleep -Seconds 20
    ```
    ```powershell
    # Check execution status
    az containerapp job execution list `
        --name data-processor-manual `
        --resource-group $RG `
        --query "[0].{Name:name, Status:properties.status, StartTime:properties.startTime, EndTime:properties.endTime}" -o table

    ```

### Trigger a Parallel Job

1. The parallel job runs 3 instances simultaneously:

    ```powershell
    # Start the parallel job
    az containerapp job start `
        --name data-processor-parallel `
        --resource-group $RG
    ```
    ```powershell
    Write-Host "Started parallel job with 3 replicas"
    ```
    ```powershell
    # Wait and check status
    Start-Sleep -Seconds 25
    ```
    ```powershell
    # View execution details
    az containerapp job execution list `
        --name data-processor-parallel `
        --resource-group $RG `
        --query "[0].{Name:name, Status:properties.status}" -o table

    ```

### View Parallel Execution in Portal

1. Navigate to the [Azure Portal](https://portal.azure.com) at `https://portal.azure.com`
1. Go to your **Resource Group** and select **data-processor-parallel**
1. Click on **Execution history**
1. Click on the latest execution
1. Observe that 3 replicas ran simultaneously

    > **Note**: You have successfully worked with Container Apps Jobs, including scheduled jobs, manual triggers, and parallel execution.

---

## Exercise 3: Azure DevOps CI/CD Pipelines

In this exercise, you will implement continuous integration and continuous deployment (CI/CD) pipelines using Azure DevOps. You'll create an automated pipeline that builds container images, pushes them to Azure Container Registry, and deploys to Azure Container Apps. You'll also learn how to implement advanced deployment strategies like traffic splitting directly in your pipeline for zero-downtime releases.

### Task 1: Deploy with Azure DevOps Pipelines

In this task, you will set up an Azure DevOps pipeline to automate the build and deployment of your Container Apps. This demonstrates how to implement CI/CD for containerized microservices.

### Prerequisites for Azure DevOps (if needed)

1. Ensure you have access to an Azure DevOps organization. If not, create one:
    - Navigate to [Azure DevOps](https://aex.dev.azure.com) at `https://aex.dev.azure.com`
    - Sign in with your Microsoft account
    - Click **New organization** if you don't have one

1. Create a new project for this exercise:

    ```powershell
    # Open Azure DevOps in your browser
    Start-Process "https://dev.azure.com"

    ```

1. In Azure DevOps:
    - Click **+ New project**
    - Enter project name: `Contoso-ContainerApps`
    - Set visibility to **Private**
    - Click **Create**

### Create an Azure Service Connection

1. Create a service connection to allow Azure DevOps to deploy to your Azure subscription:

    - In your Azure DevOps project, go to **Project settings** (bottom left)
    - Under **Pipelines**, click **Service connections**
    - Click **Create service connection**
    - Select **Azure Resource Manager** and click **Next**
    - Configure the connection:
        - **Identity type**: App registration (automatic)
        - **Credential**: Workload identity federation
        - **Scope level**: Subscription
        - **Subscription**: Select your Azure subscription
        - **Resource group**: Leave empty (subscription-level access)
        - **Service connection name**: `AzureServiceConnection`
    - Click **Save**

    > **Note**: The service connection name must match the `azureSubscription` variable in the pipeline YAML file.

### Initialize a Git Repository

1. Initialize a Git repository and push your code to Azure DevOps:

    ```powershell
    # Navigate to your project directory
    cd c:\azd-contapp-demo-v2
    ```
    ```powershell
    # Initialize Git repository 
    git init
    ```
    ```powershell
    # Add all files
    git add .
    ```
    ```powershell
    # Create initial commit
    git commit -m "Initial commit: Contoso Analytics Container Apps"

    ```

### Add Azure DevOps as Remote and Push

1. Get the repository URL from Azure DevOps:
    - In your Azure DevOps project, click **Repos**
    - Click **Files**
    - Copy the **Clone URL** (HTTPS)

1. **Update** the remote and push:

    ```powershell
    # Add Azure DevOps as remote (replace with your Azure DevOps Project and Repo URL)
    git remote set-url origin https://dev.azure.com/YOUR_ORG/YOUR_PROJECT/_git/YOUR_REPO
    ```
    ```powershell
    # Push to Azure DevOps
    git push -u origin main

    ```

    > **Note**: You may be prompted to authenticate. Use your Azure DevOps credentials or a Personal Access Token (PAT).

### Update Pipeline Variables

1. Before running the pipeline, update the deployment variables in the **correct YAML file for your Azure DevOps setup** to match your deployment:

**Ubuntu ADO Agent**:

```powershell
# Open the pipeline file
code .ado/azure-pipelines.yml
```

**Windows ADO Agent**:

```powershell
# Open the pipeline file
code .ado/azure-pipelines-windows.yml
```

2. **Modify** the following variables with their correct values:
    - **azureSubscription**: the name of the ADO Service Connection set up earlier (default=AzureServiceConnection)
    - **resourceGroupName**: Name of the Resource Group with your Azure Resources already used for this project
    - **ACR Login Server**: The FQDN of the Azure Container Registry already used in this project
    - **ACR Name**: The short name of the Azure Container Registry already used in this project
    - **Azure Region**: The Azure region location name already used for this project

3. Depending on the **setup of your [Azure DevOps Agent Pool](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/agents?view=azure-devops&tabs=yaml)**, you might also need to change the pipeline pool settings syntax:

    - **When using self-hosted agent**

    ```yaml
    pool:
        name: $(agentPool)

    ```

    - **When using Azure Hosted agent**

    ```yaml
    pool:
        vmImage: 'ubuntu-latest' #or 'windows-latest if you are on the azure-pipelines-windows.yml'

    ```

1. Save the file and commit the change:

    ```powershell
    git add .
    git commit -m "Update environment name for pipeline"
    git push

    ```

### Create the Pipeline

1. In Azure DevOps:
    - Go to **Pipelines** > **Pipelines**
    - Click **Create Pipeline** (or **New pipeline**)
    - Select **Azure Repos Git**
    - Select your repository
    - Select **Existing Azure Pipelines YAML File**
    - Choose the correct pipeline for your setup:
        - **Branch**: main
        - **Path**: 
            - `./ado/azure-pipelines.yml` (for Ubuntu ADO Agent)
            - `./ado/azure-pipelines-windows.yml` (for Windows ADO Agent)

1. Click **Run** to save the changes and kick-off the pipeline execution

### Pipeline Approvals

1. Before the pipeline starts, you might get prompted for **an approval**. This is managed through **environments**, simulating how a DevOps team can keep control of the actual deployment to production. **Confirm** the approval request.

### Review the Pipeline Structure

1. While the pipeline is running, review some details. The pipeline has three stages:

    | Stage | Description |
    |-------|-------------|
    | **Build & Test** | Builds Docker images for all services (dashboard, ingestion-service, hello-api, demo-job) and validates Bicep templates |
    | **Push Images to ACR** | Pushes built images to your Azure Container Registry |
    | **Deploy to Container Apps** | Updates all Container Apps and Jobs with the new images |

1. Note the key features:
    - **Parallel builds**: All services build simultaneously
    - **Artifact publishing**: Docker images are saved as pipeline artifacts
    - **Dynamic outputs**: Resource names are retrieved from your existing deployment
    - **Environment gates**: Deployment requires approval (optional)

### Monitor Pipeline Progress

1. Watch the pipeline stages:
    - **Build & Test**: Should complete in ~3-5 minutes
    - **Push Images to ACR**: Should complete in ~2-3 minutes
    - **Deploy to Container Apps**: Should complete in ~2-3 minutes

1. View detailed logs by clicking on any stage or job

### View Pipeline Run History

1. View the pipeline run history:
    - Go to **Pipelines** > **Pipelines**
    - Click on your pipeline
    - View the list of runs with status, duration, and trigger information

    > **Note**: You have successfully set up a CI/CD pipeline that automatically builds and deploys your Container Apps when code is pushed to the main branch.

### Verify the Deployment

1. After the pipeline completes, verify the deployment:

- **Check the Container Apps are running**

    ```powershell
    # Check all Container Apps are running with the new images
    az containerapp list -g $RG `
        --query "[].{Name:name, Image:properties.template.containers[0].image}" -o table
    ```

- **Check the Container Apps Jobs are running**

    ```powershell
    # Check the Jobs
    az containerapp job list -g $RG `
        --query "[].{Name:name, Image:properties.template.containers[0].image}" -o table

    ```

1. Note that the image tags now include the Azure DevOps Build ID

1. From the **Azure Portal**, navigate across the different **Container Apps** and see the latest revision reflecting the ADO pushed container images as **Active Revision**. 
1. You can still **see and use** the older one by selecting the **Inactive revisions** tab. 
1. Select **Activate** next to one of the inactive revision containers to present that version again as active revision.
1. Switch from the **Inactive Revision** tab back to the **Active Revision** tab. Notice the container is in a **Stopped** state.
1. **Save** the changes to start up the switched revision of the container again.

### Task 2: Enhance the Pipeline with Traffic Splitting (Optional)

In this optional task, you will extend the pipeline to implement blue-green deployments with traffic splitting, automating what you did manually in Exercise 2, Task 2.

### Create a Traffic Splitting Pipeline Stage

1. Add a new stage to the pipeline for blue-green deployments. Copy the following YAML and add it after the `DeployApps` stage in your `azure-pipelines.yml`:

> **Note**: Remember to modify the **pool** syntax accordingly for your ADO Agent pool setup

    ```yaml
    # ============================================================================
    # Stage 4: Blue-Green Deployment (Optional - Manual Trigger)
    # ============================================================================
    - stage: BlueGreenDeploy
      displayName: 'Blue-Green Deployment'
      dependsOn: DeployApps
      condition: and(succeeded(), eq(variables['deployBlueGreen'], 'true'))
      variables:
        containerRegistry: $[ stageDependencies.PushImages.PushToACR.outputs['pushImages.containerRegistry'] ]
        resourceGroup: $[ stageDependencies.PushImages.PushToACR.outputs['pushImages.resourceGroup'] ]
      jobs:
        - deployment: BlueGreenHelloApi
          displayName: 'Blue-Green Hello API'
          pool:
            vmImage: 'ubuntu-latest'
          environment: 'production'
          strategy:
            runOnce:
              deploy:
                steps:
                  - task: AzureCLI@2
                    displayName: 'Enable Multiple Revision Mode'
                    inputs:
                      azureSubscription: $(azureSubscription)
                      scriptType: 'bash'
                      scriptLocation: 'inlineScript'
                      inlineScript: |
                        az containerapp revision set-mode \
                          --name hello-api \
                          --resource-group $(resourceGroup) \
                          --mode Multiple

                  - task: AzureCLI@2
                    displayName: 'Deploy New Revision'
                    inputs:
                      azureSubscription: $(azureSubscription)
                      scriptType: 'bash'
                      scriptLocation: 'inlineScript'
                      inlineScript: |
                        # Deploy new revision with v2 suffix
                        az containerapp update \
                          --name hello-api \
                          --resource-group $(resourceGroup) \
                          --image $(containerRegistry)/hello-api:$(imageTag) \
                          --revision-suffix "v2-$(Build.BuildId)" \
                          --set-env-vars "APP_VERSION=v2"

                  - task: AzureCLI@2
                    displayName: 'Configure 50/50 Traffic Split'
                    inputs:
                      azureSubscription: $(azureSubscription)
                      scriptType: 'bash'
                      scriptLocation: 'inlineScript'
                      inlineScript: |
                        # Get the previous revision (v1)
                        V1_REVISION=$(az containerapp revision list \
                          --name hello-api \
                          --resource-group $(resourceGroup) \
                          --query "[?properties.active && !contains(name, 'v2-')].name | [0]" -o tsv)
                        
                        # Get the new revision (v2)
                        V2_REVISION=$(az containerapp revision list \
                          --name hello-api \
                          --resource-group $(resourceGroup) \
                          --query "[?contains(name, 'v2-$(Build.BuildId)')].name | [0]" -o tsv)
                        
                        echo "V1 Revision: $V1_REVISION"
                        echo "V2 Revision: $V2_REVISION"
                        
                        # Split traffic 50/50
                        az containerapp ingress traffic set \
                          --name hello-api \
                          --resource-group $(resourceGroup) \
                          --revision-weight "$V1_REVISION=50" "$V2_REVISION=50"
                        
                        echo "Traffic split configured: 50% v1, 50% v2"

    ```

1. Commit and push the updated pipeline:

    ```powershell
    git add azure-pipelines.yml
    git commit -m "Add blue-green deployment stage"
    git push

    ```

### Add Pipeline Variable for Blue-Green Toggle

1. To enable the blue-green stage, add a pipeline variable:
    - Go to **Pipelines** > **Pipelines**
    - Click on your pipeline
    - Click **Edit**
    - Click **Variables** (top right)
    - Click **New variable**
    - Name: `deployBlueGreen`
    - Value: `true`
    - Click **OK** and **Save**

### Manual Traffic Promotion

1. After testing the 50/50 split, you can promote v2 to 100% traffic via pipeline or manually:

    ```powershell
    # Promote v2 to 100% traffic
    $V2_REVISION = az containerapp revision list -n hello-api -g $RG `
        --query "[?contains(name, 'v2-')].name | [0]" -o tsv
    ```
    
    ```powershell
    az containerapp ingress traffic set `
        --name hello-api `
        --resource-group $RG `
        --revision-weight "${V2_REVISION}=100"
    
    Write-Host "V2 promoted to 100% traffic"

    ```

### Pipeline Triggers

1. Review the pipeline triggers in `azure-pipelines.yml`:

    ```yaml
    trigger:
      branches:
        include:
          - main
          - develop
      paths:
        include:
          - src/**
          - infra/**

    ```

1. This configuration means:
    - Pipeline runs automatically on pushes to `main` or `develop`
    - Only triggers when files in `src/` or `infra/` change
    - Pull requests to `main` trigger validation builds

### Test Continuous Integration

1. Make a small change to trigger the pipeline:

    ```powershell
    # Make a change to the hello-api
    $content = Get-Content ".\src\hello-api\Program.cs"
    $content = $content -replace 'Contoso Analytics API', 'Contoso Analytics API v2'
    $content | Set-Content ".\src\hello-api\Program.cs"
    ```
    ```powershell
    # Commit and push
    git add .
    git commit -m "Update API title - trigger CI/CD"
    git push

    ```

1. Watch the pipeline automatically trigger

1. Verify the deployment completed:

    ```powershell
    # Check the hello-api version
    Invoke-RestMethod -Uri "$HELLO_API_URL/api/version"

    ```

    > **Note**: You have successfully implemented CI/CD with Azure DevOps Pipelines, including automated builds, container registry pushes, and Container Apps deployments.

## Clean up

Now that you've finished the exercise, you should delete the cloud resources you've created to avoid unnecessary resource usage. Choose the cleanup method that matches how you deployed.

### Option A: Clean up with Azure CLI

Use this option if you deployed using **Option A (Azure CLI + Bicep)** in Exercise 1.

1. Delete the resource group and all resources within it:

    ```powershell
    # Delete the resource group and all resources within it
    az group delete --name $RG --yes --no-wait

    Write-Host "Resource group deletion initiated. This may take a few minutes."

    ```

1. Verify the deletion:

    ```powershell
    # Check if resource group still exists
    az group exists --name $RG

    ```

### Option B: Clean up with Azure Developer CLI (azd)

Use this option if you deployed using **Option B (azd)** in Exercise 1.

1. Run the azd down command to delete all resources:

    ```powershell
    # Delete all Azure resources provisioned by azd
    azd down --force --purge

    Write-Host "All resources have been deleted."

    ```

    > **Note**: The `--force` flag skips confirmation prompts, and `--purge` permanently deletes soft-deleted resources like Key Vault secrets.

## Summary

In this exercise, you learned how to:

| Skill | What You Did |
|-------|--------------|
| **Infrastructure Deployment** | Deployed Azure Container Apps infrastructure using Bicep templates via Azure CLI |
| **Container Management** | Built, pushed, and deployed container images to Azure Container Registry |
| **Auto-Scaling** | Observed HTTP-based auto-scaling under load with no additional configuration |
| **Traffic Splitting** | Implemented blue-green deployments with percentage-based traffic routing |
| **Container Jobs** | Worked with scheduled, manual, and parallel batch processing jobs |
| **Security** | Used Managed Identity and Key Vault for secure secret management |
| **CI/CD Pipelines** | Set up Azure DevOps Pipelines for automated build and deployment of Container Apps |

### Key Takeaways

- **Azure Container Apps** provides a serverless container platform without Kubernetes complexity
- **Auto-scaling** is built-in and requires only simple threshold configuration
- **Traffic splitting** enables zero-downtime deployments and A/B testing
- **Container Jobs** replace Kubernetes CronJobs with simpler configuration
- **Managed Identity** provides secure, passwordless authentication to Azure services
- **Azure DevOps Pipelines** automate the entire CI/CD workflow from code commit to production deployment

## Additional Resources

- [Azure Container Apps Documentation](https://learn.microsoft.com/azure/container-apps/)
- [Container Apps Scaling](https://learn.microsoft.com/azure/container-apps/scale-app)
- [Traffic Splitting](https://learn.microsoft.com/azure/container-apps/revisions-manage)
- [Container Apps Jobs](https://learn.microsoft.com/azure/container-apps/jobs)
- [Managed Identity](https://learn.microsoft.com/azure/container-apps/managed-identity)
- [Azure DevOps Pipelines](https://learn.microsoft.com/azure/devops/pipelines/)
- [Deploy to Azure Container Apps from Azure Pipelines](https://learn.microsoft.com/azure/container-apps/azure-pipelines)
