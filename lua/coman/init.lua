local vim, api = vim, vim.api
local insert = table.insert
local coman = {
  custom_template = {}
}

local ts = require('coman.ts')

function coman.split(str, reg)
  local tbl = {}
  for word in str:gmatch(reg) do
    insert(tbl, word)
  end

  return tbl
end

local generate_line_comment = function(line, lnum, ctx)
  local content = coman.split(line, '%S+')
  local new_lines, char_idx

  if content[1] == vim.split(ctx.cms, '%s')[1] then
    char_idx = line:find('%p')
    new_lines = line:sub(1, char_idx - 1) .. line:sub(char_idx + #ctx.cms)
    api.nvim_buf_set_lines(0, lnum - 1, lnum, true, { new_lines })
  else
    if ctx.follow_head then
      if ctx.head_pos == 1 then
        api.nvim_buf_set_lines(0, lnum - 1, lnum, true, { ctx.cms .. line })
        return
      else
        new_lines = line:sub(1, ctx.head_pos) ..
            ctx.cms .. line:sub(ctx.head_pos + 1)
        api.nvim_buf_set_lines(0, lnum - 1, lnum, true, { new_lines })
        return
      end
    end

    _, char_idx = line:find('%s+')

    new_lines = line:sub(1, char_idx) .. ctx.cms .. line:sub(char_idx + 1)

    api.nvim_buf_set_lines(0, lnum - 1, lnum, true, { new_lines })
  end
end

function coman.get_cms_prefix()
  local cms = vim.bo.cms
  -- match te cms like space+%s
  if cms:find('%%s$') then
    cms = cms:find('%s') and cms:gsub('%%s', '') or cms:gsub('%%s', ' ')
  end
  return cms
end

function coman:gen_comment(...)
  local lnum1, lnum2 = ...

  if not vim.bo.modifiable then
    vim.notify('Buffer is not modifiable')
    return
  end

  local ctx = {
    follow_head = false,
  }

  ctx.cms = coman.get_cms_prefix()

  self.normal_mode = function()
    local lnum = api.nvim_win_get_cursor(0)[1]
    local line = vim.fn.getline('.')
    if not line:find('^%s') then
      ctx.follow_head = true
      ctx.head_pos = 1
    end
    generate_line_comment(line, lnum, ctx)
  end

  self.visual_mode = function()
    local vstart = vim.fn.getpos("'<")
    local vend = vim.fn.getpos("'>")
    local line_start, _ = vstart[2], vstart[3]
    local line_end, _ = vend[2], vend[3]
    local lines = vim.fn.getline(line_start, line_end)

    for i, v in pairs(lines) do
      if #v > 0 then
        local _, cur_spaces = v:find('^%s+')
        if cur_spaces == nil then
          ctx.follow_head = true
          ctx.head_pos = 1
          break
        end

        local next = i + 1 > #lines and #lines or i + 1
        if string.len(lines[next]) == 0 then
          next = next + 1
        end
        local _, next_spaces = lines[next]:find('^%s+')
        -- next_spaces = next_spaces == nil and 1 or next_spaces
        if cur_spaces < next_spaces then
          ctx.follow_head = true
          ctx.head_pos = cur_spaces
          break
        end
      end
    end

    for k, line in ipairs(lines) do
      if string.len(line) ~= 0 then
        generate_line_comment(line, line_start + k - 1, ctx)
      end
    end
  end

  if lnum1 == lnum2 then
    self.normal_mode()
    return
  end

  self.visual_mode()
end

function coman:gen_annotation()
  ts:get_func_with_params()
  local context = ts.context
  local lang = require('coman.lang')
  local lines = {}
  table.insert(lines, context['func'])
  for i, val in pairs(context['params'][1]) do
    local param = val .. ' ' .. (context['params'][2][i] or '')
    table.insert(lines, param)
  end
  lang(lines)
end

return coman
