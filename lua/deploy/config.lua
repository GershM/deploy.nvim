local M = {}
local default_config = {
	servers = {
		{
			name = "default",
			host = "localhost",
			user = "user",
			method = "rsync",
			path = "/path/to/remote/directory",
			ignore = {},
		},
	},
	global_ignore = { "*.log", "*.tmp", "node_modules/", ".git/", "deploy.json" },
	default = 0,
	auto_upload = false,
}

-- INFO: Get the project root directory
local function get_project_root()
	local cwd = vim.fn.getcwd()
	if vim.fn.isdirectory(cwd .. "/.git") == 1 then
		return cwd
	end

	-- INFO: Fallback to current working directory
	return cwd
end

-- INFO: Get the path to the deploy.json file
local function get_config_path()
	local root = get_project_root()
	return root .. "/deploy.json"
end

-- INFO: Load the configuration file
function M.load_config()
	local config_path = get_config_path()
	if vim.fn.filereadable(config_path) == 0 then
		return nil
	end

	-- INFO: Read the file content
	local file_content = vim.fn.readfile(config_path)
	local config_str = table.concat(file_content, "\n")

	-- INFO: Simple parsing logic (assumes valid JSON format)
	local config = vim.fn.json_decode(config_str)

	-- INFO: Ensure global_ignore exists
	config.global_ignore = config.global_ignore or default_config.global_ignore
	return config
end

--  INFO: Save the configuration file
function M.save_config(config)
	local config_path = get_config_path()
	local config_lines = vim.fn.json_encode(config)

	if config_lines == nil then
		print("Error: Failed to encode configuration")
		return
	end

	-- INFO: Split the JSON string into lines
	local formatted_json = M.format_json(config_lines)

	-- INFO: Write to file
	local file = io.open(config_path, "w")
	if not file then
		print("Error: Could not write to file: " .. config_path)
		return
	end
	file:write(formatted_json)
	file:close()
end

-- INFO: Initialize the configuration file
function M.init_config()
	local config_path = get_config_path()
	if vim.fn.filereadable(config_path) == 0 then
		M.save_config(default_config)
		print("Created default configuration at: " .. config_path)
	else
		print("Configuration already exists: " .. config_path)
	end
end

-- INFO: Edit the configuration file
function M.edit_config()
	local config_path = get_config_path()
	vim.cmd("edit " .. config_path)
end

-- INFO: Function to format a JSON file
function M.format_json(content_str)
	if require("deploy.utils").is_jq_installed() then
		return vim.fn.system("echo '" .. content_str .. "' | jq .")
	end

	-- INFO: Add indentation manually
	local formatted_json = string.gsub(content_str, ",%s*", ",\n  ")
	formatted_json = string.gsub(formatted_json, "{%s*", "{\n  ")
	formatted_json = string.gsub(formatted_json, "}%s*", "\n}")
	formatted_json = string.gsub(formatted_json, "[%[%]]", function(match)
		return match == "[" and "[\n  " or "\n]"
	end)

	return formatted_json
end

return M
