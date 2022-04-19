# PowerShell script to deploy the main.bicep template with parameter values

#Requires -Modules "Az"
#Requires -PSEdition Core

# Use these parameters to customize the deployment instead of modifying the default parameter values
[CmdletBinding()]
Param(
	[ValidateSet('eastus2', 'eastus')]
	[string]$Location = 'eastus',
	# The environment descriptor
	[ValidateSet('test', 'demo', 'prod')]
	[string]$Environment = 'test',
	#
	[Parameter(Mandatory = $true)]
	[string]$WorkloadName,
	#
	[int]$Sequence = 1,
	[string]$NamingConvention = "{rtype}-$WorkloadName-{env}-{loc}-{seq}"
)

$TemplateParameters = @{
	# REQUIRED
	location         = $Location
	environment      = $Environment
	workloadName     = $WorkloadName

	# OPTIONAL
	sequence         = $Sequence
	namingConvention = $NamingConvention
	tags             = @{
		'date-created' = (Get-Date -Format 'yyyy-MM-dd')
		purpose        = $Environment
		lifetime       = 'short'
	}
}

$DeploymentResult = New-AzDeployment -Location $Location -Name "$WorkloadName-$Environment-$(Get-Date -Format 'yyyyMMddThhmmssZ' -AsUTC)" `
	-TemplateFile ".\main.bicep" -TemplateParameterObject $TemplateParameters

$DeploymentResult

if ($DeploymentResult.ProvisioningState -eq 'Succeeded') {
	$Outputs = $DeploymentResult.Outputs

	$OutputsEx = $Outputs | Select-Object -Property Name, Value
	$OutputsEx

	Write-Host "`nGitHub Repository or Organization Actions Secrets:`n"
	Write-Host "AZURE_CREDENTIALS     = <pending>"
	Write-Host "REGISTRY_LOGIN_SERVER = $($Outputs.containerRegistryUrl.Value)"
	Write-Host "REGISTRY_USERNAME     = $($Outputs.containerRegistryUser.Value)"
	Write-Host "REGISTRY_PASSWORD     = $($Outputs.containerRegistryKey.Value)"
	Write-Host "RESOURCE_GROUP        = $($Outputs.resourceGroupName.Value)"
	Write-Host "ST_ACCOUNT_KEY        = $($Outputs.storageAccountKey.Value)"
}
else {
}
