---
layout: post
title: DRAFT Generate Azure Resource Manager Templates Parameter files using PowerShell
subtitle: And how to test PowerShell classes
bigimg:
  - "/img/draft.jpeg": "https://unsplash.com/photos/wE37SqLAO9M"
image: "/img/ibPi5YS7QMM.jpeg"
share-img: "/img/ibPi5YS7QMM.jpeg"
tags: [AzureDevOps, PowerShell]
comments: true
time: 7
---

How do you create a Parameter File for your Azure Resource Manager template deployment?
In this post we are going to create a Parameter File generator using PowerShell Classes.
Furthermore we are looking into testing and validating your PowerShell Classes implementation.

## Learn Classes

If you are not yet familiar with the concepts of PowerShell Classes I can highly recommend the PSConfEu [Video: Learn Classes with Class {}](https://www.youtube.com/watch?v=hSk-ocD6VP4&t=1s) from [@Stephanevg](https://twitter.com/Stephanevg)

<div class="video-container">
    <iframe  src="https://www.youtube.com/embed/hSk-ocD6VP4" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</div>

## Parameter File Generator

I was looking for a way to create Azure Resource Manager template parameter files.
A parameter file typically contains sets of parameters that are consumed together with the Azure Resource Manager Template by the Azure Resource Manager.

The [`New-AzResourceGroupDeployment`](https://docs.microsoft.com/en-us/powershell/module/az.resources/new-azresourcegroupdeployment?view=azps-2.5.0) only needs two inputs, `-ResourceGroupName` and `-TemplateFile`.
A TemplateFile can specify parameters with a `defaultValue`, which is used for the deployment.

To overwrite default values you typically see the `-TemplateParameterFile` specified too.

```powershell
$Deployment = @{
    ResourceGroupName = "MyResourceGroup"
    TemplateFile = (Join-Path $PSScriptRoot "azuredeploy.json").FullName
    TemplateParameterFile = (Join-Path $PSScriptRoot "azuredeploy.parameters.json").FullName
}
New-AzResourceGroupDeployment @Deployment
```

You can also add dynamic parameters to the deployment by using `-TemplateParameterObject`.
This object will set the parameters dynamically at deployment time.
Object passed to the function will override parameters set in `-TemplateParameterFile` and `defaultValue`s.

```powershell
# Object will set the Parameter1 value to $Value
# This object will override the Parameter1 Value if it is set in TemplateParameterFile too.

$Object = @{
    Parameter1 = $Value # Set Parameter1
}

$Deployment = @{
    ResourceGroupName = "MyResourceGroup"
    TemplateFile = (Join-Path $PSScriptRoot "azuredeploy.json").FullName
    TemplateParameterFile = (Join-Path $PSScriptRoot "azuredeploy.parameters.json").FullName
    TemplateParameterObject = $Object # Will override dublicates in TemplateParamterFile
}
New-AzResourceGroupDeployment @Deployment
```

## Implementation Considerations

With all that being said, not all parameters specified in an ARM template are really necessary.
For these requirements I figured I needed some kind of flexibility and extensibility and opted for a class first code approach.

I created a Plain PowerShell Object based on the schema of the [Azure Resource Manager Parameter template file](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-manager-parameter-files). (I did not implement the reference feature yet).

The `ParamterObject` class therefor has the properties `schema`, `contenVersion` and `parameters`.
As the file expects to have the parameters name as a key I opted for a hashtable for each parameter.
The hashtables key is the parameter name, this converts nicely into the expected json when using `ConverTo-Json`.

A parameter file could contain all, none, a subset or only the _mandatory_ parameters specified in the ARM template.
My idea is, having multiple different options for ParameterFiles the ParameterObject could be used as the base class and concrete implementations could inherit it's properties.

The `ParameterFileGenerator` is created based on a given template.
It exposes the builder method `CreateParameterFile` that creates a parameter file json string based on the specification passed.
In this implementation you can specify to create a file with _mandatory_ parameters only or all parameters.

Mandatory parameters are defined as parameters that don't implement the `defaultValues` property.

## Implementation

Get the [New-ParameterFile.ps1](/code/New-ParameterFile.ps1)

```powershell
# New-ParameterFile.ps1

<#
    Parameter File
    Plain PowerShell Object that implement the schema of a parameter file
#>
class ParameterFile {
    # https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-manager-parameter-files
    [string] $schema = "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#"
    [string] $contenVersion = "1.0.0.0"
    [hashtable] $parameters

    # Accept parameter from a given template and map it to the parameter file schema
    ParameterFile ([array]$Parameters) {
        foreach ($Parameter in $Parameters) {
            $this.parameters += @{
                $Parameter.name = @{
                    value = "Prompt"
                }
            }
        }
    }
}

<#
    Parameter File  Generator
    Abstract the creation of a concrete ParameterFile
    The generator needs to be created based on a template
     A file can be created by calling  `CreateParameterFile`, this function accepts a boolean to include only Mandatory parameters.
#>
class ParameterFileGenerator {

    $Template
    $Parameter
    $MandatoryParameter

    # Accepts the tempalte
    ParameterFileGenerator ($Path) {
        $this.Template = $this._loadTemplate($Path)
        $this.Parameter = $this._getParameter($this.Template)
        $this.MandatoryParameter = $this._getMandatoryParameterByParameter($this.Parameter)
    }

    # 'private' method to load a given ARM template and create a PowerShell object
    [PSCustomObject] _loadTemplate($Path) {
        Write-Verbose "Read from $Path"
        # Test for template presence
        $null = Test-Path $Path -ErrorAction Stop

        # Test if arm template content is readable
        $TemplateContent = Get-Content $Path -Raw -ErrorAction Stop
        Write-Verbose "Template Content `n $TemplateContent"

        # Convert the ARM template to an Object
        return ConvertFrom-Json $TemplateContent -ErrorAction Stop
    }

    # 'private' function to extract all parameters of a given template
    [Array] _getParameter($Template) {
        # Extract the Parameters properties from JSON
        $ParameterObjects = $Template.Parameters.PSObject.Members | Where-Object MemberType -eq NoteProperty

        $Parameters = @()
        foreach ($ParameterObject in $ParameterObjects) {
            $Key = $ParameterObject.Name
            $Property = $ParameterObject.Value

            $Property | Add-Member -NotePropertyName "Name" -NotePropertyValue $Key
            $Parameters += $Property
            Write-Verbose "Parameter Found $Key"
        }
        return $Parameters
    }

    # 'private' function to extract all mandatory parameters of all parameters
    [Array] _getMandatoryParameterByParameter($Parameter) {
        return $Parameter | Where-Object {
            $null -eq $_.defaultValue
        }
    }

    <#
        The generator should expose this method to create a parameter file.
        A file can be created by calling  `CreateParameterFile`
        This function accepts a boolean to include only Mandatory parameters.
    #>
    [ParameterFile] CreateParameterFile([boolean] $OnlyMandatoryParameter) {
        if ($OnlyMandatoryParameter) {
            return [ParameterFile]::new($this.MandatoryParameter)
        }
        else {
            return [ParameterFile]::new($this.Parameter)
        }

    }
}

