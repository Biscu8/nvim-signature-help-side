local M = {}

M.start = function ()
	local ok = false

	-- Buffer with no files and doesnt close
	local buffer = vim.api.nvim_create_buf(false, true)
	local win = -1
	vim.bo[buffer].bufhidden = "hide"
	vim.bo[buffer].buftype = "nofile"
	vim.bo[buffer].swapfile = false
	vim.bo[buffer].filetype = "markdown"
	vim.bo[buffer].modifiable = false

	--- Gets the signature and puts it in a buffer
	--- @param buffer integer
	--- @param params table
	local function put_sig_in_buf(buffer, params)
		vim.lsp.buf_request(0, "textDocument/signatureHelp", params, function (err, result, ctx, _)
			if err or not result or not result.signatures then
				return
			end

			local lines = vim.lsp.util.convert_signature_help_to_markdown_lines(result)
			if not lines then return end
			vim.bo[buffer].modifiable = true
			vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
			vim.bo[buffer].modifiable = false
		end
		)
	end

	--- Gets the hover info and puts it in a buffer.
	--- @param buffer integer
	--- @param params table
	local function put_hover_in_buf(buffer, params)
		vim.lsp.buf_request(0, "textDocument/hover", params, function (err, result, ctx, _)
			if err or not result then
				return
			end

			local lines = vim.lsp.util.convert_input_to_markdown_lines(result.contents)
			if not lines then return end
			vim.bo[buffer].modifiable = true
			vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
			vim.bo[buffer].modifiable = false
		end
		)
	end

	--- Open a window with the lsp buffer if its not open, closes it if it is open.
	local function open_close_window()
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, false)
		else
			win = vim.api.nvim_open_win(buffer, false, {
				split = 'left',
				win = 0,
				width = 60,
				style = "minimal",
			})
		end
	end

	--- Change the text of the lsp buffer
	local function change_text(ev)
		if not ok then
			return
		end
		local params = vim.lsp.util.make_position_params()
		if ev.event == 'CursorHold'
			or ev.event == 'CursorHoldI'
			or ev.event == 'InsertLeave'
			or ev.event == 'BufEnter'  then
			put_hover_in_buf(buffer, params)
		elseif ev.event == 'CursorMovedI' then
			put_sig_in_buf(buffer, params)
		end
	end

	vim.keymap.set("n", "]", open_close_window)
	vim.keymap.set("n", "[", function ()
			local params = vim.lsp.util.make_position_params()
			put_hover_in_buf(buffer, params)
		end,
		{noremap = true}
	)

	vim.api.nvim_create_autocmd({'CursorHoldI', 'CursorHold', 'InsertLeave', 'CursorMovedI', 'BufEnter'}, {callback = change_text})
end
return M
