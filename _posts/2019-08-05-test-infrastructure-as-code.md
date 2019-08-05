---
layout: post
title: Test Infrastructure as Code
subtitle: 
bigimg: /img/work.jpg
gh-repo: MarkWarneke/Az.Test
gh-badge: [star, follow]
tags: [test, powershell, arm]
comments: true
published: false
---

Treat infrastrcuture as code as a Software development project. Implementing software engineering practices into the development of infrastructure.

Version Control


[The Practical Test Pyramid](https://martinfowler.com/articles/practical-test-pyramid.html)

Unit-Test - static analysis, 
Integration-Test - Test if your deployment works, clean environment, random variables, different locations
E2E-Test - Testing accross components
Acceptance Test - Validation of deployment

Pipelines CI/CD, build pipelein -> artefacts -> release pipeline

Innterloop and Outerloop

Testing:

Assumption:
            Big Components that have dependencies

Build Pipeline
            static analyse
            Unit Test
                        Test-
                        WhatIf
            Integration Test?
                        integration
                        dependencies
                        müssen bedingungen da sein (Hub/Tier1)
-> Bauen eines Artefacts
Release Pipeline
            Smoke Tests
            Validation Test
            Acceptence Test

Inner-Loop (View of Developer)
            Liniting - .vscode/extensions/ json lint but is there a lint on the pipeline
            convention/formating  - .vscode/settings (trim whitepsace, new line, brackets, tabs)
            
            Execution of tests locally
            code generators

PowerShell Conference EU - Test infrastructure as code?
![Test infrastructure as code?](https://www.youtube.com/watch?v=k33Nini-Dc8)

# Tools

PowerShell
- pester
- psscript analyzer


Test Kitchen
Pyton XUnit

# Resources

[Google: Testing Block](https://testing.googleblog.com/2015/04/just-say-no-to-more-end-to-end-tests.html)