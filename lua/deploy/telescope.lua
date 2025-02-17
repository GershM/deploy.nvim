local M = {}
local config = require("deploy.config")

function M.select_server()
	local cfg = config.load_config()
	if not cfg then
		print("No configuration found. Run :DeployEditConfig to create a new configuration.")
		return
	end

	if not cfg.servers or #cfg.servers == 0 then
		print("No servers configured. Use :DeployAddConnection to add a server.")
		return
	end

	-- Debugging: Print loaded servers
	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")
	local conf = require("telescope.config").values

	pickers
		.new({}, {
			prompt_title = "Select Deployment Server",
			finder = finders.new_table({
				results = cfg.servers,
				entry_maker = function(server)
					return {
						value = server, -- Ensure the full server object is passed
						display = server.name .. " (" .. server.host .. ")",
						ordinal = server.name .. " " .. server.host,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()
					if selection == nil then
						return
					end

					local server = selection.value
					if not server or not server.name then
						print("Error: Selected server is invalid.")
						return
					end

					-- Set as default server
					for i, s in ipairs(cfg.servers) do
						if s.name == server.name then
							cfg.default = i
							break
						end
					end

					actions.close(prompt_bufnr)
					config.save_config(cfg)
					print("Selected server: " .. server.name)
				end)
				return true
			end,
		})
		:find()
end

return M
