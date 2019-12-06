param (
    $Path = (Join-Path $PSScriptRoot "azuredeploy.json")
)

# Test for template presence

$null = Test-Path $Path -ErrorAction Stop

# Test if arm template content is readable

$text = Get-Content $Path -Raw -ErrorAction Stop

# Convert the ARM template to an Object

$json = ConvertFrom-Json $text -ErrorAction Stop

# Create Strings
$resourceHeader = "| Resource Type | Resource Name |  Resource Comment |"
$resourceHeaderDivider = "| --- | --- | --- |"
$resourceRow = "| {0}| {1} | {2} |"

$parameterHeader = "| Parameter Name | Parameter Type |Parameter Description | Parameter DefaultValue |"
$parameterHeaderDivider = "| --- | --- | --- | --- |"
$parameterRow = "| {0}| {1} | {2} | {3} |"

$outputHeader = "| Output Name | Output Value | Output Type |"
$outputHeaderDivider = "| --- | --- | --- |"
$outputRow = "| {0}| {1} | {2} |"

# Create a Parameter List Table
$StringBuilderParameter = @()
$StringBuilderParameter += $parameterHeader
$StringBuilderParameter += $parameterHeaderDivider

$StringBuilderParameter += $json.parameters | get-member -MemberType NoteProperty | % { $parameterRow -f $_.Name , $json.parameters.($_.Name).type , $json.parameters.($_.Name).metadata.description, $json.parameters.($_.Name).defaultValue  }

# Create a Resource List Table
$StringBuilderResource = @()
$StringBuilderResource += $resourceHeader
$StringBuilderResource += $resourceHeaderDivider

$StringBuilderResource += $json.resources | % { $resourceRow -f $_.Type, $_.Name, $_.Comments }

# Create an Output List Table
$StringBuilderOutput = @()
$StringBuilderOutput += $outputHeader
$StringBuilderOutput += $outputHeaderDivider

$StringBuilderOutput += $json.parameters | get-member -MemberType NoteProperty | % { $outputRow -f $_.Name , $json.parameters.($_.Name).type , $json.parameters.($_.Name).metadata.description, $json.parameters.($_.Name).defaultValue  }

# output

Write-Output "## Parameters"

$StringBuilderParameter
<#
| Parameter Name | Parameter Type |Parameter Description | Parameter DefaultValue |
| --- | --- | --- | --- |
| location| string | Azure location for deployment | [resourceGroup().location] |
| networkAcls| string | Optional. Networks ACLs Object, this value contains IPs to whitelist and/or Subnet information. |  |
| resourceName| string | Name of the Data Lake Storage Account |  |
| storageAccountAccessTier| string | Optional. Storage Account Access Tier. | Hot |
| storageAccountSku| string | Optional. Storage Account Sku Name. | Standard_ZRS |
#>

Write-Output ""# Empty Line
Write-Output "## Resources"
Write-Output ""# Empty Line

$StringBuilderResource
<#
| Resource Type | Resource Name |  Resource Comment |
| --- | --- | --- |
 | Microsoft.Storage/storageAccounts| [parameters('resourceName')] | Azure Data Lake Gen 2 Storage Account |
#>

Write-Output ""# Empty Line
Write-Output "## Outputs"
Write-Output ""# Empty Line

$StringBuilderOutput
<#
| Resource Name | Resource Type | Resource Comment |
| --- | --- | --- |
 | location| string | Azure location for deployment | [resourceGroup().location] |
 | networkAcls| string | Optional. Networks ACLs Object, this value contains IPs to whitelist and/or Subnet information. |  |
 | resourceName| string | Name of the Data Lake Storage Account |  |
 | storageAccountAccessTier| string | Optional. Storage Account Access Tier. | Hot |
 | storageAccountSku| string | Optional. Storage Account Sku Name. | Standard_ZRS |
#>
