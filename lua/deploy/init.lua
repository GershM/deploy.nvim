local utils = require("deploy.utils")
local M = {}

WorkingDirPath = vim.fn.getcwd()
ConfigFileName = "deploy.json"
ConfigFilePath = string.format("%s/%s", WorkingDirPath, ConfigFileName)

function M.UploadFile()
    local path = vim.fn.expand('%:p:.')
    utils.DeployByProtocolToRemote(path)
end

function M.DownloadFile()
    local path = vim.fn.expand('%:p:.')
    utils.DownloadByProtocolFromRemote(path)
end

function M.SyncRemoteProject()
    local path = ""
    utils.DeployByProtocolToRemote(path)
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

function M.resault()
    if utils.output ~= nil then
        utils.createFloatingWindow()
        vim.api.nvim_buf_set_lines(utils.bufnr, 0, -1, false, utils.output)
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

M.setup = function(config)
    if config == nil then
        config = utils.GetUsedConf()
    end

    if config ~= nil then
        if config.filename ~= nil then
            ConfigFileName = config.filename
        end

        utils.toggle_upload_on_save(config.uploadOnSave)
    end

    vim.api.nvim_create_user_command("DeploymentResault", function() M.resault() end, {})
    vim.api.nvim_create_user_command("CreateDeploymentConfig", function() M.CreateConfiguration() end, {})
    vim.api.nvim_create_user_command("EditConfiguration", function() M.EditConfiguration() end, {})
    vim.api.nvim_create_user_command("DownloadFile", function() M.DownloadFile() end, {})
    vim.api.nvim_create_user_command("UploadFile", function() M.UploadFile() end, {})
    vim.api.nvim_create_user_command("SyncRemoteProject", function() M.SyncRemoteProject() end, {})
    vim.api.nvim_create_user_command("ExecuteRemoteFile", function() M.ExecuteFile() end, {})

end

return M;
