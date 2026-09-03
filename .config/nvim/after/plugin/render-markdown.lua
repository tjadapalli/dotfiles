-- Toggle inline markdown rendering (render-markdown.nvim) for the current buffer.
-- Only does anything when the current buffer's filetype is markdown.
vim.keymap.set("n", "<leader>md", function()
	if vim.bo.filetype ~= "markdown" then
		vim.notify("Not a markdown buffer", vim.log.levels.WARN)
		return
	end
	require("render-markdown").toggle()
end, { desc = "Toggle markdown rendering" })
