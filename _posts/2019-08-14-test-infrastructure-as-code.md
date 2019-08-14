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
time: 6
---

Treat infrastructure as code development like as a software engineering project.
Implementing software development practices into the development of infrastructure.
In this article we are going to look into different test practices and how to apply them to Infrastructure as Code development.

{: .box-note}
**Note** The one fundamental is **Version Control** <br>
Get familiar with these practices first before thinking about implementing tests!

You should embrace [`Behavior Driven Development`](https://en.wikipedia.org/wiki/Behavior-driven_development) to work on your Infrastructure as Code project.
These principals will force you into writing tested code. 
A good starting point when starting with tests for infrastructure as code is the [Test Pyramid](https://martinfowler.com/articles/practical-test-pyramid.html).
Where you want to have many quick and small tests to ensure your code does what is expected.
However, when talking about Infrastructure Development there are slight differences to Software Development.

## PowerShell Conference EU

[Video: Test Infrastructure as Code?](https://www.youtube.com/watch?v=k33Nini-Dc8) [Slides & Code](https://github.com/psconfeu/2019/tree/master/sessions/MarkWarneke)

<div class="video-container">
    <iframe  src="https://www.youtube.com/embed/k33Nini-Dc8" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</div>

## Climb the Pyramid

Using an `Azure Resource Manager Template` (ARM Template) as the subject under test we are asking to test a JSON configuration file. 
I have not yet heard of a Unit Testing framework for configuration files like YAML, HTML or JSON, I am only aware of [linter](https://en.wikipedia.org/wiki/Lint_(software)). 
Having said that:

When following the best practices of Infrastructure as Code by using a [`declarative approach`](http://markwarneke.me/Cloud-Automation-101/Article/01_Cloud_Automation_Theory.html#approach) to provision resources there really is no *unit* or smallest executable unit to test except the configuration file itself, which contains the desired state of the environment.
Hence you should make sure your unit is thoroughly tested using available tools and practices.

### Unit Tests 

I personally refer to an `ARM template unit tests` as a `static code analysis`.
So validating, checking and parsing the configuration file - the ARM template. (There are open source projects working on creating an AST from an ARM template, this could be a huge game changer [Twitter: Chris Gardner](https://twitter.com/HalbaradKenafin/status/1158411375481434113?s=20))

### Integration Tests 

Additionally we found in our project that you can only safely say  an ARM template is valid when you actually deploy it once.
Let the Azure Resource Manager Engine expand, validate and EXECUTE the template with all its necessary dependencies and parameters.
This might be refereed to a System or `Integration Test` and will take some time until you can actually assert on the return, but we found it worthwhile having.

If you have additional `imperative` scripts (e.g. post configuration, custom script extension, DSC) you want to test I would emphasize to unit tests these scripts and Mock any Az native calls.
You don't want to test if the implementation of these scripts (e.g. Get-AzResource) are correct but if your logic of execution is as expected. So assert if your mocks are called and validate your code flow.

![Test Pyramid](/img/test-iac/psconfeu19_test_iac.jpg){: .center-block :}

### End-To-End Testing

We also found that a dummy deployment `End-to-End Testing` help finding out missing requirements and missing dependencies.
Having a `Engineering-Pipeline` e.g. to a standalone subscription is worthwhile having - as you really want to test if your configuration (ARM Template) is valid and stays valid.
An `Engineering Subscription` is a subscription that has no or limited access to any other subscription or on premises and should not reflect any customer or sensitive data.
Also the naming should not indicate the customers name - if this subscription gets compromised an attack should not identify the company or user.

### Tests across Azure regions

Additionally a good test should validate different input parameters.
Having a deployment to *multiple different Azure Regions* can save time when troubleshooting a deployment issue to a new region.
Some Azure Services are only available (or in Preview) in certain Azure Data center.
Keeping this in mind a tests should also considers this.

### Acceptance Tests

Lastly, you want to make sure no deviation or configuration drift is happening.
Using a test method called `Acceptance Test` of `Validation Tests` can save you a lot of time. 
These Tests are written to ensure a requirement is met. You can execute these tests on a given resource and validate if a specified configuration was applied.

### Tests Phases

These Unit and Integration tests could be grouped into the `build phase`, however some resource deployments might take a couple of hours, e.g. VNet Gateways (~25mins) etc.. 
Validation and Acceptance Tests could be group to the `release phase`.

If you want to integration tests these Azure Resources, I would recommend to rely on a release pipeline that is used for testing, this allows to not tests on change to the version control but on a `Preview-Artefact`.
Preview-Artefacts are not yet officially published (from the build phase created) Artefact for demo or testing purposes.

### Continuous Integration & Continuous Deployment

The result of a build phase when successfully should always be some kind of `Artefact`.
As we are not compiling or building a software product we can not rely on any compilers to throw errors on syntactical issues.
Same steps a compiler does could be engineered for IaC, but limited to a configuration file.
Only after an actual deployment and the validation of the requirements on the deployed Azure Resource took place an artifact could be considered build, it is also known as `Continuous Integration`.
Only then the build Artefact, in this context the ARM template, is a valid.

The created artefact is used to release and deploy to the first environment - `Continuous Delivery`, usually a Development (Dev) or Beta environment.
You can use a dedicated Azure subscription or a naming convention inside a resource group.
I would recommend to have at least dedicated subscriptions for different environments.

After the deployment to the first stage is successful you can execute the automated Acceptance Tests and have a gate that notifies Key Users to run `User Acceptance Tests` on the particular 'test' environment.
User Acceptance Tests can be managed and monitored through [Azure DevOps Test Plans](https://azure.microsoft.com/en-us/services/devops/test-plans/).
Only after the approval of a release manager, if all tests result from the key users are green, the next Stage e.g. Pre-Production or Staging should be triggered.
This staging and deployment from one environment to the next is considered `Continuous Deployment`. 
Continuous Deployment should be the end goal of every Infrastructure as Code project.

## Developer View

There are two views one could have on testing we refer to these as the `InnterLoop` and `OuterLoop`.
The *InnerLoop* is the view of the Developer.

The requirements of a Developer are usually: quick feedback, quick execution and a smooth workflow.

Tools like linting integrate easily into the workflow of a developer.
A good practice to have for the InnerLoop are convention and consistent formating.
Consistent code styles and formats prevent errors and increase productivity.
[@RobinManuelT](https://twitter.com/robinmanuelt) create a great blog post describing his setup to [enforce a consistent Coding Style across projects and programming languages](https://pumpingco.de/blog/enforcing-a-consistent-coding-style-across-projects-and-programming-languages/).
Creating Code generators will not only save time but also increase consistency throughout the code base. An example can be found in the [Az.New](https://aka.ms/Az.New) module.

The developer needs to be able to work independently and execute tests locally, so she is able to test the code before checking.
To rely solely on a release pipeline is not recommended, as the pipeline could be overcrowded and the developer might be missing the access to it.


```json
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

easy code styles could be enforced by:

```json
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