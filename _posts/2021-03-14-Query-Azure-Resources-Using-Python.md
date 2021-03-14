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


`Az.Cli` is an easy-to-use Python interface that is intuitive if you are already familiar with the Azure CLI - just run `az("group list")` to query all resource groups after importing the installed package.
The interface is providing a way to interact with Azure using Python while sticking to a well known standard - the Azure CLI.

Every command that is available in the Azure CLI can be executed using the smaller helper function `az("")`.

## How to start

Just visit [pypi.org/project/az.cli/](https://pypi.org/project/az.cli/) and install the package using pip.

```bash
python3 -m venv env  
pip install az.cli
```

After installing the package you can login using `az login` or [sign in using a service principal](https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli?view=azure-cli-latest#sign-in-using-a-service-principalt).
Under the hood the package uses the [~/.azure](https://github.com/Azure/azure-cli/blob/dev/src/azure-cli-core/azure/cli/core/_environment.py) folder to persist and retrieve the current context.
This is particularly useful if you want to programmatically set the current Azure Configuration, see [programmatically setting the Azure Configuration](#programatically-setting-azure-config).

The method returns a named tuple that allows you to retrieve the necessary information easily.

```python
AzResult = namedtuple('AzResult', ['exit_code', 'result_dict', 'log'])
```

- The `result_dict` containing a python dictionary on a successful return.
- The [`error_code`](https://docs.python.org/2/library/sys.html#sys.exit) where `0 == success`.
- On failure (`error_code` > 0) a log message is available in the `log` property as a string.

### ExampleBasally

```python
from az.cli import az

# AzResult = namedtuple('AzResult', ['exit_code', 'result_dict', 'log'])
exit_code, result_dict, logs = az("group show -n test")

# On 0 (SUCCESS) print result_dict, otherwise get info from `logs`
if exit_code == 0:
    print (result_dict)
else:
    print(logs)
```

## How it works

The package is an easy to use abstraction on top of the Azure CLI implementation.
The package wraps the [azure.cli.core](https://github.com/Azure/azure-cli/blob/dev/src/azure-cli-core/azure/cli/core/__init__.py) class `AzCLi`, and exposes a function execute `az` [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) commands in Python.
The package is a Python `azure.cli.core` wrapper to execute Azure CLI commands using Python3

## Programmatically Setting Azure Config

To change the current Azure context, the context in which you are logged in, the CLI relies on stored credentials inside the `~/.azure` folder by default.
In order to change the execution context you can simply change the environment variable inside of Python.

To try this you can just sign in with different service principals, one way to check it is to perpend `AZURE_CONFIG_DIR` to a bash command.

```bash
az login

mv ~/.azure/* ~/.azure-mw
az login --service-principal -u $id -p $p -t $t

# Validate tha it works
AZURE_CONFIG_DIR=.azure az group list 
AZURE_CONFIG_DIR=.azure-mw az group list 
```

In Python the environment variable can be set using:

```python
os.environ['AZURE_CONFIG_DIR'] = OTHER_AZURE_CONFIG_DIR
```

Changing the `AZURE_CONFIG_DIR` environment variables is described in the docs here [CLI environment variables](https://docs.microsoft.com/en-us/cli/azure/use-cli-effectively?view=azure-cli-latest#cli-environment-variables)

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

## Interactively querying Azure using Python

You can also use the package to interactively query Azure resources using Python.

Just start a new Python prompt `$ python3`

```python
from az.cli import az
# on Success, the `error_code` is 0 and the result_dict contains the output
az("group list") # list return tuple (exit_code, result_dict, log)
az("group list")[0] # 0
az("group list")[1] # print result_dict
az("group list")[1][0]['id'] # enumerate the id of the first element in dictionary

# On Error, the `error_code` will be != 1 and the log is present
az("group show -n does-not-exsist") # list return tuple (exit_code, result_dict, log)
az("group show -n does-not-exsist")[0] # 3
az("group show -n does-not-exsist")[2] # print the log
```

{: .box-warning}
Visit [pypi.org/project/az.cli/](https://pypi.org/project/az.cli/) and install the package right now to try it yourself!
