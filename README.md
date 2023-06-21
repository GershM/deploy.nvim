<h1 align="center">(Neo)vim remote deployment Plugin</h1>

# Info
- This is Plugin for nvim to upload the local projects to the remote server.
- currently, only rsync upload is supported.

1. [Installation](#installation)
1. [Basic usage](#basic-usage)
1. [Commands](#commands)

## Installation
- for Packer:
```lua
use { 'GershM/deploy.nvim', requires = "nvim-telescope/telescope.nvim", setup = require("deploy").setup() }
```
- Make sure rsync is installed.

## Basic usage
- Create 'deploy.json' file at the project's root folder or use the ``Deploy Create`` command.
- Deployment configuration file(deploy.json) example:
```json
[
    {
       "name": "Connection Name",
       "host": "Host/IP Address",
       "username": "Login User",
       "password": "User's password",
       "remoteRootPath": "",
       "isDefault": true,
       "autoUpload": true,
       "binary": "",
       "ignore": [
            ".git",
            "node_modules",
            "vendeor",
            ".vsCode",
            ".idea",
            "deploy.json"
        ]
    }
]
```

## Commands
- Configuration:
    - ``Deploy Create``: Creating basic configuration.
    - ``Deploy Edit``: Open the configuration file.

- Deployment:
    - ``Deploy Download``: Download File from remote server.
    - ``Deploy Upload``: Upload File to a remote server.
    - ``Deploy RemoteSync``: Uploading the project to remote server.
    - ``Deploy LocalSync``: Allow to execute files in Remote server using ssh (the binary can be configured in the configuration file)
    - ``Deploy Exec``: Allow to execute files in Remote server using ssh (the binary can be configured in the configuration file)
    - ``Deploy Connect``: Allow to execute files in Remote server using ssh (the binary can be configured in the configuration file)

## Todo 
- Use of the password Parameter 
- Allow remote editing 
- Commands Auto Complete
- Plugin documentation
- Update README file 
