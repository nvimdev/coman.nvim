local insert, fn, api = table.insert, vim.fn, vim.api
local get_cms_prefix = require("coman").get_cms_prefix
local split = require("coman").split

local prefix_plus = {
	c = true,
	cpp = true,
	rust = true,
	lua = true,
}

local function gen_anno_cms()
	local cms, prefix = get_cms_prefix()
	if prefix_plus[vim.bo.filetype] then
		local tbl = split(prefix, "%p")
		cms = prefix .. tbl[1] .. " "
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
		contents[j] = k .. string.rep(" ", max_length - #k)
	end
	fn.append(current_line - 1, contents)
	api.nvim_win_set_cursor(0, { current_line, max_length + 2 })
	vim.cmd("startinsert!")
end

--- TODO: clangd miss the param name
local c_family = function(tbl, cms)
	local contents = {}
	return contents
end

local lang_with_func = {
	c = c_family,
	cpp = c_family,
	go = function(tbl, cms)
		local contents = {}
		for _, v in pairs(tbl) do
			-- go method is `(*struct)methodname`
			-- remmove the strcut just use method name
			local has_dot = vim.split(v.name, "%.")
			if #has_dot > 1 then
				insert(contents, cms .. has_dot[2])
				insert(contents, cms .. "@Summary")
				insert(contents, cms .. "@Description")
			end
			if v.detail:sub(1, 1) == "(" and v.detail:sub(#v.detail) == ")" then
				local params = vim.split(v.detail:sub(2, #v.detail - 1), ",")
				for _, param in pairs(params) do
					insert(contents, cms .. "@" .. vim.trim(param))
				end
			end
		end
		return contents
	end,
	lua = function(tbl, cms)
		local contents = {}
		for i, v in pairs(tbl) do
			if i == 1 then
				insert(contents, cms .. v.name)
			else
				insert(contents, cms .. "@" .. v.name)
			end
		end
		local max_length = get_max_length(contents) + 2
		for i, v in pairs(contents) do
			contents[i] = v .. string.rep(" ", max_length - #v)
		end
		return contents
	end,
}

local lang = setmetatable(lang_with_func, {
	__call = function(t, tbl)
		-- print(vim.inspect(tbl))
		local cms = gen_anno_cms()
		local contents = t[vim.bo.filetype](tbl, cms)
		insert_annotation(contents)
	end,
	__index = function(_, ft)
		vim.notify(string.format("current filetype %s not support yet create issue for it", ft))
	end,
})

return lang
