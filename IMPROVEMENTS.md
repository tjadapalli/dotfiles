# Improvement ideas

Running list of stuff that could make these dotfiles better. Not urgent, just things worth doing eventually.

## nvim

- **gitsigns.nvim** — shows changed lines in the gutter and lets you stage/undo a hunk without leaving the buffer. Right now fugitive covers git commands but nothing shows diffs inline.
- **conform.nvim (+ nvim-lint)** — null-ls (currently used for the Black formatter) is unmaintained. These two are the actively maintained replacement for formatting/linting.
- **more mini.nvim modules** — already pulling in the plugin, so `mini.comment`, `mini.surround`, and `mini.ai` are free wins (comment lines, change surrounding quotes/brackets, better text objects).
- **compile_commands.json for clangd** — clangd on the kernel tree is mostly guessing without one. The kernel ships `scripts/clang-tools/gen_compile_commands.py` to generate it from a built tree.
- **cscope or gtags** — ctags (already set up) can't answer "what calls this function" style queries. cscope or GNU Global can, and `gutentags` would auto-regenerate tags instead of the manual `GenerateTags`/`AppendTags` commands.
- **vim-linux-coding-style** — auto-detects a kernel tree and flags CodingStyle violations (trailing whitespace, tabs/spaces, 80-col) live in the buffer.
- **checkpatch as a linter** — wiring `scripts/checkpatch.pl` into nvim-lint would surface kernel patch issues before you run it by hand.
- **indent-blankline** — visual indent guides, helps with deeply nested C.
- **auto-session** — already a TODO comment in lazy.lua, still worth doing.
- **mini.files** — tried it, but it opens as a floating window that doesn't get out of the way, so other floats (telescope) can render behind it. Needs a real fix (probably closing it on WinLeave) instead of patching individual keymaps one at a time.
