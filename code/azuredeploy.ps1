
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
    [string] 
    [string] $Location
)
$TemplateFile = "$PSScriptRoot\azuredeploy.json"
$TemplateParameterFile = "$PSScriptRoot\azuredeploy.parameters.json"

New-ParameterFile | Out-File $TemplateParameterFile

New-AzResourceGroup -ResourceGroupName $ResourceGroupName -Location $Location
New-AzResourceGroupDeployment -TemplateFile $TemplateFile -TemplateParameterFile $TemplateParameterFile -Verbose
