# Overview

The "Bespoke" module...

# System Requirements

* Windows 10
* Any Linux system with "apt" and "apt-get" installed.
* macOS with "brew" installed.
* Windows PowerShell 5.1 and .NET 4.6.1+
* PowerShell Core 7+

# Installing

To install globally:

```powershell
Install-Module -Name 'Bespoke'
Import-Module -Name 'Bespoke'
```

To install privately:

```powershell
Save-Module -Name 'Bespoke' -Path '.'
Import-Module -Name '.\Bespoke'
```

# Getting Started

* Create a Git repository somewhere that will contain your customization configuration.
* `Import-Module 'Bespoke'`
* `Initialize-Me 'Git' -Url YOUR_GIT_REPO_URL`

# Configuring

What you want Bespoke is configured in a "bespoke.json" file in the root of your repository. Here's a documented
sample:

```json
{
    "packages": {
        "winget": [
            "NAME",
            {
                "name": "Required. The name of the package.",
                "installId": "Optional. The winget ID used to install the package.",
                "listId": "Optional. The winget ID of the installed package. Used to detect if the package is alread installed. And, yes, this can be different that the ID of the package in the remote repository."
            }
        ],

        "powershellModules": [
            "NAME",
            {
                "name": "Required. The name of the package.",
                "version": "Optional. A wildcard pattern for the version to install. The most recent version to match this wildcard will be installed. By default, the latest version is installed."
            }
        ],

        "appx": [
            "NAME",
            {
                "name": "Required. The name of the package. Used to determine if the package has already been installed."
            }
        ]
    }
}
```
