---
lab:
    title: 'Lab: Deploy and manage a container app using Azure Container Apps'
    type: 'Answer Key'
    module: 'Module 1: Exploring Azure Resource Manager'
---

# Lab: Deploy and manage a container app using Azure Container Apps
# Student lab answer key

## Instructions

In this lab, you deploy and manage an app using Azure Container Apps. To achieve your solution requirements, you configure Azure Container Registry, Azure Container Apps, and an Azure Pipelines as the primary resources.  

By the end of this lab, you're able to:

1. Configure a secure connection between an Azure Container Registry and an Azure Container Apps
1. Create and configure a container app in Azure Container Apps
1. Configure continuous integration by using Azure Pipelines
1. Scale a deployed app in Azure Container Apps
1. Manage revisions in Azure Container Apps

### Before you start

The lab environment includes Azure resources and tools configured on a virtual machine that represents a local host computer.

The following Azure resources have been configured in a Resource Group named "RG1":

    - Virtual Network with subnets
    - Service Bus
    - Azure Container Registry

The following tools and resources are configured on a virtual machine host:

    - Docker Desktop.
    - Visual Studio Code with Docker and Azure App Service extensions.
    - Azure CLI with `containerapp` extension.
    - Windows PowerShell.
    - A self-hosted Windows agent.

#### Setup Task

Complete the following steps to ensure that your lab environment is configured as expected:

1. Launch your lab environment.

1. Log in to the virtual machine.

1. Verify that the following tools are installed in the virtual machine environment:

    - Docker Desktop: Docker Desktop should start running when the virtual machine boots up.
    - Visual Studio Code: Visual Studio Code should be configured with Docker and Azure App Service extensions.
    - Azure CLI: Azure CLI should be installed with `containerapp` extension.
    - Windows PowerShell: Windows PowerShell should be installed.
    - Self-hosted Windows agent: A self-hosted Windows agent should be configured in the `C:\agents` folder of the virtual machine.

1. Open your Azure portal and ensure that you're logged in using the assigned account for your lab.

1. Verify that Azure resources are  


    - Virtual Network

        - Subscription: the Azure subscription that you're using for this lab
        - Resource group name: RG1
        - Virtual network name: VNET1
        - Region: Central US

        The virtual network includes two subnets.

        - Subnet 1

            - Name: PESubnet
            - Starting address: 10.0.0.0
            - Subnet size: /24 (256 addresses)

        - Subnet 2

            - Name: ACASubnet
            - Starting address: 10.0.4.0
            - Subnet size: /23 (512 addresses)

    - Service Bus

        - Subscription: the Azure subscription that you're using for this lab
        - Resource group name: RG1
        - Namespace name: sb-apl2003- followed by unique identifier. 
        - Location: Central US
        - Pricing tier: Basic

    - Azure Container Registry

        - Subscription: the Azure subscription that you're using for this lab
        - Resource group: RG1
        - Registry name: acrapl2003 followed by unique identifier
        - Location: Central US
        - SKU: Premium

### Exercise 0: 

#### Task 0: 

1. ?

    1. ?

1. ?

    > **Note**: ?

1. ?

### Exercise 1: Configure Azure Container Registry for a secure connection with Azure Container Apps

In this exercise, you configure a container registry instance for a secure connection from a container app.

The following Azure resources must be available in your Resource group named RG1:

- A Container Registry instance that contains one image.
- A Virtual Network with subnets.
- Service Bus Namespace

You've been asked to configure your Azure resources to meet the following requirements:

- Your resource group must include a user-assigned managed identity.
- Your container registry must be able to use the managed identity to pull artifacts.
- Access for the managed identity must be limited using the principle of least privilege.
- Your container registry must be accessible from a private endpoint on VNET1/PESubnet.

#### Task 1: Configure a user-assigned managed identity

Complete the following steps to configure a user-assigned managed identity.

1. Open your Azure portal

1. On the portal menu, select **+ Create a resource**.

1. On the Create a resource page, in the Search services and marketplace text box, enter **managed identity**

1. In the filtered list of resources, select **User Assigned Managed Identity**.

1. On the User Assigned Managed Identity page, select **Create**.

1. On the Create User Assigned Managed Identity page, specify the following information:

    - Subscription: Specify the Azure subscription that you're using for this guided project.
    - Resource group: **RG1**
    - Region: **Central US**
    - Name: **uai-apl2003**

1. Select **Review + create**.

1. Select **Create**.

#### Task 2: Configure your container registry with AcrPull permissions for the managed identity

Complete the following steps to configure Container Registry with AcrPull permissions for the managed identity.

1. In the Azure portal, open your Container Registry resource.

