---
layout: post
title: DRAFT Azure DevOps Pester Tests and how to publish a Test Dashboard
subtitle:
bigimg:
  - "/img/draft.jpg": "https://unsplash.com/photos/wE37SqLAO9M"
image: "/img/draft.jpg"
share-img: "/img/draft.jpg"
tags: [draft]
comments: true
time: 4
---

EVer wondered how to publish test results in Azure DevOps?
Using the pipelines in Azure DevOps we can create a Test Dashboard to display our results.

## Implementation

![Azure DevOps Logs](/img/posts/2000-01-01-Azure-DevOps-Test-Dashboard/azuredevops-logs.jpg){: .center-block :}

![Test Results](/img/posts/2000-01-01-Azure-DevOps-Test-Dashboard/test-results.png){: .center-block :}

Make sure `Invoke-Pester` get the correct `OutputFormat = NUnitXml` passed.
Also the location of the OutputFile should be considered.
You can use the [predefined variables](https://docs.microsoft.com/en-us/azure/devops/pipelines/build/variables?view=azure-devops&tabs=yaml) of Azure DevOps `$ENV:System_DefaultWorkingDirectory` of Azure DevOps to locate the test file into the root of the agent.

## PowerShell Pester Test

```powershell
$testScriptsPath = Join-Path -Path $PSScriptRoot -ChildPath 'Test'
$testResultsFile = Join-Path -Path $PSScriptRoot -ChildPath 'TestResults.Pester.xml'

if (Test-Path $testScriptsPath) {
    $pester = @{
        Script       = $testScriptsPath
        OutputFormat = 'NUnitXml'     # Make sure the NUnitXML
        OutputFile   = $testResultsFile
        PassThru     = $true
        ExcludeTag   = 'Incomplete'
    }
    $null = Invoke-Pester @pester
}
```

## Pipeline

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
        scriptPath: $(Build.SourcesDirectory)\$(Module.Name)\test.ps1
        scriptArguments:
        azurePowerShellVersion: "latestVersion"
        errorActionPreference: "continue"

    - task: PublishTestResults@2
      inputs:
        testRunner: 'NUnit'   # Make sure to use the 'NUnit' test runner
        testResultsFiles: '**/TestResults.module.xml'
        testRunTitle: 'PS_Win2016_Module'
      displayName: 'Publish Module Test Results'
      condition: in(variables['Agent.JobStatus'], 'Succeeded', 'SucceededWithIssues', 'Failed')

    - task: PublishTestResults@2
      inputs:
        testRunner: 'NUnit'
        testResultsFiles: '**/TestResults.unit.xml'
        testRunTitle: 'PS_Win2016_Unit'
        failTaskOnFailedTests: true
      displayName: 'Publish Unit Test Results'
      condition: in(variables['Agent.JobStatus'], 'Succeeded', 'SucceededWithIssues', 'Failed')

    - task: PublishCodeCoverageResults@1
      inputs:
        summaryFileLocation: '**/CodeCoverage.xml'
        failIfCoverageEmpty: false
      displayName: 'Publish Unit Test Code Coverage'
      condition: and(in(variables['Agent.JobStatus'], 'Succeeded', 'SucceededWithIssues', 'Failed'), eq(variables['System.PullRequest.IsFork'], false))

    - task: PublishTestResults@2
      inputs:
        testRunner: 'NUnit'
        testResultsFiles: '**/TestResults.integration.xml'
        testRunTitle: 'PS_Win2016_Integration'
        failTaskOnFailedTests: true
      displayName: 'Publish Integration Test Results'
      condition: in(variables['Agent.JobStatus'], 'Succeeded', 'SucceededWithI
```
