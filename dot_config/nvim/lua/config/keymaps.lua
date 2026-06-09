-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Paste over a visual selection without overwriting the yank register
vim.keymap.set("x", "p", [["_dP]], { desc = "Paste without yanking" })
