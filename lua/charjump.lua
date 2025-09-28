-- TODO: Consider 'selection' option

local Jumper = require('charjump.jumper')

local k = vim.keycode
local jumper = nil

local M = {}

---@param forward boolean
---@param exclusive boolean
---@return string
function M.jump(forward, exclusive)
  local char = vim.fn.getcharstr()

  if char == k '<ESC>' then
    return ''
  elseif char == k '<C-k>' then -- Support digraph
    for _ = 1, 2 do
      local graph = vim.fn.getcharstr()
      if graph == k '<ESC>' then -- Cancel
        return ''
      end
      char = char .. graph
    end
  elseif char == k '<C-v>' then
    local graph = vim.fn.getcharstr()
    if graph == k '<ESC>' then -- Cancel
      return ''
    end
    char = char .. graph
  end
  jumper = Jumper.new({ forward = forward, exclusive = exclusive, char = char })
  return '<Cmd>lua require("charjump")._invoke_jump()<CR>' -- Trick to make this dot-repeatable
end

---@param obverse boolean
function M.repeat_jump(obverse)
  if jumper ~= nil then
    jumper:do_repeat(obverse)
  end
end

function M._invoke_jump()
  if jumper ~= nil then
    jumper:do_jump()
  end
end

return M
