local M = {}

local uv = vim.uv or vim.loop

local function strip_quotes(path)
	path = vim.trim(path or "")
	if path:sub(1, 1) == "&" then
		path = vim.trim(path:sub(2))
	end
	local first = path:sub(1, 1)
	local last = path:sub(-1)
	if (first == '"' and last == '"') or (first == "'" and last == "'") then
		path = path:sub(2, -2)
	end
	return vim.fn.fnamemodify(path, ":p")
end

local function exists(path)
	return uv.fs_stat(path) ~= nil
end

local function next_available_path(path)
	if not exists(path) then
		return path
	end

	local dir = vim.fn.fnamemodify(path, ":h")
	local name = vim.fn.fnamemodify(path, ":t:r")
	local ext = vim.fn.fnamemodify(path, ":e")
	ext = ext ~= "" and ("." .. ext) or ""

	local i = 1
	while true do
		local candidate = string.format("%s/%s-copy%s", dir, name, i == 1 and ext or ("-" .. i .. ext))
		if not exists(candidate) then
			return candidate
		end
		i = i + 1
	end
end

local function copy_dir(src, dst)
	vim.fn.mkdir(dst, "p")

	local scanner = uv.fs_scandir(src)
	if not scanner then
		error("Gagal membaca folder: " .. src)
	end

	while true do
		local name, kind = uv.fs_scandir_next(scanner)
		if not name then
			break
		end

		local src_child = src .. "/" .. name
		local dst_child = dst .. "/" .. name
		if kind == "directory" then
			copy_dir(src_child, dst_child)
		elseif kind == "file" then
			assert(uv.fs_copyfile(src_child, dst_child), "Gagal copy file: " .. src_child)
		end
	end
end

function M.import(src, target_dir)
	src = strip_quotes(src)
	target_dir = vim.fn.fnamemodify(target_dir or uv.cwd(), ":p")

	local stat = uv.fs_stat(src)
	if not stat then
		vim.notify("File/folder tidak ditemukan: " .. src, vim.log.levels.ERROR)
		return
	end

	if not exists(target_dir) then
		vim.notify("Folder tujuan tidak ditemukan: " .. target_dir, vim.log.levels.ERROR)
		return
	end

	local dst = next_available_path(target_dir .. "/" .. vim.fn.fnamemodify(src, ":t"))

	local ok, err = pcall(function()
		if stat.type == "directory" then
			copy_dir(src, dst)
		else
			assert(uv.fs_copyfile(src, dst), "Gagal copy file: " .. src)
		end
	end)

	if not ok then
		vim.notify(err, vim.log.levels.ERROR)
		return
	end

	vim.notify("Imported: " .. vim.fn.fnamemodify(dst, ":."))
	vim.cmd("checktime")
end

function M.from_clipboard(target_dir)
	M.import(vim.fn.getreg("+"), target_dir)
end

function M.setup()
	vim.api.nvim_create_user_command("ImportFile", function(opts)
		M.import(opts.args)
	end, {
		nargs = "+",
		complete = "file",
		desc = "Copy file/folder ke folder project",
	})

	vim.api.nvim_create_user_command("ImportFileFromClipboard", function()
		M.from_clipboard()
	end, {
		desc = "Copy file/folder dari clipboard ke folder project",
	})
end

return M
