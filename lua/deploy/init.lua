local vim = vim

local M = {}

WorkingDirPath = vim.fn.getcwd()

ConfigFileName = "deploy.json"
ConfigFilePath = string.format("%s/%s", WorkingDirPath, ConfigFileName)

local function DeploymentLogs(log, path)
    -- print(string.format("[%s] %s %s\n", os.date(), log, path))
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
        for _, v in conf.ignore do
            local ex = type:gsub(ptx, v)
            exclude = string.format("%s %s", exclude, ex)
        end
    end
    return exclude
end

local function GetMethodARGS(method, conf)
    local args = ""
    local exclude = ""
    if method == "scp"
    then
        exclude = buildExclude(conf, "!([ptx])")
        args = string.format("-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -rC %s", exclude)
    elseif method == "rsync" then
        exclude = buildExclude(conf, "--exclude=[ptx]")
        args = string.format("-a -e ssh %s", exclude)
    end
    return args
end

local function methodExists(method)
    local cmd = os.execute(string.format("which %s", method))
    return cmd == 0
end

local function GetMethod(conf)
    local method = ""
    local count = 2
    local missingMethod = false

    if conf.method == nil then
        conf.method = "scp"
    end

    while count >= 0 do
        if ((conf.method == "scp" or missingMethod) and methodExists("scp"))
        then
            method = "scp"
            break
        elseif ((conf.method == "rsync" or missingMethod) and methodExists("rsync"))
        then
            method = "rsync"
            break
        end
        missingMethod = true
        count = count - 1
    end
    if method == "" then
        return
    elseif conf.method ~= method and missingMethod
    then
        print(string.format("The %s application doesn't exists, Using %s instead", conf.method, method))
    end

    return method
end

local function DeployDownload(conf, sourcePath, destinationPath)
    if sourcePath ~= nil and destinationPath ~= nil
    then
        local method = GetMethod(conf)
        if method == nil
        then
            print("Failed to find the method's application")
            return
        end

        local args = GetMethodARGS(method, conf)
        local command = string.format("%s %s %s %s", method, args, sourcePath, destinationPath)
        vim.api.nvim_command("! "..command)
    end
end

local function DeployByProtocolToRemote(path)
    local conf = GetUsedConf()
    if conf ~= nil
    then
        DeploymentLogs("[Local -> Remote]: ", path)
        local destinationPath = string.format("%s@%s:%s/%s", conf.username, conf.ipAddress, conf.remoteRootPath, path)
        local sourcePath = string.format("%s/%s", conf.localRootPath, path)
        DeployDownload(conf, sourcePath, destinationPath)
    end
end

local function DownloadByProtocolFromRemote(path)
    local conf = GetUsedConf()
    if conf ~= nil
    then
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
    print(WorkingDirPath)
    local f = io.open(ConfigFilePath, "w+")
    if f ~= nil then
        local json = {
            {
                name = "Connection Name",
                method = "scp",
                ipAddress = "Host/IP Address",
                username = "Login User",
                password = "User's password",
                sshKey = "SSH Key Path",
                localRootPath = "",
                remoteRootPath = "",
                isDefault = true,
                uploadOnSave = false,
                ignore = {
                    "**/.git/**",
                    "**/node_modules/**",
                    "**/vendeor/**",
                    "**/.vsCode/**",
                    "**/.idea/**",
                    string.format("**/%s", ConfigFileName),
                }
            },
        }
        local jsonString = vim.fn.json_encode(json)
        io.output(f)
        io.write(jsonString)
        io.close(f)
        vim.cmd(string.format("e %s", ConfigFilePath))
    else
        print("Failed to Create Configuration File\n")

        print(io.open(ConfigFilePath, "w"))
    end

end

function EditConfiguration()
    local f = io.open(ConfigFilePath, "r")
    print(io.open(ConfigFilePath, "r"))
    if f ~= nil then
        vim.cmd(string.format("e %s", ConfigFilePath))
    else
        print("The Configuration File doesn't exists")
    end
end

M.setup = function(config)
    if config ~= nil then
        if config.filename ~= nil then
            ConfigFileName = config.filename
        end
    end

    vim.cmd("command! UploadFile lua UploadFile()")
    vim.cmd("command! DownloadFile lua DownloadFile()")

    -- vim.cmd("command! DRemoteUploadFolder lua UploadFolder()")
    -- vim.cmd("command! DRemoteDownloadFolder lua DownloadFolder()")
    -- vim.cmd("command! DRemoteUploadProject lua UploadProject()")
    -- vim.cmd("command! DRemoteDownloadProject lua DownloadProject()")
    -- vim.cmd("command! DCreateConfiguration lua CreateConfiguration()")
    -- vim.cmd("command! DEditConfiguration lua EditConfiguration()")
end

return M;
