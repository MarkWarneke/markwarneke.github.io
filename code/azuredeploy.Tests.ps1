#azuredeploy.Tests.ps1
param (
    $Path = $PSScriptRoot # Assuming the test is located in the template folder
)

# Find all Azure Resource Manager Templates in a given Path
$TemplatePath = Get-ChildItem -Path "$Path" -include "*azuredeploy.json" -Recurse

# Loop through all templates found
foreach ($Template in $TemplatePath) {

    # I would recommend to add any kind of validation at this point to ensure we actually found ARM templates.
    $Path = $Template.FullName

    # invoke our former `azuredeploy.Tests.ps1` script with the found template.
    # this could be wrapped into a loop of all *.spec.ps1 files, similar to the ARM template loop.
    . "$PSScriptRoot/azuredeploy.spec.ps1" -Path $Path
    
    # Invoke the specific ADLS spec
    . "$PSScriptRoot/azuredeploy.adls.spec.ps1" -Path $Path
}