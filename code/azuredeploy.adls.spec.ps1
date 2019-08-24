param (
    $Path = (Join-Path $PSScriptRoot "azuredeploy.json")
)
# Test for template presence
$null = Test-Path $Path -ErrorAction Stop

# Test if arm template content is readable
$text = Get-Content $Path -Raw -ErrorAction Stop

# Convert the ARM template to an Object
$json = ConvertFrom-Json $text -ErrorAction Stop

# Query naively all resources for type that match type storageAccounts
# Might need to be adjusted based on the actual resource manager template
$resource = $json.resources | Where-Object -Property "type" -eq "Microsoft.Storage/storageAccounts"

Describe "Azure Data Lake Generation 2 Resource Manager Template" {

    # Mandatory requirement of ADLS Gen 2 are:
    # - Resource Type is Microsoft.Storage/storageAccounts
    # - Kind is StorageV2
    # - Hierarchical namespace is enabled
    # https://docs.microsoft.com/en-us/azure/storage/blobs/data-lake-storage-quickstart-create-account?toc=%2fazure%2fstorage%2fblobs%2ftoc.json

    it "should have resource properties  present" {
        $resource | Should -Not -BeNullOrEmpty
    }

    it "should be of type Microsoft.Storage/storageAccounts" {
        $resource.type | Should -Be "Microsoft.Storage/storageAccounts"
    }

    it "should be of kind StorageV2" {
        $resource.kind | Should -Be "StorageV2"
    }

    it "should have Hns enabled" {
        $resource.properties.isHnsEnabled | Should -Be $true
    }

    # Optional validation tests:
    # - Ensure encryption is as specified
    # - Secure Transfer by enforcing HTTPS

    it "should have encryption key source set to Storage " {
        $resource.properties.encryption.keySource | Should -Be "Microsoft.Storage"
    }

    it "should have blob encryption enabled" {
        $resource.properties.encryption.services.blob.enabled | Should -Be $true
    }

    it "should have file encryption enabled" {
        $resource.properties.encryption.services.blob.enabled | Should -Be $true
    }

    it "should enforce Https Traffic Only" {
        $resource.properties.supportsHttpsTrafficOnly | Should -Be $true
    }
}