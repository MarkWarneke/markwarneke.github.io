---
layout: post
title: Generate Infrastructure as Code Azure Resource Manager documentation using PowerShell
subtitle:
bigimg:
  - "/img/7jNATlZXhgk.jpeg": "https://unsplash.com/photos/7jNATlZXhgk"
image: "/img/7jNATlZXhgk.jpeg"
share-img: "/img/7jNATlZXhgk.jpeg"
tags: [AzureDevOps]
comments: true
time: 6
---

Azure Resource Manager templates are complex JSON structures.
The main complaint about these templates is the difficultly to read and work with.
The language service shipped with VSCode supports comments and a better syntax highlighting.
However, to get a quick idea of the templates content a readable documentation is needed.
In this post we are going to have a look how we can address these issue.

## Document Infrastructure As Code

What if we could take a given ARM template and create readable documentation that we can publish in our Wiki?
PowerShells native ability to work with json files can come in handy to query and filter a json file.

To address the lack of readability, we can gather a few requirements based on common task:

- See what kind of Parameters are needed for a given template.
- Check what kind of resources a given ARM template is deploying
- See the outputs a given template returns

## Implementation

We can use PowerShell to return a list of resources by simply returning the `resources` `type` and `name` of an ARM template.

For demo purposes I am using [azuredeploy.json](/code/azuredeploy.json)

```powershell
# New-Readme.ps1
param (
  $Path = (Join-Path $PSScriptRoot "azuredeploy.json")
)
 # Test for template presence
$null = Test-Path $Path -ErrorAction Stop

# Test if arm template content is readable
$text = Get-Content $Path -Raw -ErrorAction Stop

# Convert the ARM template to an Object

$json = ConvertFrom-Json $text -ErrorAction Stop

# Resources
$json.resources.type
$json.resources.name
```

### String Building the Documentation

