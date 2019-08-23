---
layout: post
title: Acceptance Tests for Infrastructure as Code
subtitle:
bigimg: /img/work.jpeg
image: "/img/work.jpeg"
share-img: "/img/work.jpeg"
gh-repo: MarkWarneke/Az.Test
gh-badge: [follow]
tags: [PowerShell, AzureDevOps]
comments: true
time: 8
---

Imaging you are trying to deploy a service to Azure and want to tests whether a given resource implements the specification.
In this article we are going to look into how to validate that a resource deployment has the correct settings applied.

This blog post introduces you to the idea of validation testing or acceptance test for Infrastructure as Code using PowerShell and [Pester](https://github.com/pester/Pester).
If you are not yet familiar with Pester checkout: [Get started with Pester](https://www.powershellmagazine.com/2014/03/12/get-started-with-pester-powershell-unit-testing-framework/) and [Pester Resources](https://github.com/pester/Pester/wiki/Articles-and-other-resources)

The idea of validation testing is to ensure a specification defined by a stakeholder is matched.
Automated validation testing is the concept of writing automated tests that can be parametrized to assert the validity or correctness of a specification.

Specifications could be for instance:

- A naming convention
- Specified locations or limitations to locations
- Mandatory RBAC role assignments 
- Inbound IPs and ports for NSGs on a subnets
- Firewall rules applied to a PaaS service
- Configuration of a database, like RUs 
- or even configuration of an IaaS service like a Service running in a VM

### Example Requirements

An example requirement of the business including a specification could look like this.
We are going to take this example and have a look at a potential implementation of an Acceptance Test.

- Provision an Azure Data Lake Storage Account Generation 2
- Ensure encryption is enforced at rest
- Ensure encryption is enforced in transit
- Allow application teams to define a set of geo replication settings
- Allow applications teams to specific access availability
- Allow a set of dynamically created network access control lists (ACLs) to be processed

## Approach

The idea is to validate, after the deployments, whether the specification is implemented, or not.
We want to ensure that the tests can be executed automatically and on a regular basis's to ensure no divergence to the initial requirement happened and that the specification is still met.

These kind of tests can be very sophisticated.
You could think about writing a test that checks the inner-view of the VM by using e.g. [PowerShell Remoting](https://blogs.technet.microsoft.com/rohit-minni/2017/01/18/remoting-into-azure-arm-virtual-machines-using-powershell/) or using [SSH](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/mac-create-ssh-keys) that asserts a given service is running.
Also, querying an APIs to ensure certain settings are valid or checking a [health signal](https://microservices.io/patterns/observability/health-check-api.html).
The options are limitless and depend on the use case.

In this article we are going to look into how to validate the outer-view of a resource deployment in Azure.
The inner-loop demands a bit more detail and sophistication as direct access over the internet to the resource is often not permitted.

## Why?

Why should we write these Acceptance Tests if they are sophisticated and additional work is needed?
You could argue that the Azure Resource Manager template is the specification.

You are however, probably deploying for a customer, whether its you, your business or an end-users.
Imagine a customer asking you why something stopped working or is different then before.

You have two options:

1. Visit portal.azure.com, identify the resource and check if a setting is applied
2. Write a Script that checks that for you

Your Azure Resource Manager might have the correct specification, however it could have ben changed post deployment.
(E.g. Azure Policy, manual intervention etc.)

Which one is the better option?
It might be fun one time but what if a customer is writing you the same question again and again...?
With _Acceptance Tests_ we are trying to address the problem of post deployment validation and consistency.

> Automated tests scale.

If the infrastructure as code is based on specified, documented requirements you should be able to validate them without manual intervention.
Automated tests scale and reduce human error.

Also, you want to ensure that your initial deployment is meeting the customers requirement.
Non-technical people should evaluate if a specification is met, a human readable form of feedback is therefore necessary.
You should have _"proof"_ your implementation matched the specification.

## Implementation

The implementation is based on a parameterized Pester tests.
Any testing framework should be able to support this kind of tests.
We are going to implement a demonstration using pester, the concept is the same for others testing frameworks.

Your deployment should **always** have _version controlled_ parameter files or a central _configuration management database_.

The parameters or configuration needs to be stored somewhere centrally and the information should be able to be acquired through an API.

### Resource Specific Acceptance Test for Example Azure Data Lake Gen 2 implementation

Lets take an example of validating the deployment of a given ARM template.
In this case we take the requirements from the business to deploy a specified Azure Data Lake Storage Account Generation 2.
Using the requirements describe in the [intro](#example-requirements).

We want to ensure that requirements are implemented as specified.
To ensure the requirements are implemented correctly at development time, have a look at the [Unit Tests](../2019-08-21-static-code-analysis-for-infrastructure-as-code) article.
This describes how to analyze a given ARM template statically and ensure specifications are met in a given configuration file.

#### Example ARM Template

Here is the ARM template we are going to use:

```json
//azuredeploy.json
{
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "resourceName": {
            "type": "string",
            "metadata": {
                "description": "Name of the Data Lake Storage Account"
            }
        },
        "location": {
            "type": "string",
            "defaultValue": "[resourceGroup().location]",
            "metadata": {
                "description": "Azure location for deployment"
            }
        },
        "storageAccountSku": {
            "type": "string",
            "defaultValue": "Standard_ZRS",
            "allowedValues": [
                "Standard_LRS",
                "Standard_GRS",
                "Standard_RAGRS",
                "Standard_ZRS",
                "Standard_GZRS",
                "Standard_RAGZRS"
            ],
            "metadata": {
                "description": "Optional. Storage Account Sku Name."
            }
        },
        "storageAccountAccessTier": {
            "type": "string",
            "defaultValue": "Hot",
            "allowedValues": [
                "Hot",
                "Cool"
            ],
            "metadata": {
                "description": "Optional. Storage Account Access Tier."
            }
        },
        "networkAcls": {
            "type": "string",
            "metadata": {
                "description": "Optional. Networks ACLs Object, this value contains IPs to whitelist and/or Subnet information."
            }
        }
    },
    "variables": {
    },
    "resources": [
        {
            "comments": "Azure Data Lake Gen 2 Storage Account",
            "type": "Microsoft.Storage/storageAccounts",
            "apiVersion": "2019-04-01",
            "name": "[parameters('resourceName')]",
            "sku": {
                "name": "[parameters('storageAccountSku')]"
            },
            "kind": "StorageV2",
            "location": "[parameters('location')]",
            "tags": {},
            "identity": {
                "type": "SystemAssigned"
            },
            "properties": {
                "encryption": {
                    "services": {
                        "blob": {
                            "enabled": true
                        },
                        "file": {
                            "enabled": true
                        }
                    },
                    "keySource": "Microsoft.Storage"
                },
                "isHnsEnabled": true,
                "networkAcls": "[json(parameters('networkAcls'))]",
                "accessTier": "[parameters('storageAccountAccessTier')]",
                "supportsHttpsTrafficOnly": true
            },
            "resources": [
                {
                    "comments": "Deploy advanced thread protection to storage account",
                    "type": "providers/advancedThreatProtectionSettings",
                    "apiVersion": "2017-08-01-preview",
                    "name": "Microsoft.Security/current",
                    "dependsOn": [
                        "[resourceId('Microsoft.Storage/storageAccounts/', parameters('resourceName'))]"
                    ],
                    "properties": {
                        "isEnabled": true
                    }
                }
            ]
        }
    ],
    "outputs": {
        "resourceID": {
            "type": "string",
            "value": "[resourceId('Microsoft.DataLakeStore/accounts', parameters('resourceName'))]"
        },
        "componentName": {
            "type": "string",
            "value": "[parameters('resourceName')]"
        }
    }
}
```

#### Example Implementation

To ensure the specification are applied to the resource after the deployment we are writing a script to validate its properties.

Therefore, we need to first get the resource and its properties. Using the Az module we can leverage a `Get-` command.

The Azure module provide the command `Get-AzResource` to query any resource by `Name`, as well as either a `ResourceGroup` or `ResourceType`.

We can get the deployed resource by using `Get-AzResource -ResourceType 'Microsoft.Storage/storageAccounts'` without providing a ResourceGroupName.
As Storage Accounts are unique by name this will only return one account.
Other resources might support reuse of names and could return multiple resources - this needs to be considered.

In PowerShell a best practice is to enable support for Pipeline usage.
Essentials this means to accept an array of objects that should be passable to the script.

Now, to ensure the specification is met we need to add assertion based on the specification.
These assertions should validate that the properties are set correctly on the deployed Azure Resource.

We are storing the file with a `*.spec.ps1` file type.
`Spec` as a means to describing that this is file contains a specification that is going to be validated.

> If you wish to create script files manually with different conventions, that's fine, but all Pester test scripts must end with `.Tests.ps1` in order for Invoke‐Pester to run them. See [Creating a Pester Test](https://github.com/pester/Pester/wiki/Pester#creating-a-pester-test)

As Pester will pick up every `*.Tests.ps1` we want the specification to not be triggered, rather our loop through all resources, subjects under tests, should invoke our specification.

Hence we are going to create an additonal file with the file ending  `*.Tests.ps1`, which will invoke all `*.spec.ps1` with a given name (and resource group name).
This can be merged and adjusted, if the flexibility is not needed, and as this approach is very opinionated.
Using this approach, however, will enable you to extend your specifications dynamically by adding more and more spec `*.spec.ps1` files.

```powershell
# adls.acceptance.spec.ps1
param (
    # Name of the resource
    [Parameter(Mandatory)]
    [string]
    $Name,

    # Name of the resource group
    [Parameter()]
    [string]
    $ResourceGroupName
)

# Accepts an empty ResourceGroup and will query all resources by Type,
# If ResourceGroup is provided we can query by ResourceGroupName
if (!$ResourceGroup) {
    $ResourceType = "Microsoft.Storage/storageAccounts"
    $resource = Get-AzResource -Name $Name -ResourceType $ResourceType

    # As we have a native command to get the actual resource we will query for the Storage Accounts
    # The object returned will have all configured properties
    $adls = Get-AzStorageAccount -Name $resource.Name -ResourceGroupName $resource.ResourceGroupName
}
else {
    $resource = Get-AzResource -Name $Name -ResourceGroupName $ResourceGroupName
    $adls = Get-AzStorageAccount -Name $resource.Name -ResourceGroupName $resource.ResourceGroupName
}

Describe "$Name Data Lake Storage Account Generation 2" {
    
    <# Mandatory requirement of ADLS Gen 2 are:
     - Resource Type is Microsoft.Storage/storageAccounts, as we know we are looking for this it is obsolete to check
     - Kind is StorageV2
     - Hierarchical namespace is enabled
     https://docs.microsoft.com/en-us/azure/storage/blobs/data-lake-storage-quickstart-create-account?toc=%2fazure%2fstorage%2fblobs%2ftoc.json
    #>
    it "should be of kind StorageV2" {
        $adls.Kind | Should -Be "StorageV2"
    }

    it "should have Hierarchical Namespace Enabled" {
        $adls.EnableHierarchicalNamespace | Should -Be $true
    }

    <#
      Optional validation tests:
       - Ensure encryption is as specified
       - Secure Transfer by enforcing HTTPS
    #>

    it "should enforce https traffic" {
        $adls.EnableHttpsTrafficOnly | Should -Be $true
    }

    it "should have encryption enabled" {
        $adls.Encryption.Services.Blob.Enabled | Should -Be $true
        $adls.Encryption.Services.File.Enabled | Should -Be $true
    }

    it "should have network rule set  default action Deny" {
        $adls.NetworkRuleSet.DefaultAction | Should -Be "Deny"
    }
    
    <#
      Check for network firewall:
        - Enable Azure Services and Logs 
        - Whitelist certain IP Addresses
        - Enable access to Subnets
    #>

    it "should have network rule set bypass Logging, Metrics, AzureServices" {
        $adls.NetworkRuleSet.Bypass | Should -Be "Logging, Metrics, AzureServices"
    }

    it "should have more then 1 network access control lists ip rules" {
        $adls.NetworkRuleSet.IpRules.Count | Should -BeGreaterOrEqual 1
    }

    it "should have network access control lists ip rules Action only allow " {
        $adls.NetworkRuleSet.IpRules.Action | Select-Object -Unique | Should -Be "Allow"
    }

    it "should have more then 1 network access control lists subnet" {
        $adls.NetworkRuleSet.VirtualNetworkRules.Count  | Should -BeGreaterThan 1
    }

    it "should have network access control lists subnet Action only allow " {
        $adls.NetworkRuleSet.VirtualNetworkRules.Action | Select-Object -Unique | Should -Be "Allow"
    }
}
```

### One step further

Taking this approach a bit further and ensuring ALL deployments are matching the requirements we can adjust the Pester test.
We can get all config files by using `Get-ChildItem` on a `Path` the contain the config files to the deployment.
Or any other query to get the configuration or really just the resources name, resource group name or type.

After the config is loaded we iterate through the list and invoke the same specification.

```powershell
# adls.acceptance.tests.ps1
param (
    $Path = $PSScriptRoot
)

$ParameterPath = Get-ChildItem -Path "$Path" -include "azuredeploy.parameter.json" -Recurse


Foreach ($Path in $ParameterPath) {

    # Convert the parameter file to a usable PowerShell object
    $null = Test-Path $Path -ErrorAction Stop
    $text = Get-Content $Path -Raw -ErrorAction Stop
    $json = ConvertFrom-Json $text -ErrorAction Stop

    # Invoke or acceptance tests specification
   . adls.acceptance.spec.ps1 -Name $json.ResourceName -ResourceGroup $json.ResourceGroupName
}
```

We can even go further and remove the tests for certain resources and just query for all resources using `Get-AzResource -ResourceType $ResourceType` to ensure all Resources confirm to the specification.

## Wrap Up

We ensured a specification is correctly deployed by querying Azure for a particular resource and asserting configurations are deployed as expected.
The test results are displayed in a human readable form so the specification can be matched against the tests results.
Furthermore the results are human readable and can be share with non-technical people easily.

## Table of Content
- [Approach](#approach)
- [Why?](#why)
- [Implementation](#implementation)
  - [Resource Specific Acceptance Test for Example Azure Data Lake Gen 2 implementation](#resource-specific-acceptance-test-for-example-azure-data-lake-gen-2-implementation)
    - [Example ARM Template](#example-arm-template)
    - [Example Implementation](#example-implementation)
  - [One step further](#one-step-further)
- [Wrap Up](#wrap-up)
- [Table of Content](#table-of-content)