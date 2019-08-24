#azuredeploy.Tests.ps1
param (
    $Path = (Join-Path $PSScriptRoot "azuredeploy.json")
)

Describe "[$Path] should be valid" -Tag Unit {

    # Test for template presence
    $null = Test-Path $Path -ErrorAction Stop

    # Test if arm template content is readable
    $text = Get-Content $Path -Raw -ErrorAction Stop

    # Convert the ARM template to an Object
    try {
        $json = ConvertFrom-Json $text -ErrorAction Stop
    }
    catch {
        # Storing a potential exception in a variable to assert on it later
        $JsonException = $_
    }

    # Assert that we have a valid json and not an exception
    it "should not throw an exception" {
        $JsonException | Should -BeNullOrEmpty
    }

    # Ensure we actually got an object back that is not null or empty
    it "should have content" {
        $json | Should -Not -BeNullOrEmpty
    }

    # Ensure all properties of the Azure Resource Manager schema are implemented
    $TestCases = @(
        @{
            Expected = "parameters"
        },
        @{
            Expected = "variables"
        },
        @{
            Expected = "resources"
        },
        @{
            Expected = "outputs"
        }
    )
    it "should have <Expected>" -TestCases $TestCases {
        param(
            $Expected
        )
        # Get all top level properties of the json object
        $property = $json | Get-Member -MemberType NoteProperty
        $property.Name | Should -Contain $Expected
    }

    <#
        Assert that the parameters are as expected.
        Loop through all parameters:
        - Check if metadata is present as this should be present and a good description about the parameter
    #>
    context "parameters tests" {

        # Get Parameters details of the ARM template, e.g. Name
        $parameters = $json.parameters | Get-Member -MemberType NoteProperty

        foreach ($parameter in $parameters) {

            # For readability
            $ParameterName = $($parameter.Name)

            it "$ParameterName should have metadata" {
                # Access the json and go through all parameters, ensure the metadata property is present
                $json.parameters.$ParameterName.metadata | Should -Not -BeNullOrEmpty
            }
        }
    }

    <#
        Assert that the resources are as expected
        Loop through all resources
        - Check if comments are present
        - Should be arranged by
            1. Comments - Description/Help for the resource
            2. Type - Describes what is provisioned
            3. apiVersion - Describes which properties are needed to be provisioned
            4. Name - Describes the name of the resource provisioned
            5. Properties - Describes the actual properties that are provisioned
    #>
    context "resources tests" {
        foreach ($resource in $json.resources) {

            # For readability
            $type = $resource.type

            it "$type should have comment" {
                $resource.comments | Should -Not -BeNullOrEmpty
            }

            it "$($resource.Type) should follow comment > type > apiVersion > name > properties" {
                # The text implementation should be arranged as following
                "$resource" | Should -BeLike "*comments*type*apiVersion*name*properties*"
            }
        }
    }
}