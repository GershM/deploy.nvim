local vim = vim

local M = {}

WorkingDirPath = vim.fn.getcwd()

ConfigFileName = "deploy.json"
ConfigFilePath = string.format("%s/%s", WorkingDirPath, ConfigFileName)

local function DeploymentLogs(log, path)
    -- print(string.format("[%s] %s %s\n", os.date(), log, path))
    --   vim.fn.log(string.format("[%s] %s %s\n", os.date(), log, path))
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

local function buildExclude(conf, type)
    local exclude = ""
    local ptx = "[ptx]"
    if conf.ignore ~= nil then
        for _, v in ipairs(conf.ignore) do
            local ex = type:gsub(ptx, v)
            exclude = string.format("%s %s", exclude, ex)
        end
    end
    return exclude
end

local function GetMethodARGS(conf)
    local exclude = buildExclude(conf, "--exclude=[ptx]")
    local args = string.format(" -av --no-o --no-g %s", exclude)
    return args
end

local function DeployDownload(conf, sourcePath, destinationPath)
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
        DeploymentLogs("[Local -> Remote]: ", path)
        local destinationPath = string.format("%s@%s:%s/%s", conf.username, conf.ipAddress, conf.remoteRootPath, path)
        local sourcePath = string.format("%s/%s", conf.localRootPath, path)
        DeployDownload(conf, sourcePath, destinationPath)
    end
end

local function DownloadByProtocolFromRemote(path)
    local conf = GetUsedConf()
    if conf ~= nil then
        DeploymentLogs("[Remote -> Local]: ", path)
        local sourcePath = string.format("%s@%s:%s/%s", conf.username, conf.ipAddress, conf.remoteRootPath, path)
        local destinationPath = string.format("%s/%s", conf.localRootPath, path)
        DeployDownload(conf, sourcePath, destinationPath)
    end
end

function UploadFile()
    local path = vim.fn.expand('%:p:.')
    DeployByProtocolToRemote(path)
end

function DownloadFile()
    local path = vim.fn.expand('%:p:.')
    DownloadByProtocolFromRemote(path)
end

function UploadFolder()
    local path = vim.fn.expand('%:p:.:h')
    DeployByProtocolToRemote(path)
end

function DownloadFolder()
    local path = vim.fn.expand('%:p:.:h')
    DownloadByProtocolFromRemote(path)
end

function UploadProject()
    local path = ""
    DeployByProtocolToRemote(path)
end

function DownloadProject()
    local path = ""
    DownloadByProtocolFromRemote(path)
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
                sshKey = "SSH Key Path",
                remoteRootPath = "",
                isDefault = true,
                uploadOnSave = false,
                ignore = {
                    "**/.git/**",
                    "**/node_modules/**",
                    "**/vendeor/**",
                    "**/.vsCode/**",
                    "**/.idea/**",
                }
            },
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

        if config.uploadOnSave == true then
            vim.api.nvim_create_autocmd("BufWritePre", {
                pattern = "*",
                callback = function()
                    UploadFile()
                    -- vim.schedule(CodeRunner)
                end,
            })
            -- vim.cmd("autocmd BufWritePre lua UploadFile()")
        end
    end

    vim.cmd("command! CreateDeploymentConfig lua CreateConfiguration()")
    -- vim.cmd("command! DEditConfiguration lua EditConfiguration()")

    vim.cmd("command! DownloadFile lua DownloadFile()")
    vim.cmd("command! UploadFile lua UploadFile()")

    -- vim.cmd("command! DRemoteUploadFolder lua UploadFolder()")
    -- vim.cmd("command! DRemoteDownloadFolder lua DownloadFolder()")
    -- vim.cmd("command! DRemoteUploadProject lua UploadProject()")
    -- vim.cmd("command! DRemoteDownloadProject lua DownloadProject()")
end

return M;
