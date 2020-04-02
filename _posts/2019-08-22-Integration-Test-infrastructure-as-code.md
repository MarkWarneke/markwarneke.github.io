---
layout: post
title: DRAFT Infrastructure As Code Integration Test
subtitle:
bigimg:
  - "/img/p-rN-n6Miag.jpeg": "https://unsplash.com/photos/p-rN-n6Miag"
image: "/img/p-rN-n6Miag.jpeg"
share-img: "/img/p-rN-n6Miag.jpeg"
tags: [PowerShell, AzureDevOps]
comments: true
time: 4
---

we found that you can only safely say an Azure Resource Manager (ARM) template is valid and deployable if you have deployed it once.
The `Test-AzResourceManagerDeployment` is not invoking the Azure Resource Manager Engine, complex templates are not getting validated. In this blog post we are exploring how to write effective integration tests.

The general guidance for developing ARM templates is: Let the Azure Resource Manager Engine expand, validate and _deploy_ the template with all its necessary dependencies and parameters once. Check that it deploys without erros and run acceptance tests on the deployed resources.

That means: Use the ARM template for a deploy **at least** once!
This might be refereed to a system or **Integration Test**. 

> ".. when using a general purpose programming language, you are able to do unit testing. You are able to isolate some part of your code from the rest of the outside world and test just that code. (...). With (...) infrasturcute as code tool(s), you don't have that. Because the whole purpose of (...)  infrastructe as code is to talk to the outside world. Its meant to make an API call to (...) Azure (...). You can't really have a unit, because if you remove the outside world there is nothing left. So pretty much all of your tests (...) are inherently going to be integration test."
[Yevgeniy Brikman, Co-Founder of Gruntworks explains this test setup nicely, in "How to Build Reusable, Composable, Battle tested Terraform Modules":28:16](https://youtu.be/LVgP63BkhKQ?t=1696). 

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

The cleanup part can simply by done by removing the whole ResourceGroup e.g. by invoking `Get-AzResourceGroup -Name $ResourceGroupName | Remove-AzResourceGroup -Force -AsJob`.
The `-AsJob` will start a PowerShell job in the background so the thread is not blocked and can execute the next tests right away.

```powershell
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification = "Variables are used inside Pester blocks.")]
param(
    [string[]]$TestValueFiles
)

# Get test configuration from scripts location
if ($PSBoundParameters.Keys -notcontains 'TestValueFiles') {
    $TestValueFiles = (Get-Childitem -Path $PSScriptRoot -Include "config.*.json" -Recurse).FullName
}


Foreach ($TestValueFile in $TestValueFiles) {

    $Env:TestValueFile = $TestValueFile
    $TestValues = Get-Content $TestValueFile | ConvertFrom-Json

    Describe "New-Component function integration tests" -Tags Integration, Build {

        BeforeAll {
            # Create test environment

            # We create a unique ResourceGroup by getting a `unique` string base on the date 20190824T1830434620Z, the file date time universal has 20 characters
            $ResourceGroupName = 'TT-' + (Get-Date -Format FileDateTimeUniversal)
            Write-Host "Creating test environment $ResourceGroupName, cleanup..."
            Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue | Remove-AzResourceGroup -Force

            # Get a unique name for the resource too, some Azure Resources have a limitation of 24 characters, consider 20 for the unique string.
            $ResourceName = 'pre-' + $ResourceGroupName.ToLower()
            $null = New-AzResourceGroup -Name $ResourceGroupName -Location 'WestEurope'
        }

        AfterAll {
            # Remove test environment after test
            Write-Host "Removing test environment $ResourceGroupName..."
            Get-AzResourceGroup -Name $ResourceGroupName | Remove-AzResourceGroup -Force -AsJob
        }

        $Exception = $null
        try {
            $InputObject = @{
                ResourceName      = $ResourceName
                ResourceGroupName = $ResourceGroupName
                Location          = $TestValues.Location
            }

            $deployment = New-xAzCosmosDeployment @InputObject -Verbose

            # Query for the resource after the deployment
            # $resource = Get-AzResource -Name $ResourceName -ResourceGroupName $ResourceGroupName
            # or run any Get-Az* Command
        }
        catch {
            # See LogError function below
            LogError($_, $ResourceGroup)
        }

        # if an exception is thrown consider digging into the error
        It "should not throw" {
            $Exception | should be $null
        }

        # Add assertions similar to the acceptance tests
        it "should have... " {
            $deployment.ResourceName | Should Be $ResourceName
        }
    }
}
```

## Considerations

Deploying the solution will take time, but actually asserting on the deployed resource is very beneficial.
This might be a controversial point and I would love to have a conversation on this topic, as some people think of this step as redundant and obsolete.
However we found it worthwhile having as it ensures the template is actually deployable.
The integration test and therefore complete deployment is only needed on a change to the ARM template itself.

### Getting the error message and deployment logs

If the deployment fails you need to make sure the error message is printed.
Sometimes the errors of the New-AzResourceGroupDeployment are not sufficient.
Using the following script we can dig deeper into the issue by querying and getting the AzLogs.

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

If you have additional **imperative** scripts like post configuration, custom script extension, DSC, you want to test I would emphasize to unit tests these scripts and Mock any Az native calls.
You don't want to test the implementation of commands like `Get-AzResource`, but test wether your logic of execution and written custom code is doing what is expected.
Assert if your mocks are called and validate your code flow.

However, as these scripts communicate with the Azure REST API and might rely on dependencies and mandatory parameters an actual call to the API is mandatory to assert that the code is correct.
It should be done at least once within the test suite
The same applies for any post configuration or DSC.
You want to make sure the configuration got actually applied.

## Remarks

## Table of Content

- [Implementation](#implementation)
- [Considerations](#considerations)
  - [Getting the error message and deployment logs](#getting-the-error-message-and-deployment-logs)
- [Imperative Integration Testing](#imperative-integration-testing)
- [Remarks](#remarks)
- [Table of Content](#table-of-content)
