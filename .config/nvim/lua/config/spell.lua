-- Reliable, quiet spell checking using Neovim's built-in 'spell' option
-- (no LSP/Mason server involved, so no noisy diagnostics/virtual text).

vim.opt.spelllang = "en_us"

local function toggle_spell()
	vim.opt_local.spell = not vim.opt_local.spell:get()
	local state = vim.opt_local.spell:get() and "ON" or "OFF"
	vim.notify("Spell check: " .. state, vim.log.levels.INFO, { title = "Spell" })
end

vim.api.nvim_create_user_command("SpellToggle", toggle_spell, {
	desc = "Toggle built-in spell checking for the current buffer",
})

vim.keymap.set("n", "<leader>ts", toggle_spell, { desc = "Toggle spell check" })
