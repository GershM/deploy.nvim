local M = {}

-- INFO: Load modules
M.config = require("deploy.config")
M.deploy = require("deploy.deploy")
M.utils = require("deploy.utils")

-- INFO: Subcommand dispatcher
local function dispatch_subcommand(args)
	local subcommands = {
		upload = function()
			if args.fargs[2] == "all" then
				M.deploy.files(nil, true, true)
			else
				-- INFO: Optional file argument
				M.deploy.files(args.fargs[2], true, false)
			end
		end,
		download = function()
			if args.fargs[2] == "all" then
				M.deploy.files(nil, false, true)
			else
				-- INFO: Optional file argument
				M.deploy.files(args.fargs[2], false, false)
			end
		end,
		config = function()
			local config_action = args.fargs[2]
			if config_action == "init" then
				M.config.init_config()
			elseif config_action == "add" then
				require("deploy.add_connection").add_connection_popup()
			elseif config_action == "edit" then
				M.config.edit_config()
			else
				print("Invalid config subcommand. Use 'init', 'add', or 'edit'.")
			end
		end,
		select = function()
			require("deploy.telescope").select_server()
		end,
		auto_upload_toggle = function()
			M.utils.toggle_auto_upload()
		end,
	}

	local subcommand = args.fargs[1]
	if subcommands[subcommand] then
		subcommands[subcommand]()
	else
		print("Invalid subcommand. Use 'upload', 'download', 'config', or 'select'.")
	end
end

-- Command completion function
function Deploy_complete(arglead, _, _)
	local cfg = M.config.load_config() or {}
	local servers = cfg.servers or {}

	-- INFO: Static subcommands
	local static_completions = {
		"upload",
		"upload all",
		"download",
		"download all",
		"config init",
		"config add",
		"config edit",
		"select",
		"auto_upload_toggle",
	}

	-- INFO: Dynamic server name completions
	local server_names = vim.tbl_map(function(server)
		return server.name
	end, servers)

	-- INFO: Combine static and dynamic completions
	local all_completions = vim.fn.extend(static_completions, server_names)
	return vim.tbl_filter(function(item)
		if not item then
			return false
		end

		if not arglead then
			return true
		end

		return string.sub(item, 1, string.len(arglead)) == arglead
	end, all_completions)
end

-- INFO: Register the top-level Deploy command
function M.setup()
	vim.api.nvim_create_user_command("Deploy", function(args)
		dispatch_subcommand(args)
	end, { nargs = "*", complete = "customlist,v:lua.Deploy_complete" })

	-- INFO: Initialize auto-upload
	M.utils.autoDeploy(function(server)
		print("Auto-uploading to server: " .. server.name)
		M.deploy.files(nil, true, false)
	end)
end

return M
