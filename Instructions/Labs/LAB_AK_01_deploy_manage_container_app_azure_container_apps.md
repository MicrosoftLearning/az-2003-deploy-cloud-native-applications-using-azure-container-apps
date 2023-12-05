---
lab:
    title: 'Lab: Deploy and manage a container app using Azure Container Apps'
    type: 'Answer Key'
    module: 'Module 6: Deploy and manage a container app using Azure Container Apps'
---

# Lab: Deploy and manage a container app using Azure Container Apps
# Student lab answer key

## Instructions

In this lab, you deploy and manage an app using Azure Container Apps. To implement the solution, you begin by configuring the development environment with local tools and Azure resources. Once the environment is prepared, you use Azure Container Registry, Azure Container Apps, and Azure Pipelines to deploy and manage your app.  

By the end of this lab, you're able to:

1. Configure a secure connection between an Azure Container Registry and an Azure Container Apps
1. Create and configure a container app in Azure Container Apps
1. Configure continuous integration by using Azure Pipelines
1. Scale a deployed app in Azure Container Apps
1. Manage revisions in Azure Container Apps

### Exercise 1: Configure Azure resources

In this exercise, you configure Azure resources that support your Azure Container Apps solution.

You will complete the following tasks:

- Configure an Azure Virtual Network with subnets.
- Configure an Azure Service Bus.
- Configure an Azure Container Registry.

#### Task 2: Examine resource group settings

Complete the following steps to examine resource groups settings.

1. In the lab environment, open a browser window, and then navigate to the Azure portal: `https://portal.azure.com/`

    Work with your classroom instructor if need help signing into the Azure portal with a valid subscription/account.

1. On your Azure portal Home page, under **Navigate**, select **Resource groups**.

1. On the Resource groups page, select **RG1**.

    If the **RG1** resource group has not been created, create it now.

1. Make note of the **Location** setting assigned to the **RG1** resource group.

    You will use the same location/region when creating other Azure resources during this lab.

1. Close the **RG1** page and then close **Resource groups** page.

#### Task 2: Configure a Virtual Network and subnets

1. On the top search bar of the Azure portal, in the Search textbox, enter **virtual network**

1. In the search results, select **Virtual networks**.

1. Select **Create virtual network**.

1. On the Basics tab, configure your virtual network as follows:

    - Subscription: Ensure that the Azure subscription that you're using for this guided project is selected.
    - Resource group name: Select **RG1**
    - Virtual network name: Enter **VNET1**
    - Region: Ensure that specified Region matches the location setting of your resource group.

1. Select the **IP addresses** tab.

1. On the IP addresses tab, under **Subnets**, select **default**.

1. On the Edit subnet page, configure the subnet as follows:

    - Name: Enter **`PESubnet`**
    - Starting address: Ensure that **10.0.0.0** is specified.
    - Subnet size: Ensure that **/24 (256 addresses)** is specified.

1. Select **Save**.

1. On the IP addresses tab, select **+ Add a subnet**.

1. On the Add a subnet page, configure the subnet as follows:

    - Name: Enter **`ACASubnet`**
    - Starting address: Ensure that **10.0.4.0** is specified.
    - Subnet size: Ensure that **/23 (512 addresses)** is specified.

    The subnet for Azure Container Apps requires an address space larger than 256.

1. Select **Add**.

1. Select **Review + create**.

1. Once validation has passed, select **Create**.

1. Wait for the deployment to complete, and then close the VNET1 page.

#### Task 3: Configure Service Bus

Complete the following steps to configure a Service Bus instance.

1. On the top search bar of the Azure portal, in the Search textbox, enter **service bus**

1. In the search results, select **Service Bus**.

1. Select **Create service bus namespace**.

1. On the Basics tab, configure your Service bus namespace as follows:

    - Subscription: Ensure that the Azure subscription that you're using for this guided project is selected.
    - Resource group name: Select **RG1**
    - Namespace name: Enter **sb-apl2003-** followed by your initials and the date. For example: **sb-apl2003-cah12oct**.
    - Location: Ensure that specified Location matches the location setting of your resource group.
    - Pricing tier: Select **Basic**.

1. Select **Review + create**.

1. Once the Validation succeeded message appears, select **Create**.

1. Wait for the deployment to complete, and then close the Service Bus Namespace page.

#### Task 4: Configure Azure Container Registry

Complete the following steps to configure a Container Registry instance.

1. Ensure that you have your Azure portal open in a browser window.

1. On the top search bar of the Azure portal, in the Search textbox, enter **container registry**

1. In the search results, select **Container registries**.

1. On the Container registries page, select **Create container registry** or **+ Create**.

