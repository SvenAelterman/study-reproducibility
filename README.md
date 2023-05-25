# study-reproducibility
Sample Azure deployment to support running data science reproducibility

## pre-requisites


You can do this on your Desktop or in the [Cloud Shell](https://shell.azure.com).

If on the Desktop, you'll have to install some modules. Run the following command in PS:
```
Install-Module Az -Scope CurrentUser
```

## Deployment

Git clone this repo into the environment, and run
```
./deploy.ps1
```
Copy the output to a secure place.

As of 2022-04-19, "Workloadname" needs to be lowercase.

## Access

Access the desktop via [https://aka.ms/wvdarmweb](https://aka.ms/wvdarmweb).

- In the RG, go to "dag-*" and
  - Assignments -> add users
  - AIM -> Add Role -> "Virtual Machine Administrator/User Login" as appropriate
  - AIM -> Add Role -> "Windows Virtual Desktop" (x2) -> "Virtual Machine Contributor"
  
## Initial installs

- May need to install "App Installer" - should be installed, but was not in this case (maybe not accessible to non-root user?)
- Install the following apps: [needs automation]
```
winget install vscode
winget install Git.Git
winget install Github.cli
```

- Map network drive [needs automation]
```
net use U: \\STORAGEACOUNT.file.core.windows.net\study-repro /user:Azure\STORAGEACCOUNT /global /savecred PASSWORD
```
where STORAGEACCOUNT and PASSWORD need to be replaced.

Service principal: IL-LDI-AzureAutomation

## Set a few secrets

```
for SECRET in AZURE_CREDENTIALS REGISTRY_LOGIN_SERVER REGISTRY_PASSWORD REGISTRY_USERNAME RESOURCE_GROUP ST_ACCOUNT_KEY
do
gh secret set $SECRET --org labordynamicsinstitute --visibility private 
done
```

```
AZURE_CREDENTIALS     = (JSON)

(portal -> rg -> CR -> Access keys)
REGISTRY_LOGIN_SERVER = crreprovmtesteastus01.azurecr.io
REGISTRY_PASSWORD     = (see there)
REGISTRY_USERNAME     = crreprovmtesteastus01
RESOURCE_GROUP
ST_ACCOUNT_KEY
SUBNET_ID
```

## Get the Azure Credentials

Azure Portal > App registrations > Certificates and Secrets

In this case, Service Principal is called "IL-LDI-AzureAutomation".

The Service Principal now needs to get the right permissions.

RG -> Add role -> Contributor
CR -> Add role -> ACRPUSH

