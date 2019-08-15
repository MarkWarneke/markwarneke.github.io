---
layout: post
title: Unit Test Azure Resource Manager Templates using Pester
subtitle: Static code Analysis of Configuration Files
bigimg: /img/posts/2019-12-30-Static-Code-Analysis-for-Infrastructure-as-Code//img/static-pester-test.jpg
image: "/img/posts/2019-12-30-Static-Code-Analysis-for-Infrastructure-as-Code/static-pester-test.jpg"
share-img: "/img/posts/2019-12-30-Static-Code-Analysis-for-Infrastructure-as-Code/static-pester-test.jpg"
gh-repo: MarkWarneke/Az.Test
gh-badge: [star, follow]
tags: [Test, PowerShell, ARM, AzureDevOps]
comments: true
time: 4
published: true
---

Treat Infrastructure as Code development like a software engineering project.
In this article we are building on top of the post "Test Infrastructure as Code".
We are looking into and digging a little deeper on how to unit test Infrastructure as Code.

# Draft 15.08.19

Generally Infrastructure as Code (IaC) can be distinguished between two [approaches](http://markwarneke.me/Cloud-Automation-101/Article/01_Cloud_Automation_Theory.html#Approach).

### Declarative

When following the best practices for Infrastructure as Code by using a [**declarative approach**](http://markwarneke.me/Cloud-Automation-101/Article/01_Cloud_Automation_Theory.html#approach) to provision resources the _unit_ is the configuration file, or Azure Resource Manager (ARM) template, which is a JSON file.

### Imperative

The imperative approach on the other hand like [@pascalnaber](https://twitter.com/pascalnaber) describes it in his wonderful blog post [stop using ARM templates! Use the Azure CLI instead](https://www.google.com/search?q=stop+using+azure+resource+manager+templates&oq=stop+using+azure+resource+manager+templates&aqs=chrome..69i57j33l3.5812j1j7&sourceid=chrome&ie=UTF-8) requires that you actual test the function or script you are using to provision resoruces.

## Unit Tests

> The foundation of your test suite will be made up of unit tests. Your unit tests make sure that a certain unit (your subject under test) of your codebase works as intended. Unit tests have the narrowest scope of all the tests in your test suite. The number of unit tests in your test suite will largely outnumber any other type of test. - [The Practical Test Pyramid](https://martinfowler.com/articles/practical-test-pyramid.html#UnitTests)

Having an Azure Resource Manager Template (ARM Template) as the subject under test we are looking for a way to test a JSON configuration file.
I have not yet heard of a Unit Testing framework for configuration files like YAML or JSON.
The only tool I am aware of are [linter](<https://en.wikipedia.org/wiki/Lint_(software)>) for these file types.
The approach of a linter gives us a good starting point to dig deeper into static analysis of code.

As the configuration file usually describes the desired state of the system to be deployed.
The specified system consists generally of one ore more Azure resources that needs to be provisioned.
Each resource in an Azure Resource Manager template adheres to a specific [schema](https://github.com/Azure/azure-resource-manager-schemas).
The schema describes the resources properties that needs to be passed to be able to be deployed.
It also indicates mandatory and optional values.
The human readable form of the schema can be found in the [Azure Template Refernce](https://docs.microsoft.com/en-us/azure/templates/).

Taking the automation account as an example the Azure Resource Manager Template resource implementation looks like this.

```json
{
  "name": "string",
  "type": "Microsoft.Automation/automationAccounts",
  "apiVersion": "2015-10-31",
  "properties": {
    "sku": {
      "name": "string",
      "family": "string",
      "capacity": "integer"
    }
  },
  "location": "string",
  "tags": {}
}
```

Inside the `properties` property only the `SKU` property needs to be configured.
The SKU object only expects to have a `name` as a required parameter.
![SKU Object](../img/posts/2019-12-30-Static-Code-Analysis-for-Infrastructure-as-Code/sku.png)

A quick way to test could therefore be validating the schema and ensuring all mandatory parameters are set.

Windows 10 ships with a pre installed testing framework for PowerShell called [Pester](https://github.com/pester/Pester/). Pester is the ubiquitous test and mock framework for PowerShell.
I recommend getting the latest version from the [PSGallery](https://www.powershellgallery.com/packages/Pester/4.8.1)

```powershell
Install-Module -Name Pester -Scope CurrentUser -Force
```

Going the imperative approach the subject under test might vary and depends on the implementation.
A unit tests should execute quick, as the [Az](https://docs.microsoft.com/en-us/powershell/azure/new-azureps-module-az?view=azps-2.5.0) PowerShell Module is communicating with Azure this would violate the Unit Testing definition.
Hence you want to Mock all Az scripts and tests the flow of you implementation.
The [`Assert-MockCalled`](https://github.com/pester/Pester#mocking) ensures the flow of you code is as expected.
Generally we trust that the provided commands are thoroughly tested by Microsoft.

A unit test for a deployment script can leverage PowerShells [`WhatIf`](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_commonparameters?view=powershell-6#whatif) functionally as a way of preventing actual execution to Azure too.

```powershell
New-AzResourceGroupDeployment -ResourceGroupName $rg -TemplateFile $tf -TemplateParameterFile $tpf -WhatIf
```

A deployment script should implement the [ShouldProcess](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_advanced_methods?view=powershell-6#shouldprocess) functionality of PowerShell.

```powershell
[CmdletBinding(SupportsShouldProcess=$True)]
# ...
if ($PSCmdlet.ShouldProcess("ResourceGroupName $rg deployment of", "TemplateFile $tf")) {
    New-AzResourceGroupDeployment -ResourceGroupName $rg -TemplateFile $tf -TemplateParameterFile $tpf
}
```

This ensures the script can be executed using the `-WhatIf` switch to execute a _dry run_ of the code.

## Static Code Analysis

I personally refer to a **unit tests** for ARM templates as asserted **static code analysis**.
By using assertion the test should parse, validate and check for [best practices](https://docs.microsoft.com/en-us/azure/azure-resource-manager/template-best-practices) within the given configuration file (ARM template).

I know of two public available static code analysis tests, one is implemented by the [Azure Virtual Datacenter](https://github.com/Azure/vdc/) (VDC) and [Az.Test](https://github.com/MarkWarneke/Az.Test).

### VDC implementation

See VDC code blocks [module.tests.ps1](https://github.com/Azure/vdc/blob/vnext/Modules/SQLDatabase/2.0/Tests/module.tests.ps1).

The assertion checks if the converted JSON has expected properties.
The basic [Azure Resource Manager template schema](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-manager-tutorial-create-encrypted-storage-accounts#understand-the-schema) schema accepts `$schema`, `contentVersion`, `parameters`, `variables`, `resources` and `outputs` as top level properties.

```json
// azuredeploy.json
{
  "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {},
  "variables": {},
  "resources": [],
  "outputs": {}
}
```

PowerShell has native support for working with JSON files.
PowerShell can easily read and convert a JSON file to a PowerShell object.
If the conversion is not possible or the JSON is invalid, a terminating error is thrown.
This could be the first test.

```powershell
$TemplateFile = './azuredeploy.json'
$TemplateJSON = Get-Content $TemplateFile -Raw | ConvertFrom-Json
$TemplateJSON
# $schema        : https://schema....
# contentVersion : 1.0.0.0
# parameters     :
# variables      :
# resources      : {}
# outputs        :
```

`Get-Content -Raw`reads the text from the given file as one object rather then per line.`ConvertFrom-Json` will convert the string into a PowerShell object.

```powershell
#vdc/Modules/SQLDatabase/2.0/Tests/module.tests.ps1

# $TemplateFileTestCases can store multiple TemplateFileTestCases to test
It "Converts from JSON and has the expected properties" `
 -TestCases $TemplateFileTestCases {
    # Accept a template file per time
    Param ($TemplateFile)

    # Define all expected properties as pet ARM schema
    $expectedProperties = '$schema',
    'contentVersion',
    'parameters',
    'variables',
    'resources',
    'outputs'| Sort-Object

    # Get actual properties from the TemplateFile
    $templateProperties =
        (Get-Content (Join-Path "$here" "$TemplateFile") |
        ConvertFrom-Json -ErrorAction SilentlyContinue) |
        Get-Member -MemberType NoteProperty |
        Sort-Object -Property Name |
        ForEach-Object Name

    # Assert that the template properties are present
    # PowerShell will compare strings here, as toString() is invoked on the array of Names
    $templateProperties | Should Be $expectedProperties
}
```

The tests Asserts that the `$expectedProperties` are present within the JSON file by getting the `NoteProperties` `Name` of the converted PowerShell object.

The `Noteproperties` of a blank ARM template look like this:

```powershell
$TemplateJSON | Get-Member -MemberType NoteProperty

#   TypeName: System.Management.Automation.PSCustomObject
# Name           MemberType   Definition
# ----           ----------   ----------
# $schema        NoteProperty string $schema=https://...
# contentVersion NoteProperty string contentVersion=1.0.0.0
# outputs        NoteProperty PSCustomObject outputs=
# parameters     NoteProperty PSCustomObject parameters=
# resources      NoteProperty Object[] resources=System.Object[]
# variables      NoteProperty PSCustomObject variables=

$TemplateJSON | Get-Member -MemberType NoteProperty | select Name
# Name
# ----
# $schema
# contentVersion
# outputs
# parameters
# resources
# variables
```

Using the Name property of the `Get-Member` function we can assert all JSON properties are present.
The same test can be applied for the parameter file too.

The `module.tests.ps1` then parses the given template and checks if the required `parameters` are present in a given parameter file. A required parameter can be identified if the `defaultValue` is not set on the parameter property.

Given the following parameters inside an ARM template, we could check the `mandatory` property is present in the parameters file.

```json
// azuredeploy.json
{
  "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "name": {
      "type": "string",
      "defaultValue": "Mark"
    },
    "mandatory": {
      "type": "string"
    }
  } // ...
}
```

Given above template only `mandatory` is a mandatory parameter, as the `defaultValue` property is not present.
Using

```powershell
Where-Object -FilterScript { -not ($_.Value.PSObject.Properties.Name -eq "defaultValue") }
```

we can check the presence of `PSObjects` `Value` properties `defaultValue`.

```powershell
$TemplateFile = './azuredeploy.json'
$TemplateJSON = Get-Content $TemplateFile -Raw | ConvertFrom-Json
$TemplateJSON.Parameters.PSObject.Properties
# Value           : @{type=string; defaultValue=Mark}
# MemberType      : NoteProperty
# IsSettable      : True
# IsGettable      : True
# TypeNameOfValue : System.Management.Automation.PSCustomObject
# Name            : name
# IsInstance      : True

# Value           : @{type=string}
# MemberType      : NoteProperty
# IsSettable      : True
# IsGettable      : True
# TypeNameOfValue : System.Management.Automation.PSCustomObject
# Name            : mandatory
# IsInstance      : True
$TemplateJSON.Parameters.PSObject.Properties |
    Where-Object -FilterScript {
        -not ($_.Value.PSObject.Properties.Name -eq "defaultValue")
    }
# Value           : @{type=string}
# MemberType      : NoteProperty
# IsSettable      : True
# IsGettable      : True
# TypeNameOfValue : System.Management.Automation.PSCustomObject
# Name            : mandatory
# IsInstance      : True
```

We can then check if the returned values are present in the parameter file.

```powershell
$requiredParametersInTemplateFile = (Get-Content (Join-Path "$here" "$($Module.Template)") |
    ConvertFrom-Json -ErrorAction SilentlyContinue).Parameters.PSObject.Properties |
    Where-Object -FilterScript { -not ($_.Value.PSObject.Properties.Name -eq | "defaultValue") }
    Sort-Object -Property Name |
    ForEach-Object Name

$allParametersInParametersFile = (Get-Content (Join-Path "$here" "$($Module.Parameters)") |
    ConvertFrom-Json -ErrorAction SilentlyContinue).Parameters.PSObject.Properties |
    Sort-Object -Property Name |
    ForEach-Object Name

$allParametersInParamersFile | Should Contain $requiredParametersInTemplateFile
```

### Az.Test

See Az.Test [azuredeploy.Tests.ps1](https://github.com/MarkWarneke/Az.New/blob/master/xAz.New/static/src/test/azuredeploytests.ps1)
