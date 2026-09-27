local M = {}

local config_dir = vim.fn.stdpath("config")

M.config = {
	config_dir = config_dir,
	snippets_dir = vim.fs.joinpath(config_dir, "cp-snippets"),
}


local function get_snippets()
	local files = vim.fn.globpath(M.config.snippets_dir, "**/*.cpp", false, true)

	local snippets = {}

	for _, path in ipairs(files) do
		local relative = vim.fs.relpath(M.config.snippets_dir, path)

		relative = relative:gsub("%.cpp$", "")

		table.insert(snippets, relative)
	end

	table.sort(snippets)

	return snippets
end

local function read_snippet(name)
	local path = vim.fs.joinpath(M.config.snippets_dir, name .. ".cpp")

	local file = io.open(path, "r")

	if not file then
		vim.notify("Could not open snippet: " .. name, vim.log.levels.ERROR)
		return nil
	end

	local content = file:read("*a")
	file:close()

	local lines = vim.split(content, "\n", { plain = true })

	if lines[#lines] == "" then
		table.remove(lines)
	end

	return lines
end

local function find_solve(bufnr)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

	for i, line in ipairs(lines) do
		if line:match("^%s*void%s+solve%s*%(") then
			return i - 1
		end
	end

	return nil
end

function M.insert(name, bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()

	local lines = read_snippet(name)

	if not lines then
		return
	end

	local solve_line = find_solve(bufnr)

	if not solve_line then
		vim.notify("Could not find solve()", vim.log.levels.ERROR)
		return
	end

  local insertion = { "" }

  vim.list_extend(insertion, lines)

  table.insert(insertion, "")

	vim.api.nvim_buf_set_lines(bufnr, solve_line, solve_line, false, insertion)

	vim.notify("Inserted snippet: " .. name, vim.log.levels.INFO)
end

function M.open()
	local snippets = get_snippets()

	if #snippets == 0 then
		vim.notify("No snippets found in " .. M.config.snippets_dir, vim.log.levels.WARN)
		return
	end

	local ui = require("cp-snippets.ui")

	ui.open({
		snippets = snippets,

		on_select = function(name)
			M.insert(name)
		end,
	})
end

function M.setup(opts)
	opts = opts or {}

	M.config = vim.tbl_deep_extend("force", M.config, opts)

	vim.keymap.set("n", "<leader>snip", M.open, {
		desc = "CP: insert snippet",
	})

	vim.api.nvim_create_user_command("CPSnip", function()
		M.open()
	end, {})
end

return M
