<#
    .SYNOPSIS
    Creats an Azure Data Lake Gen 2 using azuredeploy.json
    
    .DESCRIPTION
    Creats an Azure Data Lake Gen 2 using azuredeploy.json
    Using a create parameter file which will be placed into "$PSScriptRoot\azuredeploy.parameters.json"
    
    .PARAMETER ResourceGroupName
    Name of the ResourceGroup
    
    .PARAMETER Location
    Azure Location of ResourceGroup
    Use Get-AzLocation
    
    .EXAMPLE 
    azuredeploy.ps1 -Name "MyResourceGroup" -Location "WestEurope"
#>
[CmdletBinding()]
param (
    # Name of the ResourceGroup
    [Parameter(Mandatory)]
    [Alas("Name")]
    [string] 
    $ResourceGroupName,
    
    # Azure Location of ResourceGroup
    [Parameter(Mandatory)]
    [Alas("Name")]
    [string] $Location
)
$TemplateFile = "$PSScriptRoot\azuredeploy.json"
$TemplateParameterFile = "$PSScriptRoot\azuredeploy.parameters.json"

New-ParameterFile | Out-File $TemplateParameterFile

$TemplateParameterObject = @{
    resourceName = ("mark{0}" -f (Get-Date -format FileDateTime))
}
if ($PSCmdlet.ShouldProcess("ResourceGroupName $ResourceGroupName deployment of", "TemplateFile $TemplateFile ")) {
	New-AzResourceGroup -ResourceGroupName $ResourceGroupName -Location $Location
	New-AzResourceGroupDeployment -TemplateFile $TemplateFile -TemplateParameterFile $TemplateParameterFile -TemplateParameterObject $TemplateParameterObject -Verbose
} else {
	New-AzResourceGroup -ResourceGroupName $ResourceGroupName -Location $Location -WhatIf
	New-AzResourceGroupDeployment -TemplateFile $TemplateFile -TemplateParameterFile $TemplateParameterFile -TemplateParameterObject $TemplateParameterObject -Verbose -WhatIf
	Test-AzResourceGroupDeployment -TemplateFile $TemplateFile -TemplateParameterFile $TemplateParameterFile -TemplateParameterObject $TemplateParameterObject -Verbose
}