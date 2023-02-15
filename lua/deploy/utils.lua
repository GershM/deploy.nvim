local utils = {}

utils.output = nil
utils.bufnr = nil

local win = nil
local width = 120
local height = 10

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

function utils.GetUsedConf()
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

local function enable_on_save()
    vim.api.nvim_create_augroup("upload_on_save", {})
    vim.api.nvim_create_autocmd("BufWritePost", {
        group = "upload_on_save",
        pattern = '*',
        callback = function()
            local path = vim.fn.expand('%:p:.')
            utils.DeployByProtocolToRemote(path)
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
    clear_augroup("upload_on_save")
end

function utils.toggle_upload_on_save(enable)
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
    local args = string.format(" -avz -e ssh --delete --executability %s", exclude)
    return args
end

local function DeployDownload(conf, sourcePath, destinationPath)
    utils.toggle_upload_on_save(conf.uploadOnSave)
    if sourcePath ~= nil and destinationPath ~= nil then
        local method = "rsync"
        local args = GetMethodARGS(conf)
        --local command = "ls -l"
        local command = string.format("%s %s %s %s", method, args, sourcePath, destinationPath)
        utils.exec(command)
    end
end

function utils.exec(command)
    vim.cmd("! " .. command)
    --utils.createFloatingWindow()
    --vim.fn.jobstart(command, {
    --stdout_buffered = true,
    --on_stdout = function(_, data)
    --table.insert(data, 1, command)
    --vim.api.nvim_buf_set_lines(bufnr, 0, 0, false, data)
    --output = data
    --end,
    --on_exit = function()
    --vim.cmd.sleep(1)
    --vim.api.nvim_win_close(win, true)
    --end
    --})
end

function utils.createConfig(ConfigFilePath)
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

function utils.createFloatingWindow()
    if bufnr == nil then
        bufnr = vim.api.nvim_create_buf(false, true)
    end

    local opts = {
        relative = 'win',
        width = width,
        height = height,
        col = 20,
        row = 20,
        anchor = 'NW',
        border = { "╔", "═", "╗", "║", "╝", "═", "╚", "║" },
        focusable = false,
        noautocmd = true
    }

    win = vim.api.nvim_open_win(bufnr, true, opts)
end

function utils.DeployByProtocolToRemote(path, remotePath)
    local conf = utils.GetUsedConf()
    if conf ~= nil then
        local rPath = path

        if remotePath  ~= nil then
            rPath = remotePath
        end

        local destinationPath = string.format("%s@%s:%s/%s", conf.username, conf.ipAddress, conf.remoteRootPath, rPath)
        DeployDownload(conf, path, destinationPath)
    end
end

function utils.DownloadByProtocolFromRemote(path)
    local conf = utils.GetUsedConf()
    if conf ~= nil then
        local sourcePath = string.format("%s@%s:%s/%s", conf.username, conf.ipAddress, conf.remoteRootPath, path)
        DeployDownload(conf, sourcePath, path)
    end
end

return utils