1. On the Basic tab of the Create container registry page, specify the following information:

    > [!NOTE]
    > The name of your Registry must be unique. Also, the Premium tier is required for private link with private endpoints.

    - Subscription: Ensure that the Azure subscription that you're using for this guided project is selected.
    - Resource group: Select **RG1**.
    - Registry name: Enter **acrapl2003** followed by your initials and date. For example: **acrapl2003cah12oct**
    - Location: Ensure that specified Location matches the location setting of your resource group.
    - SKU: Select **Premium**.

1. Select **Review + create**.

1. Once the Validation passed message appears, select **Create**.

1. After the deployment has completed, open the deployed resource.

1. On the left-side menu of the Container registry page, under **Settings**, select **Networking**.

1. On the Networking page, on the Public access tab, ensure that **All networks** is selected.

1. On the left-side menu, under **Settings**, select **Properties**.

1. On the Properties page, select **Admin user**, and then select **Save**.

1. Close the Container registry page.

1. Close your Azure portal (browser) window.

### Exercise 2: Configure developer tools in the host environment

In this exercise, you ensure that scripting and developer tools are configured correctly on the virtual machine.

#### Task 1: Ensure that Windows PowerShell in installed

Complete the following steps to ensure that Windows PowerShell is installed:

1. Open the Windows Start menu.

1. In the Search textbox, enter **windows powershell**

1. Verify that the Windows PowerShell app is listed.

    If Windows PowerShell isn't installed, open a browser window, installation instructions can be found here: `https://learn.microsoft.com/powershell/scripting/install/installing-powershell`

1. Close the Start menu.

#### Task 2: Configure Azure CLI extensions

Complete the following steps to configure Azure CLI:

1. Open a command line or terminal application, such as Windows Command Prompt.

1. Sign in to Azure using the `az login` command.

    A browser window will open that allows you to select the Azure account.

1. Follow the prompts to complete the authentication process.

1. Close the browser window.

1. In the command line app, to install the Azure Container Apps extension, enter the following command: `az extension add --name containerapp --upgrade`

1. Close the command line app.

#### Task 3: Install Docker Desktop

Complete the following steps to install Docker Desktop:

1. Open your browser window, and then open a new tab.

1. Navigate to the Docker Desktop install page: `https://docs.docker.com/desktop/install/windows-install/`

    Links to instructions for Mac and Linux installs are available on this page.

1. Select **Docker Desktop for Windows** and wait for the installer file to download.

1. Open the installer file, and then follow the online instructions to install Docker Desktop.

    The installation process takes about 5 minutes.

1. Once the installation has completed, select **Close and restart**.

1. Wait for the **Docker Subscription Service Agreement** to appear.

1. On the ???? page, select **Accept**.

1. On the ???? page, select **Finish**.

1. On the ???? page, select **Yes**.

1. On the ???? page, select **Continue without signing in**.

1. On the ???? page, select **Skip**.

1. Minimize the Docker Desktop app.

#### Task 4: Install the .NET 8 SDK

1. In a web browser window, and then navigate to the .NET 8 SDK download page: `https://dotnet.microsoft.com/download`

1. Select **.NET SDK x64**

1. Once the download is complete, open the installation file and follow the online instructions to install the .NET 8 SDK.

1. Close the browser window.

#### Task 5: Configure Visual Studio Code with C#, Docker, and Azure App Service extensions

Complete the following steps to configure Visual Studio Code extensions:

1. Use the Windows Start menu to launch Visual Studio Code.

    - You will be configuring Visual Studio Code extensions for C#, Docker, and Azure App Service during the lab.

1. On the **Activity bar**, select **Extensions**.

    The Activity bar is the vertical menu on the left side of the Visual Studio Code user interface.

1. In the **Search Extensions in Marketplace** textbox, enter **C#**

    Entering "C#" filters the list of extensions to show only the extensions that have something to do with C# coding.

1. In the filtered list of available extensions, select the extension labeled "**C# Dev Kit** - Official C# extension from Microsoft" that's published by Microsoft.

1. To install the extension, select **Install**.

1. Wait for the installation to complete.

1. On the **EXTENSIONS** view, replace **C#** with **docker**.

1. In the filtered list of available extensions, select the extension labeled **Docker**  that's published by Microsoft.

1. To install the extension, select **Install**.

1. Wait for the installation to complete.

1. On the **EXTENSIONS** view, replace **docker** with **azure app service**.

1. In the filtered list of available extensions, select the extension labeled **Azure App Service**  that's published by Microsoft.

1. To install the extension, select **Install**.

1. Wait for the installation to complete.

1. Close Visual Studio Code.

### Exercise 3: Create and configure app deployment resources

In this exercise, you create and deploy a container app, and deploy a self-hosted Windows agent.

You will complete the following tasks:

