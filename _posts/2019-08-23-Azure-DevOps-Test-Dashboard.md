---
layout: post
title: DRAFT Azure DevOps Pester Tests and how to publish a Test Dashboard
subtitle:
bigimg:
  - "/img/draft.jpeg": "https://unsplash.com/photos/wE37SqLAO9M"
image: "/img/hpjSkU2UYSU.jpeg"
share-img: "/img/hpjSkU2UYSU.jpeg"
tags: [AzureDevOps]
comments: true
time: 2
---

Ever wondered how to publish test results in Azure DevOps?
Using the pipelines in Azure DevOps we can create a Test Dashboard to display our results.

## Dashboard

![Test Results](/img/posts/2000-01-01-Azure-DevOps-Test-Dashboard/test-results.png){: .center-block :}

If you want to see the full implementation visit [az.new](https://dev.azure.com/az-new/xAz.New/_build/results?buildId=71&view=ms.vss-test-web.build-test-results-tab)!

## PowerShell Pester Task

Make sure `Invoke-Pester` get the correct `OutputFormat = NUnitXml` passed.
Also the location of the OutputFile should be considered.
You can use the [predefined variables](https://docs.microsoft.com/en-us/azure/devops/pipelines/build/variables?view=azure-devops&tabs=yaml) of Azure DevOps `$ENV:System_DefaultWorkingDirectory` or `$(Build.SourcesDirectory)` of Azure DevOps to save the test file into the root of the agent.

```powershell
# Invoke-Pester.ps1
$testScriptsPath = Join-Path -Path $PSScriptRoot -ChildPath 'Test'
$testResultsFile = Join-Path -Path $PSScriptRoot -ChildPath 'TestResults.Pester.xml'

if (Test-Path $testScriptsPath) {
    $pester = @{
        Script       = $testScriptsPath
        # Make sure NUnitXML is the output format
        OutputFormat = 'NUnitXml'         # !!!
        OutputFile   = $testResultsFile
        PassThru     = $true
        ExcludeTag   = 'Incomplete'
    }
    $null = Invoke-Pester @pester
}
```

## Pipeline

![Azure DevOps Logs](/img/posts/2000-01-01-Azure-DevOps-Test-Dashboard/azuredevops-logs.jpg){: .center-block :}

PowerShell `errorActionPreference: "continue"`

testRunner: 'NUnit'
PublishTestResults: `failTaskOnFailedTests`

```yaml
trigger:
  - master

variables:
  azureSubscription: "Mark"
  feed.name: "xAz"
  organization: "az-new"
  module.name: "xAz.Cosmos"

jobs:
  - job: Build_PS_Win2016
    pool:
      vmImage: vs2017-win2016

    steps:
      - checkout: self
        persistCredentials: true

      - task: AzurePowerShell@4
        inputs:
          azureSubscription: $(azureSubscription)
          scriptType: "FilePath"
          # The name of the script where the pester test setup is located
          scriptPath: $(Build.SourcesDirectory)\Invoke-Pester.ps1
          scriptArguments:
          azurePowerShellVersion: "latestVersion"
          errorActionPreference: "continue"

      - task: PublishTestResults@2
        inputs:
          # Make sure to use the 'NUnit' test runner
          testRunner: "NUnit" # !!!
          testResultsFiles: "**/TestResults.Pester.xml"
          testRunTitle: "PS_Win2016_Unit"
          # Make the whole pipeline fail if a test is failed
          failTaskOnFailedTests: true
        displayName: "Publish Unit Test Results"
        condition: in(variables['Agent.JobStatus'], 'Succeeded', 'SucceededWithIssues', 'Failed')

      - task: PublishCodeCoverageResults@1
        inputs:
          summaryFileLocation: "**/CodeCoverage.xml"
          failIfCoverageEmpty: false
        displayName: "Publish Unit Test Code Coverage"
        condition: and(in(variables['Agent.JobStatus'], 'Succeeded', 'SucceededWithIssues', 'Failed'), eq(variables['System.PullRequest.IsFork'], false))
```

## Considerations

You might want to run multiple pester tests that execute different kind of tests.
For that I would recommend extending the yaml to have a pester test and a publish test result task per kind.
This will allow you to not only get the results faster into the UI of Azure DevOps but you can also get a drill down of tests per kind, similar to the screenshot.

Also a good practice is to enable exclusion, the script to execute the pester tests should therefore have a parameter that allows you to exclude certain scripts or even whole tags.

Again, if you want to see this, visit [az.new](https://dev.azure.com/az-new/xAz.New/_build/results?buildId=71&view=ms.vss-test-web.build-test-results-tab) if you want to see the full implementation.

## Remarks

## Table of Content

- [Dashboard](#dashboard)
- [PowerShell Pester Task](#powershell-pester-task)
- [Pipeline](#pipeline)
- [Considerations](#considerations)
- [Remarks](#remarks)
- [Table of Content](#table-of-content)
