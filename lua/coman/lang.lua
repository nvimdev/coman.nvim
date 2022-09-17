local insert, fn, api = table.insert, vim.fn, vim.api
local get_cms_prefix = require('coman').get_cms_prefix
local split = require('coman').split
local coman = require('coman')
local space = ' '

local prefix_plus = {
  c = true,
  cpp = true,
  rust = true,
  lua = true,
}

local function gen_anno_cms()
  local cms = get_cms_prefix()
  local prefix = vim.split(cms,'%s')[1]
  if prefix_plus[vim.bo.filetype] then
    local tbl = split(prefix, '%p')
    cms = prefix .. tbl[1] .. ' '
  end
  return cms
end

local function get_max_length(tbl)
  local max = 0
  for _, v in pairs(tbl) do
    if #v > max then
      max = #v
    end
  end
  return max
end

local function insert_annotation(contents)
  local current_line = api.nvim_win_get_cursor(0)[1]
  local max_length = get_max_length(contents) + 2
  for j, k in pairs(contents) do
    contents[j] = k .. string.rep(' ', max_length - #k)
  end
  fn.append(current_line - 1, contents)
  api.nvim_win_set_cursor(0, { current_line, max_length + 2 })
  vim.cmd('startinsert!')
end

local function generate_anno_tmp(tbl, cms)
  local contents = {}

  local before_hook = coman.before_anno
  if before_hook then
    before_hook()
  end

  for i, v in pairs(tbl) do
    if i == 1 then
      insert(contents, cms .. space .. '@Description' .. space .. v)
    else
      insert(contents, cms .. space .. '@param' .. space .. v)
    end
  end
  return contents
end

local lang = setmetatable({}, {
  __call = function(_, tbl)
    local cms = gen_anno_cms()
    local contents
    local custom_template = coman.custom_template
    if custom_template[vim.bo.filetype] then
      contents = custom_template[vim.bo.filetype](tbl,cms)
    else
      contents = generate_anno_tmp(tbl, cms)
    end
    insert_annotation(contents)
  end,
  __index = function(_, ft)
    vim.notify(string.format('current filetype %s not support yet create issue for it', ft))
  end,
})

return lang