- Create a WebAPI app and publish the app to a GitHub repository.
- Create Docker image and push the image to Azure Container Registry.
- Configure an Azure DevOps project and starter pipeline.
- Deploy a self-hosted Windows agent.

#### Task 1: Create a WebAPI app and publish to a GitHub repository

Complete the following steps to create a WebAPI app and publish to a GitHub repository.

1. Open Visual Studio Code.

1. On the File menu, select **Open Folder**.

1. Create a new folder named **APL2003** in a location that is easy to find.

    For example, to create a folder named **APL2003** on the Windows Desktop:

    - In the Open Folder dialog, select **Desktop**.
    - Select **New folder**.
    - Type **APL2003** and then press Enter.
    - Select **Select Folder**.
    - If prompted, select **Yes, I trust the authors**.

1. On the Terminal menu, select **New Terminal**.

1. At the terminal command prompt, to create a new ASP.NET Web API project, enter the following command:

    ```dotnetcli
    dotnet new webapi --no-https
    ```

1. At the terminal command prompt, to add the Swagger package to your project, enter the following command:

    ```dotnetcli
    dotnet add package Swashbuckle.AspNetCore.Swagger --version 6.5.0
    ```

1. At the terminal command prompt, run the following dotnet CLI command:

    ```dotnetcli
    dotnet build
    ```

1. On the View menu, select **Command Palette**, and then run the following command: **.NET: Generate Assets for Build and Debug**.

    If the command generates an error message, select **OK**, and then run the command again.

1. In the root project folder, create a .gitignore file that contains the following information:

    ```gitignore
    [Bb]in/
    [Oo]bj/
    ```

1. On the File menu, select **Save All**.

1. Open the Source Control view.

1. Select **Publish to GitHub**.

1. If prompted, to enable the GitHub extension to sign in using GitHub, select **Allow**, and then provide authorization in GitHub.

1. In Visual Studio Code, select **Publish to GitHub public repository**.

#### Task 2: Create Docker image and push to Azure Container Registry

Complete the following steps to create a Docker image and push the image to your Azure Container Registry.

1. Ensure that you have your APL2003 code project open in Visual Studio Code.

1. To create a Dockerfile, run the following command in the Command Palette: **Docker: Add Docker Files to Workspace**.

1. When prompted, specify the following information:

    - Application Platform: **.NET ASP.NET Core**.
    - Operating System: **Linux**.
    - Ports: **5000**.
    - Docker Compose files: **No**.

1. At a terminal command prompt, run the following docker CLI command:

    ```azurecli
    docker build --tag aspnetcorecontainer:latest .
    ```

    The syntax for the build command is: `docker build --tag <image name>:<image tag> .`

    This command builds a container image that is hosted by Docker and accessible using the Docker extension for VS Code.

1. Open the Visual Studio Code Command Palette, and then run the following command: **Docker Images: Push**.

1. When the command runs, enter the following information:

    - Select the docker image name that you created: `aspnetcorecontainer`

    - Select the image tag that you created: `latest`

1. If you see a message stating that no registry is connected, select **Connect Registry**, and then enter the following information:

    - Registry provider: Select **Azure**. Follow the online instructions to verify your Azure account if needed.

    - Azure subscription: Select the Azure Subscription that you're using for this guided project.

    - Select your Azure Container Registry resource. For example: **acrapl2003cah12oct**

        An image tag is generated. For example: `acrapl2003cah12oct.azurecr.io/aspnetcorecontainer:latest`

    - To push the image to your Container Registry, press Enter.

    The following Docker command is executed:

    ```azurecli
    docker image push acrapl2003cah12oct.azurecr.io/aspnetcorecontainer:latest
    ```

1. Open the Source Control view, and then **Commit** and **Sync Changes**.

#### Task 3: Configure Azure DevOps and a starter Pipeline

Complete the following steps to configure Azure DevOps and a starter Pipeline:

1. Open the Azure portal.

1. On the top search bar, in the Search textbox, enter **devops**

1. In the search results, select **Azure DevOps organizations**.

1. Select **My Azure DevOps Organizations**.

1. If you haven’t created an organization, select **Free**.

1. To create a new project, select **New project**.

1. On the Create new project page, enter the following information:

    - Project name: **Project1**
    - Description: **APL-2003 project**
    - Visibility: **Public**

1. On the Create new project page, select **Create**.

1. On the left-side menu, select **Repos**.

1. Under Import a repository, select **Import**.

1. On the Import a Git repository page, enter the URL for the GitHub repository you created for your code project, and then select **Import**.

    Your repository URL should be similar to the following example:

    `https://github.com/<your account>/APL2003`

1. On the left-side menu, select **Pipelines**.

1. Select **Create Pipeline**.

1. Select **Azure Repos Git**.

