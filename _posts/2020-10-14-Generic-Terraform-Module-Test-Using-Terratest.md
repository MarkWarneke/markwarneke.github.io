---
layout: post
title: Testing reusable Terraform Modules
subtitle: leveraging Gruntworks Terratest
bigimg:
  - "/img/draft.jpeg": "https://unsplash.com/photos/wE37SqLAO9M"
image: "/img/draft.jpeg"
share-img: "/img/draft.jpeg"
tags: [Draft, Azure, Terraform]
comments: true
time: 2
---

Use Terratest to execute your real IaC tools like Terraform to deploy real infrastructure into Azure.
In this blog post we are going to look into how we leverage Terratest to have a generic test for Terraform modules.
A Terraform module is a collection of Terraform resources that serves a specific purpose.
A module can even be a composition of multiple child modules.
In order to create a reusable Terraform module we are first going to look into a typical Terraform module structure.

# What is a Terraform module?

While leveraging open-source modules from the [Terraform registry](https://registry.terraform.io/) is a good practice and a quick way to get started. In enterprise organization I typically see the need for a _private_ registry. So that enterprise organizations can create a common place for reusable Terraform modules.

The easiest way to achieve this, is to provide a Github or Azure DevOps release artifact.
Using tags (and releases) we can version our release of the module easily. The [Azure Cloud Adoption Framework landing zones for Terraform](https://github.com/Azure/caf-terraform-landingzones)uses a similar approach for versioning modules e.g. [Deploys Azure Monitor Log Analytics](https://github.com/aztfmod/terraform-azurerm-caf-log-analytics/tree/v2.3.0).
I expect that the CI/CD system has access to the source-control system, fetching the releases should therefore not be a problem.
Modules should be organized in separate repositories inside of the source control system in order to achieve a stable release strategy based on tags or releases. The Terraform `source` argument can be used to reference a git endpoint, see [usage of a Terraform module](#usage-of-a-terraform-module).

Terraform files are typically grouped into modules. A basic module structure looks like this:

```tf
README.md
main.tf
values.tf
output.tf
test/
docs/
```

Notice, that `provider.tf` needed for initializing the module is missing. This is on purpose to make the module reusable for different provider version. We are going to cover how to use and test a module using a generic `provider.tf` later.

## Usage of a Terraform module

Once a Terraform module is released, we can leverage the module using the `source` argument.

module "log_analytics" {
  source = "git::https://github.com/aztfmod/terraform-azurerm-caf-log-analytics/tree/v2.3.0"

    name                              = var.name
    solution_plan_map                 = var.solutions
    resource_group_name               = var.rg
    prefix                            = var.prefix
    location                          = var.location
    tags                              = var.tags
}

# Testing Terraform Modules

We can use [terratest](https://terratest.gruntwork.io/docs/) to run integration tests with Terraform.
Inside of the Terraform module create a folder named `test`, and add the files `test.vars`, `provider.tf`, and `generic_test.go`.

To get up and running you need to specify a test environment. 
Using [environment variables in Terraform](https://www.terraform.io/docs/commands/environment-variables.html) allows to specify the the necessary [backend configuration](https://www.terraform.io/docs/backends/index.html). 

A good practice is to run tests in a dedicated test resource group, e.g. `resource_group_name = "playground-test-resources"`.
The test resources should also be tagged as such, using the terraform tags argument: `tags = { test = true }`, see [Test Values](#test-values). Tagging the resources and using a dedicated test resource group is recommended for identification and cleanup purposes.

Per test we have to change the values in [test.vars](#test-values) to match the test environment.

```bash
# Source necessary TF environment variables
docker run --env-file .env -it -v ${PWD}:"/source" -w "/source" aztfmod/rover

cd $SUT

cd test

# Setup go module
go mod init 'github.com/aztfmod'

# Make sure to set an appropriate timeout
go test -timeout 30m
```

### Test Process

- Creates a random name that is used for testing
- Create terraform options, e.g. references a static `test.vars`
  - options are similar to the terraform command line arguments, see:
  - `plan -input=false -lock=false -var name=t7943 -var-file ./test/test.vars -lock=false`
- Moves `provider.tf` into the module (`../`)
- Runs terraform plan & terraform apply
- Moves `provider.tf` back


### Generic Test

Create a `provider.tf` file that contains the minimum Terraform provider version that should be tested. This file will be moved during test in order to execute the module.

```hcl
# Local provider for testing
provider "azurerm" {
  version = "=2.3.0"
  features {}
}
```

#### Test Values

Create a `test.vars` file that contains all the dynamic variables needed to deploy the Terraform module.

```hcl
resource_group_name                    = "playground-test-resources"
location                               = "WestEurope"
subnet_id                              = "/subscriptions/$SUBSCRIPTION_NAME/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.Network/virtualNetworks/$VNET_NAME/subnets/$SUBNET_NAME"
tags = {
  test = true
}
```

#### Test File

Create a terratest test file, e.g. `generic_test.go` and paste the following content.
The test will assume that it is located in a  `test` folder, and the module under test is located in the parent.
The file expects a `test.vars` and `provider.tf` to be present in the same directory.

```go
package test
import (
	"fmt"
	"log"
	"math/rand"
	"os"
	"strings"
	"testing"
	"github.com/gruntwork-io/terratest/modules/terraform"
)
/**
	Creates a random name that is used for testing
	Create terraform options (similar to the terraform command line arguments), references a static test.vars, that contains the configuration for the test
	Moves provider.tf into the module (../)
	Runs terraform plan & terraform apply
	Moves provider.tf back
**/
func moveFile(oldLocation, newLocation string) {
	err := os.Rename(oldLocation, newLocation)
	if err != nil {
		log.Panic(err)
	}
}
func TestTerraformVmWithGpuModule(t *testing.T) {
	terraformDir := "../"
	originalLocation := "provider.tf"
	underTestLocation := strings.Join([]string{terraformDir, originalLocation}, "")
	expectedName := fmt.Sprintf("t%d", rand.Intn(9999))
	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: terraformDir,
		VarFiles: []string{"./test/test.vars"},
		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"name": expectedName,
		},
		// Disable colors in Terraform commands so its easier to parse stdout/stderr
		NoColor: false,
	}
	// Remove provider at the end to test folder
	defer moveFile(underTestLocation, originalLocation)
	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)
	// Move provider.tf to the terraformDir
	moveFile(originalLocation, underTestLocation)
	// For debugging
	terraform.InitAndPlan(t, terraformOptions)
	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)
}
```

##### Debugging

comment out `terraform.InitAndApply` to only run the plan for debugging.

```go
// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
terraform.InitAndApply(t, terraformOptions)
```