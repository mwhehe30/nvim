local M = {}

local theme_file = vim.fn.stdpath("state") .. "/selected-colorscheme"
local default_theme = "everforest"

function M.restore()
	local selected = default_theme

	if vim.fn.filereadable(theme_file) == 1 then
		local saved = vim.fn.readfile(theme_file)
		if saved[1] and saved[1] ~= "" then
			selected = saved[1]
		end
	end

	local ok = pcall(vim.cmd.colorscheme, selected)
	if not ok and selected ~= default_theme then
		vim.cmd.colorscheme(default_theme)
	end
end

function M.save()
	local selected = vim.g.colors_name
	if not selected or selected == "" then
		return
	end

	vim.fn.mkdir(vim.fn.fnamemodify(theme_file, ":h"), "p")
	vim.fn.writefile({ selected }, theme_file)
end

return M
