local api = vim.api
local ts = {}

function ts:load_treesitter()
  local ok, treesitter = pcall(require, 'nvim-treesitter')
  if ok then
    return treesitter
  end
  vim.notify('Does not find treesitter')
  return nil
end

local function get_text(srow, scol, erow, ecol)
  local tbl = api.nvim_buf_get_text(0, srow, scol, erow, ecol, {})
  return tbl[1]
end

local context = setmetatable({}, {
  __nexindex = function(t, k, v)
    rawset(t, k, v)
  end,
})

function ts:get_func_with_params()
  local bufnr = api.nvim_get_current_buf()
  local queries = require('nvim-treesitter.query')
  local ft_to_lang = require('nvim-treesitter.parsers').ft_to_lang
  local query = queries.get_query(ft_to_lang(vim.bo[bufnr].filetype), 'highlights')

  local ts_utils = require('nvim-treesitter.ts_utils')
  local current_node = ts_utils.get_node_at_cursor()
  if not current_node then
    return
  end

  local parent_node = current_node:parent()
  if not parent_node then
    parent_node = current_node
  end

  local start_row, _, end_row, _ = parent_node:range()
  end_row = end_row + 1

  local caps_id_list = {}
  for id, _, _ in query:iter_captures(parent_node, 0, start_row, end_row) do
    table.insert(caps_id_list, id)
  end
  -- { name: type: }
  local index = 0
  local param_names, param_types = {}, {}
  for id, node, _ in query:iter_captures(parent_node, 0, start_row, end_row) do
    index = index + 1

    local name = query.captures[id] -- name of the capture in the query
    local node_srow, node_scol, node_erow, node_ecol = node:range()
    -- print(node_srow, node_scol, node_erow, node_ecol)
    -- print('- capture name: ' .. name, id)
    local text = get_text(node_srow, node_scol, node_erow, node_ecol)
    if name == 'function' or name == 'method' then
      context['func'] = text
    end

    local next_node_id = index == #caps_id_list and caps_id_list[index] or caps_id_list[index + 1]
    if name == 'parameter' then
      table.insert(param_names, get_text(node_srow, node_scol, node_erow, node_ecol))

      if query.captures[next_node_id] == 'namespace' then
        local next_node = ts_utils.get_next_node(node)
        node_srow, node_scol, node_erow, node_ecol = next_node:range()
        self.namespace_type = get_text(node_srow, node_scol, node_erow, node_ecol)
      end
    end

    if name == 'type' then
      if self.namespace_type then
        text = self.namespace_type
        self.namespace_type = nil
      end
      table.insert(param_types, text)

      if #param_types < #param_names and #param_names > 1 then
        local count = #param_names - #param_types
        for _ = 1, count do
          table.insert(param_types, text)
        end
      end
    end
  end

  param_types = { unpack(param_types, 1, #param_names) }

  context['params'] = {
    param_names,
    param_types,
  }
end

local _mt = {
  __index = function(_, k)
    if k == 'context' then
      return context
    end
  end,
}

setmetatable(ts, _mt)

return ts
