---
layout: post
title: VSCode Loves PowerShell
subtitle:
bigimg:
  - "/img/Agx5_TLsIf4.jpeg": "https://unsplash.com/photos/Agx5_TLsIf4"
image: "/img/Agx5_TLsIf4.jpeg"
share-img: "/img/Agx5_TLsIf4.jpeg"
tags: [PowerShell]
comments: true
time: 5
---

Sharing some VSCode settings and little helpers to interact with PowerShell and Azure Resource Manager templates.


## Settings

```json
// .vscode/settings.json
{
  //-------- Files configuration --------
  // When enabled, will trim trailing whitespace when you save a file.
  "files.trimTrailingWhitespace": true,
  "files.autoSave": "afterDelay",
  "files.autoSaveDelay": 2000,
  "files.hotExit": "onExit",
  "editor.formatOnSave": true,
  "editor.formatOnPaste": true,

  //-------- PowerShell Configuration --------
  // Use a custom PowerShell Script Analyzer settings file for this workspace.
  // Relative paths for this setting are always relative to the workspace root dir.
  "powershell.scriptAnalysis.enable": true,
  "powershell.codeFormatting.openBraceOnSameLine": true,

  // Change the defautl terminal
  // "terminal.integrated.shell.windows": "C:\\Program Files\\PowerShell\\6\\pwsh.exe",

  // Combine script Analyzer Settings with a config file
  "powershell.scriptAnalysis.settingsPath": "./PSScriptAnalyzerSettings.psd1"
}
```

To enable script analyzer for target PowerShell versions add this file and link it using `"powershell.scriptAnalysis.settingsPath": "./PSScriptAnalyzerSettings.psd1"` in the `.vscode/settings.json`

```powershell
# PSScriptAnalyzerSettings.psd1
@{
    Rules = @{
        PSUseCompatibleSyntax = @{
            # This turns the rule on (setting it to false will turn it off)
            Enable         = $true

            # List the targeted versions of PowerShell here
            TargetVersions = @(
                '3.0',
                '5.1',
                '6.2'
            )
        }
    }
}
```

# Tasks

```json
// .vscode/tasks.json
{
  "version": "2.0.0",
  "windows": {
    "command": "${env:windir}/System32/WindowsPowerShell/v1.0/powershell.exe",
    "args": ["-NoProfile", "-ExecutionPolicy", "Bypass"]
  },
  "type": "shell",
  "presentation": {
    "echo": true,
    "reveal": "always",
    "focus": false,
    "panel": "shared",
    "showReuseMessage": true,
    "clear": false
  },
  "tasks": [
    {
      "label": "Test",
      "group": "test",
      "command": [
        "Write-Host 'Invoking Pester...'; $ProgressPreference = 'SilentlyContinue'; Invoke-Pester -PesterOption @{IncludeVSCodeMarker=$true};",
        "Invoke-Command { Write-Host 'Completed Test task in task runner.' }"
      ],
      "args": [],
      "problemMatcher": "$pester"
    },
    {
      "group": "test",
      "label": "CustomTestTask",
      "type": "shell",
      "command": "start powershell -ArgumentList '-noexit -noprofile -command \"& {cd ${fileDirname}; cd ..; $Pester = Invoke-Pester -PassThru}\"'",
      "args": []
    }
  ]
}
```

## Extensions

```json
//.vscode/extensions.json
{
  "recommendations": [
    "msazurermtools.azurerm-vscode-tools",
    "samcogan.arm-snippets",
    "ms-vsts.team",
    "ms-azure-devops.azure-pipelines",
    "DavidAnson.vscode-markdownlint",
    "yzhang.markdown-all-in-one",
    "eamodio.gitlens",
    "eriklynd.json-tools",
    "ms-vscode.azure-account",
    "ms-vscode.azurecli",
    "ms-vscode.PowerShell",
    "ms-vscode.wordcount",
    "streetsidesoftware.code-spell-checker"
  ]
}
```

Export installed extensions:

```sh
code --list-extensions | xargs -L 1 echo code --install-extension
```

### Gitignore

```powershell
# MSTest test Results
[Tt]est[Rr]esult*/
[Bb]uild[Ll]og.*

# NUNIT
*.VisualState.xml
test/**/TestResults.*.xml
test/**/CodeCoverage.xml

TestResults.*.xml
CodeCoverage.xml
```

## Common Resource Helper

The DSC community has a great `CommonResourceHelper` module that can be used to develop advanced IaC modules.

```powershell
## https://github.com/PowerShell/SqlServerDsc/blob/dev/DSCResources/CommonResourceHelper.psm1


<#
    .SYNOPSIS
        Creates and throws an invalid argument exception.

    .PARAMETER Message
        The message explaining why this error is being thrown.

    .PARAMETER ArgumentName
        The name of the invalid argument that is causing this error to be thrown.
#>
function New-InvalidArgumentException {
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Message,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ArgumentName
    )

    $argumentException = New-Object -TypeName 'ArgumentException' `
        -ArgumentList @($Message, $ArgumentName)

    $newObjectParameters = @{
        TypeName     = 'System.Management.Automation.ErrorRecord'
        ArgumentList = @($argumentException, $ArgumentName, 'InvalidArgument', $null)
    }

    $errorRecord = New-Object @newObjectParameters

    throw $errorRecord
}

