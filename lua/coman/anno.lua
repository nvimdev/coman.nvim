local api, lsp = vim.api, vim.lsp
local method = "textDocument/documentSymbol"
local anno = {}
local insert = table.insert
local lang = require("coman.lang")

local function get_symbol_cache()
	local current_buf = api.nvim_get_current_buf()
	local ok, symbar = pcall(require, "lspsaga.symbolwinbar")
	local symbols
	if ok and symbar.symbol_cache[current_buf] and next(symbar.symbol_cache[current_buf][2]) ~= nil then
		symbols = symbar.symbol_cache[current_buf][2]
	end

	return ok, symbols
end

local function get_clientid()
	local client_id
	local clients = vim.lsp.buf_get_clients()
	for id, conf in pairs(clients) do
		if conf.server_capabilities.documentSymbolProvider then
			client_id = id
			break
		end
	end
	return client_id
end

--@private
local function binary_search(tbl, line)
	local left = 1
	local right = #tbl
	local mid = 0

	while true do
		mid = bit.rshift(left + right, 1)
		local range

		if tbl[mid].location ~= nil then
			range = tbl[mid].location.range
		elseif tbl[mid].range ~= nil then
			range = tbl[mid].range
		else
			return nil
		end

		if line >= range.start.line and line <= range["end"].line then
			return mid
		elseif line < range.start.line then
			right = mid - 1
			if left > right then
				return nil
			end
		else
			left = mid + 1
			if left > right then
				return nil
			end
		end
	end
end

local function find_in_nodes(tbl, line, element)
	local mid = binary_search(tbl, line)
	if mid == nil then
		return
	end

	insert(element, { kind = tbl[mid].kind, name = tbl[mid].name, detail = tbl[mid].detail })

	if tbl[mid].children and next(tbl[mid].children) ~= nil then
		find_in_nodes(tbl[mid].children, line, element)
	end
end

local do_symbol_request = function()
	local bufnr = api.nvim_get_current_buf()
	local params = { textDocument = lsp.util.make_text_document_params(bufnr) }
	lsp.buf_request_all(0, method, params, function(result)
		if type(result) ~= "table" or next(result) == nil then
			error("all server of this buffer not support")
			return
		end

		local client_id = get_clientid()
		local symbols = result[client_id].result or nil
		anno:update_anno(symbols)
	end)
end

function anno:update_anno(symbols)
	local current_line = api.nvim_win_get_cursor(0)[1]
	local element = {}
	-- print(vim.inspect(symbols))
	find_in_nodes(symbols, current_line - 1, element)
	lang(element)
end

function anno:gen_annotation()
	local has_saga, symbols = get_symbol_cache()
	if has_saga and symbols ~= nil then
		self:update_anno(symbols)
		return
	end

	do_symbol_request()
end

return anno
