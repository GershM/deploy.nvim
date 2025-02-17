<h1 align="center">(Neo)vim remote deployment Plugin</h1>

# Info
- This plugin is a simple deployment plugin for neovim.
- It uses rsync and sftp to upload and download files.
- It supports:
    - Multiple servers.
    - Auto-upload.
    - Global ignore for all the registered servers.
- It is still in development, so there might be some bugs.
- Feel free to open an issue or a pull request.

1. [Installation](#installation)
1. [Basic usage](#basic-usage)
1. [Commands](#commands)

## Installation
- For Lazy:
```lua
    {
        "https://github.com/GershM/deploy.nvim",
        config = function()
            require("deploy")
        end
    },
```
- Make sure rsync is installed.

## Basic usage
- Create 'deploy.json' file at the project's root folder or use the ``Deploy Create`` command.
- Deployment configuration file(deploy.json) example:
```json
{
    "auto_upload": false,
    "global_ignore": [
                ".git",
                "node_modules",
                "html/assets",
                "lib",
                ".vsCode",
                ".idea",
                "deploy.json"
    ],
    "default": 1,
    "servers": [
        {
            "ignore": [],
            "host": "host",
            "path": "/var/www/",
            "password":"password",
            "user": "root",
            "name": "connection name",
            "method": "rsync"
        }
    ]
}
```

## Commands
- Configuration:
    - ``Deploy init``: Creating basic configuration.
    - ``Deploy add``: Add a new server to the configuration file.
    - ``Deploy edit``: Open the configuration file.
    - ``Deploy auto_upload_toggle``: Toggle auto upload.

- Deployment:
    - ``Deploy download``: Download File from remote server.
    - ``Deploy download all``: Download the project from remote server.
    - ``Deploy upload``: Upload File to a remote server.
    - ``Deploy upload all``: Uploading the project to remote server.
