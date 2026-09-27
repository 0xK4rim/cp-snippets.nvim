local M = {}

function M.open(opts)
	local snippets = opts.snippets
	local on_select = opts.on_select

	local input_buf = vim.api.nvim_create_buf(false, true)
	local results_buf = vim.api.nvim_create_buf(false, true)

	vim.api.nvim_buf_set_name(input_buf, "cp-snippets-input")

	vim.api.nvim_buf_set_name(results_buf, "cp-snippets-results")

	vim.bo[input_buf].buftype = "nofile"
	vim.bo[input_buf].bufhidden = "wipe"
	vim.bo[input_buf].swapfile = false

	vim.bo[results_buf].buftype = "nofile"
	vim.bo[results_buf].bufhidden = "wipe"
	vim.bo[results_buf].swapfile = false
	vim.bo[results_buf].modifiable = false

	local width = math.min(math.max(30, vim.o.columns - 10), 60)

	local input_height = 1
	local results_height = math.min(#snippets, 10)

	local total_height = input_height + results_height

	local row = math.floor((vim.o.lines - total_height) / 2)

	local col = math.floor((vim.o.columns - width) / 2)


	local input_win = vim.api.nvim_open_win(input_buf, true, {
		relative = "editor",
		width = width,
		height = input_height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
		title = " CP Snippet ",
		title_pos = "center",
	})


	local results_win = vim.api.nvim_open_win(results_buf, false, {
		relative = "editor",
		width = width,
		height = results_height,
		row = row + 2,
		col = col,
		style = "minimal",
		border = "rounded",
	})

	vim.wo[results_win].cursorline = true


	local matches = snippets
	local selected = 1

	local function close()
		if vim.api.nvim_win_is_valid(input_win) then
			vim.api.nvim_win_close(input_win, true)
		end

		if vim.api.nvim_win_is_valid(results_win) then
			vim.api.nvim_win_close(results_win, true)
		end
	end

	local function set_results(items)
		matches = items

		if #items == 0 then
			vim.bo[results_buf].modifiable = true

			vim.api.nvim_buf_set_lines(results_buf, 0, -1, false, { "No snippets found" })

			vim.bo[results_buf].modifiable = false

			selected = 1
			return
		end

		selected = math.min(selected, #items)

		vim.bo[results_buf].modifiable = true

		vim.api.nvim_buf_set_lines(results_buf, 0, -1, false, items)

		vim.bo[results_buf].modifiable = false

		vim.api.nvim_win_set_cursor(results_win, { selected, 0 })
	end

	local function update()
		local lines = vim.api.nvim_buf_get_lines(input_buf, 0, 1, false)

		local query = lines[1] or ""

		if query == "" then
			set_results(snippets)
			return
		end

		local fuzzy_matches = vim.fn.matchfuzzy(snippets, query)

		set_results(fuzzy_matches)
	end

	local function select()
		if #matches == 0 then
			return
		end

		local name = matches[selected]

		close()

		vim.cmd("stopinsert")

		on_select(name)
	end

	local function move_selection(delta)
		if #matches == 0 then
			return
		end

		selected = selected + delta

		if selected < 1 then
			selected = #matches
		elseif selected > #matches then
			selected = 1
		end

		vim.api.nvim_win_set_cursor(results_win, { selected, 0 })
	end

	vim.api.nvim_create_autocmd({
		"TextChangedI",
		"TextChanged",
	}, {
		buffer = input_buf,

		callback = function()
			if vim.api.nvim_buf_is_valid(input_buf) then
				selected = 1
				update()
			end
		end,
	})


	local map_opts = {
		buffer = input_buf,
		silent = true,
	}

	vim.keymap.set("i", "<CR>", select, map_opts)

	vim.keymap.set("i", "<Esc>", close, map_opts)

	vim.keymap.set("i", "<C-n>", function()
		move_selection(1)
	end, map_opts)

	vim.keymap.set("i", "<C-p>", function()
		move_selection(-1)
	end, map_opts)

	vim.keymap.set("i", "<Down>", function()
		move_selection(1)
	end, map_opts)

	vim.keymap.set("i", "<Up>", function()
		move_selection(-1)
	end, map_opts)

	vim.api.nvim_buf_set_lines(input_buf, 0, -1, false, { "" })

	update()

	vim.api.nvim_win_set_cursor(input_win, { 1, 0 })

	vim.cmd("startinsert")
end

return M
