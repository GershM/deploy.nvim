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
use { 'GershM/deploy.nvim',requires = "nvim-telescope/telescope.nvim" , setup = require("deploy").setup() }
```
- Make sure rsync is installed.

## Basic usage
- Create 'deploy.json' file at the project's root folder or use the ``CreateDeploymentConfig`` command.
- Deployment config file(deploy.json) example:
```json
[
    {
       "name": "Connection Name",
       "ipAddress": "Host/IP Address",
       "username": "Login User",
       "password": "User's password",
       "remoteRootPath": "",
       "isDefault": true,
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
- ``CreateDeploymentConfig``: Creating basic configuration.
- ``EditConfiguration``: Open the configuration file.
- ``DownloadFile``: Download File from remote server.
- ``UploadFile``: Upload File to a remote server.
- ``SyncRemoteProject``: Uploading the project to remote server.
- ``ExecuteRemoteFile``: Allow to execute files in Remote server useing ssh (the binary can be configured in the configuration file)