1. On the left-side menu, select **Access Control (IAM)**.

1. On the Access Control (IAM) page, select **Add role assignment**.

1. Search for the AcrPull role, and then select **AcrPull**.

1. Select **Next**.

1. On the Members tab, to the right of Assign access to, select **Managed identity**.

1. Select **+ Select members**.

1. On the Select managed identities page, under Managed identity, select **User-assigned managed identity**, and then select the user-assigned managed identity created for this project.

    For example: `uai-apl2003`.

1. On the Select managed identities page, select **Select**.

1. On the Members tab of the Add role assignment page, select **Review + assign**.

1. On the Review + assign tab, select **Review + assign**.

1. Wait for the role assignment to be added.

#### Task 3: Configure your container registry with a private endpoint connection

Complete the following steps to configure your container registry with a private endpoint connection.

1. Ensure that your Container Registry resource is open in the portal.

1. Under Settings, select **Networking**.

1. On the Private access tab, select **+ Create a private endpoint connection**.

1. On the Basics tab, under Project details, specify the following information:

    - Subscription: Specify the Azure subscription that you're using for this guided project.
    - Resource group: **RG1**
    - Name: **pe-acr-apl2003**
    - Region: Ensure that **Central US** is selected.

1. Select **Next: Resource**.

1. On the Resource tab, ensure the following information is displayed:

    - Subscription: Ensure that the Azure subscription that you're using for this guided project is selected.
    - Resource type: Ensure that **Microsoft.ContainerRegistry/registries** is selected.
    - Resource: Ensure that the name of your registry is selected.
    - Target sub-resource: Ensure that **registry** is selected.

1. Select **Next: Virtual Network**.

1. On the Virtual Network tab, under Networking, ensure the following information is displayed:

    - Virtual network: Ensure that **`VNET1`** is selected
    - Subnet: Ensure that **`PESubnet`** is selected.

1. Select **Next: DNS**.

1. On the DNS tab, under Private DNS Integration, ensure the following information is displayed:

    - Integrate with private DNS zone: Ensure that **Yes** is selected.
    - Private DNS Zone: Notice that **(new) privatelink.azurecr.io** is specified.

1. Select **Next: Tags**.

1. Select **Next: Review + create**.

1. On the Review + create tab, when you see the Validation passed message, select **Create**.

1. Wait for the deployment to complete.

#### Review

In this exercise, you completed the following:

- you created a user-assigned managed identity.
- you ensured that the managed identity can pull artifacts by using the principle of least privilege.
- you ensured that your Azure Container Registry can be accessed from a private endpoint on VNET1/PESubnet.

To verify that your configuration meets the specified requirements, complete the following steps:

1. In the Azure portal, open your Container Registry resource.

1. On the Access Control (IAM) page, select **Role assignments**.

1. Verify that the role assignments list shows the **AcrPull** role assigned to the User-assigned Managed Identity resource.

1. On the left-side menu, under Settings, select **Networking**.

1. On the Networking page, select the **Private access** tab.

1. Under Private endpoint, select the private endpoint that you created.

    For example, select **per-acr-apl2003**

1. On the Private endpoint page, under Settings, select **DNS configuration**.

1. Verify the following DNS setting:

    - Private DNS zone: set to **privatelink.azurecr.io**.

1. On the left-side menu, select **Overview**.

1. Verify the following setting:

    - Virtual network/subnet: set to **VNET1/PESubnet**.

### Exercise 2: Create and configure a container app in Azure Container Apps

In this exercise, you deploy a container app from an image in the Azure Container Registry to the Azure Container Apps platform.

The following Azure resources must be available in your Resource group named RG1:

- A Container registry instance that contains one image.
- A Virtual network with subnets.
- A Service Bus Namespace
- A Managed Identity
- A Private endpoint

You've been asked to configure a container app that meets the following requirements:

- Is deployed to VNET1/ACASubnet.
- Pulls an image from a container registry.
- Authenticates using a user-assigned managed identity (uai-apl2003).
- Uses Container App to connect to a Service Bus instance using the .NET client type.
- The app can run up to two replicas that are added whenever there are 10,000 HTTP concurrent requests.

You complete the following tasks during this exercise:

1. Create a container app that uses an ACR image

1. Configure the container app to authenticate using the user assigned identity

1. Configure a connection between the container app and Service Bus

1. Configure HTTP scale rules

1. Verify the configuration

#### Task 1:  Create a container app that uses an ACR image

Complete the following steps to create a container app that uses an ACR image.

1. Open your Azure portal.

1. On the portal menu, select **+ Create a resource**.

