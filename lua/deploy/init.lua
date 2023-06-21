local utils = require("deploy.utils")
local M = {}

WorkingDirPath = vim.fn.getcwd()
ConfigFileName = "deploy.json"
ConfigFilePath = string.format("%s/%s", WorkingDirPath, ConfigFileName)

function M.UploadFile(forceTelescope)
    local relativePath = vim.fn.expand('%:p:.')
    local fullPath = vim.fn.expand('%:p')

    utils.DeployToRemote(relativePath, fullPath, "", forceTelescope)
end

function M.DownloadFile(forceTelescope)
    local path = vim.fn.expand('%:p:.')
    local fullPath = vim.fn.expand('%:p')

    utils.DownloadFromRemote(path, fullPath, forceTelescope)
end

function M.SyncRemote(forceTelescope)
    utils.DeployToRemote(WorkingDirPath .. "/", WorkingDirPath, "", forceTelescope)
end

function M.SyncLocal(forceTelescope)
    local fullPath = vim.fn.expand('%:p')
    utils.DownloadFromRemote(WorkingDirPath .. "/", fullPath, forceTelescope)
end

function M.CreateConfiguration()
    utils.createConfig(ConfigFilePath)
end

function M.EditConfiguration()
    local f = io.open(ConfigFilePath, "r")
    if f ~= nil then
        vim.cmd(string.format("e %s", ConfigFilePath))
    else
        print("The Configuration File doesn't exists")
    end
end

function M.ExecuteFile(forceTelescope)
    local path = vim.fn.expand('%:p:.')
    local func = function(conf)
        local command = string.format("ssh %s@%s \"%s %s/%s\"", conf.username, conf.host, conf.binary,
            conf.remoteRootPath, path)
        utils.exec(command)
    end
    utils.picker(func, forceTelescope)
end

function M.SSHConnection(forceTelescope)
    utils.SSHConnection(forceTelescope)
end

function Deployment(opts)
    local args = opts.args or nil
    if args == nil then
        return
    end


    local s = string.lower(args)
    local cmd = {}
    for substring in s:gmatch("%S+") do
        table.insert(cmd, substring)
    end

    local forceTelescope = false
    if cmd[2] == "force" then
        forceTelescope = true
    end

    if cmd[1] == "upload" then
        M.UploadFile(forceTelescope)
    elseif cmd[1] == "download" then
        M.DownloadFile(forceTelescope)
    elseif cmd[1] == "create" then
        M.CreateConfiguration()
    elseif cmd[1] == "edit" then
        M.EditConfiguration()
    elseif cmd[1] == "remotesync" then
        M.SyncRemote(forceTelescope)
    elseif cmd[1] == "localsync" then
        M.SyncLocal(forceTelescope)
    elseif cmd[1] == "exec" then
        M.ExecuteFile(forceTelescope)
    elseif cmd[1] == "connect" then
        M.SSHConnection(forceTelescope)
    elseif cmd[1] == "remoteedit" then
        --   vim scp://user@myserver[:port]//path/to/file.txt
        -- M.SSHConnection(forceTelescope)
    end
end

-- TODO: Add Auto Upload Toggle Functionality
M.setup = function(config)
    utils.autoDeploy(M.UploadFile)
    vim.api.nvim_create_user_command("Deploy", Deployment, { nargs = '?' })
end

return M;
