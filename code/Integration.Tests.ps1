Describe "Azure Data Lake Generation 2 Resource Manager Integration" -Tags Integration {

    BeforeAll {
        # Create test environment
        Write-Host "Creating test environment $ResourceGroupName, cleanup..."

        # Create a unique ResourceGroup 
        # `unique` string base on the date
        # e.g. 20190824T1830434620Z
        # the file date time universal format has 20 characters
        $ResourceGroupName = 'TT-' + (Get-Date -Format FileDateTimeUniversal)

        Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue | 
        Remove-AzResourceGroup -Force

        # Get a unique name for the resource too, 
        # Some Azure Resources have a limitation of 24 characters
        # consider 20 for the unique ResouceGroup.
        $ResourceName = 'pre-' + $ResourceGroupName.ToLower()

        # Setup the environment
        $null = New-AzResourceGroup -Name $ResourceGroupName -Location 'WestEurope'
    }

    AfterAll {
        # Remove test environment after test
        Write-Host "Removing test environment $ResourceGroupName..."

        Get-AzResourceGroup -Name $ResourceGroupName | 
        Remove-AzResourceGroup -Force -AsJob
    }

    # Deploy Resource
    New-AzResourceGroupDeployment -ResrouceGroupName $ResourceGroupName -Name $ResourceName

    #  Run Acceptance Test
    . $PSScriptRoot/acceptance.spec.ps1 -ResourceName $ResourceName -ResourceGroupName $ResourceGroupName
}