1. On the top search bar, in the Search textbox, enter **container app**

1. In the search results under Services, select **Container App**.

1. Select **Create**.

1. On the Basics tab, specify the following:

    - Subscription: Specify the Azure subscription that you're using for this guided project.
    - Resource group: **RG1**
    - Container app name: **aca-apl2003**
    - Region: Select the Region specified for VNET1 (Central US).

        The container app needs to be in the same region/location as the virtual network so you can choose VNET1 for the managed environment. For this guided project, keep all of your resources in the region/location specified for your resource group.

    - Container Apps Environment: Select **Create new**.

1. On the Create Container Apps Environment page, select the **Networking** tab, and then specify the following:

    - Use your own virtual network: Select **Yes**.
    - Virtual network: Select **VNET1**.
    - Infrastructure subnet: **ACASubnet**.

    > [!NOTE]
    > If the ACASubnet subnet is not listed, open your virtual network resource, adjust the subnet address range to **10.0.2.0/23** and retry the steps to create the Container App.

1. On the Create Container Apps Environment page, select **Create**.

1. On the Create Container App page, select the Container tab, and then specify the following:

    - Use quickstart image: **Uncheck** this setting.
    - Name: Enter **aca-apl2003**
    - Image source: Ensure that **Azure Container Registry** is selected.
    - Registry: Select your container registry. For example: **acrapl2003cah.azurecr.io**
    - Image: Select **aspnetcorecontainer**
    - Image tag: Select **latest**

1. Select **Review + create**.

1. Once verification has Passed, select **Create**.

1. Wait for the deployment to complete.

    > [!NOTE]
    > This deployment can take about 10 minutes to complete.

#### Task 2: Configure the container app to authenticate using the user assigned identity

Complete the following steps to configure the container app to authenticate using the user assigned identity.

1. On the Azure portal, open the Container App that you created.

1. Under Settings, select **Identity**.

1. Select the tab for **User assigned**.

1. Select **Add user assigned managed identity**.

1. On the Add user assigned managed identity page, select **uai-apl2003**, and then select **Add**.

#### Task 3: Configure a connection between the container app and Service Bus

Complete the following steps to configure a connection between the container app and Service Bus.

1. On the Azure portal, ensure that you have your Container App open.

1. Under Settings, select **Service Connector (Preview)**.

1. Select **Connect to your Services**.

1. On the Create connection page, specify the following:

    - Service type: Select **Services Bus**.
    - Client type: Select **.NET**.

1. Select **Next: Authentication**.

1. On the Authentication tab, select **User assigned managed identity**.

1. To change tabs, select **Review + Create**.

1. Once the Validation passed message appears, select **Create**.

1. Wait for the connection to be created.

#### Task 4: Configure HTTP scale rules

Complete the following steps to configure HTTP scale rules for your Container App.

1. Ensure that your Container App is open in the portal.

1. On the left-side menu under Application, select **Revisions**.

1. Notice the Name assigned to your active revision.

1. On the left-side menu under Application, select **Scale and replicas**.

1. To the right of Revision, ensure that your active revision is selected.

1. At the top of the page, select **Edit and deploy**.

1. At the bottom of the page, select **Next : Scale**.

1. Configure the Min / max replicas as follows:

    - Set Min replicas: 0
    - Set Max replicas: 2

1. Under Scale rule, select **+ Add**.

1. On the Add scale rule page, specify the following:

    - Rule name: Enter **scalerule-http**
    - Type: Select **HTTP scaling**.
    - Concurrent requests: Set the value to **10,000**.

1. On the Add scale rule page, select **Add**.

1. On the Create and deploy new revision page, select **Create**.

1. Ensure that your new scale rule is displayed.

#### Review

In this exercise, you created a container app that meets the following requirements:

- is deployed to VNET1/ACASubnet
- pulls an image from Azure Container Registry
- authenticates using the managed identity
- uses Container App to connect to a Service Bus instance using the .NET client type
- the app can run up to two replicas, where scaling is based on HTTP scaling rules

To verify that your configuration meets the specified requirements, complete the following steps:

1. In the Azure portal, ensure that your Container App resource is open.

1. On the left-side menu, under Settings, select **Continuous deployment**.

1. Verify that the expected values are selected:

    - Repository source: **Azure Container Registry**
    - Registry: the name of your Container Registry (for example: acrapl2003cah)
    - Image: **aspnetcorecontainer**

1. Close the Container App page.

1. Open your Container App Environment resource.

1. Verify that your Container App uses the proper subnet as follows:

    - On the Overview page, verify that Virtual Network is set to **VNET1**.
    - On the Overview page, verify that Infrastructure subnet is set to **ACASubnet**.

