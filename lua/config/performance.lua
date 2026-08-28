local M = {}

M.max_autoformat_size = 384 * 1024
M.max_treesitter_size = 512 * 1024
M.max_treesitter_lines = 3000

local ignored_path_patterns = {
	"[/\\]node_modules[/\\]",
	"[/\\]vendor[/\\]",
	"[/\\]%.git[/\\]",
	"[/\\]dist[/\\]",
	"[/\\]build[/\\]",
	"[/\\]%.next[/\\]",
	"[/\\]__pycache__[/\\]",
}

function M.buf_path(bufnr)
	return vim.api.nvim_buf_get_name(bufnr or 0)
end

function M.file_size(path)
	if not path or path == "" then
		return 0
	end

	local ok, stat = pcall(vim.uv.fs_stat, path)
	return ok and stat and stat.size or 0
end

function M.is_ignored_path(path)
	for _, pattern in ipairs(ignored_path_patterns) do
		if path:match(pattern) then
			return true
		end
	end

	return false
end

function M.is_large_buffer(bufnr, opts)
	bufnr = bufnr or 0
	opts = opts or {}

	if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].buftype ~= "" then
		return false
	end

	local max_lines = opts.max_lines or M.max_treesitter_lines
	local max_size = opts.max_size or M.max_treesitter_size
	local line_count = vim.api.nvim_buf_line_count(bufnr)
	local size = M.file_size(M.buf_path(bufnr))

	return line_count > max_lines or size > max_size
end

function M.is_large_project(root)
	if not root or root == "" then
		return true
	end

	local heavy_dirs = {
		"node_modules",
		"vendor",
		".git",
	}

	for _, dir in ipairs(heavy_dirs) do
		if vim.uv.fs_stat(vim.fs.joinpath(root, dir)) then
			return true
		end
	end

	return false
end

return M
