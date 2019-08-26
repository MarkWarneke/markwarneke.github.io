---
layout: post
title: Cloud Automation Theory
subtitle: Cloud-Automation-101
bigimg:
  - "/img/2KJjKrod2RA.jpeg": "https://unsplash.com/photos/2KJjKrod2RA"
image: "/img/2KJjKrod2RA.jpeg"
share-img: "/img/2KJjKrod2RA.jpeg"
tags: [AzureDevOps]
comments: true
time: 12
---

Introduction to Cloud Automation, Azure DevOps, Infrastructure As Code (IaC), PowerShell, Azure Resource Manager (ARM), Unit-Testing with Pester, CI/CD Pipeline with Azure DevOps and more!

## What is Cloud Automation

_My Definition of Infrastructure as Code:_

> Infrastructure as Code (IaC) is the management of infrastructure in a descriptive model, using the same versioning as DevOps team uses for source code. Like the principle that the same source code generates the same binary, an IaC model generates the same environment every time it is applied

[Docs](https://docs.microsoft.com/en-us/azure/devops/learn/what-is-infrastructure-as-code)

_My Definition of DevOps:_

> DevOps is the union of people, process, and products to enable continuous delivery of value to our end users. The contraction of “Dev” and “Ops” refers to replacing siloed Development and Operations to create multidisciplinary teams that now work together with shared and efficient practices and tools. Essential DevOps practices include agile planning, continuous integration, continuous delivery, and monitoring of applications.

[Docs](https://docs.microsoft.com/en-us/azure/devops/learn/what-is-devops)

So DevOps is about the union of people, process, and technology to enable continuous delivery of value to your end users.

## Why Cloud Automation

- Consistency: Standardized provisioning
- Accelerating: Rapid deployment and provisioning
- Reusability: JSON code and pipeline
- Extensibility: Extensible JSON

_Characteristics of Infrastructure as Code:_

- Declarative
- Single source of truth
- Increase repeatability and testability
- Decrease provisioning time
- Rely less on availability of persons to perform tasks
- Use proven software development practices for deploying infrastructure
- Repeatable and testable
- Faster to provision
- Idempotent provisioning and configuration (calls can be executed repeatedly while producing the same result)

## How to Cloud Automation

A practice in Infrastructure as Code is to write your definitions in a declarative way versus an imperative way.

You define the state of the infrastructure you want to have and let the system do the work on getting there. In the following sections we will have a look at tools to implement the practice.

## Conclusion

### Infrastructure as Code

- Help you to create a robust and reliable infrastructure
- Each time you deploy, the infrastructure will be exactly the same
- Easily change the resources you are using by changing code and not by changing infrastructure
- Everything should be automated to:
  - save time
  - make fewer manual configuration
  - only allow tested changes
  - ultimately you will encounter fewer errors
- All changes in the infrastructure are accessible in source control.
- Source control gives great insight in why and what is changed and by whom.

### DevOps

- culture, movement or practice
- emphasizes collaboration and communication
- automating process of software delivery and infrastructure changes
- build, testing and releasing software

## Objectives

- Understand Cloud Automation Theory
- Implement, configure, and apply Azure Resource Manager templates.
- Use source control for configurations, and integrate Infrastructure as Code into the deployment pipeline.

## Introduction Cloud Automation Theory

Distinguish between:

- **Provisioning** Runbook (PowerShell)
- **Configuration** Desired State

## Idempotence

Idempotence is a principle of Infrastructure as Code.

> Idempotence is the property where a deployment command always sets the target environment into the same configuration, regardless of the environment’s starting state.

_Idempotency_ is achieved by either automatically configuring an existing target or by discarding the existing target and recreating a fresh environment.

It saves time and increases the reliability of regular administrative tasks, and even schedules them to be automatically performed at regular intervals.
You can automate processes using runbooks or automate configuration management by using Desired State Configuration

## Approach

There are two types of approaches to Infrastructure as Code:

> Declarative (functional) and imperative (procedural).

The _declarative_ approach states “what” the final state should be. When run, the script or definition will initialize or configure the machine to have the finished state that was declared.

In the _imperative_ approach, the script states the “how” for the final state of the machine by executing through the steps to get to the finished state.

## Type

There are also two types of methods in Infrastructure as Code:

> push and pull methods.

In the _pull_ method, the machines configured will pull the configuration from a controlling server, such as a master server.

In the _push_ method, the controlling or master server will push the configuration to the target machines. Some organizations may benefit from Infrastructure as Code frameworks such as PowerShell DSC.

## Goal

> The goal of IaC is to create a _build process_ that creates _consistent infrastructure_ and _deploys the application_.

Changes are committed, and the build process spins up a new server and deploys the application. This means that testing is always performed on a clean machine with a known configuration. It’s possible with source control to create several builds, such as development, test, and production, and to choose which one to target.

## Common automation tasks

- **Disaster recovery.** Deploy new instances of Azure resources quickly within an alternative Azure datacenter after a disaster occurs. Resources might include Azure virtual machines (VMs), virtual networks, or cloud services, in addition to database servers.
- **Provisioning.** Perform initial and subsequent provisioning of a complete deployment, for example, a virtual network, where you assign VMs to it, create cloud services, and join the services to the same virtual network.
- **State management.** Apply DSC to manage the state of your machines.
- **Running backups.** Azure Automation is very helpful for running regular backups of non-database systems, such as backing up Blob storage at certain intervals.
- **Deploying patches.** Azure Automation allows you to develop a runbook to manage the updates at scheduled times to manage patch remediation. Ensure machines continually align with configured security policy.

## Imperative vs Declarative

### Methods

1. manual Azure Portal
2. Scripts Imperative
3. Template Declarative

### Manual

#### Pro

- Browser based
- Exploration
- Visual
- Fully featured

#### Cons

- Performed manually
- Error rpone
- Lack of process integration (DevOps, ITSM)

### Imperative

#### Pro

- Process Integration (DevOps, ITSM)
- Less Error Prone (removes human)
- Unopinionated
- Flexible
- Testable

#### Cons

- Scripting Knowledge
- Complex Logic
- Hand Build

### Declarative

#### Pro

- Process Integration (DevOps, ITSM)
- Less Error Prone (removes human)
- Handles some complex logic
- state management

#### Cons

- Templating Knowledge needed
- Opinionated and lack of flexibility

#### ARM Template

- JSON based
- Tooling Visual Studio / Visual Studio Code
- Native Azure portal integration
- Generated directly from REST / Swagger

#### Terra Form

- Open Source Project
- Cross computing environment templating language
- Provision, Update and Delete resources
- Authored in HashiCorp Configuration Language (HCL) or JSON

### Source

[Youtube: Microsoft Ignite - Cloud native Azure deployments with Terraform - BRK3306](https://www.youtube.com/watch?v=YoLV0tJ_DxE)

### Imperative Using .Net Core

[Azure management library for .NET fluent concepts](https://docs.microsoft.com/en-us/dotnet/azure/dotnet-sdk-azure-concepts?view=azure-dotnet)

> A fluent interface is a specific form of the builder pattern that creates objects through a method chain that enforces correct configuration of a resource. For example, the entry-point Azure object is created using a fluent interface

```c#
var azure = Azure
    .Configure()
    .Authenticate(credentials)
    .WithDefaultSubscription();

var sql = azure.SqlServers.Define(sqlServerName)
    .WithRegion(Region.USEast)
    .WithNewResourceGroup(rgName)
    .WithAdministratorLogin(administratorLogin)
    .WithAdministratorPassword(administratorPassword)
    .Create();
```

## Azure Resource Manager Parameter Recommendations

- Minimize your use of parameters. Whenever possible, use a variable or a literal value. Use parameters only for these scenarios:

  - Settings that you want to use variations of according to environment (SKU, size, capacity).
  - Resource names that you want to specify for easy identification.
  - Values that you use frequently to complete other tasks (such as an admin user name).
  - Secrets (such as passwords).
  - The number or array of values to use when you create multiple instances of a resource type.

- Use camel case for parameter names.
- Provide a description of every parameter in the metadata
- Define default values for parameters (except for passwords and SSH keys). By providing a default value, the parameter becomes optional during deployment. The default value can be an empty string.
- Avoid using a parameter or variable for the API version for a resource type.

[Docs: parameters](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-manager-templates-parameters)

## Azure Resource Manager Template Composition

### Composition Theory

You are composing one template into its own template, which makes it smaller and reusable as a referenced templates by leveraging the `Microsoft.Resources/deployments` Provider. Going for a `"master-template"` that specifies every component by its provider like:

```json
// azureDeploy.json
"resources" : [
    Microsoft.Storage/storageAccounts
    Microsoft.Network/virtualNetworks
    Microsoft.Compute/virtualMachines
]
```

To a master template that orchestrates multiple deployments. Each of which are responsible for a certain component of the solution, e.g. `storageAccount`, `virtualNetwork` and `virtualMachine` and a just referenced by the `Microsoft.Resources/deployments` Provider.

```json
// azureDeploy.json
"resources" : [
    Microsoft.Resources/deployments # storageAccount.json
    Microsoft.Resources/deployments # virtualNetwork.json
    Microsoft.Resources/deployments # virtualMachines.json
]
```

```json
// storageAccount.json
"resources" : [
     Microsoft.Storage/storageAccounts
]
```

```json
// virtualNetwork.json
"resources" : [
     Microsoft.Network/virtualNetworks
]
```

```json
// virtualMachines.json
"resources" : [
     Microsoft.Compute/virtualMachines
]
```

### Output

Composed templates need to _communicate_ with each other you can use the `outputs` property of the ARM template.

```json
"outputs" : {
    "key" : {                                   # key of the output, e.g. virtualMachineName
        "type" : "string",                      # type of the value, e.g. string or int
        "value" : "[variable('variableKey')]"   # value of the output, e.g. specified variable or parameter / resource
    }
}
```

The master template can use the returned value of the composed template to make further use of the output or pass that to a shared template.

You can access the outputs within a template by using the `.outputs.key.value` of a reference, where you provide a composed child template as the parameter and the outputs key as the specified key property in the child template outputs property.

```json
// nestedDeploymentvirtualMachine
"outputs" : {
    "virtualMachineName" : {
        "type" : "string",
        "value" : "[variable('virtualMachineName')]"
    }
}
```

```json
// Master
"parameters" : {
    "virtualMachineName" : {
        "value" : "[reference(parameter('nestedDeploymentvirtualMachine')).outputs.virtualMachineName.value]"
    }
}
```

### Composition Demo

```json
"resources" : [
    {
        "apiVersion": "[vairables('deploymentApiVersion')]",            # earlier specified apiVersion
        "name" : "[parameters('nestedDeploymentResource')]",            # name of the nested deployment files for resource
        "type" : "Microsoft.Resource/deployments",                      # Provider for composed child arm template file
        "properties" : {
            "mode" : "Incremental",                                     # Incremental: only changes gets deployed
            "templateLink" : {
                "uri" : "[concat(parameters('baseTemplateUri'), '/shared/', parameters('sharedTemplateNameResource'))]",
                                                                        # url to the child template,
                                                                        # gets composed of the url of the current template provided as a parameter a folder '/shared/'
                                                                        # and the name of the child template provided by a parameter
                "contenVerison": "1.0.0.0"
            },
            {
                "parameters" {                                          # specify a list of parameters that are needed for the nested template
                    "key" : { "value" : "[parameters('key')]" },        # provide value for the parameter by referencing own parameters
                    ... #
                }
            }
        }
    }
]

```

When using outputs of a nested deployment you should implement the `depensdOn` property within te `Microsoft.Resource/deployments`

```json
{
    "apiVersion": "[vairables('deploymentApiVersion')]",
    "name" : "[parameters('nestedDeploymentDependendResource')]",
    "type" : "Microsoft.Resource/deployments",
    "dependsOn" : [                                                 # list of predecessor deployments as dependencies
        "[concat('Microsoft.Resource/deployment', parameters('nestedDeploymentPredecessor'))]",
                                                                    # concat to get  the resource name specified earlier
        "..."
    ]
    "properties" : {
"..." : "...",                                                      # see above, mode, templateLink etc.
        {
            "parameters" : {
                "key" : { "value" : "[reference(parameters('nestedDeploymentPredecessor')).outputs.key.value]" },
                                                                    # notice the outputs.key.value as discussed earlier
            }
        }
    }
}
```

## Tips and Tricks for ARM templates

### How to save time intensive output state and reuse for debugging (ARM template outputs debugging)

If you want to troubleshoot a time intensive output and save the state you can leverage `export-clixml`. For ARM templates that would be:

```powershell
# Deploy actual arm template or time intensive task then generates an object to reuse
$Deploy = New-AzResourceGroupDeployment ....

# save the state by serializing the object to xml
$Deploy | Export-Clixml $Home\state.xml
```

after that you can use the `state.xml` to retrieve the objects and all of their properties.

```powershell
# load time intensive object from serialized state
$session = Import-Clixml $home\state.xml
```

That will allow you to troubleshoot the output without rerunning the whole script until this point.
In debug mode you are able to export the output of a script at runtime at a specific place and time, too.

### Map Outputs from an Am Template to a custom object

```powershell
# get enumerator from stored session output
$enum = $session.GetEnumerator()

# prepare custom object
$return = [PSCustomObject]@{}

# uses enumerator to iterate through the output
while($enum.MoveNext()) {
    # get current object from enumerator
    $current = $enum.Current
    # add properties to object based on key and use the value as value value (see outputs structure in ARM) objects might need to be handled differently
    $return | Add-Member -MemberType NoteProperty -Name $current.Key -Value $current.Value.Value
}
# return constructed object
$return
```

An example implementation could look like the following code sample. However

```powershell
function Get-DeploymentOutput {
    <#
        .SYNOPSIS
            Takes Outputs from Arm Template deployment and generates a pscustomobject.

        .NOTES
            Outputs is Dictionary`2  needs enumerator
            Output value has odd value key again -> $output.Value.Value

            [DBG]: PS C:\dev> $$Output.GetType()
            Dictionary`2

            [DBG]: PS C:\dev> $output

            Key              Value
            ---              -----
            virtualMachineId Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.DeploymentVariable

            [DBG]: PS C:\dev> $output.Value

            Type   Value
            ----   -----
            String /subscriptions/*/resourceGroups/*/providers/Microsoft.Compute/virtualMachines/*

            $output.value.value
    #>
    [CmdletBinding()]
    param(
        $Outputs
    )

    if (-Not $Outputs) {
        Write-Error "[$(Get-Date)] Deployment output can not be parsed ´n $Deployment"
        return
    }
    else {
        try {
            $return = [PSCustomObject]@{}
            $enum = $Outputs.GetEnumerator()

            while ($enum.MoveNext()) {
                $current = $enum.Current
                $return | Add-Member -MemberType NoteProperty -Name $current.Key -Value $current.Value.Value
            }
            $return
        }
        catch {
            Write-Verbose "[$(Get-Date)] Unable to parse"
            return $Outputs
        }
    }
}
```

### Working with Resources

#### Resource Providers

List if resource is available in region

```powershell
#Requires -Modules @{ ModuleName="Az.Resources"; ModuleVersion="0.3.0" }
Get-AzResourceProvider |
    Select-Object ProviderNamespace, ResourceTypes |
    Sort-Object ProviderNamespace
```

#### Resource Types

```powershell
#Requires -Modules @{ ModuleName="Az.Resources"; ModuleVersion="0.3.0" }
Get-AzResourceProvider -ProviderNamespace Microsoft.Compute |
    Select-Object ResourceTypes, Locations |
    Sort-Object ResourceTypes
```

#### Azure Resource Manager REST APIs

`https://management.azure.com/subscriptions/{subscription-id}/providers/{provider-name}?&api-version={api-version}`

```powershell
param ( [Parameter(Mandatory=$true)] $SubscriptionName, $ProviderName = 'Microsoft.Compute',
$ResourceTypeName = 'virtualMachines')

$apiVersions = ((Get-AzResourceProvider -ProviderNamespace $ProviderName).ResourceTypes | Where-Object {$_.ResourceTypeName -eq $ResourceTypeName}).ApiVersions

$subcriptions = Get-AzSubscription -SubscriptionName $SubscriptionName

$uri = 'https://management.azure.com/subscriptions/{0}/providers/{1}?&api-version={2}' -f $subcriptions[0].SubscriptionId, $providerName, $apiVersions[0]

Invoke-WebRequest -Method Get -Uri $Uri
```

Source:

- [docs](https://docs.microsoft.com/en-us/rest/api/resources/deployments/validate)
- [msdn](https://msdn.microsoft.com/en-us/library/azure/dn790568.aspx)

### Source

[Pluralsight: Mastering Microsoft Azure Resource Manager - by James Bannan](https://app.pluralsight.com/library/courses/microsoft-azure-resource-manager-mastering/table-of-contents)

## Naming

Naming and naming conventions should be simple and consider limitation. KISS is the keyword (Keep it simple, stupid) to not add unnecessary complexity but creating consistency and readability to generate clarity.

[Docs: Naming conventions](https://docs.microsoft.com/en-us/azure/architecture/best-practices/naming-conventions)

### Limitations Examples

- Storage Groups
  - cannot exceed 24 characters
  - must be lowercase
  - no hyphens
- Windows
  - cannot exceed 15 characters

Global Unique Naming

- Azure Storage
- Web Apps
- Azure Key Vault
- Redis Cache
- Traffic Manager
- ...

### Convention by template

```json
{
  "$schema": "http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters":{
    "Prefix":{
        "type":"string",
        "maxLength":2
    },
    "Suffix":{
        "type":"string",
        "maxLength":1
    },
    "location":{
        "type":"string",
        "maxLength":2
    }
  },
  "variables":{    "nameconvention":"[concat(parameters('Prefix'),parameters('location'),parameters('Suffix'))]"
  },
  "resources":[
    ],
    "outputs":{
      "name" : {
        "type" : "string",
        "value": "[variables('nameconvention')]"
      }
    }
 }
```

### Source

- [Youtube: Deploy Infrastructure As A Service with Azure Resource Manager Templates by Will Anderson](https://www.youtube.com/watch?v=fY62tqENNw4)
- [Blog: Best Practices For Using Azure Resource Manager Templates](https://blogs.msdn.microsoft.com/mvpawardprogram/2018/05/01/azure-resource-manager/)

## Version Control Introduction

> Version control systems are software that help you track changes you make in your code over time. As you edit to your code, you tell the version control system to take a snapshot of your files. The version control system saves that snapshot permanently so you can recall it later if you need it.
> _By: Robert Outlaw_ [Link](https://docs.microsoft.com/en-us/azure/devops/learn/git/what-is-version-control)

## Version Control Tools

- [Git](https://git-scm.com/)

### Git Introduction

- Find a comprehensive Git introduction on Microsoft docs [Learn Git](https://docs.microsoft.com/en-us/azure/devops/learn/git/what-is-version-control).
- Inclduing how Microsoft uses Git [How We Use Git at Microsoft](https://docs.microsoft.com/en-us/azure/devops/learn/devops-at-microsoft/use-git-microsoft).
- If you are working in a team a good branching policy is adviced, find some inspiration on [Adopt a Git branching strategy](https://docs.microsoft.com/en-us/azure/devops/repos/git/git-branching-guidance?view=vsts), also see [Cloud Automation DevOps](07_Cloud_Automation_DevOps.md).

### Git Installation

Install git via [Chocolatey](https://chocolatey.org/).

```powershell
choco install git
```

### Git Common Commands

Table to list the common commands used in git
They are ordered by execution flow.

| Command                                   | Description                                                                                                                                                                      |
| ----------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| git status                                | Show the working tree status                                                                                                                                                     |
| git fetch                                 | Updates the local repository with all remote changes                                                                                                                             |
| git pull                                  | Fetch from and integrate with another repository or a local branch                                                                                                               |
| git branch                                | List, create, or delete branches                                                                                                                                                 |
| git branch -v -a                          | List, create, or delete branches -all -verbose (Including Remote Branches -- in case you are missing them locally)                                                               |
| Git checkout - - track origin/feature/... | Checkout specific branch -- including remote branches if you are missing them locally.Use origin/feature/<WORKITEMNUMBER_WORKITEMDESCRIPTION> (don't include the remote/ before) |
| git add .                                 | Adds all changes in the current directory (and sub directories) to the staging (need commit after)                                                                               |
| git add <PATH_TO_FILE>                    | Adds a specific file to the staging (Needs commit after)                                                                                                                         |
| git commit -am "Text"                     | Commit the changes (provide a descriptive message like "adds" ,"removes", "fixes" - those commit messages should describe the changes made)                                      |
| git push                                  | Update remote refs along with associated objects                                                                                                                                 |

A common sequence to check in code is:

```Bash
git add .
git commit -am '<COMMITMESSAGE>'
git push
```

Where `add .` stages all files. `commit -am` commits **a**ll changes with a given **m**essage. And `push` changes into remote repository.
For more details see [Save and share code with Git](https://docs.microsoft.com/en-us/azure/devops/learn/git/git-share-code)

## Repositories

- [Github](https://github.com/)
- [Azure DevOps](https://dev.azure.com/)

_Get Free AzureSubscription and Azure DevOps access through [Visual Studio](http://my.visualstudio.com/)_

## Source

- [softwaretestingfundamentals](http://softwaretestingfundamentals.com/)
- [docs.microsoft](https://docs.microsoft.com/en-us/azure/azure-resource-manager/)
- [What is Infrastructure as Code](https://docs.microsoft.com/en-us/azure/devops/learn/what-is-infrastructure-as-code)
- [What is DevOps?](https://docs.microsoft.com/en-us/azure/devops/learn/what-is-devops)
- [derrickcawthon](http://derrickcawthon.com/2018/04/30/fast-start-infrastructure-as-code-using-azure-devtestlabs/)
- [openedx.microsoft](https://openedx.microsoft.com/courses/course-v1:Microsoft+DEVOPS200.2x+2018_T1/info)
- [blogs.msdn.microsoft.com/azuredev](https://blogs.msdn.microsoft.com/azuredev/2017/02/11/iac-on-azure-an-introduction-of-infrastructure-as-code-iac-with-azure-resource-manager-arm-template/)
- [blogs.msdn.microsoft.com/mvpawardprogram](https://blogs.msdn.microsoft.com/mvpawardprogram/2018/02/13/infrastructure-as-code/)
- [blogs.msdn.microsoft.com/mvpawardprogram](https://blogs.msdn.microsoft.com/mvpawardprogram/2018/05/01/azure-resource-manager/)
- [Blog: Stop using ARM, use CLI instead](https://pascalnaber.wordpress.com/2018/11/11/stop-using-arm-templates-use-the-azure-cli-instead/)
- [openedx.microsoft - DEVOPS200](https://openedx.microsoft.com/courses/course-v1:Microsoft+DEVOPS200.2x+2018_T1/info)

## Table of content

- [What is Cloud Automation](#what-is-cloud-automation)
- [Why Cloud Automation](#why-cloud-automation)
- [How to Cloud Automation](#how-to-cloud-automation)
- [Conclusion](#conclusion)
  - [Infrastructure as Code](#infrastructure-as-code)
  - [DevOps](#devops)
- [Objectives](#objectives)
- [Introduction Cloud Automation Theory](#introduction-cloud-automation-theory)
- [Idempotence](#idempotence)
- [Approach](#approach)
- [Type](#type)
- [Goal](#goal)
- [Common automation tasks](#common-automation-tasks)
- [Imperative vs Declarative](#imperative-vs-declarative)
  - [Methods](#methods)
  - [Manual](#manual)
    - [Pro](#pro)
    - [Cons](#cons)
  - [Imperative](#imperative)
    - [Pro](#pro-1)
    - [Cons](#cons-1)
  - [Declarative](#declarative)
    - [Pro](#pro-2)
    - [Cons](#cons-2)
    - [ARM Template](#arm-template)
    - [Terra Form](#terra-form)
  - [Source](#source)
  - [Imperative Using .Net Core](#imperative-using-net-core)
- [Azure Resource Manager Parameter Recommendations](#azure-resource-manager-parameter-recommendations)
- [Azure Resource Manager Template Composition](#azure-resource-manager-template-composition)
  - [Composition Theory](#composition-theory)
  - [Output](#output)
  - [Composition Demo](#composition-demo)
- [Tips and Tricks for ARM templates](#tips-and-tricks-for-arm-templates)
  - [How to save time intensive output state and reuse for debugging (ARM template outputs debugging)](#how-to-save-time-intensive-output-state-and-reuse-for-debugging-arm-template-outputs-debugging)
  - [Map Outputs from an Am Template to a custom object](#map-outputs-from-an-am-template-to-a-custom-object)
  - [Working with Resources](#working-with-resources)
    - [Resource Providers](#resource-providers)
    - [Resource Types](#resource-types)
    - [Azure Resource Manager REST APIs](#azure-resource-manager-rest-apis)
  - [Source](#source-1)
- [Naming](#naming)
  - [Limitations Examples](#limitations-examples)
  - [Convention by template](#convention-by-template)
  - [Source](#source-2)
- [Version Control Introduction](#version-control-introduction)
- [Version Control Tools](#version-control-tools)
  - [Git Introduction](#git-introduction)
  - [Git Installation](#git-installation)
  - [Git Common Commands](#git-common-commands)
- [Repositories](#repositories)
- [Source](#source-3)
- [Table of content](#table-of-content)
