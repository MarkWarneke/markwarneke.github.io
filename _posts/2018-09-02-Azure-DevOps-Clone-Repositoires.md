---
layout: post
title: AzureDevOps managing multiple repositories using PowerShell
subtitle:
bigimg:
  - "/img/contact.jpeg"
image: "/img/contact.jpeg"
share-img: "/img/contact.jpeg"
tags: [AzureDevOps, PowerShell]
comments: true
time: 4
---

```powershell
function Clone-Repositories {
    <#
    .SYNOPSIS
        Clones a list of repositories to a specific location

    .EXAMPLE
        PS C:\> Clone-Repositories -Path 'C:\Users\<User>\dev\...'
        Git clone ....

    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory=$true)]
        [string] $Path = 'C:\Users\<User>\dev',
        [string[]] RepositoryList,
        [string] $RepositoryListFile = 'C:\Users\<User>\Documents\repos.txt',
        [string] $Url = 'https://dev.azure.com/az-new'
    )

    begin {
        Push-Location -Path $path
        if ([string]::IsNullOrEmpty($RepositoryList)) {
            Write-Verbose 'Load RepositoryList from file'
            $RepositoryList = Get-Content -Path $RepositoryListFile -ErrorAction Stop
        }
    }

    process {
        foreach ($repo in $RepositoryList) {

            $repoUrl = '{0}{1}' -f $url, $repo
            Write-Verbose $repoUrl

            $gitClone = 'git clone {0}' -f $repoUrl

            Write-Verbose $gitClone
            if (Get-ChildItem -Path $repo -ErrorAction SilentlyContinue) {
                Write-Verbose 'Repository already exists'
            }
            else {
                if ($PSCmdlet.ShouldProcess("run {0}" -f $gitClone)) {
                    Invoke-Expression $gitClone
                }
                Write-Output (Join-Path $path $repo)
            }
        }
    }

    end {
    }
}

$repos = "azure-automation",  "wiki", "mein-module"
Clone-Repositories -RepositoryList $repos -Verbose
```