1. On the Select a repository page, select **Project1**.

1. Select **Starter pipeline**.

1. Under Save and Run, select **Save**, and then select **Save**.

1. To rename the pipeline to `Pipeline1`, complete the following steps:

    1. On the left-side menu, select **Pipelines**.

    1. To the right of the Project1 pipeline, select **More options**, and then select **Rename/move**.

    1. In the Rename/move pipeline dialog, under Name, enter **Pipeline1** and then select **Save**.

#### Task 4: Deploy a self-hosted Windows agent

For an Azure Pipeline to build and deploy Windows, Azure, and other Visual Studio solutions you need at least one Windows agent in the host environment.

Complete the following steps to deploy a self-hosted Windows agent:

1. Ensure that you're signed-in to Azure DevOps with the user account you're using for your Azure DevOps organization.

    For example: `https://dev.azure.com/{your organization}`

1. From the home page of your organization, open your user settings, and then select **Personal access tokens**.

1. To create a personal access token, select **+ New Token**.

1. Under Name, enter **APL2003**.

1. At the bottom of the Create a new personal access token window, to see the complete list of scopes, select **Show all scopes**.

1. For the scope, select **Agent Pools (read, manage)** and **Deployment group (read, manage)**.

    Ensure that all the other boxes are cleared.

1. Select **Create**.

1. On the Success page, to copy the token, select **Copy to clipboard**.

    You use this token when you configure the agent.

1. Ensure that you’re signed into Azure DevOps as the Azure DevOps organization owner.

1. Select your DevOps organization, and then select **Organization settings**.

1. On the left side menu under Pipelines, select **Agent pools**.

1. If the **Get the agent** dialog box opens, skip to the next step.

    If a list of Agent pools is displayed, complete the following steps:

    1. To select the default pool, select **default**.

        If the **default** pool doesn't exist, select **Add pool**, and then enter the following information:

        1. Under Pool type, select **Self-hosted**.

        1. Under Name, enter **default**

        1. Select **Create**.

        1. To open the pool that you just created, select **default**.

    1. Select **Agents**, and then select **New agent**.

1. On the **Get the agent** dialog box, complete the following steps:

    1. Select the **Windows** tab.

    1. On the left pane, select the processor architecture of the installed Windows OS version on your machine.

        The x64 agent version is intended for 64-bit Windows, whereas the x86 version is intended for 32-bit Windows.

    1. On the right pane, select **Download**.

    1. Follow the instructions to download the agent.

1. Use File Explorer to create the following folder location for the agent:

    ```dos
    C:\agents
    ```

1. Unpack the agent zip file into the directory you created.

1. Open PowerShell as an Administrator, and then enter the following PowerShell command:

    `.\config`

1. Respond to the configuration prompts as follows:

    - Enter server URL >: enter the URL for your DevOps organization. Such as: `https://dev.azure.com/<your organization>`
    - Enter authentication type (press enter for PAT) >: press Enter.
    - Enter personal access token >: Paste-in the personal access token that you copied to the clipboard earlier.
    - Enter agent pool (press enter for default) >: press Enter.
    - Enter agent name (press enter for YOUR-PC-NAME) > enter **apl2003-agent**
    - Enter work folder (press enter for _work) >: press Enter.
    - Enter run agent as service? (Y/N) (press enter for N) >: enter **Y**
    - Enter enable SERVICE_SID_TYPE_UNRESTRICTED for agent service (Y/N) (press enter for N) >: enter **Y**
    - Enter User account to use for the service (press enter for NT AUTHORITY\NETWORK SERVICE) >: press Enter.
    - Enter whether to prevent service starting immediately after configuration is finished? (Y/N) (press enter for N) >: press Enter.

    A message informing you that the agent started successfully is displayed.

    For extra help, see the following documentation: `https://learn.microsoft.com/azure/devops/pipelines/agents/windows-agent`

### Exercise 4: Configure Azure Container Registry for a secure connection with Azure Container Apps

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
    - Region: Enter the Region that matches the region setting of your resource group.
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
    - Region: Ensure that specified Region matches the region setting of your resource group.

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

### Exercise 5: Create and configure a container app in Azure Container Apps

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
    - Region: Ensure that specified Region matches the region setting of VNET1.

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

### Exercise 6: Configure continuous integration by using Azure Pipelines

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

1. Open a browser window, navigate to `https://dev.azure.com`, and then open your Azure DevOps organization.

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

    It can take a couple minutes for the status to transition from Queued to Waiting.

1. If 'Permission needed' is displayed under Job,  requires permission to proceed (), view the requirement and provide the required permissions.

1. Monitor the status of the run operation and verify that the run is successful.

### Exercise 7: Manage revisions in Azure Container Apps

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
