<h1 align="center">(Neo)vim remote deployment Plugin</h1>
# deploy.nvim
This is Plugin for nvim to upload local project to remote server
1. [Installation](#installation)
1. [Basic usage](#basic-usage)
1. [Commands](#commands)

## Installation
- for Packer:
```lua
use { "GershM/deploy.nvim" }
```

## Basic usage
- Create 'deploy.json' file at the project's root folder or use ``CreateDeploymentConfig`` command.
- Deployment config file(deploy,json) example:
```json
[
    {
       "name": "Connection Name",
       "ipAddress": "Host/IP Address",
       "username": "Login User",
       "password": "User's password",
       "remoteRootPath": "",
       "isDefault": true,
       "uploadOnSave": false,
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
- ``CreateDeploymentConfig``: Creating basic configuration
- ``EditConfiguration``: Open the configuration file
- ``DownloadFile``: Download File from remote server
- ``UploadFile``: Upload File to a remote server
- ``SyncRemoteProject``: Uploading the project to remote server

