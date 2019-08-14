---
layout: post
title: DRAFT Acceptance Tests for Infrastructure as Code
subtitle:
bigimg: /img/work.jpg
image: "/img/work.jpg"
gh-repo: MarkWarneke/Az.Test
gh-badge: [star, follow]
tags: [Test, PowerShell, AzureDevOps]
comments: true
time: 8
---

Validating that a deployment has the correct settings applied.
Imaging you are trying to deploy a service to Azure and specifying certain requirements that the resource should meet.
After you deploy, how are you ensuring that your deployment met the requirements and is still matching them?

# Draft 2019-08-08

This blog post introduces you to the idea of validation testing or acceptance test for Infrastructure as Code using PowerShell and [Pester](https://github.com/pester/Pester) the testing framework. 
If you are not yet familiar with Pester go checkout: [Get started with Pester](https://www.powershellmagazine.com/2014/03/12/get-started-with-pester-powershell-unit-testing-framework/) and [Pester Resources](https://github.com/pester/Pester/wiki/Articles-and-other-resources)
The idea of validation testing is to ensure a specification defined by the stakeholder is matched. 
Automated validation testing is the concept of writing automated tests that can be parametrized to assert the validity or correctness of a specification.

Specifications could be:

- A Naming Convention
- Allowed Locations
- RBAC rules
- Inbound ports of NSGs on a subnets 
- Applied Firewall rules on a PaaS service
- Configuration of a database like RUs or configuration of a IaaS service like a VM

An example requirement of the business including a specification could look like

- As a User I want to be able deploy and connect to Azure Cosmos DB
- Ensure the ComosDB is only accessible from a list of IP addresses __(insert list of IPs)__ and is NOT accessible from the internet otherwise.

The idea is to validate right after the deployments if the requirements are met, and to ensure that after a while the tests can be executed frequently to ensure no divergence to the initial state is happening and that the requirements specification are still met after changes have been applied manually or automated.

These kind of tests can be very sophisticated, you could imagine writing some automated test even for the inner-view of the VM by using [PowerShell Remoting](https://blogs.technet.microsoft.com/rohit-minni/2017/01/18/remoting-into-azure-arm-virtual-machines-using-powershell/) or using [SSH](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/mac-create-ssh-keys) to check the state of Virtual Machines.
Also querying REST APIs to ensure certain settings are valid or checking a [health check](https://microservices.io/patterns/observability/health-check-api.html) on a web api.
The options are limitless and depend on the use case. 

## Why?

Why should we write these Acceptance Tests if they are sophisticated and additional work is needed? 
You could say that inside of the Azure Resource Manager template everything is specified and you met your requirement?

> Automated tests, when written carefully and reusable, scale.

Imaging having a sophisticated CI/CD pipeline that runs every day a couple of times and deploy frequent new Azure Resources while redeploying existing Resources idempotent. 
Best case scenario you are in control of what you deploy.
Or you don't have a sophisticated CI/CD and deploy Azure Resources within your development team to Azure.

You are however, probably deploying for a customer, whether its you, your business or end users.
Imagine a customer asking you why the connection to the deployed Cosmos DB is not running.

You have two options:

1. Visit portal.azure.com and identify the resource and check if a firewall rules went wild and is applied even thought it shouldn't be there
2. Write a Script that checks that for you

Which one is the better option if that customer is writing you the same question again two days later?
With *Acceptance Tests* we are trying to address the problem of validation and consistency.
If you infrastructure as code is based on specific requirements you should be able to validate them again without your manual intervention.
Also, you want to ensure that your initial deployment is meeting the customers requirement. 
You should have "proof" your implementation matched the specification.

## Implementation

The implementation is based on parameterized Pester tests.
You really can use any testing framework pester the concept is the same.
Your deployment should always have version controlled parameters or a central configuration management database that stores information and can be queried by automation code.

Lets take the use case of the Cosmos DB further. Having a configuration file that looks like this:

FIXME: Use .parameter.json

```json
{
    "Environment": "S",
    "ResourceGroupName": "TT-PSConfEu",
    "Location": "westeurope",
    "ResourceName": "tt-markpsconfcosmosdb",
    "Descriptor": "testdescriptor",
    "ResourceNameTest": "t-testdescriptor"
}
```

Inside of the Azure Resource Manager Template we implement the specification by using the `ipRangeFilter` property. See [Configure an IP firewall](https://docs.microsoft.com/en-us/azure/cosmos-db/how-to-configure-firewall#configure-ip-firewall-arm).

TODO: Create real ARM template example to repro

```json
{
  "comments": "Default CosmosDB deployment using defined IP Range Filter for restricting access",
  "type": "Microsoft.DocumentDB/databaseAccounts",
  "apiVersion": "2016-03-31",
  "name": "[variables('accountName')]",
  "location": "[parameters('location')]",
  "kind": "GlobalDocumentDB",
  "properties": {
    "consistencyPolicy": "[variables('consistencyPolicy')[parameters('defaultConsistencyLevel')]]",
    "locations": "[variables('locations')]",
    "databaseAccountOfferType": "Standard",
    "enableAutomaticFailover": "[parameters('automaticFailover')]",
    "enableMultipleWriteLocations": "[parameters('multipleWriteLocations')]",
    "ipRangeFilter":"[parameters('defaultIpRangeFilter')]]"
  }
}
```

To ensure the specification of IP Ranges are applied to the resource we are writing a validation script.
First, we need to get the resource which is in Azure by using a `Get-` command.
Azure ComosDB doesn't provide a native command so we are just getting the Resource by using `Get-AzResource -ResourceType 'Microsoft.DocumentDB/databaseAccounts'`.
This will return a list of resources of type `DocumentDB/databaseAccounts`. 
Now to ensure the specification is met we need to add an assertion to validate the settings are set correctly on the obtained Azure Resoruce.

TODO: add to az.new to repro

```powershell
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification = "Variables are used inside Pester blocks.")]
param(
    [string] $Name,
    [string] $ResourceGroup
)

# Specify the ip range filter requirement, might be a config or some other location.
$IpRangeFilterRequirement = @("183.240.196.255", "104.42.195.92","40.76.54.131","52.176.6.30","52.169.50.45","52.187.184.26")

Describe "Validate CosmosDB Deployment" -Tag Validate {
    Context "CosmosDb Secure Deployment" {

        # Query Azure for the CosmosDB that is specified in the config.json
        $resources = Get-AzResource -ResourceType 'Microsoft.DocumentDB/databaseAccounts' -Name $Name -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
        
        # Describe the requirement to the fullest
        it "<resource.Name> should have ip range filter" -TestCase $resources {
            param(
                $resource
            )
             $resource.Properties.ipRangeFilter | Should -Contain $IpRangeFilterRequirement
        }
    }
}
```

### One step further

Taking this approach a bit further and ensuring ALL Cosmos DB deployments are matching the requirements we can adjust the Pester test.
We can get all config files that are stored on the machine by using Get-ChildItem on a Path containing the config files to the CosmosDBs deployed. Or any other query to get the configuration.
After the config is loaded we iterate through the list and invoke the same assertion on the resource as written above.

```powershell
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification = "Variables are used inside Pester blocks.")]
param(
    [string[]]$TestValueFiles
)

if ($PSBoundParameters.Keys -notcontains 'TestValueFiles') {
    $TestValueFiles = (Get-ChildItem -Path (Join-Path $ModuleBase "Test") -Include "config.*.json" -Recurse).FullName
}

Foreach ($TestValueFile in $TestValueFiles) {

    $Env:TestValueFile = $TestValueFile
    $TestValues = Get-Content $TestValueFile | ConvertFrom-Json
    
    
    Describe "Validate CosmosDB Deployment" -Tag Validate {
        Context "CosmosDb Secure Deployment" {

            # Query Azure for the CosmosDB that is specified in the config.json
             $resources = Get-AzResource -ResourceType 'Microsoft.DocumentDB/databaseAccounts' -ResourceGroupName $TestValues.ResourceGroupName -ErrorAction SilentlyContinue
            
            # Describe the requirement to the fullest
            it "<resource.Name> should have ip range filter" -TestCase $resources {
                param(
                    $resource
                )
                $resource.Properties.ipRangeFilter | Should -Contain $IpRangeFilterRequirement
            }
        }
    }
}
```

We can even go further and remove the tests for certain resources and just query for all Cosmos DB using `Get-AzResource -ResourceType 'Microsoft.DocumentDB/databaseAccounts'` to ensure all CosmosDB we have access to match the requirements.
