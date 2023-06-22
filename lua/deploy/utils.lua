local actions      = require 'telescope.actions'
local action_state = require 'telescope.actions.state'
local finders      = require 'telescope.finders'
local pickers      = require 'telescope.pickers'
local previewers   = require 'telescope.previewers'

local utils        = {}
local group        = vim.api.nvim_create_augroup("AutoUploadOnSave", {})

-- INFO: Read Configuration file
local function readUploadConfig()
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

-- INFO:
local function picker(func, forceTelescope, opts)
    opts = opts or {}

    local conf = readUploadConfig()
    if conf == nil then
        print("Empty Configuration")
        return
    end

    local count = 0
    local results = {}

    for _, v in ipairs(conf) do
        table.insert(results, v)
        if v.isDefault == true and forceTelescope == false then
            func(v)
            return
        end
        count = count + 1
    end

    if count == 0 then
        return
    end

    if count == 1 then
        func(results[1])
        -- print(vim.inspect(results[1].name))
        return
    end

    pickers.new(opts, {
        prompt_title    = 'Deployment Configurations',
        finder          = finders.new_table {
            results = results,
            entry_maker = function(entry)
                local config = ""
                if entry.isDefault then
                    config = " (Default)"
                    func(entry)
                    return
                end

                if entry.autoUpload then
                    config = config .. " (Auto Upload)"
                end

                return {
                    value = entry,
                    display = entry.name .. ": " .. entry.username .. "@" .. entry.host .. " " .. config,
                    ordinal = entry.name .. ": " .. entry.username .. "@" .. entry.host .. " " .. config,
                    preview_command = function(entry, bufnr)
                        local output = vim.split(vim.inspect(entry.value), '\n')
                        vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, output)
                    end
                }
            end,
        },
        attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                func(selection.value)
                -- print(vim.inspect(selection))
            end)
            return true
        end,
        previewer       = previewers.display_content.new(opts)
    }):find()
end

-- INFO: Create Ignore list parameters
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

-- INFO: Preparing the Deployment Command
local function deployment(conf, sourcePath, destinationPath)
    if sourcePath ~= nil and destinationPath ~= nil then
        local exclude = ignoreList(conf, "--exclude")
        local command = string.format("rsync  -avz -e ssh --delete --executability %s %s %s", exclude, sourcePath,
            destinationPath)
        utils.exec(command)
    end
end

-- INFO: Preparing the ssh command
function utils.SSHConnection(forceTelescope)
    local func = function(conf)
        local command = ""
        -- if conf.password then
        --     -- INFO: With Password
        --     command = string.format("ssh %s@%s", conf.username, conf.host)
        -- else
        -- INFO: Without password
        command = string.format("ssh %s@%s", conf.username, conf.host)
        -- end
        utils.exec(command)
    end
    picker(func, forceTelescope)
end

-- INFO: Executing the commands
function utils.exec(command)
    -- print(command)
    vim.cmd("belowright split |terminal " .. command)
end

-- INFO: Creating new configuration File
function utils.createConfig(ConfigFilePath)
    local f = io.open(ConfigFilePath, "w+")

    if f ~= nil then
        local json = [[
[
    {
        "name": "Connection Name",
        "host": "Host/IP Address",
        "username": "Login User",
        "password": "User's password",
        "remoteRootPath": "",
        "binary": "",
        "isDefault": false,
        "autoUpload": false,
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

local function ignoreRootPaths(path)
    return path:find("^" .. WorkingDirPath) == nil
end

local function deploymentValidation(conf, path)
    if conf == nil then
        return true
    end

    for key, value in ipairs(conf.ignore) do
        if path:find("^" .. value) ~= nil then
            print("Path '" .. path .. "' ignored")
            return true
        end
    end

    return false
end

function utils.DeployToRemote(relativePath, fullPath, remotePath, forceTelescope)
    local func = function(conf)
        if deploymentValidation(conf, relativePath) == true then
            return
        end

        local rPath = relativePath

        if remotePath ~= nil then
            rPath = remotePath
        end

        local destinationPath = string.format("%s@%s:%s/%s", conf.username, conf.host, conf.remoteRootPath, rPath)
        deployment(conf, relativePath, destinationPath)
    end

    if ignoreRootPaths(fullPath) == true then
        return
    end

    picker(func, forceTelescope)
end

function utils.DownloadFromRemote(relativePath, fullPath, forceTelescope)
    local func = function(conf)
        if deploymentValidation(conf, relativePath) == true then
            return
        end

        local sourcePath = string.format("%s@%s:%s/%s", conf.username, conf.host, conf.remoteRootPath, relativePath)
        deployment(conf, sourcePath, relativePath)
    end

    if ignoreRootPaths(fullPath) == true then
        return
    end

    picker(func, forceTelescope)
end

-- INFO: Auto Deployment
-- Deploying only the first configuration with autoUpload and isDefault parameters are true
function utils.autoDeploy(func)
    vim.api.nvim_create_autocmd('BufWritePre', {
        pattern = '*.*',
        group = group,
        callback = function()
            local conf = readUploadConfig()
            if conf == nil then
                return
            end

            for _, v in ipairs(conf) do
                if v.autoUpload and v.isDefault then
                    func(false)
                    return
                end
            end
        end,
    })
end

return utils
