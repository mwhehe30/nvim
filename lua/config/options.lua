local opt = vim.opt

-- =========================================================
-- GENERAL
-- =========================================================

opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.mouse = "a"
opt.clipboard = "unnamedplus"

-- =========================================================
-- INDENTATION
-- =========================================================

opt.expandtab = true
opt.autoindent = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.smartindent = true

-- =========================================================
-- WRAPPING
-- =========================================================

opt.wrap = true
opt.linebreak = true
opt.breakindent = true

-- =========================================================
-- SEARCH
-- =========================================================

opt.ignorecase = true
opt.smartcase = true

-- =========================================================
-- SPLITS
-- =========================================================

opt.splitbelow = true
opt.splitright = true

-- =========================================================
-- SCROLLING
-- =========================================================

opt.scrolloff = 8
opt.sidescrolloff = 8

-- =========================================================
-- UI
-- =========================================================

opt.signcolumn = "yes"
opt.termguicolors = true
opt.laststatus = 3
opt.showtabline = 0
opt.showmode = false
opt.winblend = 0
opt.pumblend = 0

-- =========================================================
-- COMPLETION
-- =========================================================

opt.completeopt = {
	"menu",
	"menuone",
	"noselect",
}

-- =========================================================
-- MISC
-- =========================================================

opt.undofile = true
opt.updatetime = 500
opt.timeoutlen = 400
opt.confirm = true

-- =========================================================
-- SMOOTH SCROLL
-- =========================================================

if vim.fn.has("nvim-0.10") == 1 then
	opt.smoothscroll = true
end

-- =========================================================
-- FILE FORMAT
-- =========================================================

-- File baru menggunakan LF.
-- Tetap bisa membaca Unix / Windows / Mac.
opt.fileformat = "unix"
opt.fileformats = {
	"unix",
	"dos",
	"mac",
}

-- =========================================================
-- DIAGNOSTICS
-- =========================================================

vim.diagnostic.config({
	virtual_text = false,

	float = {
		border = "single",
		source = "if_many",
	},
})

-- =========================================================
-- LSP FLOATING WINDOWS
-- =========================================================

local function bordered_lsp_handler(handler)
	return function(err, result, ctx, config)
		config = vim.tbl_deep_extend("force", config or {}, {
			border = "single",
		})

		return handler(err, result, ctx, config)
	end
end

vim.lsp.handlers["textDocument/hover"] =
	bordered_lsp_handler(vim.lsp.handlers.hover)

vim.lsp.handlers["textDocument/signatureHelp"] =
	bordered_lsp_handler(vim.lsp.handlers.signature_help)

-- =========================================================
-- FILETYPE
-- =========================================================

vim.cmd("filetype plugin indent on")

-- =========================================================
-- WINDOWS
-- =========================================================

if vim.fn.has("win32") == 1 then

	-- =======================================================
	-- GIT BASH
	-- =======================================================

	-- Cari bash dari PATH terlebih dahulu.
	local bash = vim.fn.exepath("bash")

	if bash ~= "" then
		-- bash dari PATH tidak perlu path manual.
		--
		-- Kalau hasilnya ternyata C:/Program Files/...,
		-- kita quote supaya Neovim tidak memotong pada spasi.
		bash = '"' .. bash:gsub('"', "") .. '"'
	else
		-- Git Bash default.
		local bash_candidates = {
			"C:/Program Files/Git/bin/bash.exe",
			"C:/Program Files/Git/usr/bin/bash.exe",
			"C:/Git/bin/bash.exe",
			"C:/Git/usr/bin/bash.exe",
		}

		for _, path in ipairs(bash_candidates) do
			if vim.fn.filereadable(path) == 1 then
				bash = '"' .. path .. '"'
				break
			end
		end
	end

	if bash ~= "" then
		-- ===================================================
		-- PENTING:
		-- ===================================================
		-- Path executable di-quote karena "Program Files"
		-- mengandung spasi.
		opt.shell = bash

		-- Bash menggunakan -c untuk menjalankan command.
		opt.shellcmdflag = "-c"

		-- Bash di Windows membutuhkan quoting command.
		opt.shellquote = '"'
		opt.shellxquote = ""

		-- Unix-style path untuk Git Bash.
		opt.shellslash = true

		-- Redirection untuk shell Unix/Bash.
		opt.shellredir = ">%s 2>&1"
		opt.shellpipe = "2>&1| tee"

	else
		vim.schedule(function()
			vim.notify(
				"Git Bash tidak ditemukan.",
				vim.log.levels.WARN
			)
		end)
	end

	-- =======================================================
	-- GCC
	-- =======================================================

	-- Paksa Tree-sitter menggunakan GCC,
	-- bukan MSVC cl.exe.
	local home = vim.env.HOME or vim.env.USERPROFILE

	local gcc_candidates = {
		vim.fn.expand("~/scoop/apps/gcc/current/bin/gcc.exe"),

		home
			and (
				home:gsub("\\", "/")
				.. "/scoop/apps/gcc/current/bin/gcc.exe"
			)
			or nil,

		-- Fallback.
		"C:/Users/zaky/scoop/apps/gcc/current/bin/gcc.exe",
	}

	for _, gcc in ipairs(gcc_candidates) do
		if gcc and vim.fn.filereadable(gcc) == 1 then
			vim.env.CC = gcc
			break
		end
	end

	-- Kalau GCC tersedia melalui PATH / Scoop shim.
	if not vim.env.CC and vim.fn.executable("gcc") == 1 then
		vim.env.CC = vim.fn.exepath("gcc")
	end

	-- =======================================================
	-- CLIPBOARD
	-- =======================================================

	if vim.fn.executable("win32yank.exe") == 0 then
		vim.schedule(function()
			vim.notify(
				"win32yank.exe tidak ditemukan — clipboard (unnamedplus) tidak akan jalan.\n"
					.. "Install dengan: scoop install win32yank",
				vim.log.levels.WARN
			)
		end)
	end
end