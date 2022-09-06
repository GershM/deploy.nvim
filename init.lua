Path = vim.fn.expand('%:h')
ConfigFileName = string.format("%s/deploy.json", Path)

local function ParseConfiguration()
    local f = io.open(ConfigFileName, "r")
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
    else
        print("failed to Read file")
    end

end

local function DeployDownload(sourcePath, destinationPath)
    local protocol = "scp -rC "
    if sourcePath ~= nil and destinationPath ~= nil
    then
        local command = string.format("%s %s %s", protocol, sourcePath, destinationPath)
        print(command)
        os.execute(command)
        local result = vim.fn.systemlist(command)
        for k, v in pairs(result) do
            print( '  ' .. result[k])
        end
    end
end

local function DeploymentLogs(log, path)
    print(string.format("[%s] %s %s\n", os.date(), log, path))
end

local function DeployByProtocolToRemote(path)
    local conf = ParseConfiguration()

    if conf ~= nil
    then
        DeploymentLogs("[Local -> Remote]: ", path)
        local destinationPath = string.format("%s@%s:%s/%s", conf.username, conf.ipAddress, conf.remoteRootPath, path)
        local sourcePath = string.format("%s/%s", conf.localRootPath, path)
        DeployDownload(sourcePath, destinationPath)
    else
        print("conf is null")
    end
end

local function DownloadByProtocolFromRemote(path)
    local conf = ParseConfiguration()
    if conf ~= nil
    then
        DeploymentLogs("[Remote -> Local]: ", path)
        local sourcePath = string.format("%s@%s:%s/%s", conf.username, conf.ipAddress, conf.remoteRootPath, path)
        local destinationPath = string.format("%s/%s", conf.localRootPath, path)
        DeployDownload(sourcePath, destinationPath)
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

function CreateConfiguration() end

function EditConfiguration() end

vim.api.nvim_create_user_command('RUploadFile', UploadFile,
    { bang = true, desc = 'Upload Current File To Remote Server' })
