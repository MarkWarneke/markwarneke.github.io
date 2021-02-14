---
layout: post
title: Integration Tests for Infrastructure As Code
subtitle:
bigimg:
  - "/img/p-rN-n6Miag.jpeg": "https://unsplash.com/photos/p-rN-n6Miag"
image: "/img/p-rN-n6Miag.jpeg"
share-img: "/img/p-rN-n6Miag.jpeg"
tags: [PowerShell, Azure]
comments: true
time: 8
---


How can you tell that an Azure Resource Manager template is valid and deployable?
We found that you can only safely say a template is tested if you have deployed it once.
In this blog post, we are exploring how to write integration tests for Infrastructure as Code.

The general guidance for developing Azure Resource Manager (ARM) templates is to let the ARM Engine expand, validate and _deploy_ the template with all necessary dependencies and parameters. The engine is taking care of validating the input, orchestrating the deployment and combining necessary dependencies. There are a lot of outside factors that could go wrong during a deployment.

The goal is to validate that the template can be deployed without errors. We want to make sure that the deployed resource is matching acceptance criteria before we release the Infrastructure as Code module.

`Test-AzResourceManagerDeployment` is not leveraging the ARM Engine fully. The command is just ensuring that the schema of the template is valid. Complex templates, however, are not validated. The deployability of the ARM template can not be validated by using this cmdlet.

My recommendation: Use the ARM template for a test deployment **at least once**!
Make sure the template stays deployable by testing the deployment regularly...

## Introduction

Why are integration tests for Infrastructure as Code needed?

