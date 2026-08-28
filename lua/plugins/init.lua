-- plugins/init.lua
-- Entry point untuk semua plugin.
-- Tambah/hapus kategori plugin di sini cukup dengan satu baris.

local modules = {
	"plugins.colorschemes",
	"plugins.ui",
	"plugins.editor",
	"plugins.lsp",
	"plugins.git",
	"plugins.terminal",
	"plugins.vimwiki",
	"plugins.extras",
}

local specs = {}
for _, mod in ipairs(modules) do
	local ok, list = pcall(require, mod)
	if ok then
		for _, spec in ipairs(list) do
			specs[#specs + 1] = spec
		end
	else
		vim.notify("plugins/init.lua: gagal load " .. mod .. "\n" .. list, vim.log.levels.ERROR)
	end
end

return specs
