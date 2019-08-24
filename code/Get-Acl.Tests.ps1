$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"


Describe "Get-Acl" {

    Context "No Paramater" {

        $ACL = Get-Acl

        It "Should be valid json" {
            {
                $json = $ACL | ConvertFrom-Json
                $json | Format-List * | Out-String | Write-Host
            } | Should -Not -Throw
        }

        $TestCases = @{ property = "bypass" } , @{ property = "virtualNetworkRules" }, @{ property = "ipRules" }, @{ property = "defaultAction" }
        it "should have <Property>" -TestCases $TestCases {
            param(
                $Property
            )
            $json = $ACL | ConvertFrom-Json
            $properties = $json | Get-Member -MemberType NoteProperty
            $properties.Name | Should -Contain $Property
        }

        It "Should have bypass set to Logging,Metrics,AzureServices" {
            $json = $ACL | ConvertFrom-Json
            $json.bypass | Should -Be "Logging,Metrics,AzureServices"
        }

        It "Should have default action set to Deny" {
            $json = $ACL | ConvertFrom-Json
            $json.defaultAction | Should -Be "Deny"
        }
    }


    Context "simple valid paramaters" {

        $IpAddresses = "192.168.0.1", "255.255.255.255", "0.0.0.0"


        $Subnets = "/subscriptions/11111-1111-1111-1111-11111/resourceGroups/my-resource-group/providers/Microsoft.Network/virtualNetworks/my-vnet/subnets/my-subnet1", "/subscriptions/11111-1111-1111-1111-11111/resourceGroups/my-resource-group/providers/Microsoft.Network/virtualNetworks/my-vnet/subnets/my-subnet2"

        $ACL = Get-Acl -IpAddresses $IpAddresses -Subnets $Subnets

        $TestCases = @{
            IpAddresses = $IpAddresses
        }
        It "Should have set ipRule to value <IpAddresses> and action to allow" -TestCases $TestCases {
            param(
                $IpAddresses
            )

            $json = $ACL | ConvertFrom-Json

            foreach ($rule in $json.ipRules) {
                $rule.action | Should -Be "Allow"
                $rule.value | Should -BeIn $IpAddresses
            }
        }


        $TestCases = @{
            SubnetIds = $Subnets
        }
        It "Should have virtualNetworkRules id set to <SubnetIds>" -TestCases $TestCases {
            param(
                $SubnetIds
            )

            $json = $ACL | ConvertFrom-Json

            foreach ($rule in $json.virtualNetworkRules) {
                $rule.id | Should -BeIn $SubnetIds
            }
        }
    }
}