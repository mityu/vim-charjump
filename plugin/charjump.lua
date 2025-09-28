if vim.fn.has('nvim') == 0 then
  return
end

---@param forward boolean
---@param exclusive boolean
local function jump(forward, exclusive)
  ---@return string
  return function()
    return require('charjump').jump(forward, exclusive)
  end
end

---@param obverse boolean
local function repeat_jump(obverse)
  return function()
    require('charjump').repeat_jump(obverse)
  end
end

vim.keymap.set({ 'n', 'v', 'o' }, '<Plug>(charjump-inclusive-forward)', jump(true, false), { expr = true })
vim.keymap.set({ 'n', 'v', 'o' }, '<Plug>(charjump-inclusive-backward)', jump(false, false), { expr = true })
vim.keymap.set({ 'n', 'v', 'o' }, '<Plug>(charjump-exclusive-forward)', jump(true, true), { expr = true })
vim.keymap.set({ 'n', 'v', 'o' }, '<Plug>(charjump-exclusive-backward)', jump(false, true), { expr = true })
vim.keymap.set({ 'n', 'v', 'o' }, '<Plug>(charjump-repeat-obverse)', repeat_jump(true), {})
vim.keymap.set({ 'n', 'v', 'o' }, '<Plug>(charjump-repeat-reverse)', repeat_jump(false), {})
