local vim = vim

local M = {}

WorkingDirPath = vim.fn.getcwd()

ConfigFileName = "deploy.json"
ConfigFilePath = string.format("%s/%s", WorkingDirPath, ConfigFileName)

local function enable_on_save()
    vim.api.nvim_create_augroup("upload_on_save", {})
    vim.api.nvim_create_autocmd("BufWritePre", {
        group = "upload_on_save",
        pattern = '*',
        callback = function()
            UploadFile()
        end,
    })
end

local function clear_augroup(name)
    vim.schedule(function()
        pcall(function()
            vim.api.nvim_clear_autocmds { group = name }
        end)
    end)
end

local function disable_on_save()
    clear_augroup "upload_on_save"
end

local function toggle_upload_on_save(enable)
    local exists, autocmds = pcall(vim.api.nvim_get_autocmds, {
        group = "upload_on_save",
        event = "BufWritePre",
    })
    if enable then
        if not exists or #autocmds == 0 then
            enable_on_save()
        end
    else
        disable_on_save()
    end
end

local function ParseConfiguration()
    local f = io.open(ConfigFilePath, "r")
    if f ~= nil
    then
        io.input(f)
        local json = io.read("a")
        local conf = vim.fn.json_decode(json)
        io.close(f)
        if conf ~= nil
        then
            return conf
        end
    end

end

local function GetUsedConf()
    local conf = ParseConfiguration()
    if conf ~= nil
    then
        for _, value in ipairs(conf) do
            if value.isDefault == true
            then
                return value
            end
        end
    end
end

local function ignoreList(conf, type)
    local exclude = ""
    if conf.ignore ~= nil then
        for _, v in ipairs(conf.ignore) do
            local ex = string.format("%s%s \"%s\" ", exclude, type, v)
            exclude = ex
        end
    end
    return exclude
end

local function GetMethodARGS(conf)
    local exclude = ignoreList(conf, "--exclude")
    local args = string.format(" -a -z --no-o --no-g -r %s", exclude)
    return args
end

local function DeployDownload(conf, sourcePath, destinationPath)
    toggle_upload_on_save(conf.uploadOnSave)
    if sourcePath ~= nil and destinationPath ~= nil then
        local method = "rsync"
        local args = GetMethodARGS(conf)
        local command = string.format("!%s %s %s %s", method, args, sourcePath, destinationPath)
        vim.api.nvim_command(command)
    end
end

local function DeployByProtocolToRemote(path)
    local conf = GetUsedConf()
    if conf ~= nil then
        local destinationPath = string.format("%s@%s:%s/%s", conf.username, conf.ipAddress, conf.remoteRootPath, path)
        DeployDownload(conf, path, destinationPath)
    end
end

local function DownloadByProtocolFromRemote(path)
    local conf = GetUsedConf()
    if conf ~= nil then
        local sourcePath = string.format("%s@%s:%s/%s", conf.username, conf.ipAddress, conf.remoteRootPath, path)
        DeployDownload(conf, sourcePath, path)
    end
end

function UploadFile()
    local path = vim.fn.expand('%:p:.')
    DeployByProtocolToRemote(path)
end

function ExecuteFile()
    local path = vim.fn.expand('%:p:.')
    local conf = GetUsedConf()
    if conf ~= nil then
        local command = string.format("!ssh %s@%s \"%s %s/%s\"", conf.username, conf.ipAddress, conf.binary, conf.remoteRootPath, path)
        vim.api.nvim_command(command)
    end
end

function DownloadFile()
    local path = vim.fn.expand('%:p:.')
    DownloadByProtocolFromRemote(path)
end

function SyncRemoteProject()
    local path = ""
    DeployByProtocolToRemote(path)
end

function CreateConfiguration()
    local f = io.open(ConfigFilePath, "w+")

    if f ~= nil then
        local json = [[
        [
            {
                name = "Connection Name",
                ipAddress = "Host/IP Address",
                username = "Login User",
                password = "User's password",
                remoteRootPath = "",
                binary = "",
                isDefault = true,
                uploadOnSave = false,
                ignore = {
                    ".git",
                    "node_modules",
                    "vendeor",
                    ".vsCode",
                    ".idea",
                    "deploy.json"
                }
            }
        ]
        ]]
        io.output(f)
        io.write(json)
        io.close(f)
        vim.cmd(string.format("e %s", ConfigFilePath))
    else
        print("Failed to Create Configuration File\n")
        print(io.open(ConfigFilePath, "w"))
    end

end

function EditConfiguration()
    local f = io.open(ConfigFilePath, "r")
    if f ~= nil then
        vim.cmd(string.format("e %s", ConfigFilePath))
    else
        print("The Configuration File doesn't exists")
    end
end

M.setup = function(config)
    if config == nil then
        config = GetUsedConf()
    end

    if config ~= nil then
        if config.filename ~= nil then
            ConfigFileName = config.filename
        end

        toggle_upload_on_save(config.uploadOnSave)
    end

    vim.cmd("command! CreateDeploymentConfig lua CreateConfiguration()")
    vim.cmd("command! EditConfiguration lua EditConfiguration()")
    vim.cmd("command! DownloadFile lua DownloadFile()")
    vim.cmd("command! UploadFile lua UploadFile()")
    vim.cmd("command! SyncRemoteProject lua SyncRemoteProject()")
    vim.cmd("command! ExecuteRemoteFile lua ExecuteFile()")
end

return M;
