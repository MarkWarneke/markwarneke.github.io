---
layout: post
title: Acceptence Tests for Infrastructure as Code
subtitle: 
bigimg: /img/work.jpg
gh-repo: MarkWarneke/Az.Test
gh-badge: [star, follow]
tags: [test, powershell, arm]
comments: true
published: false
---

Validating that a deployment has the correct settings applied.
Imaging you are trying to deploy a service to Azure and specifying certain requirements that the resource should meet.
After you deploy, how are you testing that your deployment meet the requirements?

This blog post will introduce you to the concept of validation testing or automated acceptance test for Infrastructure as Code using PowerShell and Pester the testing framework.
The idea of validation testing is to write reusable parameterized tests that matches a specification defined by the stakeholder.
Specifications could be:

- Check Naming Convention
- Check allowed Locations
- Check applied RBAC rules
- Check the inbound ports of a subnets NSGs
- Check applied Firewall rules
- Check configuration of a database like RUs

The idea is to validate right after the deployments if the requirements are met, and to ensure that after a while the tests can be executed frequently to ensure no divergence to the initial state is happening or that the requirements are still met after changes have been applied.

These kind of tests can be very sophisticated, you could imagine writing some automated test even for the inner-view of the VM by using [PowerShell Remoting](https://blogs.technet.microsoft.com/rohit-minni/2017/01/18/remoting-into-azure-arm-virtual-machines-using-powershell/) or using [SSH](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/mac-create-ssh-keys) to check the state of Virtual Machines.
Also querying REST APIs to ensure certain settings are valid or checking a [health check](https://microservices.io/patterns/observability/health-check-api.html) on a web api.
The options are limitless and depend on the use case. 

# Why? Write Acceptence Tests

> Automated tests, when written carefully and reusable, scale.

Imaging having a sophisticated CI/CD pipeline that runs every day a couple of times and deploy frequent new Azure Resources while redeploying existing Resources idempotent.
Or you don't have a sophisticated CI/CD and deploy Azure Resources within your development team to Azure.
A customer is asking you why the connection to your Cosmos DB is not running.

You have two options:
1. Vist portal.azure.com and identify the resource and check if a Firewall rules go applied that shouldn't be there
2. Write a Script that checks that for you

Which one is the better option if that customer is writing you the same question again two days later?
Having Acceptence Tests is trying to address these kind of problems.
If you infrastructure as code is based on specific requirements you should be able to validate them again without your manual intervention.

# Implementation

The implementation is based on simple Pester tests that are parameterized. You can use any testing framework as long as it allows parameterization.
Your deployment should always have version controlled parameters or a configuration management database that stores this information and can be queried by automation code.

Lets take the use case of the Cosmos DB and with a config file that looks like this:

```json
{
    "Environment": "S",
    "ResourceGroupName": "TT-PSConfEu",
    "Location": "westeurope",
    "ResourceName": "tt-markpsconfcosmosdb",
    "Descriptor": "testdescriptor",
    "ResourceNameTest": "t-testdescriptor"
}

The requirement of the business is:
- Ensure the ComosDB is only accessible from a list of IP addresses (insert list of IPs) and is NOT accessible from the internet otherwise.

So inside of the Azure Resource Manager Template we specify a couple of `ipRangeFilter`. See [Configure an IP firewall](https://docs.microsoft.com/en-us/azure/cosmos-db/how-to-configure-firewall#configure-ip-firewall-arm).

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

Now to ensure the IP Ranges are applied to the resource we are going to write a validation script with pester or acceptance tests.


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
