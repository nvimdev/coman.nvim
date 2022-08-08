local api = vim.api
local ts = {}

function ts:load_treesitter()
  local ok,treesitter = pcall(require,'nvim-treesitter')
  if ok then
    return treesitter
  end
  vim.notify('Does not find treesitter')
  return nil
end

function ts:init()
  local treesitter = self:load_treesitter()
  if not treesitter then
    return
  end

  local queries = require('nvim-treesitter.query')

  treesitter.define_modules({
    coman = {
      attatch = function(bufnr,lang)
      end,
      is_supported = function(lang)
        return queries.get_query(lang,'params-list') ~= nil
      end
    }
  })
end

local function print_node(title, node)
    print(string.format("%s: type '%s' isNamed '%s'", title, node:type(), node:named()))
end

function ts:get_node()
  local bufnr = api.nvim_get_current_buf()
  local queries = require('nvim-treesitter.query')
  local ft_to_lang = require('nvim-treesitter.parsers').ft_to_lang
  local query = queries.get_query(ft_to_lang(vim.bo[bufnr].filetype),'func_params')

  local ts_utils = require('nvim-treesitter.ts_utils')
  local current_node = ts_utils.get_node_at_cursor()
  if not current_node then
    return
  end

  local parent_node = current_node:parent()
  if not parent_node then
    parent_node = current_node
  end
  print(parent_node:type())

  local start_row,_,end_row,_ = parent_node:range()
  end_row = end_row + 1

  for id, node, _ in query:iter_captures(parent_node, 0, start_row, end_row) do
    local name = query.captures[id] -- name of the capture in the query
    local row, col, end_row, end_col = node:range()
    print(row,col,end_row,end_col)
    print("- capture name: " .. name)
    print_node(string.format("- capture node id(%s)", id), node)
  end
end

return ts
