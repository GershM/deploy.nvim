local M = {}
local config = require("deploy.config")

-- INFO: Create a popup for adding a new connection
function M.add_connection_popup()
	local bufnr = vim.api.nvim_create_buf(false, true)
	local win_id = vim.api.nvim_open_win(bufnr, true, {
		relative = "editor",
		width = 80,
		height = 17,
		row = math.floor((vim.o.lines - 17) / 2),
		col = math.floor((vim.o.columns - 80) / 2),
		style = "minimal",
		border = "rounded",
	})

	-- INFO: Add instructions and input fields
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
		"Add New Connection",
		"-----------------",
		"Name: ",
		"Host: ",
		"User: ",
		"Method (rsync/sftp): ",
		"Password (optional): ",
		"Ignore Files (comma-separated): ",
		"Destination Path (e.g., /var/www): ",
		"",
		"Press <Enter> to save, q to cancel.",
	})

	-- INFO: Highlight the input lines
	for i = 2, 9 do
		vim.api.nvim_buf_add_highlight(bufnr, -1, "Comment", i, 0, -1)
	end

	-- INFO: Map keys for saving or canceling
	vim.keymap.set("n", "<CR>", function()
		local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
		local new_server = {
			name = lines[3]:match("Name: (.*)"),
			host = lines[4]:match("Host: (.*)"),
			user = lines[5]:match("User: (.*)"),
			method = lines[6]:match("Method.*: (.*)"),
			password = lines[7]:match("Password.*: (.*)") or nil,
			ignore = vim.split(lines[8]:match("Ignore Files.*: (.*)") or "", ","),
			path = lines[9]:match("Destination Path.*: (.*)") or "/",
		}

		-- INFO: Validate inputs
		if not new_server.name or not new_server.host or not new_server.user then
			print("Error: Name, Host, and User are required.")
			return
		end

		-- INFO: Load existing config
		local cfg = config.load_config() or config.init_config()
		if cfg == nil then
			cfg = {}
			return
		end

		if cfg.servers == nil then
			cfg.servers = {}
		end

		-- INFO: Check for duplicate names
		for _, server in ipairs(cfg.servers) do
			if server.name == new_server.name then
				print("Error: A server with this name already exists.")
				return
			end
		end

		-- INFO:  Add the new server
		table.insert(cfg.servers, new_server)
		config.save_config(cfg)
		print("Added new connection: " .. new_server.name .. " (" .. #cfg.servers .. ")")

		-- INFO: Close the popup
		vim.api.nvim_win_close(win_id, true)
	end, { buffer = bufnr })

	vim.keymap.set("n", "q", function()
		vim.api.nvim_win_close(win_id, true)
	end, { buffer = bufnr })
end

return M
