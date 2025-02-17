local M = {}
local config = require("deploy.config")
local auto_deploy_group = vim.api.nvim_create_augroup("DeployAutoUpload", { clear = true })

-- INFO: Auto-deploy function
function M.autoDeploy(func)
	vim.api.nvim_create_autocmd("BufWritePost", {
		pattern = "*",
		group = auto_deploy_group,
		callback = function()
			local cfg = config.load_config()
			if not cfg or not cfg.auto_upload and not cfg.servers and not cfg.default then
				return
			end

			if cfg.default ~= 0 and cfg.auto_upload then
				func(cfg.servers[cfg.default])
			end
		end,
	})
end

-- INFO: Toggle auto-upload
function M.toggle_auto_upload()
	local cfg = config.load_config()
	if not cfg then
		print("No configuration file found")
		return
	end
	cfg.auto_upload = not cfg.auto_upload
	require("deploy.config").save_config(cfg)

	if cfg.auto_upload then
		print("Auto-upload enabled")
	else
		print("Auto-upload disabled")
	end
end

function M.is_jq_installed()
  vim.fn.system("jq --version")

  if vim.v.shell_error == 0 then
    return true
  else
    return false
  end
end

return M
