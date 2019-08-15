---
layout: post
title: Test Infrastructure as Code
subtitle:
bigimg:
  - "/img/pyramid.jpg": "https://unsplash.com/photos/I74RH4XeHlA"
image: "/img/pyramid.jpg"
gh-repo: MarkWarneke/Az.Test
gh-badge: [star, follow]
tags: [Test, PowerShell, AzureDevOps]
comments: true
time: 10
---

Treat Infrastructure as Code development like a software engineering project.
Implement existing software development practices into your infrastructure development.
In this article we are going to look into different practices regarding test implementation in an Infrastructure as Code project.

{: .box-note}
**Note** The one fundamental is **Version Control** <br>
Get familiar with this practice first before thinking about implementing tests!

You should embrace [**Behavior Driven Development**](https://en.wikipedia.org/wiki/Behavior-driven_development) to work on your **Infrastructure as Code** IaC project.
These principals will force you into writing tested code.
A good starting point when starting with tests for infrastructure as code is the [Test Pyramid](https://martinfowler.com/articles/practical-test-pyramid.html).
Where you want to have many quick and small tests to ensure your code does what is expected.
However, when talking about Infrastructure Development there are slight differences to Software Development.

## PowerShell Conference EU

[Video: Test Infrastructure as Code?](https://www.youtube.com/watch?v=k33Nini-Dc8) [Slides & Code](https://github.com/psconfeu/2019/tree/master/sessions/MarkWarneke)

<div class="video-container">
    <iframe  src="https://www.youtube.com/embed/k33Nini-Dc8" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</div>

During the PowerShell Conference EU 2019 I had the opportunity to talk about Infrastructure as Code testing and what we learned in a large scale IaC and automation project.
I covered a few fundamentals on IaC, unfortunately the Fridays session had some technical problems and hasn't been recorded.

The talk is addressing the following key topics:

- Introduction to Infrastructure as Code
- DevOps foundations
- Quality & Maturity Framework

Let me know if you have feedback in the comments below or [@MarkWarneke](https://twitter.com/MarkWarneke)!

## Climb the Pyramid

When following the best practices for Infrastructure as Code by using a [**declarative approach**](http://markwarneke.me/Cloud-Automation-101/Article/01_Cloud_Automation_Theory.html#approach) to provision resources there really is no _unit_ or smallest executable code to test except the configuration file itself.
This file usually only describes the desired state of the system to be deployed.
The specified system consists of one ore more Azure resources that needs to be provisioned.
Hence, you should make sure your unit is thoroughly tested using available methods, tools and practices.

Having an **Azure Resource Manager Template** (ARM Template) as the subject under test we are looking into _testing_ a JSON configuration file.
I have not yet heard of a Unit Testing framework for configuration files like YAML or JSON; I am only aware of [linter](<https://en.wikipedia.org/wiki/Lint_(software)>) for these file types.

![Test Pyramid](/img/test-iac/psconfeu19_test_iac.jpg){: .center-block :}

The Test Pyramid for IaC could look something like this.
Where the **x-axis** indicates how mature the IaC project is and the **y-axis** indicates the quality of the IaC.
This is of course a generalization and you should strive to implement all practices, starting from the bottom left and ending up in top right.

### Unit Tests

I personally refer to a **unit tests** for ARM templates as asserted **static code analysis**.
By using assertion the test should parse, validate and check for [best practices](https://docs.microsoft.com/en-us/azure/azure-resource-manager/template-best-practices) within the given configuration file (ARM template).

As we are not compiling or building a software product we can not rely on any compilers to throw errors on syntactical issues.
See VDC codeblocks [module.tests.ps1](https://github.com/Azure/vdc/blob/vnext/Modules/SQLDatabase/2.0/Tests/module.tests.ps1) tests and Az.Test [azuredeploy.Tests.ps1](https://github.com/MarkWarneke/Az.New/blob/master/xAz.New/static/src/test/azuredeploytests.ps1) for different implementations of unit tests for ARM templates.

### Integration Tests

We found in our project that you can only safely say _an ARM template is valid and deployable if you deployed it once_.

As `Test-AzResourceManagerDeployment` is not invoking the Azure Resource Manager Engine, complex templates are not validated.
The general guidance therefore is: Let the Azure Resource Manager Engine expand, validate and _execute_ the template with all its necessary dependencies and parameters. That means, use the ARM template for a deploy at least once.
This might be refereed to a System or **Integration Test**.

Deploying the solution will take time, but actually asserting on the deployed resource is very beneficial.
This might be a controversial point and I would love to have a conversation on this topic, as some people think of this step as redundant and obsolete.
However we found it worthwhile having as it ensures the template is actually deployable.
The integration test and therefore complete deployment is only needed on a change to the ARM template itself.

If you have additional **imperative** scripts like post configuration, custom script extension, DSC, you want to test I would emphasize to unit tests these scripts and Mock any Az native calls.
You don't want to test the implementation of commands like `Get-AzResource`, but test wether your logic of execution and written custom code is doing what is expected.
Assert if your mocks are called and validate your code flow.

However, as these scripts communicate with the Azure REST API and might rely on dependencies and mandatory parameters an actual call to the API is mandatory to assert that the code is correct.
It should be done at least once within the test suite
The same applies for any post configuration or DSC.
You want to make sure the configuration got actually applied.

### End-To-End Testing

We also found that a dummy deployment **End-to-End Testing** (e2e) will help to find missing requirements, missing dependencies and deployment issues.
Again, a controversial topic as this testing approach is similar to Integration Tests and therefore in a way redundant.
A combination of both is probably a good approach depending on the resource.

Having an **Engineering-Pipeline**, that is a Release-Pipeline into a standalone subscription, is also worthwhile having.
You really want to test if your configuration (ARM Template) is valid and stays valid and can be redeployed [**idempotent**](http://markwarneke.me/Cloud-Automation-101/Article/01_Cloud_Automation_Theory.html#idempotence) over and over again.
The Engineering-Pipeline is also usable for feature and experimental development.

An **Engineering Subscription** is a subscription that has no or limited access to any other subscription or on premises and should not reflect any customer environment or contain _any_ data.
If the engineering subscription is compromised an attacker should not be able to identify the company or user.
Also the naming should not indicate in any way the company or brand.

### Tests across Azure regions

Additionally a good test should validate different input parameters.
Having a deployment to _multiple different Azure Regions_ can save time when troubleshooting a deployment issue to a new region.
Some Azure Services are only available (or in Preview) in certain Azure Data centers.
Keeping this in mind: All tests should considers different Parameter combination and Azure.

### Acceptance Tests

You probably want to make sure no deviation or configuration drift is happening.
Using a test method called **Acceptance Test** of **Validation Tests** can save you a lot of time.
These Tests are written to ensure a requirement is met. You can execute these tests on a given resource and validate if a specified configuration was applied.

Acceptance Tests should be written in a way that they can be executed in different stages.
An acceptance tests should be small enough to validate a specific requirement.
These kind of tests can be executed during integration, e2e test and especially after a release.

### Smoke Tests

Using the specification defined in form of a acceptance tests.
Multiple tests cases can be used combined for exploration testing or **smoke testing** on previously deployed resources.

That is, querying for existing Azure resources and checking the properties against certain requirements or specifications, which are implemented as acceptance tests.
Smoke tests are usually executed against a black box system to validate and check the state and behavior.
Using smoke tests against Azure resources will ensure general requirements of resources are met.

## Code generator

Using a code generator to bootstrap you project saves time and implements best practices right from the start. The [Az.New](https://github.com/MarkWarneke/Az.New/) module has been create to demonstrate an example code generator for IaC project. The module will create a folder structure and a basic set of tests for the project. It is inspired on the code generator [yo](https://yeoman.io/) that was initially created for web projects. [Ruby on Rails](https://guides.rubyonrails.org/generators.html) and [Angular](https://angular.io/cli/generate) for example base the Developer workflow on generating code, it is less error prone and implement code consistency.

## Review und Pull-Requests

A good practice is to have regular **peer reviews** and rely on **pull-requests** to apply changes to the code base.

A **branching policy** prevents the immediate change to a given branch. It is a must to implement a branching policy when using IaC. The branching policy should enforce a required reviewer and foster the peer review concept. The review is therefore enforced on each change to the code base. The four eyes principle increases Code Quality tremendously and helps knowledge sharing.

The branching policy can also enforce the assignment of tickets like change request, features or bugs. The policy can also associated a build pipeline. This pipeline will pre-merge the requested changes and execute the pipeline on the pre merged code. The tests are thus executed before the actual change is done to the code base.

## Tests Phases

Unit and Integration tests could be grouped into the **build phase**.
While Validation, Acceptance and e2e Tests could be group to the **release phase**.
User Acceptance Test and Smoke Tests are done after a particular release.

Some resource deployments can take hours, e.g. VNet Gateways (~25mins).
Having an integration test inside the build-phase might wast precious build time of the [Build Agent](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/hosted?view=azure-devops#capabilities-and-limitations).
You might only want to leverage e2e tests for Azure Resources that take a long time to deploy.
The right testing approach should be considered resource by resource.

I would recommend to rely solely on e2e tests inside a release pipeline if you are able to keep the resources provisioned.
The build phase will therefore limit the tests to the static analysis and linting of the ARM template.
While the actual deployment happens the first time in the release phase.
You can also limit it to only deploy on approval.

This approach will not trigger a new deployment on each change to the version control but on each new **Artifact** that is being published and the approval of the release.
If changes to the template are minor only the changes will be deployed and the deployment should be rather quick, if the resource existed.

This kind of test will result in costs if the resources are not cleaned up periodically.

I would recommend **Preview-Artifacts**. these Artifacts can be leverage to use this kind of Release-Pipeline testing.
These artifacts are not yet officially published and might have a Beta or Preview indicator.
These Artifact should only be used for demo or testing purposes.

## Continuous Integration & Continuous Deployment

The result of a build phase, if successful, should always create some kind of **Artifact**.
Similar to a compiler but for a IaC configuration file.
Only after an actual deployment and the validation of the requirements on the deployed Azure Resource took place an artifact could be considered build, it is also known as **Continuous Integration**.
Only then the build Artifact, in this context the ARM template, is valid.
An Artifact will have a dedicated traceable version number and should contain release information and a change log.
Other teams can subscribe and get notification on new Artifact versions.

The created Artifact is used to release and deploy to the first environment - **Continuous Delivery**, usually a Development (Dev) or Beta environment.
You can use a dedicated Azure subscription or a naming convention inside a resource group.
I would recommend to have at least dedicated subscriptions for different environments.

After the deployment to the first stage is successful you can execute the automated Acceptance Tests and have a gate that notifies Key Users to run **User Acceptance Tests** on the particular 'test' environment.
User Acceptance Tests can be managed and monitored through [Azure DevOps Test Plans](https://azure.microsoft.com/en-us/services/devops/test-plans/).
Only after the approval of a release manager, if all tests result from the key users are green, the next Stage e.g. Pre-Production or Staging should be triggered.
This staging and deployment from one environment to the next is considered **Continuous Deployment**.
Continuous Deployment should be the end goal of every Infrastructure as Code project.

## Developer View

There are two views one could have on testing we refer to these as the **InnerLoop** and **OuterLoop**.
The _InnerLoop_ is the view of the Developer.

The requirements of a Developer are usually: quick feedback, quick execution and a smooth workflow.

Tools like linting integrate easily into the workflow of a developer.
A good practice to have for the InnerLoop are convention and consistent formating.
Consistent code styles and formats prevent errors and increase productivity.
[@RobinManuelT](https://twitter.com/robinmanuelt) create a great blog post describing his setup to [enforce a consistent Coding Style across projects and programming languages](https://pumpingco.de/blog/enforcing-a-consistent-coding-style-across-projects-and-programming-languages/).
Creating Code generators will not only save time but also increase consistency throughout the code base. An example can be found in the [Az.New](https://aka.ms/Az.New) module.

The developer needs to be able to work independently and execute tests locally, so she is able to test the code before check-in.
To rely solely on a release pipeline is not recommended, as the pipeline could be overcrowded and the developer might be missing the access to it.

### VSCode Setup

Visual Studio Code is the go to editor when developing Azure Resource Manager templates.
Its extensibility and configurations makes it a powerful editor of choice.

```json
//.vscode/extensions.json
{
  "recommendations": [
    // Linter for ARM teampltes
    "msazurermtools.azurerm-vscode-tools",

    // Code generator for ARM template snippets
    "samcogan.arm-snippets",

    // Linter for Markdown
    "DavidAnson.vscode-markdownlint",

    // Version Control Helper Extension
    "eamodio.gitlens",

    // JSON tool
    "eriklynd.json-tools",

    // PowerShell Extension and Linter (PSScriptAnalyzer)
    "ms-vscode.PowerShell",

    // Spell Checker
    "streetsidesoftware.code-spell-checker"
  ]
}
```

easy code styles could be enforced by using a `.vscode/settings.json` in the root of a vscode session.

```json
// .vscode/settings.json
{
  //-------- Files configuration --------

  // When enabled, will trim trailing whitespace when you save a file.
  "files.trimTrailingWhitespace": true,
  "files.autoSave": "afterDelay",
  "files.autoSaveDelay": 2000,
  "files.hotExit": "onExit",

  "editor.formatOnSave": true,
  "editor.formatOnPaste": true,

  //-------- PowerShell Configuration --------

  // Use a custom PowerShell Script Analyzer settings file for this workspace.
  // Relative paths for this setting are always relative to the workspace root dir.
  "powershell.scriptAnalysis.enable": true,
  "powershell.codeFormatting.openBraceOnSameLine": true,
  "powershell.scriptAnalysis.settingsPath": "./PSScriptAnalyzerSettings.psd1" // See below
}
```

PowerShell linting and best practices validation through [`PSScriptAnalyzerSettings`](https://github.com/PowerShell/PSScriptAnalyzer) which can be configured with a `PSScriptAnalyzerSettings.psd1` file.

```powershell
#./PSScriptAnalyzerSettings.psd1
@{
    Rules = @{
        PSUseCompatibleSyntax = @{
            # This turns the rule on (setting it to false will turn it off)
            Enable         = $true

            # List the targeted versions of PowerShell here
            TargetVersions = @(
                '3.0',
                '5.1',
                '6.2'
            )
        }
    }
}
```

## Resources

- [PSConf Eu: Slides & Code](https://github.com/psconfeu/2019/tree/master/sessions/MarkWarneke)
- [Google: Testing Block](https://testing.googleblog.com/2015/04/just-say-no-to-more-end-to-end-tests.html)
- [Move Fast & Don't Break Things](https://docs.google.com/presentation/d/15gNk21rjer3xo-b1ZqyQVGebOp_aPvHU3YH7YnOMxtE/edit#slide=id.g437663ce1_53_98)

## Remarks

There are open source projects working on creating an Abstract Syntax Tree (AST) from an ARM template, this could be a huge game changer [Twitter: Chris Gardner](https://twitter.com/HalbaradKenafin/status/1158411375481434113?s=20).

The [Azure Resource Manager Schema](https://github.com/Azure/azure-resource-manager-schemas) Files are located on github. A simple way to ensure a JSON file has the correct syntax is validating the JSON against its schema. You can leverage [Get-xAzSchema](https://github.com/MarkWarneke/Az.New/blob/master/xAz.New/Public/Get-Schema.ps1) from the [xAz](https://github.com/MarkWarneke/Az.New) Module to obtain a given Resource Schema by Provider Name and leverage PowerShell Core 6 `Test-Json` to validate.

## Changelog

| Date       | Change                                                     |
| ---------- | ---------------------------------------------------------- |
| 15.08.2019 | Edit Intro, add Remarks, Code Generator and Review Section |

## Table of Contents

- [PowerShell Conference EU](#powershell-conference-eu)
- [Climb the Pyramid](#climb-the-pyramid)
  - [Unit Tests](#unit-tests)
  - [Integration Tests](#integration-tests)
  - [End-To-End Testing](#end-to-end-testing)
  - [Tests across Azure regions](#tests-across-azure-regions)
  - [Acceptance Tests](#acceptance-tests)
  - [Smoke Tests](#smoke-tests)
- [Code generator](#code-generator)
- [Review und Pull-Requests](#review-und-pull-requests)
- [Tests Phases](#tests-phases)
- [Continuous Integration & Continuous Deployment](#continuous-integration--continuous-deployment)
- [Developer View](#developer-view)
  - [VSCode Setup](#vscode-setup)
- [Resources](#resources)
- [Remarks](#remarks)
- [Changelog](#changelog)
- [Table of Contents](#table-of-contents)
