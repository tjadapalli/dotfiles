local set = vim.opt_local

set.expandtab = false
set.tabstop = 8
set.softtabstop = 8
set.shiftwidth = 8

set.cindent = true
-- '+4': continuation lines get 4 extra columns from the parent statement's
-- indent, independent of shiftwidth/tabstop.
set.cinoptions = "+4"