Now that we have traverse the list of properties we can use PowerShell to create a string that is similar to [markdown](http://daringfireball.net/projects/markdown/), plain text, or any other markup language.
In this demo implementation I am going to stick to Markdown.
An easy way to get started and learn markdown is the interactive [markdowntutorial](https://www.markdowntutorial.com).

Markdown can be used with [Github](https://help.github.com/en/articles/basic-writing-and-formatting-syntax) to create documentation for your project through [Github Pages](https://pages.github.com/) or as means to document your repository.
Azure DevOps uses Markdown to publish the content in form of a [Wiki](https://azure.microsoft.com/en-in/services/devops/wiki/).
Automating the documentation and the creation of Markdown comes in handy.

As Markdown is very light weight we can leverage simple strings to create our documentation.
To better visualize the parameters, resource and outputs of an ARM template a table might be a feasible option for display.

Get [New-Readme.ps1](/code/New-Readme.ps1)

```powershell
# New-Readme.ps1

# Create a Parameter List Table
parameterHeader = "| Parameter Name | Parameter Type |Parameter Description | Parameter DefaultValue |"
$parameterHeaderDivider = "| --- | --- | --- | --- | "
$parameterRow = " | {0}| {1} | {2} | {3} |"

$StringBuilderParameter = @()
$StringBuilderParameter += $parameterHeader
$StringBuilderParameter += $parameterHeaderDivider

$StringBuilderParameter += $json.parameters | get-member -MemberType NoteProperty | % { $parameterRow -f $_.Name , $json.parameters.($_.Name).type , $json.parameters.($_.Name).metadata.description, $json.parameters.($_.Name).defaultValue  }

# Create a Resource List Table
$resourceHeader = "| Resource Name | Resource Type | Resource Comment |"
$resourceHeaderDivider = "| --- | --- | --- | "
$resourceRow = " | {0}| {1} | {2} | "

$StringBuilderResource = @()
$StringBuilderResource += $resourceHeader
$StringBuilderResource += $resourceHeaderDivider

$StringBuilderResource += $json.resources | % { $row -f $_.Name, $_.Type, $_.Comments }

# Create an Output List Table
$outputHeader = "| Output Name | Output Value | Output Type |"
$outputHeaderDivider = "| --- | --- | --- |  "
$outputRow = " | {0}| {1} | {2} | "

$StringBuilderOutput = @()
$StringBuilderOutput += $outputHeader
$StringBuilderOutput += $outputHeaderDivider

$StringBuilderOutput += $json.outputs | get-member -MemberType NoteProperty | % { $outputRow -f $_.Name , $json.parameters.($_.Name).type , $json.parameters.($_.Name).metadata.description, $json.parameters.($_.Name).defaultValue  }

# output

$StringBuilderResource
<#
| Resource Type | Resource Name |  Resource Comment |
| --- | --- | --- |
 | Microsoft.Storage/storageAccounts| [parameters('resourceName')] | Azure Data Lake Gen 2 Storage Account |
#>

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

$StringBuilderOutput
<#
| Output Name   | Output Value | Output Type |
| ------------- | ------------ | ----------- |
| componentName | string       |             |
| resourceID    | string       |             |
#>

```

We can use the strings to output into a file or concat them into a bigger string incorporating more information. For now this is a good baseline to extend on it.
The output can be saved to a file using `Out-File`.

```powershell
./New-Readme.ps1 | Out-File Documentation.md

## Parameters
| Parameter Name | Parameter Type |Parameter Description | Parameter DefaultValue |
| --- | --- | --- | --- |
| location| string | Azure location for deployment | [resourceGroup().location] |
| networkAcls| string | Optional. Networks ACLs Object, this value contains IPs to whitelist and/or Subnet information. |  |
| resourceName| string | Name of the Data Lake Storage Account |  |
| storageAccountAccessTier| string | Optional. Storage Account Access Tier. | Hot |
| storageAccountSku| string | Optional. Storage Account Sku Name. | Standard_ZRS |

## Resources

| Resource Type | Resource Name |  Resource Comment |
| --- | --- | --- |
| Microsoft.Storage/storageAccounts| [parameters('resourceName')] | Azure Data Lake Gen 2 Storage Account |

## Outputs

| Output Name   | Output Value | Output Type |
| ------------- | ------------ | ----------- |
| componentName | string       |             |
| resourceID    | string       |             |

```

To demonstrate the output the generated documentation is displayed below.

### Example Output

#### Parameters

| Parameter Name           | Parameter Type | Parameter Description                                                                           | Parameter DefaultValue     |
| ------------------------ | -------------- | ----------------------------------------------------------------------------------------------- | -------------------------- |
| location                 | string         | Azure location for deployment                                                                   | [resourceGroup().location] |
| networkAcls              | string         | Optional. Networks ACLs Object, this value contains IPs to whitelist and/or Subnet information. |                            |
| resourceName             | string         | Name of the Data Lake Storage Account                                                           |                            |
| storageAccountAccessTier | string         | Optional. Storage Account Access Tier.                                                          | Hot                        |
| storageAccountSku        | string         | Optional. Storage Account Sku Name.                                                             | Standard_ZRS               |

#### Resources

| Resource Type                     | Resource Name                | Resource Comment                      |
| --------------------------------- | ---------------------------- | ------------------------------------- |
| Microsoft.Storage/storageAccounts | [parameters('resourceName')] | Azure Data Lake Gen 2 Storage Account |

#### Outputs

| Output Name   | Output Value | Output Type |
| ------------- | ------------ | ----------- |
| componentName | string       |             |
| resourceID    | string       |             |

## Parameters

You can use a ParameterFile generator that will generate a valid Parameter File base on a given ARm template for you.
In [Generate Azure Resource Manager Templates Parameter files using PowerShell](/2019-08-26-Generate-Azure-Resource-Manager-Template-File) you can find an implementation guide.

A quick way to let your users create a parameter file is by given an example.
To generate a simple parameter structure for documentation purposes this one-liner comes in handy:

```powershell
# Create azuredeploy.parameters.json
$json.parameters | get-member -MemberType NoteProperty | % { [pscustomobject]@{  $_.Name = @{ Value = $json.parameters.($_.Name).DefaultValue  } } } | ConvertTo-Json  #| clip
```

You can store the output (on Windows) to the clipboard by passing it to the `| clip` function.
Or add this line to the Readme generator to allow your Readme users to copy paste the blueprint.

```json
[
  {
    "location": {
      "Value": "[resourceGroup().location]"
    }
  },
  {
    "networkAcls": {
      "Value": null
    }
  },
  {
    "resourceName": {
      "Value": null
    }
  },
  {
    "storageAccountAccessTier": {
      "Value": "Hot"
    }
  },
  {
    "storageAccountSku": {
      "Value": "Standard_ZRS"
    }
  }
]
```

## Remarks

## Table of Content

- [Document Infrastructure As Code](#document-infrastructure-as-code)
- [Implementation](#implementation)
  - [String Building the Documentation](#string-building-the-documentation)
  - [Example Output](#example-output)
    - [Parameters](#parameters)
    - [Resources](#resources)
    - [Outputs](#outputs)
- [Parameters](#parameters-1)
- [Remarks](#remarks)
- [Table of Content](#table-of-content)