# Exposed function to the user
function New-ParameterFile {
    <#
    .SYNOPSIS
    Creats a parameter file json based on a given ARM tempalte

    .DESCRIPTION
    Creats a parameter file json based on a given ARM tempalte

    .PARAMETER Path
    Path to the ARM template, by default searches the script path for a "azuredeploy.json" file

    .PARAMETER OnlyMandatoryParameter
    Creates parameter file only with Mandatory Parameters ("defaultValue") not present
    #>

    [CmdletBinding()]
    param (
        [string] $Path = (Join-Path $PSScriptRoot "azuredeploy.json"),
        [switch] $OnlyMandatoryParameter
    )
    process {
        # Instanciate the ParameterFileGenerator and uses the public function to create a file
        # The object is converted to Json as this is expected
        [ParameterFileGenerator]::new($Path).CreateParameterFile($OnlyMandatoryParameter) | ConvertTo-Json

         # Could be abstract further by using | out-file
    }
}
```

## Usage

Now we created a function that can create Parameter Files of a given template.
The usage is pretty straight forward.

```powershell
# Functionality needs to dot source
# Sould be placed into a module
. .\New-ParameterFile.ps1

New-ParameterFile
<#
{
  "schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
  "contenVersion": "1.0.0.0",
  "parameters": {
    "networkAcls": {
      "value": "Prompt"
    },
    "storageAccountAccessTier": {
      "value": "Prompt"
    },
    "storageAccountSku": {
      "value": "Prompt"
    },
    "location": {
      "value": "Prompt"
    },
    "resourceName": {
      "value": "Prompt"
    }
  }
}
#>

New-ParameterFile -OnlyMandatoryParameter
<#
{
  "schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
  "contenVersion": "1.0.0.0",
  "parameters": {
    "resourceName": {
      "value": "Prompt"
    },
    "networkAcls": {
      "value": "Prompt"
    }
  }
}
#>

