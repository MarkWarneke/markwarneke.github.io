$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe ".\New-ParameterFile" {
    
    $ParameterFile = New-ParameterFile 
    $Json = $ParameterFile | ConvertFrom-Json -ErrorAction Stop -ErrorVariable JsonException
        
        
    It "should create valid json" {
        $JsonException | Should -BeNullOrEmpty
      
    }

    $TestCases = @(
        @{
            Property = "Schema"
        },
        @{
            Property = "contenVersion"
        },
        @{
            Property = "parameters"
        }   
    )
    it "should have <Property> " -TestCases $TestCases { 
        Param(
            $Property
        )
        $Json.$Property | Should -Not -BeNullOrEmpty
    }
    
 
    $TestCases = @(
        @{
            Parameter = "networkAcls"
        },
        @{
            Parameter = "resourceName"
        },
        @{
            Parameter = "storageAccountSku"
        },
        @{
            Parameter = "location"
        }      
    )
    it "should have <Parameter> with value Prompt" -TestCases $TestCases { 
        Param(
            $Parameter
        )
        $Json.Parameters.$Parameter | Should -Not -BeNullOrEmpty
        $Json.Parameters.$Parameter.Value | Should -Be "Prompt"
    }

}

Describe "Class ParameterFile" {
    
    [array]$Parameters = @(
        @{ 
            Name = "Test1"
        },
        @{ 
            Name = "Test2"
        },
        @{ 
            Name = "Test3"
        }
    )
    it "should create a ParameterFile object" {
        [ParameterFile]::new($Parameters).GetType() | Should -Be "ParameterFile"
    }
    
    it "should have schema" {
        [ParameterFile]::new($Parameters).Schema | Should -Be "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#"
    }
    
    it "should have contenVersion" {
        [ParameterFile]::new($Parameters).contenVersion | Should -Be "1.0.0.0"
    }
    
    it "should have parameters" {
        [ParameterFile]::new($Parameters).parameters | Should -Not -BeNullOrEmpty
    }
}


Describe "Class ParameterFactory" {
    
    it "should create a ParameterFactory object" {
        [ParameterFileFactory]::new("$here\azuredeploy.json").GetType() | Should -Be "ParameterFileFactory"
    }
    
    it "should have template" {
        [ParameterFileFactory]::new("$here\azuredeploy.json").template | Should -Not -BeNullOrEmpty
    }
    
    it "should have Parameter" {
        [ParameterFileFactory]::new("$here\azuredeploy.json").Parameter | Should -Not -BeNullOrEmpty
        [ParameterFileFactory]::new("$here\azuredeploy.json").Parameter.Count | Should -BeGreaterOrEqual 5
    }
    
    it "should have MandatoryParameter" {
        [ParameterFileFactory]::new("$here\azuredeploy.json").MandatoryParameter | Should -Not -BeNullOrEmpty
        [ParameterFileFactory]::new("$here\azuredeploy.json").MandatoryParameter.Count | Should -Be 2
    }
    
    it "should create ParameterFile" {
        $ParameterFile = [ParameterFileFactory]::new("$here\azuredeploy.json").CreateParameterFile($false)
        $ParameterFile.GetType() | Should -Be "ParameterFile"
        $ParameterFile | Should -Not -BeNullOrEmpty
    }
    

}