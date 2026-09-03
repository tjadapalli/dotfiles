-- nvim-treesitter, main branch (the project's current default branch — a
-- full rewrite, see https://github.com/nvim-treesitter/nvim-treesitter).
-- The old `require('nvim-treesitter.configs').setup{ ensure_installed, highlight }`
-- API is gone. Per the README's own "Installation"/"Highlighting" sections:
-- install parsers explicitly, then turn on treesitter highlighting per
-- filetype yourself.

require('nvim-treesitter').install {
	'c', 'cpp', 'lua', 'vim', 'vimdoc', 'query',
	'markdown', 'markdown_inline',
	'go', 'rust', 'javascript', 'typescript',
	'html', 'css', 'java',
}

vim.api.nvim_create_autocmd('FileType', {
	pattern = {
		'c', 'cpp', 'lua', 'vim', 'help', 'query',
		'markdown',
		'go', 'rust', 'javascript', 'typescript',
		'html', 'css', 'java',
	},
	callback = function() vim.treesitter.start() end,
})
