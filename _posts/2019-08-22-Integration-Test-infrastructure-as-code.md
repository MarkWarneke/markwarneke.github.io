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

how can you tell that an Azure Resource Manager template is valid and deployable?
We found that you can only safely say a template is tested if you have deployed it once.
In this blog post we are exploring how to write integration tests for Infrastrucutre as Code.

The general guidance for developing Azure Resource Manager (ARM) templates is to let the ARM Engine expand, validate and _deploy_ the template with all necessary dependencies and parameters. The engine is a taking care of validating input, orchestreting deploymets and combining dependencies, there are a lot of outside factors that needs to be considered.

The goal is to validate that the deployment can be executed without erros and to make sure the deployed resource is matching acceptance criteria.

`Test-AzResourceManagerDeployment` is not leveraging the ARM Engine fully. The commandlet is only ensuring the schema validaty of the template. Complex templates hwoever are not getting validated. The deployability of an ARM template is not validated using this cmdlet.

My recommendation: Use the ARM template for a test deployment **at least once**!
Make sure the template stays deployable by testing the deployment on a regualr basis...

## Introduction

Why are integration tests for Infrastructure as Code needed?

> ".. when using a general purpose programming language, you are able to do unit testing. You are able to isolate some part of your code from the rest of the outside world and test just that code. (...). **With (...) infrasturcute as code tool(s), you don't have that. Because the whole purpose of (...)  infrastructe as code is to talk to the outside world.** Its meant to make an API call to (...) Azure (...). You can't really have a unit, because if you remove the outside world there is nothing left. **So pretty much all of your tests (...) are inherently going to be integration test.**"  
> [Yevgeniy Brikman, Co-Founder of Gruntworks on "How to Build Reusable, Composable, Battle tested Terraform Modules" Youtube (28:16)](https://youtu.be/LVgP63BkhKQ?t=1696).

We want to create a tests that leverage execution logic thats lets us define a **before-test-block** to setup our infastructure and an **after-test-block** to tear it down after the test executed.

PowerShell Pester tests allows you to define a ScriptBlock section for `BeforeAll`, `BeforeEach`,  `AfterAll` and `AfterEach`, see [BeforeEach and AfterEach](https://github.com/pester/Pester/wiki/BeforeEach-and-AfterEach)

These ScriptBlocks can be used to create a test environment based on a given ARM template and execute a set of tests to assert that used ARM template provisions expected infrastructure reliable.

If the provisoning fails, we know immediatly that our tempalte is broken or that the cloud provider is currently not availble. The feedback loop is quicker and the transparency of our the deployability of the IaC modules is increased.

## Implementation

Inside the `BeforeAll` block of the integration test a unique ResourceGroup name is created. The resource group is only going to be needed for a test deploymentment. (One could also leverage specific `tags` on resources to identify automated test deployments.)

For the ResourceGroup nam a unique name can be generated with PowerShell using the current date: `$ResourceGroupName = 'TT-' + (Get-Date -Format FileDateTimeUniversal)`. Possible alternatives are `New-Guid` or `Get-Random` for the name. Beware, some resource do not support under scores `_` or other special characters, hence, stick to dashes `-` and small letters.

The ResourceGroup will be delete after the tests is completed. To make sure no Azure resource artefact is left behind. Error messages and deployment logs can be retrieved from Azure and stored as error logs after the deployment to investigate failing tests and unsuccesful deployments, see [getting the error messages and deployment logs](#getting-the-error-message-and-deployment-logs)

Depending on the test setup the implementation can be switched around.
 
Sometimes a deployment must be kept after the test. For instance, if post configuration needs to be applied. Destroying the infrastructure in the `BeforeAll` block first and then recreating from scratch can be an option to. The `AfterAll` could be used for stops the VM from running to reduce the costs of a running VM.

The cleanup part of Azure resources can simply by done by removing the  ResourceGroup invoking `Get-AzResourceGroup -Name $ResourceGroupName | Remove-AzResourceGroup -Force -AsJob`.
Similar, if tags are used the resources can be deleted by first finding the resources by the generated tag and then deleting them.

The `-AsJob` will start a PowerShell job in the background so the thread is not blocked and can execute the next tests right away.

## Integration Test Structure

The basic strucutre of the Pester integration test can look like the following code block.

In the `BeforeAll` ScriptBlock the infrastructure is prepared by creating a uniqe ResourceGroup based on the current datetime.
A `$ResourceName` is constructred based on the resource group name but using lower case letters. 

The name of this particular Azure resource is restricted to a maximum of 24 characters. Make sure the test deployments are not failing because of this constraint reason.

```powershell
# integration.Tests.ps1

Describe "Azure Data Lake Generation 2 Resource Manager Integration" -Tags Integration {
  BeforeAll {
    # Create test environment
    Write-Host "Creating test environment $ResourceGroupName, cleanup..."

    # Create a unique ResourceGroupName
    # 'unique' string base on the date
    # e.g. 20190824T1830434620Z
    # file date time universal format ~ 20 characters
    $ResourceGroupName = 'TT-' + (Get-Date -Format FileDateTimeUniversal)

    # Make sure the environment is clean by deleting the resource group
    Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue | 
                Remove-AzResourceGroup -Force

    # Get a unique name for the resource too, 
    # Some Azure Resources have a limitation of 24 characters
    # consider 20 for the unique ResouceGroup.
    $ResourceName = $ResourceGroupName.ToLower()
    
    # Create a new resource group for the test deployment
    $null = New-AzResourceGroup -Name $ResourceGroupName -Location 'WestEurope'
  } 

# ...
```

The test is beeing executed like a regular PowerShell Pester test. All options for assertion and testing, see [performing Assertions with Should](https://pester.dev/docs/usage/assertions/)

One could add a `try {} catch {}` block around the `New-AzResourceGroupDeployment` to make sure that any deployment error is handled and the exception is failing the test.

A static tempalte parameter file `$templateParameterFile` is used to provide default configuration. The default configuration could  contain the resource settings like the default size of the VM or an exsisting network that needs to be present in order to run the test deployment.

The dynamically created unique name is passed as a dynamic parameter to the tempalte deployment.
> Alternatively, you can use the template parameters that are dynamically added to the command when you specify a template. To use dynamic parameters, type them at the command prompt, or type a minus sign (-) to indicate a parameter and use the Tab key to cycle through available parameters. [Source](https://docs.microsoft.com/en-us/powershell/module/az.resources/new-azresourcegroupdeployment?view=azps-3.7.0)

Leveraging [Acceptance Tests](./2019-08-15-acceptance-test-infrastructure-as-code.md) it can be ensured that the deployment has the correct configurations applied and provisioned.

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
  # Notice that we expect the ARM template to have a parameter called name
  # The name is dynamically passed here based on the `BeforeAll` block
  # The output can also be stored
  $result = New-AzResourceGroupDeployment @Deployment -name $ResourceName

  # # Optional: Rn assertions on the returned object
  # $result.output | Should -Be ...

  # Optioal: Run Acceptance Test on provisioned resource
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

Deploying the solution might take time.
The integration test can also be flaky, as they depend on the outside world that sometimes can not be controlled by us.

Asserting on the deployed resource is very beneficial, as it **proves** the deployability of the template. It can also be used in nightly builds and automation.

The tests can be executed automatically, as they clean up after the themselfs. We can make sure a template **stays valid** throughout the time, by implementing frequent automated tests. API changes, changes in the template as well as changes in the  deployment can be detected immediatly.

This approach might be controversial. Some opinions think of this step as redundant, obsolete and too time consuming. The template might only be developed to be deployed once. However, how can you tell your IaC can be deployed again without messing up your whole infrastructure?

## Benefits - Why are integration tests important

There are certain benefits of having automated integration test:

- The test ensures the template is actually deployable. Running in automation the test can prove it every time, e.g. Nightly Builds.
- The integration test and therefore complete deployment is only needed on a change to the ARM template itself. On changes the feedback is immediatly presented to the developer if the changes broke the template.
- The template can be shared including the test and static configuration file. Much like a [Happy Path](https://en.wikipedia.org/wiki/Happy_path), the test documents how to use the template.
- Building modules. A tempalte can be considered a building block, similar to a library function that has a [Single Responsibility](https://de.wikipedia.org/wiki/Single-Responsibility-Prinzip). It should be ensured that this functionallty works with a test.

## Getting the error messages and deployment logs

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

## Final thoughts and tips

Make sure the tests are actually cleaning up.
Having a naming convention ensures test resource can be easily identified.

Have a asynchronous destroyer that makes sure all test resources are cleaned. A cleanup script can easily be implemented using a Azure Automation Account that searches for naming convention to remove resources.

Some resource my take a while to provision and some might take the time to tear down.
Some changes may introduce changes to other resources. Make sure to revert back or created entirly new resource to not interfere.

Haveing a dedicated test or validation subscription only for test deployments is a good practice, as you limit accedental changes and can wipe the whole subscription frequently.

The costs for test deployments should be small, depedning on the size of the project these costs are worth investing, as the return on invest is going to happen throughout the time.