# Or specify a path to the ARM template manually
$AzureDeployPath = "azuredeploy.json"
New-ParameterFile -Path $AzureDeployPath
New-ParameterFile -Path $AzureDeployPath -OnlyMandatoryParameter
```

## Test PowerShell classes

In order to test the functionality the whole implementation needs to be available in memory.
So PowerShell is aware of the classes and the functions.

Using `New-Fixture` command from the `Pester` module the whole script will be dot sourced.

After the classes are available in memory we can instantiate the class and execute its functionality.
As classes expect to implement the return, when not void, we can assert the functionality is executed as expected by asserting the returned value. Also, we can check the inner state by asserting the properties of the object.

![Pester Output](../img/posts/2000-01-01-Test-PowerShell-Classes/pester-output.jpeg){: .center-block :}

The end user facing function should be tested thoroughly as this exposes our functionality to the user.

Get the [New-ParameterFile.Tests.ps1](/code/New-ParameterFile.Tests.ps1)

```powershell
# New-ParameterFile.Tests.ps1

# this is created when running `New-Fixture`
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Class ParameterFile" {

    [array]$Parameters = @(
        @{
            Name = "Test1"
        },
        @{
            Name = "Test2"
        },
        @{
            Name = "Test3"
        }
    )
    it "should create a ParameterFile object" {
        [ParameterFile]::new($Parameters).GetType() | Should -Be "ParameterFile"
    }

    it "should have schema" {
        [ParameterFile]::new($Parameters).Schema | Should -Be "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#"
    }

    it "should have contenVersion" {
        [ParameterFile]::new($Parameters).contenVersion | Should -Be "1.0.0.0"
    }

    it "should have parameters" {
        [ParameterFile]::new($Parameters).parameters | Should -Not -BeNullOrEmpty
    }
}


Describe "Class ParameterFileGenerator" {

    it "should create a ParameterFileGenerator object" {
        [ParameterFileGenerator]::new("$here\azuredeploy.json").GetType() | Should -Be "ParameterFileFactory"
    }

    it "should have template" {
        [ParameterFileGenerator]::new("$here\azuredeploy.json").template | Should -Not -BeNullOrEmpty
    }

    it "should have Parameter" {
        [ParameterFileGenerator]::new("$here\azuredeploy.json").Parameter | Should -Not -BeNullOrEmpty
        [ParameterFileGenerator]::new("$here\azuredeploy.json").Parameter.Count | Should -BeGreaterOrEqual 5
    }

    it "should have MandatoryParameter" {
        [ParameterFileGenerator]::new("$here\azuredeploy.json").MandatoryParameter | Should -Not -BeNullOrEmpty
        [ParameterFileGenerator]::new("$here\azuredeploy.json").MandatoryParameter.Count | Should -Be 2
    }

    it "should create ParameterFile" {
        $ParameterFile = [ParameterFileGenerator]::new("$here\azuredeploy.json").CreateParameterFile($false)
        $ParameterFile.GetType() | Should -Be "ParameterFile"
        $ParameterFile | Should -Not -BeNullOrEmpty
    }
}


Describe ".\New-ParameterFile" {
    context "Valid Public Function Tests" {

        # Execute the user facing command first, as we want to make sure the user can run it
        $ParameterFile = New-ParameterFile

        # The command will return a JSON, so we convert it to assert on it
        $Json = $ParameterFile | ConvertFrom-Json -ErrorAction Stop -ErrorVariable JsonException

        # Basic sanity assertion to check if valid json is returned
        It "should create valid json" {
            $JsonException | Should -BeNullOrEmpty
        }

        $TestCases = @(
            @{
                Property = "Schema"
            },
            @{
                Property = "contenVersion"
            },
            @{
                Property = "parameters"
            }
        )
        it "should have <Property> " -TestCases $TestCases {
            Param(
                $Property
            )
            $Json.$Property | Should -Not -BeNullOrEmpty
        }


        $TestCases = @(
            @{
                Parameter = "networkAcls"
            },
            @{
                Parameter = "resourceName"
            },
            @{
                Parameter = "storageAccountSku"
            },
            @{
                Parameter = "location"
            }
        )
        it "should have <Parameter> with value Prompt" -TestCases $TestCases {
            Param(
                $Parameter
            )
            $Json.Parameters.$Parameter | Should -Not -BeNullOrEmpty
            $Json.Parameters.$Parameter.Value | Should -Be "Prompt"
        }
    }
}
```

In order to validate the code I used the example ADLS Gen2 [azuredeploy.json](/code/azuredeploy.json).

## Remarks

## Table of contents

- [Learn Classes](#learn-classes)
- [Parameter File Generator](#parameter-file-generator)
- [Implementation Considerations](#implementation-considerations)
- [Implementation](#implementation)
- [Usage](#usage)
- [Test PowerShell classes](#test-powershell-classes)
- [Remarks](#remarks)
- [Table of contents](#table-of-contents)
