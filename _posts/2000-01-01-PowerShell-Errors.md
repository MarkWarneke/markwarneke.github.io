---
layout: post
title: DRAFT Error Handling  and Useful Snippets
subtitle:
bigimg:
  - "/img/draft.jpeg": "https://unsplash.com/photos/wE37SqLAO9M"
image: "/img/draft.jpeg"
share-img: "/img/draft.jpeg"
tags: [draft]
comments: true
time: 4
---

## Snippets

### Parameter

```powershell
#Get Function Parameters in Script
$params = $PSBoundParameters
```

### Error

```powershell
# PowerShell saves all Errors in $Error Variable

$global:Error.Clear()

$global:ErrorView = "NormalView"
```

#### Prioritize Error

```powershell
$Error |
Group-Object |
Sort-Object -Property Count -Descending |
Format-Table -Property Count, Name -AutoSize
```

#### List All Error Members

```powershell
$Error[0] | fl * -Force
$Error[0].Exception | fl * -Force
```

#### Stack Trace of Error

```powershell
$Error[0].StackTrace
$Error[0].Exception.StackTrace
```

### Output Error User

```powershell
# Will have a nice error message
$callerErrorActionPreference = $ErrorActionPreference # Save Callers Preference
Catch {
  Write-Error -ErrorRecord $_ -ErrorAction $callerErrorActionPreference
}
```

Output Error Dev

```powershell
# Will have all the details in error message

Catch {
  $ex = $_.Exception | Format-List -Force
}

# Or throw up, will get details into shell if not handled

Catch {
  Throw
}
```

### ARM Deployment

```powershell
$ResourceGroupName = 'deploymentGroupName'

$correlationId = ((Get-AzureRMLog -ResourceGroupName $ResourceGroupName)[0]).CorrelationId

$logentry = (Get-AzureRMLog -CorrelationId $correlationId -DetailedOutput)



#$logentry

$rawStatusMessage = $logentry.Properties

$status = $rawStatusMessage.Content.statusMessage | ConvertFrom-Json

$status.error.details

$status.error.details.details
```

#### Pester Test

```powershell
# Invoke with Output Object

$pester = Invoke-Pester -PassThru

# Get Summary of Pester
$pester


# Display only Failed Tests
$pester.TestResult | ? { $_.Result -eq 'Failed' }


# Pest Test Error Display
$_.Exception | Format-List * -Force | Out-String|% {Write-Host $_}
```

#### ScriptAnalyzer

```powershell
 Invoke-ScriptAnalyzer -Path $Path -IncludeDefaultRules
```

#### Outputs

```powershell
$return = [PSCusomtOBject]@{}
Foreach($output in $Outputs.GetEnumerator()) {
  $return | Add-Member -MemberType NoteProperty -Name $output.Name -Value $output.Value.Value
}
$return
```

#### Log complex Objects

```powershell
# Function is not needed, but makes the idea clear.
function _log($Object) {
    $Object | format-list * -force | Out-String | Write-Verbose
}
```

#### Save Session State

```powershell
$output = Export-Clixml
```
