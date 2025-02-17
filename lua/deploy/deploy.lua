M = {}
local config = require("deploy.config")

local function get_relative_path()
	-- INFO: Full absolute path of the current file
	local absolute_path = vim.fn.expand("%:p")

	-- INFO: Convert to relative path
	return vim.fn.fnamemodify(absolute_path, ":.")
end

local function normalize_path(path)
	if not path or path == "" then
		return "\\"
	end

	if vim.fn.has("win32") == 1 then
		path = path:gsub("/", "\\")
		if not path:match("\\$") then
			path = path .. "\\"
		end
	else
		if not path:match("/$") then
			path = path .. "/"
		end
	end

	return path
end

local function get_upload_command(cfg, isUpload, isSync, path)
	local base_cmd = ""
	local server = cfg.servers[cfg.default]
	if not server then
		print("No default server configured. Opening server selection...")
		require("deploy.telescope").select_server()
		return
	end

	local sshpass = ""
	local m = server.method or "rsync"
	local server_path = normalize_path(server.path)
	if not isSync then
		server_path = server_path .. path
		path = "./" .. path
	else
		path = "./"
		path = normalize_path(path)
	end

	if m == "rsync" then
		local ignore_cmd = ""
		local used_ignore = {}

		for _, v in ipairs(cfg.global_ignore) do
			ignore_cmd = ignore_cmd .. " --exclude " .. v
			used_ignore[v] = true
		end

		for _, v in ipairs(server.ignore) do
			if not used_ignore[v] then
				ignore_cmd = ignore_cmd .. " --exclude " .. v
			end
		end

		if server.password and server.password ~= "" then
			sshpass = "sshpass -p " .. server.password .. " "
		end

		base_cmd = sshpass .. "rsync -avz --progress" .. ignore_cmd
		if isUpload then
			base_cmd = string.format(base_cmd .. " %s %s@%s:%s", path, server.user, server.host, server_path)
		else
			print("path", path)
			base_cmd = string.format(base_cmd .. " %s@%s:%s %s", server.user, server.host, server_path, path)
		end
	elseif m == "sftp" then
		base_cmd = [[sftp -oBatchMode=no %s@%s <<EOF
%s
exit
EOF
]]

		-- INFO: Determine the SFTP action (upload or download)
		local action = ""
		if isUpload then
			local str = "put -r %s %s"
			action = string.format(str, path, server_path)
		else
			local str = "get -r %s %s"
			action = string.format(str, server_path, path)
		end

		-- INFO: Format the command with the appropriate variables
		base_cmd = string.format(base_cmd, server.user, server.host, action)
		if server.password and server.password ~= "" then
			base_cmd = "sshpass -p " .. server.password .. " " .. base_cmd
		end
	else
		print("Invalid method")
		return
	end

	return base_cmd
end

function M.files(path, isUpload, isSync)
	if not isSync and (path == nil or path == "") then
		path = get_relative_path()
		if path == "" then
			print("No file to upload")
			return
		end
	end

	local cfg = config.load_config() or config.init_config()
	if not cfg then
		print("No configuration found. Run 'deploy config init' to create a new configuration.")
		return
	end

	if cfg.servers == nil or #cfg.servers == 0 then
		print("No servers configured. Run 'deploy config add' to add a new server.")
		return
	end

	if cfg.default == nil or cfg.default == 0 then
		print("No default server configured. Select a default server.")
		require("deploy.telescope").select_server()
		cfg = config.load_config() or config.init_config()
	end

	local cmd = get_upload_command(cfg, isUpload, isSync, path)
	if not cmd or cmd == "" then
		return
	end

	local opts = {
		on_stdout = function(_, data)
			local msg = table.concat(data, "\n")
			if msg ~= "" then
				print("Output:", table.concat(data, "\n"))
			end
		end,
		on_stderr = function(_, data)
			local msg = table.concat(data, "\n")
			if msg ~= "" then
				print("Error:", msg)
			end
		end,
		on_exit = function(_, code)
			if code == 0 then
				if isUpload then
					print("Upload completed successfully.")
				else
					print("Download completed successfully.")
				end
			else
				if isUpload then
					print("Upload failed with exit code:", code)
				else
					print("Download failed with exit code:", code)
				end
			end
		end,
	}
	vim.o.autoread = true
	vim.fn.jobstart(cmd, opts)
	vim.cmd("e! " .. path)
end

return M