<#
    .SYNOPSIS
        Creates and throws an invalid operation exception.

    .PARAMETER Message
        The message explaining why this error is being thrown.

    .PARAMETER ErrorRecord
        The error record containing the exception that is causing this terminating error.
#>
function New-InvalidOperationException {
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Message,

        [Parameter()]
        [ValidateNotNull()]
        [System.Management.Automation.ErrorRecord]
        $ErrorRecord
    )

    if ($null -eq $ErrorRecord) {
        $invalidOperationException = New-Object -TypeName 'InvalidOperationException' `
            -ArgumentList @($Message)
    }
    else {
        $invalidOperationException = New-Object -TypeName 'InvalidOperationException' `
            -ArgumentList @($Message, $ErrorRecord.Exception)
    }

    $newObjectParameters = @{
        TypeName     = 'System.Management.Automation.ErrorRecord'
        ArgumentList = @(
            $invalidOperationException.ToString(),
            'MachineStateIncorrect',
            'InvalidOperation',
            $null
        )
    }

    $errorRecordToThrow = New-Object @newObjectParameters

    throw $errorRecordToThrow
}

<#
    .SYNOPSIS
        Creates and throws an object not found exception.

    .PARAMETER Message
        The message explaining why this error is being thrown.

    .PARAMETER ErrorRecord
        The error record containing the exception that is causing this terminating error.
#>
function New-ObjectNotFoundException {
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Message,

        [Parameter()]
        [ValidateNotNull()]
        [System.Management.Automation.ErrorRecord]
        $ErrorRecord
    )

    if ($null -eq $ErrorRecord) {
        $exception = New-Object -TypeName 'System.Exception' `
            -ArgumentList @($Message)
    }
    else {
        $exception = New-Object -TypeName 'System.Exception' `
            -ArgumentList @($Message, $ErrorRecord.Exception)
    }

    $newObjectParameters = @{
        TypeName     = 'System.Management.Automation.ErrorRecord'
        ArgumentList = @(
            $exception.ToString(),
            'MachineStateIncorrect',
            'ObjectNotFound',
            $null
        )
    }

    $errorRecordToThrow = New-Object @newObjectParameters

    throw $errorRecordToThrow
}

<#
    .SYNOPSIS
        Creates and throws an invalid result exception.

    .PARAMETER Message
        The message explaining why this error is being thrown.

    .PARAMETER ErrorRecord
        The error record containing the exception that is causing this terminating error.
#>
function New-InvalidResultException {
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Message,

        [Parameter()]
        [ValidateNotNull()]
        [System.Management.Automation.ErrorRecord]
        $ErrorRecord
    )

    if ($null -eq $ErrorRecord) {
        $exception = New-Object -TypeName 'System.Exception' `
            -ArgumentList @($Message)
    }
    else {
        $exception = New-Object -TypeName 'System.Exception' `
            -ArgumentList @($Message, $ErrorRecord.Exception)
    }

    $newObjectParameters = @{
        TypeName     = 'System.Management.Automation.ErrorRecord'
        ArgumentList = @(
            $exception.ToString(),
            'MachineStateIncorrect',
            'InvalidResult',
            $null
        )
    }

    $errorRecordToThrow = New-Object @newObjectParameters

    throw $errorRecordToThrow
}

<#
    .SYNOPSIS
        Retrieves the localized string data based on the machine's culture.
        Falls back to en-US strings if the machine's culture is not supported.

    .PARAMETER ResourceName
        The name of the resource as it appears before '.strings.psd1' of the localized string file.
        For example:
            For WindowsOptionalFeature: MSFT_WindowsOptionalFeature
            For Service: MSFT_ServiceResource
            For Registry: MSFT_RegistryResource
            For Helper: SqlServerDscHelper

    .PARAMETER ScriptRoot
        Optional. The root path where to expect to find the culture folder. This is only needed
        for localization in helper modules. This should not normally be used for resources.
#>
function Get-LocalizedData {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ResourceName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ScriptRoot
    )

    if ($PSUICulture) {
        $Culture = $PSUICulture
    }
    else {
        $Culture = 'en-US'
    }

    if ( -not $ScriptRoot ) {
        $resourceDirectory = Join-Path -Path $PSScriptRoot -ChildPath $ResourceName
        $localizedStringFileLocation = Join-Path -Path $resourceDirectory -ChildPath $Culture
    }
    else {
        $localizedStringFileLocation = Join-Path -Path $ScriptRoot -ChildPath $Culture
    }

    if (-not (Test-Path -Path $localizedStringFileLocation)) {
        # Fallback to en-US
        if ( -not $ScriptRoot ) {
            $localizedStringFileLocation = Join-Path -Path $resourceDirectory -ChildPath 'en-US'
        }
        else {
            $localizedStringFileLocation = Join-Path -Path $ScriptRoot -ChildPath 'en-US'
        }
    }

    Import-LocalizedData `
        -BindingVariable 'localizedData' `
        -FileName "$ResourceName.strings.psd1" `
        -BaseDirectory $localizedStringFileLocation

    return $localizedData
}

Export-ModuleMember -Function @(
    'New-InvalidArgumentException',
    'New-InvalidOperationException',
    'New-ObjectNotFoundException',
    'New-InvalidResultException',
    'Get-LocalizedData' )

```
