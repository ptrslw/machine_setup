-- Neovim config (Lua). Symlinked: machine_setup/home/.config/nvim → ~/.config/nvim
--
-- Modern Neovim uses init.lua, not a Vimscript .vimrc. This file is a minimal
-- $EDITOR baseline (git commit messages, quick terminal edits, SSH) — not a
-- full IDE. Cursor / CLion / VS Code own language intelligence.
-- Sensible options, Space as <Leader>, a few keymaps, and lazy.nvim with an
-- empty plugin list. Add LSP/treesitter as separate specs when you want them.

-- Leader must be set before lazy.nvim and any keymap that uses <leader>.
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Options -----------------------------------------------------------------
local opt = vim.opt
opt.number = true             -- absolute line number on the current line
opt.relativenumber = true     -- relative numbers elsewhere (easy 10j / 5k jumps)
opt.mouse = 'a'               -- mouse in all modes
opt.ignorecase = true         -- search case-insensitive…
opt.smartcase = true          -- …unless the pattern has uppercase
opt.signcolumn = 'yes'        -- always reserve the gutter (no text jump on diagnostics)
opt.updatetime = 250          -- faster CursorHold / diagnostics refresh
opt.timeoutlen = 300          -- shorter wait for mapped key sequences
opt.undofile = true           -- persistent undo across sessions
opt.clipboard = 'unnamedplus' -- yank/paste use the system clipboard

-- Indentation: 2 spaces, expand tabs
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2

-- Keymaps -----------------------------------------------------------------
local map = vim.keymap.set

map('i', 'jk', '<Esc>', { desc = 'Exit insert mode' })
map('n', '<leader>w', '<cmd>w<CR>', { desc = 'Save file' })
map('n', '<leader>q', '<cmd>q<CR>', { desc = 'Quit' })

-- Window focus (Ctrl+h/j/k/l). Matches common tmux/vim muscle memory.
map('n', '<C-h>', '<C-w><C-h>', { desc = 'Focus left window' })
map('n', '<C-l>', '<C-w><C-l>', { desc = 'Focus right window' })
map('n', '<C-j>', '<C-w><C-j>', { desc = 'Focus lower window' })
map('n', '<C-k>', '<C-w><C-k>', { desc = 'Focus upper window' })

map('n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = 'Clear search highlight' })

-- lazy.nvim ---------------------------------------------------------------
-- Clone on first launch into Neovim's data dir, then prepend to runtimepath.
-- Plugin specs go in the setup({}) table (or a separate lua/plugins/ module).
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable',
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Empty for now — add plugins here as needed, e.g.:
--   { "folke/tokyonight.nvim", lazy = false, priority = 1000 }
require('lazy').setup({})