1. In the Azure portal, open PowerShell.

1. Run the following command:

    ```azurecli
    az containerapp connection show [--connection]
                                    [--name]
                                    [--resource-group]
    
    ```

    For example:

    ```azurecli
    az containerapp connection show --connection servicebus_b2a10 --name aca-apl2003 --resource-group RG1  
    ```

1. Verify that the targetService properties match the specified configuration.

1. To verify your HTTP scale rule, run testing software to simulate 10,000 concurrent HTTP requests and ensure that container replicas are created.

### Exercise 3: Configure continuous integration by using Azure Pipelines

In this exercise, you deploy a container app from an image in the Azure Container Registry to the Azure Container Apps platform.

The following Azure resources must be available in your Resource group named RG1:

- A Container registry instance that contains one image.
- A Virtual network with subnets.
- A Service Bus Namespace
- A Managed Identity
- A Private endpoint
- A Container App
- A Container Apps Environment

You've been asked to configure a continuous integration environment for Container Apps that meets the following requirements:

- You need an Azure Container Apps deployment task in your ADO environment.
- `Pipeline1` must deploy a container image from your container registry to your container app using a self-hosted agent pool.
- You must ensure that the pipeline successfully deploys the image at least once.

You complete the following tasks during this exercise:

1. Configure `Pipeline1` to use the self-hosted agent pool.

1. Configure `Pipeline1` with an Azure Container Apps deployment task.

1. Run the `Pipeline1` deployment task.

1. Verify the configuration.

#### Task 1: Configure `Pipeline1` to use the self-hosted agent pool

Complete the following steps to configure your pipelines to use the self-hosted agent pool.

1. Open a browser window, navigate to https://dev.azure.com, and then open your Azure DevOps organization.

1. On your Azure DevOps page, to open your DevOps project, select **`Project1`**.

1. In the left-side menu, select **`Pipelines`**.

1. Select **`Pipeline1`**, and then select **Edit**.

1. To use the self-hosted agent pool, update the azure-pipelines.yml file as shown in the following example:

    ```yml
    trigger:
    - main

    pool:
      name: default

    steps:

    ```

1. Select **Save**.

1. Enter a commit message, and then select **Save**.

#### Task 2: Configure `Pipeline1` with an Azure Container Apps deployment task

1. Ensure that you have `Pipeline1` open for editing.

1. On the right side under Tasks, in the Search tasks field, enter **azure container**

1. In the filtered list of tasks, select **Azure Container Apps Deploy**

1. Under Azure Resource Manager connection, select the Subscription you're using, and then select **Authorize**.

1. In the Azure portal tab, open your Container App resource, and then open the Containers page.

1. Use the information on the Containers page to configure the following `Pipeline1` Task information:

    - Docker Image to Deploy: `<Registry>/<Image>:<Image tag>`
    - Azure Container App name: `<Name>`

1. Configure the following `Pipeline1` Task information:

    - Azure Resource group name: **RG1**

    > [!NOTE]
    > If you need to verify the resource group name, you can find it on the Overview page of your Container App resource.

1. On the Azure Container Apps Deploy page, select **Add**.

    The Yaml file for your pipeline should now include the AzureContainerApps tasks as follows:

    ```yml
    trigger:
    - main
    pool:
      name: default
    steps:
    - task: AzureContainerApps@1
      inputs:
        azureSubscription: '<Subscription>(<Subscription ID>)'
        imageToDeploy: '<Registry>/<Image>:<Image tag>' from Container App resource
        containerAppName: '<Name>' from Container App resource 
        resourceGroup: '<resource group name>'
    
    ```

    Here's an example that shows a YAML configuration snippet:

    ```yml
    trigger:
    - main
    pool:
      name: default
    steps:
    - task: AzureContainerApps@1
      inputs:
        azureSubscription: 'Visual Studio Enterprise(1111aaaa-22bb-33cc-44dd-555555eeeeee)'
        imageToDeploy: 'acrapl2003cah12oct.azurecr.io/aspnetcorecontainer:latest'
        containerAppName: 'aca-apl2003'
        resourceGroup: 'RG1'
    ```

1. Select **Save**, and then select **Save** again to commit.

#### Task 3: Run the `Pipeline1` deployment task

1. Ensure that you have `Pipeline1` open in Azure DevOps.

1. To run the AzureContainerApps task, select **Run**.

1. On the Run pipeline page, select **Run**.

    A pipeline page opens to display the associated job. The job section displays job status, which progresses from Queued to Waiting.

    ![Screenshot of Azure Pipelines showing a successful run of Pipeline1.](../media/pipeline-progress-queued-waiting.png)

    It can take a couple minutes for the status to transition from Queued to Waiting.

