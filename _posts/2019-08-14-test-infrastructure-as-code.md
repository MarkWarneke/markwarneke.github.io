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

Treat infrastructure as code as a Software development project. 
Implementing software engineering practices into the development of infrastructure.
In this article we are going to look into the different Test practices of Infrastructure as Code.

{: .box-note}
**Note** The one fundamental thing is **Version Control** <br>
Get familiar with these practices first before thinking about implementing Tests!

You should embrace [`Behavior Driven Development`](https://en.wikipedia.org/wiki/Behavior-driven_development) to work on your infrastructure as code project.
These principals will force you into writing tested code. A good starting point when looking at Test for infrastructure as code is the the called [Test Pyramid](https://martinfowler.com/articles/practical-test-pyramid.html).
Where you want to have many quick and small tests to ensure your code does what is expected.
However, when talking about Infrastructure Development there are slight differences to Software Development.

## PowerShell Conference EU

[Test infrastructure as code?](https://www.youtube.com/watch?v=k33Nini-Dc8)

<div class="video-container">
    <iframe  src="https://www.youtube.com/embed/k33Nini-Dc8" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</div>

## Climb the Pyramid

If you are asking about an Azure Resource Manager template as the subject under test we are talking about a configuration file. I have not heard about a Unit Testing framework for e.g. YAML, HTML or JSON. Having said that:

When going the [`declarative approach`](http://markwarneke.me/Cloud-Automation-101/Article/01_Cloud_Automation_Theory.html#approach) there really is no unit except the configuration file.
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
 
The result of a build phase when successfully should always be some kind of Artefact.
The Artefact in this context is a valid ARM template itself.
Only if unit and integration test are successful an artefact should be created, this is considered Continuous Integration.

This artefact is then used to release and deploy to the first environment - Continuous Delivery, usually a Development (Dev) or Beta environment.
You can use a dedicated Azure subscription or a naming convention inside a resource group.
I would recommend to have at least dedicated subscriptions for different environments.

After the deployment to the first stage is successful you can execute the automated Acceptance Tests and have a gate that notifies Key Users to run `User Acceptance Tests` on the particular 'test' environment. 
Only after the approval of a release manager that go the tests result from the key users the next Stage e.g. Pre-Production or Staging should be triggered, using the same artefact. This is considered Continious Deployment and should be the end goal of every infrastructure as code project.

## Developer View

There are two views one could have on testing we refer to these as the `InnterLoop` and `OuterLoop`.
The Inner-Loop is the view of the Developer. 
The requirements of a Developer are usually quick feedback and a smooth workflow when working on code.
Testing tools like linting e.g. through .vscode/extensions/ json lint.
These linters usually don't exist natively and are just a static analysis of style and form. 
A good practice to have in the inner loop is rely on convention and default formating - you could use the .vscode/settings (e.g. trim whitespace, new line, brackets, tabs).
Consistent code styles and formats prevent errors and increase productivity.
Creating Code generators will not only save time but also increase consistency throughout the code base.
You can leverage tools like Plaster or Az.New.

The developer also needs to be able to execution tests locally, so relying solely on a release pipeline won't help if the developer is missing the access to it.

## Resources

- [PSConf Eu: Slides & Code](https://github.com/psconfeu/2019/tree/master/sessions/MarkWarneke)
- [Google: Testing Block](https://testing.googleblog.com/2015/04/just-say-no-to-more-end-to-end-tests.html)
- [Move Fast & Don't Break Things](https://docs.google.com/presentation/d/15gNk21rjer3xo-b1ZqyQVGebOp_aPvHU3YH7YnOMxtE/edit#slide=id.g437663ce1_53_98)