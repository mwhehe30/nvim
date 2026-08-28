local group = vim.api.nvim_create_augroup("UserConfig", { clear = true })

-- Aktifkan indentasi berbasis treesitter.
-- Catatan: modul builtin `vim.treesitter.indent` dihapus dari core di Neovim 0.12,
-- jadi untuk 0.12+ pakai API dari nvim-treesitter (branch main).
-- Kalau parser untuk filetype-nya belum terpasang, biarkan indentexpr bawaan runtime
-- (tidak di-override) supaya indentasi lama tetap jalan.
local function enable_treesitter_indent(buf)
	-- Neovim 0.12+: pakai API plugin nvim-treesitter; 0.10/0.11: builtin lama.
	local expr
	if vim.fn.has("nvim-0.12") == 1 then
		local ok, lang = pcall(vim.treesitter.language.get_lang, vim.bo[buf].filetype)
		if not ok or not lang then
			return
		end
		local ok_add, loaded = pcall(vim.treesitter.language.add, lang)
		if not (ok_add and loaded) then
			return -- parser belum terpasang, biarkan indentasi bawaan runtime
		end
		expr = "v:lua.require'nvim-treesitter'.indentexpr()"
	else
		expr = "v:lua.require'vim.treesitter.indent'.get_indent_expr()"
	end

	vim.bo[buf].indentexpr = expr

	-- Perilaku ala VSCode: baris ikut di-reindent saat mengetik kurung tutup
	-- `}`, `)`, `]` di posisi mana pun (bukan cuma di kolom 0 seperti default Vim).
	local parts = vim.split(vim.bo[buf].indentkeys or "", ",")
	local present = {}
	for _, p in ipairs(parts) do
		present[p] = true
	end
	local add = {}
	for _, c in ipairs({ "}", ")", "]" }) do
		if not present[c] then
			add[#add + 1] = c
		end
	end
	if #add > 0 then
		vim.bo[buf].indentkeys = (vim.bo[buf].indentkeys or "") .. "," .. table.concat(add, ",")
	end
end

-- Kembali ke posisi terakhir saat buka buffer
vim.api.nvim_create_autocmd("BufReadPost", {
	group = group,
	callback = function()
		local mark = vim.api.nvim_buf_get_mark(0, '"')
		local lines = vim.api.nvim_buf_line_count(0)
		if mark[1] > 0 and mark[1] <= lines then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

-- File baru disimpan dengan LF; file lama dibiarkan sesuai format aslinya (CRLF tidak dikonversi diam-diam)
vim.api.nvim_create_autocmd("BufNewFile", {
	group = group,
	callback = function(args)
		if vim.bo[args.buf].buftype == "" then
			vim.bo[args.buf].fileformat = "unix"
		end
	end,
})

-- Indentasi khusus untuk PHP dan Blade
vim.api.nvim_create_autocmd("FileType", {
	group = group,
	pattern = { "php", "blade" },
	callback = function(args)
		vim.bo[args.buf].autoindent = true
		vim.bo[args.buf].expandtab = true
		vim.bo[args.buf].shiftwidth = 4
		vim.bo[args.buf].tabstop = 4
		vim.bo[args.buf].softtabstop = 4

		if vim.bo[args.buf].filetype == "php" then
			vim.bo[args.buf].smartindent = false
			enable_treesitter_indent(args.buf)
		end
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	group = group,
	pattern = {
		"astro",
		"blade",
		"css",
		"html",
		"javascript",
		"javascriptreact",
		"json",
		"jsonc",
		"scss",
		"svelte",		"typescript", "typescriptreact",
		"python",
		"vue",
	},
	callback = function(args)
		vim.bo[args.buf].autoindent = true
		vim.bo[args.buf].smartindent = false
		enable_treesitter_indent(args.buf)
	end,
})

-- Simpan tema saat keluar
vim.api.nvim_create_autocmd("VimLeavePre", {
	group = group,
	callback = function()
		require("config.theme").save()
	end,
})

-- Matikan cursorline saat mengetik (Insert Mode) untuk performa, aktifkan di Normal Mode
vim.api.nvim_create_autocmd({ "InsertEnter", "WinLeave" }, {
	group = group,
	callback = function()
		vim.wo.cursorline = false
	end,
})
vim.api.nvim_create_autocmd({ "InsertLeave", "WinEnter" }, {
	group = group,
	callback = function()
		vim.wo.cursorline = true
	end,
})
-- Samakan background breadcrumb winbar dengan panel Neo-tree.
local winbar_group = vim.api.nvim_create_augroup("UserWinbarTheme", { clear = true })
local function match_winbar_to_explorer()
	vim.api.nvim_set_hl(0, "WinBar", { link = "NeoTreeNormal" })
	vim.api.nvim_set_hl(0, "WinBarNC", { link = "NeoTreeNormal" })
end

vim.api.nvim_create_autocmd({ "ColorScheme", "VimEnter" }, {
	group = winbar_group,
	callback = function()
		vim.schedule(match_winbar_to_explorer)
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	group = winbar_group,
	pattern = "neo-tree",
	callback = match_winbar_to_explorer,
})

-- Neo-tree SELALU di sisi kanan. Setiap ada perubahan layout (window baru, buffer
-- masuk window, window tertutup), kalau window tree bukan yang paling kanan —
-- misalnya akibat bug `close_if_last_window` neo-tree yang memakai
-- 'rightbelow vertical split' sehingga tree jadi di kiri — pindahkan ke kanan.
local neotree_right_group = vim.api.nvim_create_augroup("UserNeoTreeRight", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
	group = neotree_right_group,
	pattern = "neo-tree",
	callback = function()
		vim.schedule(function()
			local wins = vim.api.nvim_tabpage_list_wins(0)
			for _, win in ipairs(wins) do
				local buf = vim.api.nvim_win_get_buf(win)
				local is_tree = vim.bo[buf].filetype == "neo-tree"
				local is_float = vim.api.nvim_win_get_config(win).relative ~= ""
				if is_tree and not is_float then
					local pos = vim.api.nvim_win_get_position(win)
					for _, w2 in ipairs(wins) do
						if w2 ~= win and vim.api.nvim_win_get_config(w2).relative == "" then
							local p2 = vim.api.nvim_win_get_position(w2)
							if p2[2] > pos[2] then
								vim.api.nvim_win_call(win, function()
									vim.cmd("wincmd L")
								end)
								return
							end
						end
					end
				end
			end
		end)
	end,
})