1. If 'Permission needed' is displayed under Job,  requires permission to proceed (), view the requirement and provide the required permissions.

1. Monitor the status of the run operation and verify that the run is successful.

    ![Screenshot of Azure Pipelines showing a successful run of Pipeline1.](../media/pipeline-progress-run-success.png)

#### Review

In this exercise, you configured an Azure Pipeline that meets the following requirements:

- deploys a container image from your container registry to your container app using a self-hosted agent pool.

To verify that your pipeline deployed the app image successfully, complete the following steps:

1. Ensure that you have `Project1` open in Azure DevOps.

1. On the left side menu, select **Pipelines**, and then select **`Pipeline1`**.

1. The Runs tab displays individual runs that can be selected to review details.

    ![Screenshot of Azure Pipelines showing a successful run of Pipeline1.](../media/pipeline-run-validation-devops.png)

1. Open your Azure portal, and then open your Container App.

1. On the left side menu, select **Activity Log**.

1. Verify that a **Create or Update Container App** operation succeeded as a result of running your pipeline.

    ![Screenshot of a Container App Activity Log showing a successful Create or Update Container App operation.](../media/pipeline-run-validation-azure-portal.png)

    Notice that the **Event initiated by** column on the right shows your `Project1` as the source.

### Exercise 4: Manage revisions in Azure Container Apps

In this exercise, you deploy a new revision of your container app and configure traffic splitting between two labeled revisions.

The following Azure resources must be available in your Resource group named RG1:

- A Container registry instance that contains one image.
- A Virtual network with subnets.
- A Service Bus Namespace
- A Managed Identity
- A Private endpoint
- A Container App
- A Container Apps Environment

You've been asked to configure traffic splitting for your Container Apps to meet the following requirements:

- You need to create a new revision of the container app that uses a suffix of v2.
- You must ensure that 25 percent of requests to your app are directed to the v2 revision.
- You must label the revisions "current" and "updated" and ensure that requests to the "---updated" revision are directed to the v2 revision.

You complete the following tasks during this exercise:

1. Set revision management to multiple.

1. Create a new revision with a v2 suffix.

1. Configure labels on the revisions.

1. Configure a traffic percentage on the revisions.

1. Verify the configuration.

#### Task 1: Set revision management to multiple

1. In the Azure portal, open your container app resource.

1. On the left side menu, under Revisions, select **Revisions**.

1. At the top of the Revisions page, select **Choose revision mode**.

1. To switch from single to multi-revision mode, select **Confirm**.

1. On the Revisions page, wait for the **Revision Mode** setting to update.

    The Revision Mode will be set to **Multiple** after the update.

#### Task 2: Create a new revision with a v2 suffix

1. In the Azure portal, ensure that you have the Revisions page of your container app resource open.

1. At the top of the page, select **+ Create new revision**.

1. On the Create and deploy new revision page, complete the following steps:

    - Name / suffix: Enter **v2**
    - Under Container image, select your container image. For example, aca-apl2003.

1. Select **Create**.

1. Wait for the deployment to be completed.

#### Task 3: Configure labels on the revisions

1. On the left-side menu, under Settings, select **Ingress**.

1. If Ingress isn't enabled, select **Enabled**.

1. On the Ingress page, specify the following information:

    - Ingress traffic: select **Accepting traffic from anywhere**.

    - Ingress type: select **HTTP**.

    - Client certificate mode: ensure that **Ignore** is selected.

    - Transport: ensure that **Auto** is selected.

    - Insecure connections: ensure that Allowed is **NOT** checked.

    - Target port: enter **80**

    - IP Security Restrictions Mode: ensure that **Allow all traffic** is selected.

1. At the bottom of the Ingress page, select **Save**, and then wait for the update to complete.

1. On the left-side menu, under Revisions, select **Revisions**.

1. For the v2 revision, under Label, enter **updated**

1. For the other revision, enter **current**

1. At the top of the page, select **Save**.

#### Task 4: Configure a traffic percentage on the revisions

1. Ensure that you have the Revisions page open.

1. For the v2 revision, under Traffic, enter **25** as the percentage.

1. For the other revision, under Traffic, enter **75** as the percentage.

1. At the top of the page, select **Save**.

#### Review

1. Ensure that you have your Container App open in the Azure portal.

1. On the left-side menu, under Revisions, select **Revisions**.

1. Verify that your revisions are configured as follows:

    ![Screenshot of a Container App revisions configured with labels for traffic-splitting.](../media/container-app-traffic-splitting-percentage-labels.png)