> ".. when using a general-purpose programming language, you are able to do unit testing. You are able to isolate some parts of your code from the rest of the outside world and test just that code. (...). **With (...) infrastructure as code tool(s), you don't have that. Because the whole purpose of (...)  infrastructure as code is to talk to the outside world.** Its meant to make an API call to (...) Azure (...). You can't really have a unit, because if you remove the outside world there is nothing left. **So pretty much all of your tests (...) are inherently going to be integration test.**"  
> [Yevgeniy Brikman, Co-Founder of Gruntworks on "How to Build Reusable, Composable, Battle-tested Terraform Modules" Youtube (28:16)](https://youtu.be/LVgP63BkhKQ?t=1696).

We want to create tests that leverage a life-cycle execution logic. We want to define a **before-test** code block to set up our infrastructure and an **after-test** code block to tear down the resources created after the test executed.

PowerShell Pester tests allows us to define a ScriptBlock section for `BeforeAll`,  `AfterAll`,  [BeforeEach and AfterEach](https://github.com/pester/Pester/wiki/BeforeEach-and-AfterEach).

These ScriptBlocks can be used to prepare a test environment. Next a set of tests to assert that the provisioned resource is valid can be executed. After test the ScriptBlock should clean up and remove provisioned resources.

If the provisioning fails, the test should fail. Making sure we know that the template is either broken or the provisioning at the cloud provider is currently not possible.

The feedback loop for seeing the impact of changes is much quicker.
The transparency for the deployability of IaC modules can be created.
Developers get confidence in that the IaC can be deployed at all times.

## Implementation

Inside the `BeforeAll` block of the integration test, a unique ResourceGroup name is created. The resource group is only going to be needed for test deployments. (One could also leverage specific `tags` on resources to identify automated test deployments.)

For the ResourceGroup name a unique string can be generated with PowerShell using the current date: `$ResourceGroupName = 'TT-' + (Get-Date -Format FileDateTimeUniversal)`. Possible alternatives are `New-Guid` or `Get-Random`. 

Beware, some resources do not support underscores `_` or other special characters, hence, stick to dashes `-` and small letters. You can find more information for [naming Azure resources in my Cloud Atuomation 101 article](https://markwarneke.me/2018-10-03-Cloud-Automation-Theory/#naming).

Inside the `AfterAll` block the ResourceGroup, including all Azure resources inside of the group, will be deleted after the test is completed.

Error messages and deployment logs can be retrieved from Azure and stored as error logs after the deployment to investigate failing tests and unsuccessful deployments by [getting the error messages and deployment logs](#getting-the-error-message-and-deployment-logs).

Depending on the test setup the implementation of infrastructure preparation and tear down can be switched around.

Sometimes a deployment must be kept after the test. For instance, if post configuration needs to be applied. Destroying the infrastructure in the `BeforeAll` block first and then recreating the infrastructure from scratch can be an option too. The `AfterAll` block could be used to stops a provisioned VM to reduce costs.

The cleanup of Azure resources can simply be done by removing the  ResourceGroup invoking `Get-AzResourceGroup -Name $ResourceGroupName | Remove-AzResourceGroup -Force -AsJob`. This will delete all Azure resources inside the Resource Group too.

Similarly, if tags are used to identify test resources. The resources can be located by the tag. The resources can then safely be deleted.

Make sure to keep some infrastructure present, for instance, you want to have a "test" virtual network running to check if the network integration works. You can save these resources by [locking resources to prevent unexpected changes](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/lock-resources).

The `-AsJob` will start a PowerShell job in the background. The test thread is not blocked and can execute the next tests right away. The resources will be deleted in the background. (Notice this can impact the cleanup, see [final thoughts and tips](#final-thoughts-and-tips) for taking care of this.)

## Integration Test Structure

The basic structure of the Pester integration test looks like the following code block.

In the `BeforeAll` ScriptBlock the infrastructure is prepared by creating a unique `$ResourceGroupName` based on the current DateTime.
A `$ResourceName` is constructed based on the resource group name but using lower case letters. 

The name of this particular Azure resource is restricted to a maximum of 24 characters. Make sure the test deployment is not failing because of this constraint.

```powershell
# integration.Tests.ps1

Describe "Azure Data Lake Generation 2 Resource Manager Integration" -Tags Integration {
  BeforeAll {
    Write-Host "Creating test environment $ResourceGroupName, cleanup..."

    # Create a unique ResourceGroupName
    # 'unique' string base on the date
    # e.g. 20190824T1830434620Z
    # file date time universal format ~ 20 characters
    $ResourceGroupName = 'TT-' + (Get-Date -Format FileDateTimeUniversal)

    # Make sure the environment is clean by deleting the resource group
    Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue | 
                Remove-AzResourceGroup -Force

    # Get a unique name for the resource too, 
    # Some Azure Resources have a limitation of 24 characters
    # consider 20 for the unique ResouceGroup.
    $ResourceName = $ResourceGroupName.ToLower()
    
    # Create a new resource group for the test deployment
    $null = New-AzResourceGroup -Name $ResourceGroupName -Location 'WestEurope'
  } 

# ...
```

The test is being executed like a regular PowerShell Pester test. You can [perform Assertions with Should](https://pester.dev/docs/usage/assertions/) like any other Pester test. For instance, the output of the deployment can be checked and asserted on the expected output.

A `try {} catch {}` block around the `New-AzResourceGroupDeployment` can be implemented to make sure that any deployment error is caught. The exception can be used to gracefully fail the test.

A static template parameter file `$templateParameterFile` is used to provide default configuration. The default configuration contains the resource settings, like the default sizes of the VM, an existing network that needs to be present or other parameters that can be fixed to run the test deployment successfully. A good practice is to have multiple parameter files and deploying the resource to multiple Azure locations.

The dynamically created unique name is passed as a dynamic parameter to the deployment.
> Alternatively, you can use the template parameters that are dynamically added to the command when you specify a template. To use dynamic parameters, type them at the command prompt, or type a minus sign (-) to indicate a parameter and use the Tab key to cycle through available parameters. [Source](https://docs.microsoft.com/en-us/powershell/module/az.resources/new-azresourcegroupdeployment?view=azps-3.7.0)

Leveraging [Acceptance Tests](/2019-08-15-acceptance-test-infrastructure-as-code.md) the test can also ensure that the deployed resource has the correct configurations applied.

```powershell
# integration.Tests.ps1  
# ...

  $Deployment = @{
      ResourceGroupName     = $ResourceGroupName  
      TemplateFile          = $templateFile 
      TemplateParameterFile = $templateParameterFile
  }

  # Deploy Resource
  # Run the deployment of the template
  # Notice that we expect the ARM template to have a parameter called name
  # The name is dynamically passed here based on the `BeforeAll` block
  # The output can also be stored
  $result = New-AzResourceGroupDeployment @Deployment -name $ResourceName

  # # Optional: Rn assertions on the returned object
  # $result.output | Should -Be ...

  # Optioal: Run Acceptance Test on provisioned resource
  . $PSScriptRoot/acceptance.spec.ps1 -ResourceName $ResourceName -ResourceGroupName $ResourceGroupName

# ...
```

After the test is executed. The ResourceGroup gets simply removed leveraging the `AfterAll` ScriptBlock of Pester.

```powershell
# integration.Tests.ps1  
# ...

  AfterAll {
    # Remove test environment after test
    Write-Host "Removing test environment $ResourceGroupName..."
    Get-AzResourceGroup -Name $ResourceGroupName |
      Remove-AzResourceGroup -Force -AsJob
  }
}
```

## Considerations

Deploying the solution might take time.
The integration test can also be flaky, as they depend on the outside world that changes.

Asserting on the deployed resource is very beneficial, as it **proves** the deployability of the template and the correctness of the settings, learn how to do [Acceptance Tests for Infrastructure as Code here.](/2019-08-15-acceptance-test-infrastructure-as-code.md)

We can make sure a template **stays valid** throughout the time, by implementing regular executed test runs. API changes, changes in the template as well as changes in the deployment context can be detected early and quickly. The tests can be integrated into nightly builds and other automation scenarios, e.g. web hooks that trigger the tests on new released versions.

The tests can be executed without human interaction. The test will make sure to clean up after itself.

This approach might be controversial. Some opinions think of integration tests as redundant, obsolete and too time-consuming. The template might only be developed to be deployed once. However, how can you tell your IaC can be deployed again without messing up your whole infrastructure?

And, how do you make sure changes to the infrastructure are working without impacting currently running services?

## Benefits - Why are integration tests important

There are certain benefits of having integration test in my opinion:

- The test ensures the template is deployable. Running in automation the test can prove deployability on each test run, e.g. Nightly Builds.
- The integration test and therefore a complete deployment is not only needed on a change to the ARM template but also changes on the environment. The feedback can be quickly presented to the developer.
- The template can be shared including the test and its configuration. Much like a [Happy Path](https://en.wikipedia.org/wiki/Happy_path) the test documents how to use the given template in a reproducible way.
- Build a module. A template can be packaged and considered a building block. Similar to a library function that implements the [single-responsibility principle](https://en.wikipedia.org/wiki/Single-responsibility_principle). It should be ensured that the intended functionality works given a test.

## Getting the error messages and deployment logs

If the deployment fails the logs and error message should be persisted to troubleshoot the failing test.

Sometimes the errors returned from the `New-AzResourceGroupDeployment` are not sufficient to find the error.

Using the following script the error can be investigated, by digging deeper into the issue using `Get-AzLog` to query the Azure Logs.

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

If you have additional **imperative** scripts like post configuration, custom script extension, and DSC. I emphasize to first unit test scripts and Mock any Az calls.

As the goal of the test is not to test the implementation of the provided commands like `Get-AzResource`, but to test whether the logic and flow of execution of the custom code is like expected.

Assert your mocks and validate if functions are called as expected. Only after the unit is tested write an integration test to validate against the outside world.

As these scripts will communicate with the Azure API and other external environments a call to the API is necessary to ensure the code is working.

An integration test of an imperative script must be executed at least once within the infrastructure as a code test suite.

The same applies to any post configuration like DSC.
You want to make sure that the configuration can be applied by doing it once.

## Final thoughts and tips

Make sure the tests are cleaning up correctly.
Having a naming convention ensures test resources can be identified easily.

Have an asynchronous destroyer that makes sure all test resources are cleaned. A cleanup script can easily be implemented using Azure Automation. Create a script that finds test resources by naming convention or tag and remove the test resources periodically.

Some resources may take a while to provision and some may take time to tear down.
Some changes may introduce changes to other resources. 
And some changes may introduce irreversible changes.
Make sure to revert or create an entirely new resource to not interfere with existing systems. Having infrastructure as code modules should allow you to create test environments quickly.

Having a dedicated test or validation subscription for test deployments is a good practice. You can limit accidental changes and can wipe the whole subscription frequently. There can also be loosened Azure policies applied. The subscription can be limited to a certain budget too.

The costs of test deployments should be small. Depending on the size of the environment the costs associated with test resources are worth investing as the increased reliability, transparency and developer efficiency will return the investment over time.