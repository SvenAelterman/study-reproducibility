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
  

