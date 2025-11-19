-- disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.opt.number=true
vim.opt.relativenumber=true
vim.wo.cursorline = true
-- Display tabs and trailing spaces
vim.opt.list = true
vim.opt.listchars = { tab = ">-", trail = "-" }

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true

vim.opt.scrolloff = 15
vim.opt.sidescrolloff = 10
vim.opt.startofline = false

vim.opt.conceallevel = 2

vim.wo.wrap = false

-- Prevent readonly mode by default
vim.opt.readonly = false
vim.opt.modifiable = true
vim.opt.write = true

-- Auto-create directories when saving files
vim.api.nvim_create_autocmd("BufWritePre", {
  callback = function()
    local dir = vim.fn.expand('<afile>:p:h')
    if vim.fn.isdirectory(dir) == 0 then
      vim.fn.mkdir(dir, 'p')
    end
  end,
})

-- Backup and swap file settings to avoid conflicts
vim.opt.backup = false
vim.opt.writebackup = false
vim.cmd('set noswapfile')

-- Tab related options
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("config.lazy") -- Import `./lua/config/lazy.lua`

require("keymapping")
