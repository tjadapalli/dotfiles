local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	spec = {
		-- Add new plugins here...
		-- XXX: Remore /after and move all plugins to config/plugin and
		-- import them here
		-- XXXX: Reformat all the lua files.
		"nvim-telescope/telescope.nvim",
		"nvim-lua/plenary.nvim",
		"folke/tokyonight.nvim",
		{
			"rose-pine/neovim",
			name = "rose-pine",
			config = function()
				vim.cmd("colorscheme rose-pine")
			end
		},
		{
			"nvim-treesitter/nvim-treesitter",
			branch = 'master',
			lazy = false,
			build = ":TSUpdate"
		},
		"ThePrimeagen/vim-be-good",
		"ThePrimeagen/harpoon",
		"mbbill/undotree",
		"tpope/vim-fugitive",
		--------- These three plugins work together
		{
			"mason-org/mason.nvim",
			opts = {
				ui = {
					icons = {
						package_installed = "✓",
						package_pending = "➜",
						package_uninstalled = "✗",
					},
				},
			},
		},
		"mason-org/mason-lspconfig.nvim",
		-- This pulls in config for various languages 
		"neovim/nvim-lspconfig",
		---------
		{ 'nvim-mini/mini.nvim', version = '*' },
		{
			'saghen/blink.cmp',
			dependencies = { 'rafamadriz/friendly-snippets' },

			-- use a release tag to download pre-built binaries
			version = '1.*',

			opts = {
				-- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
				-- 'super-tab' for mappings similar to vscode (tab to accept)
				-- 'enter' for enter to accept
				-- 'none' for no mappings
				--
				-- All presets have the following mappings:
				-- C-space: Open menu or open docs if already open
				-- C-n/C-p or Up/Down: Select next/previous item
				-- C-e: Hide menu
				-- C-k: Toggle signature help (if signature.enabled = true)
				--
				-- See :h blink-cmp-config-keymap for defining your own keymap
				keymap = { preset = 'default' },

				appearance = {
					nerd_font_variant = 'mono'
				},

				completion = { documentation = { auto_show = false } },

				signature = { enabled = true },

			},
			opts_extend = { "sources.default" }
		},
		{
			"jay-babu/mason-null-ls.nvim",
			event = { "BufReadPre", "BufNewFile" },
			dependencies = {
				"nvimtools/none-ls.nvim",
			},
		},
		-- To enable codeium, uncomment below plugin and look at 
		-- https://github.com/Exafunction/windsurf.vim#-installation-options
		-- to auth and enable this plugn
		--[[{
			'Exafunction/windsurf.vim',
			event = 'BufEnter'
		} ]]--
		--[[ {
			"nvim-tree/nvim-tree.lua",
			version = "*",
			lazy = false,
			dependencies = {
				"nvim-tree/nvim-web-devicons",
			},
			config = function()
				require("nvim-tree").setup {}
			end,
		}, ]]
		-- look into https://github.com/nvim-mini/mini.nvim
		-- look into https://github.com/rmagatti/auto-session
	},
	defaults = {
		-- By default, only LazyVim plugins will be lazy-loaded. Your custom plugins will load during startup.
		-- If you know what you're doing, you can set this to `true` to have all your custom plugins lazy-loaded by default.
		-- lazy = false,
		-- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
		-- have outdated releases, which may break your Neovim install.
		version = false, -- always use the latest git commit
		-- version = "*", -- try installing the latest stable version for plugins that support semver
	},
	install = {},
	checker = {
		enabled = true, -- check for plugin updates periodically
		notify = false, -- notify on update
	}, -- automatically check for plugin updates
	performance = {
		-- Learn about this later
	},
})

