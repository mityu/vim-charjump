---@class State
---@field forward boolean
---@field exclusive boolean
---@field char string

local k = vim.keycode

-- Check equality of table.  This is very limited implementation and only works
-- for table consist of primitive values.
---@param t1 table
---@param t2 table
---@return boolean
local function simple_table_equal(t1, t2)
  for k1, v1 in pairs(t1) do
    local v2 = t2[k1]
    if type(v1) == 'table' and type(v2) == 'table' then
      if not simple_table_equal(v1, v2) then
        return false
      end
    elseif v1 ~= v2 then
      return false
    end
  end
  return true
end

---@param char string
---@return string
local function word_boundary_alphabet_search_pattern(char)
  local pats = {}
  if char:match('%l') then
    local upper = char:upper()
    local lower = char:lower()
    pats = {
      ('%%(^|<|\\A)@<=[%s%s]'):format(upper, lower), -- snake case
      ('[%s%s]%%(>|\\A|$)@='):format(upper, lower),  -- snake_case
      ('%s\\u@='):format(lower),                     -- CamelCase
      ('\\l@<=%s'):format(upper),                    -- CamelCase
    }
  else                                               -- Upper-cased alphabet
    pats = {
      ([[%%(^|<|\A|\l)@<=%s]]):format(char),
      ([[%s%%(>|\A|$)@=]]):format(char),
    }
  end
  return ([[\C\v%%(%s)]]):format(table.concat(pats, '|'))
end

---@param state State
---@return boolean
local function do_jump_word_boundary(state)
  local curpos = vim.fn.getcurpos()
  local pattern = word_boundary_alphabet_search_pattern(state.char)
  local stopline = vim.fn.line('.')
  local flags = state.forward and '' or 'b'
  for _ = 1, vim.v.count1 do
    if vim.fn.search(pattern, flags, stopline) == 0 then
      vim.fn.setpos('.', curpos)
      return false
    end
  end
  if state.exclusive then
    if state.forward then
      vim.cmd([[normal! h]])
    else
      vim.cmd([[normal! l]])
    end
  end
  if vim.fn.mode(1) == 'no' then
    vim.cmd([[normal! v]])
    vim.fn.setpos('.', curpos)
  end
  return true
end

---@param state State
---@return boolean
local function do_jump_anyware(state)
  local curpos = vim.fn.getcurpos()
  local operator = state.exclusive and 't' or 'f'
  if not state.forward then
    operator = operator:upper()
  end

  vim.cmd(([[normal! %d%s%s]]):format(vim.v.count1, operator, state.char))
  if simple_table_equal(vim.fn.getcurpos(), curpos) then
    return false
  end

  if vim.fn.mode(1) == 'no' then
    vim.cmd('normal! v')
    vim.fn.setpos('.', curpos)
  end
  return true
end

---@param state State
---@return boolean
local function do_jump(state)
  if state.char:match([[^%a]]) then
    return do_jump_word_boundary(state)
  elseif state.char:match('^' .. k '<C-v>') then
    local s = vim.deepcopy(state)
    s.char = s.char:sub(2, 2)
    return do_jump_anyware(s)
  else
    return do_jump_anyware(state)
  end
end

local Jumper = {
  _state = {
    forward = false,
    exclusive = false,
    char = '',
  },
}

function Jumper.do_jump(self)
  do_jump(self._state)
end

---@param obverse boolean
function Jumper.do_repeat(self, obverse)
  local state = vim.deepcopy(self._state)
  if not obverse then
    state.forward = not state.forward
  end

  local curpos = vim.fn.getcurpos()
  if state.exclusive then
    if state.forward then
      vim.cmd('normal! l')
    else
      vim.cmd('normal! h')
    end
  end

  local is_textobj = vim.fn.mode(1) == 'no'
  local jumped = do_jump(state)

  if state.exclusive then
    if not jumped then
      vim.fn.setpos('.', curpos)
    elseif is_textobj then
      if state.forward then
        vim.cmd('normal! h')
      else
        vim.cmd('normal! l')
      end
    end
  end
end

return {
  ---@param state State
  new = function(state)
    local obj = setmetatable({}, { __index = Jumper })
    obj._state = vim.deepcopy(state)
    return obj
  end,
}
