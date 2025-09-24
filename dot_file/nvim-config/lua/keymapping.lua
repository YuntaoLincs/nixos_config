vim.keymap.set("n", "<C-h>", "<C-w>h", {desc="Select left-window"})
vim.keymap.set("n", "<C-l>", "<C-w>l", {desc="Select right-window"})
vim.keymap.set("n", "<C-j>", "<C-w>j", {desc="Select down-side window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", {desc="Select up-side window"})

vim.keymap.set({ "n", "x" }, "<S-H>", "^", { desc = "Start of line" })
vim.keymap.set({ "n", "x" }, "<S-L>", "$", { desc = "End of line" })
vim.keymap.set("n", "y<S-H>", "y^", { desc = "Yank from start of line" })
vim.keymap.set("n", "y<S-L>", "y$", { desc = "Yank to end of line" })

vim.keymap.set({ "n", "x" }, "Q", "<CMD>:qa<CR>")
vim.keymap.set({ "n", "x" }, "qq", "<CMD>:q<CR>")

vim.keymap.set("n", "<A-z>", "<CMD>set wrap!<CR>", { desc = "Toggle line wrap" })

-- Command line navigation with Ctrl+j and Ctrl+k
vim.keymap.set('c', '<C-j>', '<Down>', { desc = 'Next command in history' })
vim.keymap.set('c', '<C-k>', '<Up>', { desc = 'Previous command in history' })

-- Enhanced command line window setup
vim.keymap.set('n', 'q:', function()
  vim.cmd('botright copen')
  vim.cmd('resize 10')
end, { desc = 'Open command line window' })

-- Command line window navigation
vim.api.nvim_create_autocmd('CmdwinEnter', {
  callback = function()
    vim.keymap.set('n', '<C-j>', 'j', { buffer = true, desc = 'Move down in command window' })
    vim.keymap.set('n', '<C-k>', 'k', { buffer = true, desc = 'Move up in command window' })
    vim.keymap.set('n', '<CR>', '<CR>', { buffer = true, desc = 'Execute command' })
    vim.keymap.set('n', '<Esc>', '<C-c><C-c>', { buffer = true, desc = 'Close command window' })
  end
})
