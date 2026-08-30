local builtin = require('telescope.builtin')

vim.keymap.set('n', '<leader>pf', builtin.find_files, {})

vim.keymap.set('n', '<C-p>', builtin.git_files, {})

vim.keymap.set('n', '<leader>pg', function()
  if vim.fn.executable('rg') == 0 then
    vim.notify("ripgrep (rg) is not installed! Please install it to use Telescope grep.", vim.log.levels.ERROR)
    return
  end
  builtin.grep_string({ search = vim.fn.input("Grep > ") })
end, { desc = "Search with ripgrep" })

