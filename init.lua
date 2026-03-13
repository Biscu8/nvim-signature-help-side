local M = {}

M.start = function ()
	local start = false
	local enabled = true
	local WIDTH = 60
	local HEIGHT = vim.api.nvim_win_get_height(0)

	-- Buffer with no files and doesnt close
	local buffer = vim.api.nvim_create_buf(false, true)
	local win = -1
	vim.bo[buffer].bufhidden = "hide"
	vim.bo[buffer].buftype = "nofile"
	vim.bo[buffer].swapfile = false
	vim.bo[buffer].filetype = "markdown"
	vim.bo[buffer].syntax = "markdown"
	vim.bo[buffer].modifiable = false

	--- Cleans up the text in markdown format and sets the lines to the buffer
	local function cleanup_and_set_lines(lines, buffer)
		if not lines then return end
		vim.bo[buffer].modifiable = true
		lines = vim.lsp.util.stylize_markdown(buffer, lines, {height = HEIGHT, width = WIDTH})
		lines = vim.lsp.util._normalize_markdown(lines)
		vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
		vim.bo[buffer].modifiable = false
	end

	--- Gets the signature and puts it in a buffer
	--- @param buffer integer
	--- @param params table
	local function put_sig_in_buf(buffer, params)
		vim.lsp.buf_request(0, "textDocument/signatureHelp", params, function (err, result, ctx, _)
			if err or not result or not result.signatures then
				return
			end

			local lines = vim.lsp.util.convert_signature_help_to_markdown_lines(result)
			cleanup_and_set_lines(lines, buffer)
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
			cleanup_and_set_lines(lines, buffer)
		end
		)
	end

	--- Open a window with the lsp buffer if its not open, closes it if it is open.
	local function open_close_window()
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, false)
		elseif enabled then
			win = vim.api.nvim_open_win(buffer, false, {
				split = 'left',
				win = 0,
				width = WIDTH,
				style = "minimal",
			})
			vim.wo[win].wrap = true
			vim.wo[win].breakindent = true
			vim.wo[win].conceallevel = 2
			vim.wo[win].concealcursor = "n"
		end
	end

	--- Change the text of the lsp buffer
	local function change_text(ev)
		if not start then
			start = true
			return
		end
		if not enabled then return end
		local params = vim.lsp.util.make_position_params(0, 'utf-8')
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
			if enabled then
				local params = vim.lsp.util.make_position_params(0, 'utf-8')
				put_hover_in_buf(buffer, params)
			end
		end,
		{noremap = true}
	)

	vim.api.nvim_create_autocmd({'CursorHoldI', 'CursorHold', 'InsertLeave', 'CursorMovedI', 'BufEnter'}, {callback = change_text})
	vim.api.nvim_create_user_command(
		"DisableLsp",
		function ()
			enabled = false
			if vim.api.nvim_win_is_valid(win) then
				vim.api.nvim_win_close(win, true)
			end
		end,
		{}
	)
	vim.api.nvim_create_user_command(
		"EnableLsp",
		function ()
			enabled = true
			open_close_window()
		end,
		{}
	)
end
return M
