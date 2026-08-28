local M = {}

local image_extensions = {
	avif = true,
	bmp = true,
	gif = true,
	heic = true,
	heif = true,
	jpeg = true,
	jpg = true,
	jxl = true,
	png = true,
	svg = true,
	tif = true,
	tiff = true,
	webp = true,
}

function M.is_image(path)
	return image_extensions[vim.fn.fnamemodify(path or "", ":e"):lower()] == true
end

local function path_under_cursor()
	local name = vim.fn.expand("<cfile>"):gsub('^!%[[^%]]*%]%(', ""):gsub("%)$", "")
	name = name:gsub('^"', ""):gsub('"$', ""):gsub("^'", ""):gsub("'$", "")
	if name == "" then
		name = vim.api.nvim_buf_get_name(0)
	end
	if vim.fn.filereadable(name) == 1 then
		return vim.fn.fnamemodify(name, ":p")
	end
	local joined = vim.fs.joinpath(vim.fn.expand("%:p:h"), name)
	if vim.fn.filereadable(joined) == 1 then
		return vim.fn.fnamemodify(joined, ":p")
	end
end

function M.open_path(path)
	if not M.is_image(path) then
		vim.notify("Not an image: " .. tostring(path), vim.log.levels.WARN)
		return
	end
	vim.ui.open(path)
end

function M.open()
	local path = path_under_cursor()
	if not path then
		vim.notify("No image file under cursor", vim.log.levels.WARN)
		return
	end
	M.open_path(path)
end

function M.neo_tree_enter(state)
	local node = state.tree:get_node()
	local path = node and (node.path or node:get_id())
	if node and node.type == "file" and M.is_image(path) then
		M.open_path(path)
	else
		require("neo-tree.sources.filesystem.commands").open(state)
	end
end

return M
