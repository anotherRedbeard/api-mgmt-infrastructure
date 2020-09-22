# api-mgmt-infrastructure

This repository is for templates that will be deployed into Azure

## Setup

We will be using the Azure Cloud Shell to do the deployments, but the templates are setup to be used in a release pipeline as well.

### Deployment Process Sequence

1. We will be creating multiple templates per logical unit of work.  For example, there will be one ARM template for the ODS database/server/storage account and a separate templates for other work.  This will allow for the templates to be smaller and manageable and we can even break them up into one template per resource if necessary.
2. First you have to upload the template that you are wanting to deploy to the cloud shell
      1. Select the upload option and find the template you want to upload to the cloud shell, it should be in this repo!!
      2. Once you have it uploaded you will see a message indicating it was complete
3. Then you will want to upload the parameter file that matches that template for the environment you want to deploy to.
      1. So for example: KeyVault-template.json will have a matching KeyVault-template-dev.parameter.json and KeyVault-template-prd.parameter.json file.
      2. Choose the one you want to deploy based on the environment extension (-dev or -prd).
      3. Follow the same instructions above to upload the parameter file into the cloud shell.
4. Then you will want to run the following command(s) to deploy the template you just uploaded.  This example is using the KeyVault-template.json file, so if you are using another template make sure to replace the filename below.
      1. Most of the time the resource group will already be created but if it hasn't been created you will need to run a command similar to this (using the new resource group name and Azure location like "southcentralus") to create the resource group before you deploy to it.  If you already have a resource group created you can skip this step.

            ```bash
            user@Azure:~$ az group create --name <**ResourceGroupName**> --location <**AzureLocation**>
            ```

      2. You can run this command once you've confirmed you already have the resource group created in the correct location to deploy the template using the parameter file you just uploaded.  

            ```bash
            user@Azure:~$ az deployment group create -g <**ResourceGroupName**> --template-file <**TemplateFileName.json**>
            ```

            **In some cases you will NOT want to store parameter values in the .parameters.json file.  These would be things like passwords and connections strings.  We are using Azure Key Vault for these values and access them directly from the parameter file so they aren't saved in any file, but should you need to overwrite any parameter you can use the --parameters switch on the az deployment command to add these additional parameters**

            ```bash
            user@Azure:~$ az deployment group create -g <**ResourceGroupName**> --template-file <**TemplateFileName.json**> --parameters <**ParametersFileName.json**> --parameters MySecretValue=SuperSecretPassword
            ```

### Deployment Sequence Used

This is the deployment sequence for a full deployment, if you are just doing a partial deployment make sure you follow the order.  The sub-items are the parameters for each template with an example of their default values.

1. KeyVault-template.json
      1. Description
            1. The template that will created the enterprise key vault.
      2. Parameters
            1. **vaults_enterprise_kv_dev_name** - "ar-enterprise-kv-dev"
            2. **kv_sku_name** - "Standard"
            3. **kv_secrets_sql_admin_pwd_name** - "sqlserver-admin-pwd"
            4. **kv_secrets_sql_admin_pwd_value** - @passwordVariable - This is the sql server admin password
            5. **ad_tenant_id** - @tenant_idVariable - This is the AD tenant id
            6. **ad_object_id_kv_access** - @object_idVariable - This is the object id of the user you want to have access to the key vault
            7. **location** - "southcentralus"
      3. Deployment script

            Run this first if the resource group hasn't been created yet.

            ```bash
            user@Azure:~$ az group create --name <**ResourceGroupName**> --location <**AzureLocation**>
            ```

            ```bash
            user@Azure:~$ az group create -g ar-scus-enterprise-rg-dev --location southcentralus
            user@Azure:~$ az deployment group create -g ar-scus-enterprise-rg-dev --template-file KeyVault-template.json  --parameters KeyVault-template-dev.parameters.json --parameters kv_secrets_sql_admin_pwd_value=<**Password_Value**> --parameters ad_tenant_id=<**AD_Tenant_ID**> --parameters ad_object_id_kv_access=<**AD_Object_ID**>
            ```

2. OdsAzureSql-template.json
      1. Description
            1. The template that will created the sql server, database and storage account.
      2. Parameters
            1. **servers_sql_server_name** - "ar-scus-dataestate-dev"
            2. **storageAccounts_sqlvargbjzt5sludoa_name** - "desqlstoragesbx"
            3. **sqlAdminLogin** - "loginAdmin"
            4. **sqlAdminLoginPassword** - "Password" (this is where you would enter your secure password)
            5. **enterprise_kv_name** - keyvault name to get the password from
            6. **sqlDbSKUServiceObjective** - "SO" (This is the pricing tier you want for your database)
            7. **sqlDbSKUEdition** - "Standard" (This is the name of the pricing tier you want for your database)
            8. **location** - "southcentralus"
      3. Deployment script

            Run this first if the resource group hasn't been created yet.

            ```bash
            user@Azure:~$ az group create --name <**ResourceGroupName**> --location <**AzureLocation**>
            ```

            ```bash
            user@Azure:~$ az group create -g ar-scus-enterprise-rg-dev --location southcentralus
            user@Azure:~$ az deployment group create -g ar-scus-enterprise-rg-dev --template-file OdsAzureSql-template.json  --parameters ODSAzureSql-template-dev.parameters.json
            ```

      4. Add Active Directory admin
            1. In order for someone to login with an AD account you have to setup permissions as an AD user.  That is why you will need to add an Active Directory admin.  Here are the steps to do that.
            2. Navigate to the resource group and sql server instance you just created above.
            3. Now click on the Active Directory admin and verify there is someone there that can create the rest of the user/roles.

3. Database Scripts
    1. Description
        1. This is where all the database scripts will be stored.  I pulled the database setup from <https://www.sqlservertutorial.net/>, they had an example of creating a BikeStore so I thought I would use the scripts located there.  Please go <https://www.sqlservertutorial.net/sql-server-sample-database/> for more information on the setup of the database using those scripts.  The only modification I made was to change the name of the database from BikeStore to ODS to match what I've already created above.
    2. Deployment scripts
        1. Run the scripts in this order to setup the database
            1. Database/ODS/CreateODSObjects.sql
            2. Database/ODS/LoadODSData.sql
            3. (Optional) Database/ODS/CleanUpODS.sql - this will remove all data and objects from the ODS that you just created

4. Api-template.json
    1. Description
        1. This template will create the azure functions and all of it's related resources.
    2. Parameters
        1. **serverfarms_consumption_name** - "ar-scus-funcs-asp-dev" - App service plan to run the functions in
        2. **func_app_insights_name** - "ar-scus-funcs-ai-dev" - App insights for the functions
        3. **sales_func_app_name** - "ar-scus-salesapi-fa-dev" - Sales function app name
        4. **production_func_app_name** - "ar-scus-productionapi-fa-dev" - Production function app name
        5. **storage_acct_name** - "arfuncationappsdev001" - Storage account name
    3. Deployment script

        Run this first if the resource group hasn't been created yet.

        ```bash
        user@Azure:~$ az group create --name <**ResourceGroupName**> --location <**AzureLocation**>
        ```

        ```bash
        user@Azure:~$ az group create -g ar-scus-apis-rg-dev --location southcentralus
        user@Azure:~$ az deployment group create -g ar-scus-apis-rg-dev --template-file Api-template.json  --parameters Api-template-dev.parameters.json
        ```
