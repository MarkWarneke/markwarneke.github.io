---
layout: post
title: DRAFT Test PowerShell Classes
subtitle:
bigimg: 
  - "/img/draft.jpg": "https://unsplash.com/photos/wE37SqLAO9M"
image: "/img/draft.jpg"
share-img: "/img/draft.jpg"
tags: [draft]
comments: true
time: 4
---

In thie post we are going to look into how we can write Pester test for PowerShell Classes.

## Learn Classes

If you are not yet familiar with the concepts of PowerShell Classes I can highly recommend the [Video: Stéphane van Gulick - Learn Classes with Class {}](https://www.youtube.com/watch?v=hSk-ocD6VP4&t=1s) from [@Stephanevg](https://twitter.com/Stephanevg)

 [Slides & Code](https://github.com/psconfeu/2019/tree/master/sessions/MarkWarneke)

<div class="video-container">
    <iframe  src="https://www.youtube.com/watch?v=hSk-ocD6VP4&t=1s" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</div>

## Test Classes Implementation of Parameter File Generator

I was looking for a way to create Azure Resource Manager tempalte Parameter files.
A parameter file typically contains sets of parameters that are specified in an Azure Resource Manager.
You can add dynamic parameters to a deployment using `-TemplateParameterObject` when executing `New-AzResourceGroupDeployment`, hence not all parameters specified are really necessary.
Furthermore ARM template allow to specify default values for parameters. 

Having these requirements I figured I needed some kind of flexibility and extensibility and opted for a class first code approach.
I created a Plain PowerShell Object that ensures the schema of the [Azure Resource Manager Parameter template file](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-manager-parameter-files) is matched. (I did not implement the reference feature yet).

The `ParamterObject` class has the properties `schema`, `contenVersion` and `parameters`. 
AS the file expects to have a key as the parameters name inside parameters I opted for a hashtable for parameters, as this converts nicely into the expected json.

Having multiple different options for ParameterFiles the ParameterObject could be the base class and concrete implementations could inherit the properties.

The whole creation of the file is abstracted into the Factory pattern by implementing a `ParameterFileFactory` that accepts a given template and creates a parameter file based on the specification passed - in this implementation you can specify to only create a file with *mandatory* parameters or all.
Mandatory parameters are defined as parameters that don't implement the `defaultValues` property.

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
    Parameter File  Factroy
    Abstract the creation of a concrete ParameterFile
    The factory needs to be created based on a template
     A file can be created by calling  `CreateParameterFile`, this function accepts a boolean to include only Mandatory parameters.
#>
class ParameterFileFactory {

    $Template
    $Parameter
    $MandatoryParameter

    # Accepts the tempalte
    ParameterFileFactory ($Path) {
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
        The factory should expose this method to create a parameter file.
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
        # Instanciate the Factory and uses the public function to create a file
        # The object is converted to Json as this is expected
        [ParameterFileFactory]::new($Path).CreateParameterFile($OnlyMandatoryParameter) | ConvertTo-Json
    
         # Could be abstract further by using | out-file
    }
}
```

In order to test the functionality the whole script needs to be available in memory.
Using `New-Fixture` command from the `Pester` module the whole script will be dot sourced.

After the classes are available in memory we can instantiate the class and execute the functions.
As classes expect to implement the return we can assert the functionality is executed as expected.

The regular function should also be tested, as this is user facing.

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


Describe "Class ParameterFactory" {

    it "should create a ParameterFactory object" {
        [ParameterFileFactory]::new("$here\azuredeploy.json").GetType() | Should -Be "ParameterFileFactory"
    }

    it "should have template" {
        [ParameterFileFactory]::new("$here\azuredeploy.json").template | Should -Not -BeNullOrEmpty
    }

    it "should have Parameter" {
        [ParameterFileFactory]::new("$here\azuredeploy.json").Parameter | Should -Not -BeNullOrEmpty
        [ParameterFileFactory]::new("$here\azuredeploy.json").Parameter.Count | Should -BeGreaterOrEqual 5
    }

    it "should have MandatoryParameter" {
        [ParameterFileFactory]::new("$here\azuredeploy.json").MandatoryParameter | Should -Not -BeNullOrEmpty
        [ParameterFileFactory]::new("$here\azuredeploy.json").MandatoryParameter.Count | Should -Be 2
    }

    it "should create ParameterFile" {
        $ParameterFile = [ParameterFileFactory]::new("$here\azuredeploy.json").CreateParameterFile($false)
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
