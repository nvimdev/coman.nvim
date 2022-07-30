local vim, api = vim, vim.api
local insert = table.insert
local coman = {}

function coman.split(str, reg)
	local tbl = {}
	for word in str:gmatch(reg) do
		insert(tbl, word)
	end

	return tbl
end

local generate_line_comment = function(line, lnum, ctx)
	local content = coman.split(line, "%S+")
	local new_lines, char_idx

	if content[1] == ctx.prefix then
		char_idx = line:find("%p")
		new_lines = line:sub(1, char_idx - 1) .. line:sub(char_idx + #ctx.cms)
		api.nvim_buf_set_lines(0, lnum - 1, lnum, true, { new_lines })
	else
		if ctx.follow_head then
			if ctx.head_pos == 1 then
				api.nvim_buf_set_lines(0, lnum - 1, lnum, true, { ctx.cms .. line })
				return
			else
				new_lines = line:sub(1, ctx.head_pos) .. ctx.cms .. line:sub(ctx.head_pos + 1)
				api.nvim_buf_set_lines(0, lnum - 1, lnum, true, { new_lines })
				return
			end
		end

		_, char_idx = line:find("%s+")

		new_lines = line:sub(1, char_idx) .. ctx.cms .. line:sub(char_idx + 1)

		api.nvim_buf_set_lines(0, lnum - 1, lnum, true, { new_lines })
	end
end

function coman.get_cms_prefix()
	local cms = vim.bo.cms
	local prefix = ""
	if cms:find("%%s") then
		cms = cms:gsub("%%s", " ")
		prefix = cms:gsub("%s", "")
		return cms, prefix
	end
	return cms, prefix
end

function coman:gen_comment(...)
	local lnum1, lnum2 = ...

	if not vim.bo.modifiable then
		vim.notify("Buffer is not modifiable")
		return
	end

	local ctx = {
		follow_head = false,
	}

	ctx.cms, ctx.prefix = coman.get_cms_prefix()

	self.normal_mode = function()
		local lnum = api.nvim_win_get_cursor(0)[1]
		local line = vim.fn.getline(".")
		if not line:find("^%s") then
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
			local next = i + 1 > #lines and #lines or i + 1
			local _, cur_spaces = v:find("%s+")
			if cur_spaces == nil then
				ctx.follow_head = true
				ctx.head_pos = 1
				break
			end

			local _, next_spaces = lines[next]:find("%s+")
			if cur_spaces < next_spaces then
				ctx.follow_head = true
				ctx.head_pos = cur_spaces
				break
			end
		end

		for k, line in ipairs(lines) do
			generate_line_comment(line, line_start + k - 1, ctx)
		end
	end

	if lnum1 == lnum2 then
		self.normal_mode()
		return
	end

	self.visual_mode()
end

return coman
