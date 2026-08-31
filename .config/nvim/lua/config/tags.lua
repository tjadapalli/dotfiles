local function project_root()
	local buf_dir = vim.fn.expand("%:p:h")
	local start = buf_dir ~= "" and buf_dir or vim.loop.cwd()
	return vim.fs.root(start, ".git") or start
end

local function generate_tags()
	if vim.fn.executable("ctags") == 0 then
		vim.notify("ctags not found on PATH", vim.log.levels.ERROR)
		return
	end

	local root = project_root()
	local tags_file = root .. "/tags"

	if vim.fn.filewritable(root) ~= 2 then
		vim.notify("no write access to " .. root .. " (open a file inside your project first)", vim.log.levels.ERROR)
		return
	end

	vim.system(
		{ "ctags", "-R", "--exclude=.git", "-f", tags_file, root },
		{ text = true },
		function(res)
			vim.schedule(function()
				if res.code == 0 then
					vim.notify("tags generated: " .. tags_file)
				else
					vim.notify("ctags failed writing " .. tags_file .. ": " .. (res.stderr or ""), vim.log.levels.ERROR)
				end
			end)
		end
	)
end

vim.api.nvim_create_user_command("GenerateTags", generate_tags, {})
vim.keymap.set("n", "<leader>ct", generate_tags, { desc = "Generate ctags for project" })
