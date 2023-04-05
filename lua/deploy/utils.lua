local actions      = require 'telescope.actions'
local action_state = require 'telescope.actions.state'
local finders      = require 'telescope.finders'
local pickers      = require 'telescope.pickers'
local previewers   = require 'telescope.previewers'

local utils        = {}

utils.output       = nil
utils.bufnr        = nil

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

local function picker(func, opts)
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
        count = count + 1
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
                end
                if entry.uploadOnSave then
                    config = config .. " (Auto Upload)"
                end

                return {
                    value = entry,
                    display = entry.name .. ": " .. entry.username .. "@" .. entry.ipAddress .. " " .. config,
                    ordinal = entry.name .. ": " .. entry.username .. "@" .. entry.ipAddress .. " " .. config,
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

function utils.GetUsedConf()
    local conf = readUploadConfig()
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

local function enableAutoUpload()
    vim.api.nvim_create_augroup("autoUpload", {})
    vim.api.nvim_create_autocmd("BufWritePost", {
        group = "autoUpload",
        pattern = '*',
        callback = function()
            local path = vim.fn.expand('%:p:.')
            utils.DeployToRemote(path, true, true)
        end,
    })
end

local function clearAutoGroup(name)
    vim.schedule(function()
        pcall(function()
            vim.api.nvim_clear_autocmds { group = name }
        end)
    end)
end

local function disableAutoUpload()
    clearAutoGroup("autoUpload")
end

function utils.autoUpload(enable)
    local exists, autocmds = pcall(vim.api.nvim_get_autocmds, {
        group = "autoUpload",
        event = "BufWritePre",
    })
    if enable then
        if not exists or #autocmds == 0 then
            enableAutoUpload()
        end
    else
        disableAutoUpload()
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

local function getMethodARGS(conf)
    local exclude = ignoreList(conf, "--exclude")
    local args = string.format(" -avz -e ssh --delete --executability %s", exclude)
    return args
end

local function deployment(conf, sourcePath, destinationPath)
    utils.autoUpload(conf.uploadOnSave)
    if sourcePath ~= nil and destinationPath ~= nil then
        local method = "rsync"
        local args = getMethodARGS(conf)
        local command = string.format("%s %s %s %s", method, args, sourcePath, destinationPath)
        utils.exec(command)
    end
end

function utils.exec(command)
    vim.cmd("! " .. command)
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

local function ignoreRootPaths(path)
    return path:find("^"..WorkingDirPath) == nil
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

function utils.DeployToRemote(relativePath, fullPath, remotePath, default)
    local func = function(conf)
        if deploymentValidation(conf, relativePath) == true then
            return
        end

        local rPath = relativePath

        if remotePath ~= nil then
            rPath = remotePath
        end

        local destinationPath = string.format("%s@%s:%s/%s", conf.username, conf.ipAddress, conf.remoteRootPath, rPath)
        deployment(conf, relativePath, destinationPath)
    end
    if ignoreRootPaths(fullPath) == true then
        return
    end
    picker(func, default)
end

function utils.DownloadFromRemote(relativePath, fullPath, default)
    local func = function(conf)
        if deploymentValidation(conf, relativePath) == true then
            return
        end
        local sourcePath = string.format("%s@%s:%s/%s", conf.username, conf.ipAddress, conf.remoteRootPath, relativePath)
        deployment(conf, sourcePath, relativePath)
    end

    if ignoreRootPaths(fullPath) == true then
        return
    end
    picker(func, default)
end

return utils
