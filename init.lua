-- Buffer with no files and doesnt close
local buffer = vim.api.nvim_create_buf(false, true)
local win = vim.api.nvim_open_win(buffer, false, { split = 'left', win = 0, width = 60})

vim.bo[buffer].bufhidden = "hide"
vim.bo[buffer].buftype = "nofile"
vim.bo[buffer].swapfile = false
vim.bo[buffer].filetype = "markdown"

-- Gets the signature and puts it in a buffer
local function put_sig_in_buf(buffer, params)
	vim.lsp.buf_request(0, "textDocument/signatureHelp", params, function (err, result, ctx, _)
		if err or not result or not result.signatures then
			return
		end

		local lines = vim.lsp.util.convert_signature_help_to_markdown_lines(result)
		if not lines then return end
		vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
	end
	)
end

local function open_close_window()
	if vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_win_close(win, false)
	else
		win = vim.api.nvim_open_win(buffer, false, { split = 'left', win = 0, width = 60})
	end
end

local function change_text(ev)
	local params = vim.lsp.util.make_position_params(0, 'utf-32')
	put_sig_in_buf(buffer, params)
end

vim.keymap.set("n", "]", open_close_window)
vim.keymap.set("n", "[", change_text, {noremap = true})

vim.api.nvim_create_autocmd({'CursorHold', 'InsertEnter'}, {callback = change_text})
