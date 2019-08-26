---
layout: post
title: Error Handling and Useful Snippets
subtitle:
bigimg:
  - "/img/9SoCnyQmkzI.jpeg": "https://unsplash.com/photos/9SoCnyQmkzI"
image: "/img/9SoCnyQmkzI.jpeg"
share-img: "/img/9SoCnyQmkzI.jpeg"
tags: [PowerShell]
comments: true
time: 3
---

- [Error](#error)
  - [Prioritize Errors](#prioritize-errors)
  - [List All Error Members](#list-all-error-members)
  - [Stack Trace of Error](#stack-trace-of-error)
  - [Output Error User](#output-error-user)
  - [Output Error Dev](#output-error-dev)
- [ARM Deployment](#arm-deployment)
  - [Debug Azure Resource Manager Deployment](#debug-azure-resource-manager-deployment)
  - [Azure Resource Manager Outputs](#azure-resource-manager-outputs)
  - [Log complex Objects](#log-complex-objects)
  - [Save Session State](#save-session-state)
- [Pester Test](#pester-test)
  - [ScriptAnalyzer](#scriptanalyzer)

## Error

Thanks Kirk Munro: [Become a PowerShell Debugging Ninja](https://www.youtube.com/watch?v=zhjU24hbYuI)

```powershell
# PowerShell saves all Errors in $Error Variable, clear the Errors in the beginning
$global:Error.Clear()

$global:ErrorView = "NormalView"
```

### Prioritize Errors

```powershell
$Error |
Group-Object |
Sort-Object -Property Count -Descending |
Format-Table -Property Count, Name -AutoSize
```

### List All Error Members

```powershell
$Error[0] | fl * -Force
$Error[0].Exception | fl * -Force
```

### Stack Trace of Error

```powershell
$Error[0].StackTrace
$Error[0].Exception.StackTrace
```

### Output Error User

```powershell
# Save Callers Preference
$callerErrorActionPreference = $ErrorActionPreference
# ...
Catch {
 # Will have a nice error message
  Write-Error -ErrorRecord $_ -ErrorAction $callerErrorActionPreference
}
```

### Output Error Dev

```powershell
catch {
 # Log thedetails in error message
   $_.Exception | Format-List -Force| Out-String | Write-Verbose
}

# Or throw up, will get details into shell if not handled
Catch {
  Throw
}
```

## ARM Deployment

Trouble shooting ARM templates can be tedious.
With these few scripts your ARM development will be much smoother and debugging way easier.

```powershell
$ResourceGroupName = 'deploymentGroupName'

$correlationId = ((Get-AzLog -ResourceGroupName $ResourceGroupName)[0]).CorrelationId
$logentry = (Get-AzLog -CorrelationId $correlationId -DetailedOutput)

$logentry



$rawStatusMessage = $logentry.Properties

$status = $rawStatusMessage.Content.statusMessage | ConvertFrom-Json

$status.error.details

$status.error.details.details
```

### Debug Azure Resource Manager Deployment

```powershell
function Test-ArmTemplate {

    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [object]
        $TemplateFile,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [HashTable]
        $templateParameterObject,

        [string]
        $Name = 'testdeployment'
    )

    $debugpreference = "Continue"

    $rawResponse = Test-AzResourceGroupDeployment -ResourceGroupName $Name `
        -TemplateFile $TemplateFile.FullName `
        -TemplateParameterObject $TemplateParameterObject `
        -ErrorAction Stop 5>&1

    $debugpreference = "SilentlyContinue"

    $deploymentOutput = ($rawResponse.Item(32) -split 'Body:' | Select-Object -Skip 1 | ConvertFrom-Json).properties

    return $deploymentOutput
}
```

### Azure Resource Manager Outputs

When dealing with Azure Resource Manager Templates `New-AzResourceGroupDeployment -...` returns a json.
To get only the outputs a little script is needed to extract the values.

```powershell
$return = [PSCusomtOBject]@{}
Foreach($output in $Outputs.GetEnumerator()) {
  $return | Add-Member -MemberType NoteProperty -Name $output.Name -Value $output.Value.Value
}
$return
```

### Log complex Objects

If you want to log a complex object while sticking limiting the output to the Verbose stream.
You can use `Format-List * -Force` to expand the whole object.
Pipe it to `Out-String` to create one big string stream and pipe this into `Write-Verbose`.
Now youy have the whole output in your verbose output.

```powershell
# Function is not needed, but makes the idea clear.
function _log($Object) {
    $Object | format-list * -force | Out-String | Write-Verbose
}
```

### Save Session State

How to save time intensive output state and reuse for debugging (ARM template outputs debugging)
If you want to troubleshoot a time intensive output and save the state you can leverage `export-clixml`.

After that you can use the state.xml to retrieve the objects and all of their properties.

```powershell
# Deploy actual arm template or time intensive task then generates an object to reuse
$Deploy = New-AzResourceGroupDeployment ....

# save the state by serializing the object to xml
$Deploy | Export-Clixml $Home\state.xml


# load time intensive object from serialized state
$session = Import-Clixml $home\state.xml
```

That will allow you to troubleshoot the output without rerunning the whole script until this point.
In debug mode you are able to export the output of a script at runtime at a specific place and time, too.

## Pester Test

Leveraging Pester is a good practice.
There are some tricks to work with Pester a bit smarter.

Store the output into a variable using `-PassThru`.
No you can query the output and search e.g. for only Failed tests.

Also, if you are within a Pester test the output, especially from exceptions, is suppressed.
Using a work around you can still get the exception message.

```powershell
# Invoke with Output Object
$pester = Invoke-Pester -PassThru

# Get Summary of Pester
$pester

# Display only Failed Tests
$pester.TestResult | ? { $_.Result -eq 'Failed' }

# Pest Test Error Display
$_.Exception | Format-List * -Force | Out-String | Write-Host
```

### ScriptAnalyzer

Script Analyzer helps you to write good PowerShell code.

```powershell
 Invoke-ScriptAnalyzer -Path $Path -IncludeDefaultRules
```
