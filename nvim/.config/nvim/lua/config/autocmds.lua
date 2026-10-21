-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

local function wrap_diff_windows()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(win) and vim.wo[win].diff then
      vim.wo[win].wrap = true
      vim.wo[win].linebreak = true -- kelimeyi ortadan bölmesin
      vim.wo[win].breakindent = true -- sarılan satır girintiyi korusun
    end
  end
end

vim.api.nvim_create_autocmd({ "OptionSet", "BufWinEnter", "WinEnter" }, {
  group = vim.api.nvim_create_augroup("diff_wordwrap", { clear = true }),
  pattern = "*",
  callback = function(ev)
    if ev.event == "OptionSet" and ev.match ~= "diff" then
      return
    end
    -- claudecode diff'i kurduktan sonra çalışsın diye bir tick bekle
    vim.schedule(wrap_diff_windows)
  end,
})
