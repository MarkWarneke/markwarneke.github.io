# adls.acceptance.tests.ps1
param (
    $Path = $PSScriptRoot
)

$ParameterPath = Get-ChildItem -Path "$Path" -include "azuredeploy.parameter.json" -Recurse


Foreach ($Path in $ParameterPath) {

    # Convert the parameter file to a usable PowerShell object
    $null = Test-Path $Path -ErrorAction Stop
    $text = Get-Content $Path -Raw -ErrorAction Stop
    $json = ConvertFrom-Json $text -ErrorAction Stop

    # Invoke or acceptance tests specification
    # this could be wrapped into a loop of all *.spec.ps1 files, similar to the parameter file loop.
    . adls.acceptance.spec.ps1 -Name $json.ResourceName -ResourceGroup $json.ResourceGroupName
}