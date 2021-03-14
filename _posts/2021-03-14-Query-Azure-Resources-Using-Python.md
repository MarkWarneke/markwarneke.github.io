---
layout: post
title: Query Azure Resources using Python
subtitle: an introduction to the easy to use Az.Cli Python interface
bigimg:
  - "/img/fPkvU7RDmCo.jpeg": "https://unsplash.com/photos/fPkvU7RDmCo"
image: "/img/fPkvU7RDmCo.jpeg"
share-img: "/img/fPkvU7RDmCo.jpeg"
tags: [Azure, Draft]
comments: true
time: 2
---


`Az.Cli` is an easy-to-use Python interface that lets developers and administrators query Azure resources.
The Python package is providing a way to interact with Azure using Python while sticking to a well-known concept of the Azure CLI.
If you are already familiar with the Azure CLI you should feel right at home using the `Az.Cli` Python package API.

Every command that is available in the Azure CLI can be executed using the function `az("<sub command>")`.
The function enables Azure developers and administrators to run shell commands like `az group list` inside of Python like `az("group list")`.

## Why?

I encountered numerous projects where Azure developers and administrators created sophisticated shell scripts that leverage the idempotent functionality of the Azure CLI to get their work done. 

While bash scripts are great to get things done quickly and the WSL allows Windows users to run and develop shell scripts as well, I always disliked the syntax and unnecessary complication of bash scripting. Including user input, input validation, loops, property access (mostly done using [`jq`](https://stedolan.github.io/jq/)), as well as logging and error handling.

At mature teams, we can find the implementation of [shell style guides](https://google.github.io/styleguide/shellguide.html), and the implementation of tools for linting like [shellcheck](https://github.com/koalaman/shellcheck), as well as testing to deal with the increasing complexity of the Infrastructure as Code automation over time. 
I always found those tools in the early stages of the adoption great but leave a lot of maintenance and toil in large-scale environments.
If not worked on constantly the complexity makes it hard to maintain and onboard new users to the codebase.

The `Az.Cli` is a simple solution to this mess as it allows the refactoring of existing shell scripts from the Azure CLI to a Python implementation.
The move to Python harnesses the power of a fully-fledged object-oriented scripting language with a huge open-source community and wide adoption while sticking to a well-known syntax, that enables easy onboarding and maintenance and native debugging capabilities.

As the `Az.Cli` relies on the official Python libraries of the Azure CLI, and is thus fully compatible and stays current.

## How to start

Visit [pypi.org/project/az.cli/](https://pypi.org/project/az.cli/) and install the package using pip.
A getting started guide is provided in the pypi description or visit [github.com/MarkWarneke/Az.Cli](https://github.com/MarkWarneke/Az.Cli) for more information and help.

Install the package

```bash
pip install az.cli
```

After installing the package log in using `az login` or [sign in using a service principal](https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli?view=azure-cli-latest#sign-in-using-a-service-principalt).
Under the hood the package uses the [~/.azure](https://github.com/Azure/azure-cli/blob/dev/src/azure-cli-core/azure/cli/core/_environment.py) folder to persist and retrieve config.


The `az` function returns a named tuple that allows you to retrieve the results easily.

```python
AzResult = namedtuple('AzResult', ['exit_code', 'result_dict', 'log'])
```

- The [`error_code`](https://docs.python.org/2/library/sys.html#sys.exit) where `0 == success`.
- The `result_dict` containing a python dictionary on a successful return.
- On failure (`error_code` > 0) a log message is available in the `log` property as a string.

### Example

The usage of the packe is straight forward, after installing and importing the package.

```python
from az.cli import az

# AzResult = namedtuple('AzResult', ['exit_code', 'result_dict', 'log'])
exit_code, result_dict, logs = az("group list")

# On 0 (SUCCESS) print result_dict, otherwise get info from `logs`
if exit_code == 0:
    print (result_dict)
else:
    print(logs)
```

... or simply

```python
az("group list")[0] # error code
az("group list")[1] # result 
az("group list")[2] # log messages on failure 
```

{: .box-warning}
Visit [pypi.org/project/az.cli/](https://pypi.org/project/az.cli/) now and install the package to try it yourself!

## Programmatically Setting The Azure Config

To change the Azure context, the "session" in which you are logged in, the package relies on the stored credentials inside the `~/.azure` folder by default.
This typically limits the context in which an automation script can execute to the saved context. 
Querying multiple tenants or with different users requires you to sign-in multiple times and switch between the contexts.

To change the credentials a change to the environment variable `AZURE_CONFIG_DIR` will point to a new context.
This can easily be done in Python using the `os.enviorn` interface.

To try this in the shell version of the Azure CLI sign in with different service principals and copy the `~/.azure` folder multiple times.
One way to validate this functionality is to perpend `AZURE_CONFIG_DIR` in front of an Azure CLI command.

```bash
az login
mv ~/.azure/* ~/.azure-mw

az login --service-principal -u $id -p $p -t $t

# Validate that it works
AZURE_CONFIG_DIR=.azure az group list 
AZURE_CONFIG_DIR=.azure-mw az group list 
```

In a Python script the environment variable can be set using:

```python
os.environ['AZURE_CONFIG_DIR'] = "<OTHER AZURE CONFIG DIR>"
```

Changing the `AZURE_CONFIG_DIR` environment variables is described in the docs to the [Azure CLI environment variables](https://docs.microsoft.com/en-us/cli/azure/use-cli-effectively?view=azure-cli-latest#cli-environment-variables).
To demonstrate how to change the environment variable programmatically a small example:

```python
from az.cli import az
import os

exit_code, result_dict, logs = az("group list")
print (result_dict)
# [{'id': '/subscriptions/...', 'location': 'westeurope',  'name': 'test1']

# Change the environment variable
os.environ['AZURE_CONFIG_DIR'] = '/Users/mark/.azure_mw'

exit_code, result_dict, logs = az("group list")
print (result_dict)
# [{'id': '/subscriptions/...', 'location': 'westeurope', 'name': 'test2']
```

## Interactively Querying Azure Using Python

You can also use the package to interactively query Azure resources using Python.

Just start a new interactive Python prompt `$ python3`

```python
from az.cli import az


 # list return tuple (exit_code, result_dict, log)
az("group list")

# on Success, the `error_code` is 0 and the result_dict contains the output
az("group list")[0] 

# print the returned object
az("group list")[1] 

# enumerate the id of the first element in dictionary
az("group list")[1][0]['id'] 


# On Error, the `error_code` will be != 0 and the log property is returned
az("group show -n does-not-exsist") 

az("group show -n does-not-exsist")[0] # returns 3

# print the error messagelog
az("group show -n does-not-exsist")[2] 
```

## How it works

The package is an easy-to-use abstraction on top of the officiale Microsoft [Azure CLI](https://github.com/Azure/azure-cli).
The official [azure.cli.core](https://github.com/Azure/azure-cli/blob/dev/src/azure-cli-core/azure/cli/core/__init__.py) library is simply wrapped in a funciton to execute Azure CLI commands using Python3.
The package provides a funciton `az` the is based on the class `AzCLI`.
It exposes the function to execute `az` commands and returns the results in a structured manner.

It has thus a similar API and usage to the shell version of the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest), but commands can be executed within Python, leveraging Pythons full potential. 

The package uses the stored credentials in [~/.azure](https://github.com/Azure/azure-cli/blob/dev/src/azure-cli-core/azure/cli/core/_environment.py) folder to retrieve the current context and log-in information.
This is particularly useful if you want to [programmatically set the current Azure Configuration](#programmatically-setting-the-azure-config), for instance when dealing with multiple Azure tenants.

{: .box-warning}
Visit [pypi.org/project/az.cli/](https://pypi.org/project/az.cli/) now and install the package to try it yourself!
