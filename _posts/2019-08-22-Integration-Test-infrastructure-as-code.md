---
layout: post
title: Integration Tests for Infrastructure As Code
subtitle:
bigimg:
  - "/img/p-rN-n6Miag.jpeg": "https://unsplash.com/photos/p-rN-n6Miag"
image: "/img/p-rN-n6Miag.jpeg"
share-img: "/img/p-rN-n6Miag.jpeg"
tags: [PowerShell, AzureDevOps]
comments: true
time: 8
---

We found that you can only safely say an Azure Resource Manager (ARM) template is valid and deployable if you have deployed it once.

The `Test-AzResourceManagerDeployment` is not invoking the Azure Resource Manager Engine, complex templates are not getting validated. In this blog post we are exploring how to write effective integration tests.

The general guidance for developing ARM templates is: Let the Azure Resource Manager Engine expand, validate and _deploy_ the template with all its necessary dependencies and parameters once. Check that it deploys without erros and run acceptance tests on the deployed resources.

That means: Use the ARM template for a deploy **at least** once!
This might be refereed to a system or **Integration Test**. 

## Introduction

Why are integration tests needed?

> ".. when using a general purpose programming language, you are able to do unit testing. You are able to isolate some part of your code from the rest of the outside world and test just that code. (...). With (...) infrasturcute as code tool(s), you don't have that. Because the whole purpose of (...)  infrastructe as code is to talk to the outside world. Its meant to make an API call to (...) Azure (...). You can't really have a unit, because if you remove the outside world there is nothing left. So pretty much all of your tests (...) are inherently going to be integration test."
[Yevgeniy Brikman, Co-Founder of Gruntworks on "How to Build Reusable, Composable, Battle tested Terraform Modules" Youtube (28:16)](https://youtu.be/LVgP63BkhKQ?t=1696). 

## Implementation

We want to create a tests that leverage execution logic thats lets us define a **before-test-block** to setup our infastructure and an **after-test-block** to tear it down after the test runt automatically.

A PowerShell Pester test gives you the ScriptBlock sections `BeforeAll` and `AfterAll`.
The idea is, that the integration tests creates a test environment based on a given ARM template and runs a set of assertions on that provioned infrastructure.

When the provisoning fails, we know immediatly our tempalte is broken or that the cloud provider is currently not availble. 

Inside the `BeforeAll`block of Pester we are need to create a unique ResourceGroup that is only used for test deployments. One could also leverage specific `tags` on resources to identify automated test deployments.

For the ResourceGroup we can generate a unique name with PowerShell, e.g. based on the current date: `$ResourceGroupName = 'TT-' + (Get-Date -Format FileDateTimeUniversal)`. Possibel alternatives are `New-Guid` or `Get-Random`.

The ResourceGroup will be delete after the tests is successful, to make sure no Azure resource artefacts are left provisioned in Azure. Error messages and deployment logs can be retrieved from Azure and stored as error logs after the deployment to investigate failing tests and unsuccesful deployments.

Depending on the setup one could also switch the implementation around. 
Sometimes you need to keep a deployment for post configuration, so you would destroy the infrastructure and the `BeforeAll` block first and then create a fresh deployment - while the `AfterAll` maybe just stops the VM from running.

The cleanup part can simply by done by removing the whole ResourceGroup by invoking `Get-AzResourceGroup -Name $ResourceGroupName | Remove-AzResourceGroup -Force -AsJob`.
The `-AsJob` will start a PowerShell job in the background so the thread is not blocked and can execute the next tests right away.


 ## Integration Test Structure
 
The basic strucutre of the integration test looks something like this.
In the `BeforeAll` the infrastructure is prepared by creating a uniqe ResourceGrou.

```powershell
# integration.Tests.ps1 
Describe "Azure Data Lake Generation 2 Resource Manager Integration" -Tags Integration {
    BeforeAll {
        # Create test environment
        Write-Host "Creating test environment $ResourceGroupName, cleanup..."
        # Create a unique ResourceGroup 
        # 'unique' string base on the date
        # e.g. 20190824T1830434620Z
        # file date time universal format ~ 20 characters
        $ResourceGroupName = 'TT-' + (Get-Date -Format FileDateTimeUniversal)
        Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue | 
                Remove-AzResourceGroup -Force
        # Get a unique name for the resource too, 
        # Some Azure Resources have a limitation of 24 characters
        # consider 20 for the unique ResouceGroup.
        $ResourceName = 'pre-' + $ResourceGroupName.ToLower()
        # Setup the environment
        $null = New-AzResourceGroup -Name $ResourceGroupName -Location 'WestEurope'
    } 

# ...
```

The test is beeing executed simply like a regular PowerShell Pester test. Including all options for assertion and testing.

One could add a `try {} catch {}` block around the `New-AzResourceGroupDeployment` to assert that the deployment is succesful and not throwing errors.

A static tempalte parameter file `$templateParameterFile` is used to provide default configuration. The default configuration could  contain the resource settings like the size of the vm or an exsisting network that is used for testing.

The dynamically created unique name is passed as a dynamic parameter to the tempalte deployment.
> Alternatively, you can use the template parameters that are dynamically added to the command when you specify a template. To use dynamic parameters, type them at the command prompt, or type a minus sign (-) to indicate a parameter and use the Tab key to cycle through available parameters. [Source](https://docs.microsoft.com/en-us/powershell/module/az.resources/new-azresourcegroupdeployment?view=azps-3.7.0)

We can also leverage [Acceptance Tests](./2019-08-15-acceptance-test-infrastructure-as-code.md) to ensure our deployment has the correct properties provisioned.

```powershell
# integration.Tests.ps1  
# ...

$Deployment = @{
    ResourceGroupName     = $ResourceGroupName  
    TemplateFile          = $templateFile 
    TemplateParameterFile = $templateParameterFile
}

# Deploy Resource
# Run the deployment of the template
New-AzResourceGroupDeployment @Deployment -name $ResourceName #Notice that we expect the ARM template to have a parameter called name that is dynamically passed here

# Run Acceptance Test
. $PSScriptRoot/acceptance.spec.ps1 -ResourceName $ResourceName -ResourceGroupName $ResourceGroupName

# ... 
```

After the test is executed. The ResourceGroup gets simply removed leveraging the `AfterAll` ScriptBlock of Pester.

```powershell
# integration.Tests.ps1  
# ...

    AfterAll {
        # Remove test environment after test
        Write-Host "Removing test environment $ResourceGroupName..."
        Get-AzResourceGroup -Name $ResourceGroupName | 
                Remove-AzResourceGroup -Force -AsJob
    }
   
}
```

## Considerations

Deploying the solution will take time.
The test can also be flaky sometimes, as they depend on the outside world that sometimes can not be controlled by us. 

asserting on the deployed resource is very beneficial, as it **proves** the deployability of the template. It can also be used in nightly builds and automation. 

The tests can be executed automatically, as they clean up after the test. So that we can make sure a template **stays valid** throughout the time. API changes, and changes in the deployment can be detected immediatly.

This approach might be controversial, as some opinions think of this step as redundant and obsolete, because the template is only developed  to be deployed. However, there are certain benefits to having an integration test.

- The test ensures the template is actually deployable. Running in automation the test can prove it every time, e.g. Nightly Builds.
- The integration test and therefore complete deployment is only needed on a change to the ARM template itself. On changes the feedback is immediatly presented to the developer if the changes broke the template.
- The template can be shared including the test and static configuration file. Much like a [Happy Path](https://en.wikipedia.org/wiki/Happy_path), the test documents how to use the template.
- Building modules. A tempalte can be considered a building block, similar to a library function that has a [Single Responsibility](https://de.wikipedia.org/wiki/Single-Responsibility-Prinzip). It should be ensured that this functionallty works with a test.

### Getting the error message and deployment logs

If the deployment fails the logs and error message should be persitet to troubleshoot the failing test. 

Sometimes the errors returned from the `New-AzResourceGroupDeployment` are not sufficient to find the error.

Using the following script the error can be investigated, by digging deeper into the issue using and querying the Azure Logs using `Get-AzLog`.

```powershell
function LogError($Exception, $ResourceGroupName) {

  $VerbosePreference = "Continue"

  # Log the exception
  $Exception | Format-List -Force | Out-String | Write-Verbose

  # Get the correlation id to track the logs
  $correlationId = ((Get-AzLog -ResourceGroupName $ResourceGroupName)[0]).CorrelationId

  # Query the log for the deployment log
  $logEntry = (Get-AzLog -CorrelationId $correlationId -DetailedOutput)

  # Print it to the screen
  $logEntry | Format-List -Force | Out-String | Write-Verbose

  # Digging deeper into the log entry and getting the status message
  $rawStatusMessage = $logEntry.Properties
  $status = $rawStatusMessage.Content.statusMessage | ConvertFrom-Json

  # Print to the screen
  $status.error.details | Format-List -Force | Out-String | Write-Verbose
  $status.error.details.details | Format-List -Force | Out-String | Write-Verbose
}
```

## Imperative Integration Testing

If you have additional **imperative** scripts like post configuration, custom script extension and DSC. I would emphasize to first unit tests these scripts and Mock any Az calls.

As the goal of the test is not to test the implementation of the provided commands like `Get-AzResource`, but to test wether the logic and flow of execution of the custom code is doing what is expected.

Assert your mocks and validate if functionsa are called as expected. Only after the unit is tested write an integration test to validate against the outside world.

As these scripts will communicate with the Azure REST API and might depend on resouces, as well as mandatory parameters an actual call to the API is sometimes need to assert that the code is correctly running.

An integration test of imperative scripts should be done at least once within the infrastructure as code test suite.

The same applies for any post configuration or DSC.
You want to make sure that also the configuration got actually applied. 
