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

Describe "Azure Data Lake Generation 2 Resource Manager Resource Acceptance" -Tags Acceptance {

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