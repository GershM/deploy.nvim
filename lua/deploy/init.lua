local utils = require("deploy.utils")
local M = {}

WorkingDirPath = vim.fn.getcwd()
ConfigFileName = "deploy.json"
ConfigFilePath = string.format("%s/%s", WorkingDirPath, ConfigFileName)

function M.UploadFile()
    local relativePath = vim.fn.expand('%:p:.')
    local fullPath = vim.fn.expand('%:p')
    utils.DeployToRemote(relativePath, fullPath)
end

function M.DownloadFile()
    local path = vim.fn.expand('%:p:.')
    local fullPath = vim.fn.expand('%:p')
    utils.DownloadFromRemote(path, fullPath)
end

function M.SyncRemote()
    utils.DeployToRemote(WorkingDirPath, WorkingDirPath, "")
end

function M.SyncLocal()
    local fullPath = vim.fn.expand('%:p')
    utils.DownloadFromRemote(WorkingDirPath, fullPath)
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

function M.ExecuteFile()
    local path = vim.fn.expand('%:p:.')
    local conf = utils.GetUsedConf()
    if conf ~= nil then
        local command = string.format("ssh %s@%s \"%s %s/%s\"", conf.username, conf.ipAddress, conf.binary,
            conf.remoteRootPath, path)
        utils.exec(command)
    end
end

-- TODO: Add Auto Upload Toggle Functionality

M.setup = function(config)
    if config == nil then
        config = utils.GetUsedConf()
    end

    if config ~= nil then
        if config.filename ~= nil then
            ConfigFileName = config.filename
        end

        utils.autoUpload(config.uploadOnSave)
    end

    vim.api.nvim_create_user_command("CreateDeploymentConfig", function() M.CreateConfiguration() end, {})
    vim.api.nvim_create_user_command("EditConfiguration", function() M.EditConfiguration() end, {})
    vim.api.nvim_create_user_command("DownloadFile", function() M.DownloadFile() end, {})
    vim.api.nvim_create_user_command("UploadFile", function() M.UploadFile() end, {})
    vim.api.nvim_create_user_command("SyncRemote", function() M.SyncRemote() end, {})
    vim.api.nvim_create_user_command("SyncLocal", function() M.SyncLocal() end, {})
    vim.api.nvim_create_user_command("ExecuteRemote", function() M.ExecuteFile() end, {})
end

return M;
