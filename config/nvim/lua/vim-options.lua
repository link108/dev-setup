vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")
vim.cmd("map s <Nop>")

local opts = { noremap = true, silent = true }


vim.opt.number = true


vim.keymap.set("n", "<Space>", "<Nop>", opts)
vim.g.mapleader = " "

-- vim.cmd("let g:tmux_navigator_no_mappings = 1")
-- vim.cmd("nnoremap <silent> <M-h> :TmuxNavigateLeft<cr>")
-- vim.cmd("nnoremap <silent> <M-j> :TmuxNavigateDown<cr>")
-- vim.cmd("nnoremap <silent> <M-k> :TmuxNavigateUp<cr>")
-- vim.cmd("nnoremap <silent> <M-l> :TmuxNavigateRight<cr>")

vim.keymap.set('n', '<M-h>', ':wincmd h<CR>')
vim.keymap.set('n', '<M-j>', ':wincmd j<CR>')
vim.keymap.set('n', '<M-k>', ':wincmd k<CR>')
vim.keymap.set('n', '<M-l>', ':wincmd l<CR>')

vim.keymap.set('n', '<M-H>', ':wincmd <<CR>')
vim.keymap.set('n', '<M-J>', ':wincmd -<CR>')
vim.keymap.set('n', '<M-K>', ':wincmd +<CR>')
vim.keymap.set('n', '<M-L>', ':wincmd ><CR>')

vim.keymap.set('n', '<M-=>', ':wincmd =<CR>')


vim.keymap.set('n', '<leader>h', ':nohlsearch<CR>')

vim.keymap.set('n', '<M-->', ':split<CR><C-w>w')
vim.keymap.set('n', '<M-\\>', ':vsplit<CR><C-w>w')
