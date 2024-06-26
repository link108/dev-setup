vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")
vim.cmd("map s <Nop>")


vim.keymap.set("n", "<Space>", "<Nop>", { silent = true, remap = false })
vim.g.mapleader = " "

-- vim.cmd("let g:tmux_navigator_no_mappings = 1")
-- vim.cmd("nnoremap <silent> <M-h> :TmuxNavigateLeft<cr>")
-- vim.cmd("nnoremap <silent> <M-j> :TmuxNavigateDown<cr>")
-- vim.cmd("nnoremap <silent> <M-k> :TmuxNavigateUp<cr>")
-- vim.cmd("nnoremap <silent> <M-l> :TmuxNavigateRight<cr>")

-- was not able to get meta key working for nvim 
-- vim.keymap.set("n", "<M-h>", "<Nop>", { silent = true, remap = true })

-- vim.cmd("nnoremap <M-p> :echom 'p'<cr>")
-- vim.cmd("nnoremap <M-h> :wincmd h<cr>")
-- vim.cmd("nnoremap <M-j> :wincmd j<cr>")
-- vim.cmd("nnoremap <M-k> :wincmd k<cr>")
-- vim.cmd("nnoremap <M-l> :wincmd l<cr>")

vim.keymap.set('n', '<M-h>', ':wincmd h<CR>')
vim.keymap.set('n', '<M-j>', ':wincmd j<CR>')
vim.keymap.set('n', '<M-k>', ':wincmd k<CR>')
vim.keymap.set('n', '<M-l>', ':wincmd l<CR>')

vim.keymap.set('n', '<leader>h', ':nohlsearch<CR>')



