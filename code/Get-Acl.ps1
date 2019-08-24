class NetworkAcls {
    #https://docs.microsoft.com/en-us/azure/templates/microsoft.storage/2019-04-01/storageaccounts#NetworkRuleSet

    [string] $bypass = "Logging,Metrics,AzureServices"
    [array] $virtualNetworkRules
    [array] $ipRules
    [string] $defaultAction = "Deny"
}

class Rule {
    [string] $action = "Allow"
}

class VirtualNetworkRule : Rule {
    # https://docs.microsoft.com/en-us/azure/templates/microsoft.storage/2019-04-01/storageaccounts#virtualnetworkrule-object
    
    # Resource ID of a subnet, for example: /subscriptions/{subscriptionId}/resourceGroups/{groupName}/providers/Microsoft.Network/virtualNetworks/{vnetName}/subnets/{subnetName}.
    [string] $id

    VirtualNetworkRule ([string] $id) {
        if ([string]::IsNullOrEmpty($id)) {
            throw [ArgumentException]::new('id is empty')
        }
        $this.Id = $id
    }

    [string] ToString() {
        return "$($this.Action) $($this.id)"
    }
}

class IpRule : Rule {
    # https://docs.microsoft.com/en-us/azure/templates/microsoft.storage/2019-04-01/storageaccounts#iprule-object
    
    # Specifies the IP or IP range in CIDR format. Only IPV4 address is allowed.
    [string] $value

    IpRule ([string] $value) {
        if ([string]::IsNullOrEmpty($value)) {
            throw [ArgumentException]::new('Value is empty')
        }
        $this.Value = $value
    }

    [string] ToString() {
        return "$($this.Action) $($this.Value)"
    }
}

function Get-Acl {

    <#
    .SYNOPSIS
    Returns a valid json string for Azure Storage Account ACL Object

    .DESCRIPTION
     Returns a valid json string for Azure Storage Account ACL Object
     https://docs.microsoft.com/en-us/azure/templates/microsoft.storage/2019-04-01/storageaccounts#NetworkRuleSet

    .PARAMETER Subnets
    A list of Subnet Ids

    .PARAMETER IpAddresses
    A list of IPAddresses

    .EXAMPLE
    Get-Acl -IpAddress 255.255.255.0, 0.0.0.0

    ACL .. { }
    
    .LINK
    #https://docs.microsoft.com/en-us/azure/templates/microsoft.storage/2019-04-01/storageaccounts#NetworkRuleSet
    #>

    param (
        $Subnets,
        $IpAddresses
    )

    process {

        $networkAcls = [NetworkAcls]::new()

        $IpRules = @()
        foreach ($IpAddress in $IpAddresses) {
            if ($IpAddress) {
                Write-Verbose "$IpAddress"
                $IpRules += [IpRule]::new($IpAddress)
            }
        }
        Write-Verbose "$IpRules"

        $virtualNetworkRules = @()
        foreach ($subnet in $Subnets) {
            if ($subnet) {
                $virtualNetworkRules += [VirtualNetworkRule]::new($subnet)
            }
        }

        $networkAcls.IpRules = $IpRules
        $networkAcls.virtualNetworkRules = $virtualNetworkRules
        [string] $json = $networkAcls | ConvertTo-Json -Compress
        return $json
    }
}