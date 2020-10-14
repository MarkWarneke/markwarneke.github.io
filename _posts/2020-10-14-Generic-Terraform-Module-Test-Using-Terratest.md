---
layout: post
title: Testing reusable Terraform Modules
subtitle: leveraging Gruntworks Terratest
bigimg:
  - "/img/RNjbcPAsol8.jpg": "https://unsplash.com/photos/RNjbcPAsol8"
image: "/img/RNjbcPAsol8.jpg"
share-img: "/img/RNjbcPAsol8.jpg"
tags: [Azure]
comments: true
time: 5
---

How to use Terratest to test Infrastructure as Code Terraform modules on Azure.
A good practice is to use the Terraform module as a collection of Terraform resources that serves a specific purpose.
In this blog post, we are going to look into how we can leverage a generic Terratest for all Azure-based Terraform modules.

A module can even be a composition of multiple child modules.
To create a reusable Terraform module, we are first going to look into a typical Terraform module structure.

# What is a Terraform module?

While leveraging open-source modules from the [Terraform registry](https://registry.terraform.io/) is a good practice and a quick way to get started.
However, enterprise organizations typically require a _private_ registry. The private registry should ensure full control and consistency across the source code. The private registry is a good practice so that enterprise organizations can create a common place for reusable Terraform modules, that can be shared across the organization.

The easiest way to achieve this is to provide a Github or Azure DevOps release artifact.
Using tags (and releases) we can version our release of the module easily. The [Azure Cloud Adoption Framework landing zones for Terraform](https://github.com/Azure/caf-terraform-landingzones) uses a similar approach for versioning modules e.g. [CAF: Azure Monitor Log Analytics](https://github.com/aztfmod/terraform-azurerm-caf-log-analytics/tree/v2.3.0).
I expect that the CI/CD system has access to the source-control system, fetching the releases should therefore not be a problem.

Modules should be organized in separate dedicated repositories inside of the source control system.
A dedicate repository ensures a good release strategy.
Based on releases or tags that contain changelog information a module can safely be published.
The Terraform `source` argument can then be used to reference a specific git endpoint, see [usage of a Terraform module](#usage-of-a-terraform-module), e.g. a certain release version of a module or even specific commits.

Terraform files are typically grouped into modules. A basic module structure looks like this:

```bash
README.md     # Documentation and usage explanation, typically generated using https://github.com/terraform-docs/terraform-docs
main.tf       # Collection of Terraform resources, Resources should be split into separate files
variables.tf  # 'Input' Parameter of the Terraform module  
output.tf     # 'Output' Parameter of the Terraform module
test/         # Contents of this blog post
docs/         # Further documentation for the module if needed
```

Notice, that the common `provider.tf` is missing. The provider is needed for initializing the module. However, the purpose of the module is to make it reusable and composable with different provider versions. We are going to cover how to use and test a module using a generic `provider.tf` later.

## Usage of a Terraform module

Once a Terraform module is released, we can leverage the module using the `source` argument.

```hcl
module "log_analytics" {
  source = "git::https://github.com/aztfmod/terraform-azurerm-caf-log-analytics/tree/v2.3.0"

    name                              = var.name
    solution_plan_map                 = var.solutions
    resource_group_name               = var.rg
    prefix                            = var.prefix
    location                          = var.location
    tags                              = var.tags
}
```

# Testing Terraform Modules

We can use [Terratest](https://terratest.gruntwork.io/docs/) to run integration tests with Terraform.
Inside of the repository for the Terraform module create a folder named `test`; add the following files:

- `test.vars`,
- `provider.tf`, and
- `generic_test.go`.

To get up and running you need to specify the backend test environment.
Using [environment variables in Terraform](https://www.terraform.io/docs/commands/environment-variables.html) allows us to specify the the necessary [backend configuration](https://www.terraform.io/docs/backends/index.html) in an `.env` file. This is also very handy for testing across multiple backends and staging environments.

A good practice is to run tests in a dedicated test resource group, e.g. `resource_group_name = "playground-test-resources"`.
The test resources should also be tagged as such, using the terraform tags argument: `tags = { test = true }`, see [Test Values](#test-values). 

Tagging the resources and using a dedicated test resource group is recommended for identification and cleanup purposes. When a test fails or the pipeline crashes the provisioned resources can easily be found and removed.

### Test Process

1. Creates a random name that is used for testing
2. Create terraform options, e.g. references a static `test.vars`
  - options are similar to the terraform command line arguments, see:
  - `plan -input=false -lock=false -var name=t7943 -var-file ./test/test.vars -lock=false`
3. Moves `provider.tf` into the module (`../`)
4. Run `terraform plan` & `terraform apply`
5. Moves `provider.tf` back

### Generic Test

Create a `provider.tf` file that contains the minimum Terraform provider version that should be tested. This file will be moved during the test in order to execute the module.

```hcl
# Local provider for testing
provider "azurerm" {
  version = "=2.3.0"
  features {}
}
```

#### Test Values

Create a `test.vars` file that contains all the dynamic variables needed to deploy the Terraform module.
Per module and test, we have to change the values in [test.vars](#test-values) to match the subject under test (SUT).

Using a dedicated file for the test configuration allows us to reuse as much code as possible while having a reproducible test input present.
We can even create multiple `test.vars` that get tested in a loop to check for different configuration inputs. Leveraging this, we can test different variables like regions or sizes in one test run.

```hcl
resource_group_name = "playground-test-resources"
location            = "WestEurope"

tags = {
  test = true
}
```

#### Test File

Create a Terratest test file, e.g. `generic_test.go` and paste the following content.
The test will assume that it is located in a  `test` folder, and the SUT is located in the parent.

The file expects a `test.vars` and `provider.tf` to be present in the same directory.

{% gist 53fa4645049a16584615c59632a1493c %}

##### Debugging

comment out `terraform.InitAndApply` to only run the plan for debugging.

```go
// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
terraform.InitAndApply(t, terraformOptions)
```

##### gitignore

```txt
.terraform
terraform.tfstate
terraform.tfstate.backup
crash.log
go.sum
go.mod
```
