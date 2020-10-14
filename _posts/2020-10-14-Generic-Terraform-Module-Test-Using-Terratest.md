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
# terraform_module/

README.md     # Documentation and usage explanation, typically generated using https://github.com/terraform-docs/terraform-docs
main.tf       # Collection of Terraform resources, Resources should be split into separate files
variables.tf  # 'Input' Parameter of the Terraform module  
output.tf     # 'Output' Parameter of the Terraform module
test/         # Contents of this blog post
docs/         # Further documentation for the module if needed
```

Notice, that the common `provider.tf` is missing. Learn more about why in [generic test provider.tf](#generic-test).

## Usage of a Terraform module

Once a Terraform module is released, we can leverage the module using the `source` argument.

```hcl
# main.tf

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
  - options are similar to the terraform command line arguments like `plan -input=false -lock=false -var name=t7943 -var-file ./test/test.vars -lock=false`
3. Moves `provider.tf` into the module (`../`)
4. Run `terraform plan` & `terraform apply`
5. Run `terraform destroy`
6. Move `provider.tf` back

### Generic Test

Create a `provider.tf` file that contains the minimum Terraform provider version that should be tested. This file will be moved during the test in order to execute the module.

```hcl
# provider.tf

# Local provider for testing
provider "azurerm" {
  version = "=2.3.0"
  features {}
}
```

The provider is mandatory for initializing the module.
It is used to ensure parameters and features are versioned and accessible through a specific version, while protection from breaking-changes that might impact existing configurations. Most of the time (🤡) providers are back-compatible, we should ensure to test the provider version based on our users requirements.

We want to create reusable, composable and compatible Terraform modules.
Also, we want to ensure that the consumer of our module can provide a specific provider version for their needs.
The purpose of the Terraform module is to make it reusable and composable with different provider versions.

We thus want to make sure we tested the module using a a specific `provider.tf` version, or test with multiple different versions in one go. Inside of the release notes a hint to the tested provider version might be a good addition.

#### Test Values

Create a `test.vars` file that contains all the dynamic variables needed to deploy the Terraform module.
Per module and test, we have to change the values in [test.vars](#test-values) to match the subject under test (SUT).

Using a dedicated file for the test configuration allows us to reuse as much code as possible, while using a reproducible test input.
We can even create multiple `test.vars` that get tested in a loop to check for different configuration inputs. Leveraging this, we can test different variables like regions or sizes in one test run.

```hcl
# test.vars

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

In order to reuse the test, the test will create a unique name based on a random number. 
The `name` variable will then be mapped to the Terraform variables using:

```go
// generic_test.go

expectedName := fmt.Sprintf("t%d", rand.Intn(9999))

// ...

Vars: map[string]interface{}{
  "name": expectedName,
},

// ...
```

Thus, make sure that the name of the Azure resource is mapped to a Terraform variable called `name`.
As most Terraform providers are using `name`, it is a good practice to adapt this convention for modules, too.

{% gist 53fa4645049a16584615c59632a1493c %}

This is a very generic test, that will ensure the Terraform module is plan- and apply-able. In order to validate that properties are deployed as expected a more specific test should be created.
You can leverage go's programming language to attach specific test cases to this generic test if needed.

{: .box-warning}
**Note:** Make sure the Terraform module uses `var.name` as the resource name, make sure `test.vars` contains the test specific variables, `provider.tf` has the correct provider version configured, and all files including `generic_test.go` is in the folder `test`.

The generic test can be reused across Terraform modules, the only requirement is to stick to a convention, e.g. the `name` variable. Havening a generic test is in most cases better than havening none. We can always exchange the generic test with a more sophisticated test case later.

##### Debugging

During development or when a test cases fails you can just comment out `terraform.InitAndApply` to only run the plan for debugging, without applying the Terraform module. This is useful if the test case should not be executed because of a long runtime or for troubleshooting configurations.

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
