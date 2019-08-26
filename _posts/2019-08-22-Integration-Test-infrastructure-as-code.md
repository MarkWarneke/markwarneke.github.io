---
layout: post
title: DRAFT Infrastructure As Code Integration Test
subtitle:
bigimg:
  - "/img/p-rN-n6Miag.jpeg": "https://unsplash.com/photos/p-rN-n6Miag"
image: "/img/p-rN-n6Miag.jpeg"
share-img: "/img/p-rN-n6Miag.jpeg"
tags: [draft]
comments: true
time: 4
---

We found in our project that you can only safely say _an ARM template is valid and deployable if you deployed it once_.
As `Test-AzResourceManagerDeployment` is not invoking the Azure Resource Manager Engine, complex templates are not validated.
The general guidance therefore is: Let the Azure Resource Manager Engine expand, validate and _execute_ the template with all its necessary dependencies and parameters. That means, use the ARM template for a deploy at least once.
This might be refereed to a System or **Integration Test**.

## Implementation

We want to create Pester tests that leverage the `BeforeAll` and `AfterAll` functionality.
The idea is, that the integration tests creates a test environment for a set of assertions.
Inside the BeforeAll block of Pester we are going to create a unique ResourceGroup that is used for a deployment.
This ResourceGroup gets a unique name. `$ResourceGroupName = 'TT-' + (Get-Date -Format FileDateTimeUniversal)`
The ResourceGroup will be delete after the tests is successful.
Error messages and logs can be tracked and put to the logs.

Depending on your setup you can switch the implementing around, sometimes you need to keep a deployment for post configuration.
Therefore the cleanup should be in `BeforeAll`, rather then after the test.
Cleanup will be done simply by invoking `Get-AzResourceGroup -Name $ResourceGroupName | Remove-AzResourceGroup -Force -AsJob`.
The `-AsJob` will start a PowerShell job in the background so the thread is not blocked and can execute the next tests.

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
