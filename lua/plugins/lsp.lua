-- plugins/lsp.lua
-- LSP, completion, formatting, diagnostics

local perf = require("config.performance")

return {
	-- Snippet engine
	{
		"L3MON4D3/LuaSnip",
		version = "2.*",
		event = "InsertEnter",
		dependencies = {
			"rafamadriz/friendly-snippets",
			"hollowtree/vscode-vue-snippets"
		},
		config = function()
			local ls = require("luasnip")
			local vscode = require("luasnip.loaders.from_vscode")

			-- Extend blade to include php and html snippets BEFORE lazy loading
			ls.filetype_extend("blade", { "php", "html" })
			-- Extend vue to include html and javascript snippets
			ls.filetype_extend("vue", { "html", "javascript", "typescript" })

			vscode.lazy_load()
		end,
	},

	-- Completion engine
	{
		"saghen/blink.cmp",
		event      = "InsertEnter",
		version    = "1.*",
		dependencies = {
			"L3MON4D3/LuaSnip",
		},
		opts = {
			keymap = {
				preset    = "none",
				-- Catatan: <CR> TIDAK di-map di sini. Mapping <CR> di insert mode
				-- ditangani satu tempat di lua/plugins/editor.lua (split kurung ala
				-- VSCode / accept completion blink / newline) biar tidak dobel.
				["<Tab>"] = { "select_next", "fallback" },
				["<S-Tab>"] = { "select_prev", "fallback" },
				["<Up>"]  = { "fallback" },
				["<Down>"] = { "fallback" },
				["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
			},
			appearance  = { nerd_font_variant = "mono" },
			completion  = {
				menu = { border = "single" },
				documentation = {
					auto_show = true,
					window = { border = "single" },
				},
				list = { selection = { preselect = false, auto_insert = false } },
			},
			signature = {
				enabled = true,
				window = { border = "single" },
			},
			sources     = {
				default = { "lsp", "blade-nav", "path", "snippets", "buffer" },
				providers = {
					["blade-nav"] = {
						name   = "blade-nav",
						module = "blade-nav.integrations.blink",
					},
				},
			},
			snippets    = { preset = "luasnip" },
			fuzzy       = { implementation = "prefer_rust_with_warning" },
		},
		opts_extend = { "sources.default" },
	},

	-- Package manager untuk LSP/linter/formatter
	{
		"mason-org/mason.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts  = {},
	},

	-- Bridge mason ↔ lspconfig
	{
		"mason-org/mason-lspconfig.nvim",
		event        = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"mason-org/mason.nvim",
			"neovim/nvim-lspconfig",
		},
		opts = {
			ensure_installed = {
				"lua_ls", "eslint", "html", "cssls",
				"tailwindcss", "jsonls", "ts_ls", "vue_ls",
				"emmet_language_server", "intelephense", "pyright",
			},
			-- Server di-enable manual di config/lsp.lua setelah custom config didaftarkan.
			automatic_enable = false,
		},
	},

	-- Extra tool installer (formatter, linter)
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		event        = { "BufReadPre", "BufNewFile" },
		dependencies = { "mason-org/mason.nvim" },
		opts = {
			ensure_installed = {
				"stylua",
				"prettier",
				"blade-formatter",
				"rustywind",
				"pint",
				"ruff",
			},
			run_on_start     = false, -- jangan cek tiap startup, jalankan manual :MasonToolsInstall
		},
	},

	-- LSP configs
	{
		"neovim/nvim-lspconfig",
		event        = { "BufReadPre", "BufNewFile" },
		dependencies = { "saghen/blink.cmp", "mason-org/mason.nvim" },
		opts         = { diagnostics = { virtual_text = false } },
		config       = function()
			require("config.lsp")
		end,
	},

	-- Formatting
	{
		"stevearc/conform.nvim",
		event = "BufWritePre",
		cmd   = { "ConformInfo", "Format" },
		keys  = {
			{
				"<leader>fm",
				function()
					require("conform").format({ async = true, lsp_format = "fallback" })
				end,
				mode = { "n", "x" },
				desc = "Format file",
			},
		},
		opts = {
			formatters_by_ft = {
				lua             = { "stylua" },
				php             = { "pint" },
				blade           = { "blade-formatter", stop_after_first = true },
				css             = { "prettier" },
				html            = { "prettier", "rustywind" },
				javascript      = { "prettier" },
				javascriptreact = { "prettier", "rustywind" },
				json            = { "prettier" },
				jsonc           = { "prettier" },
				markdown        = { "prettier" },
				scss            = { "prettier" },
				svelte          = { "prettier", "rustywind" },
				typescript      = { "prettier" },
				typescriptreact = { "prettier", "rustywind" },
				vue             = { "prettier", "rustywind" },
				python          = { "ruff_format" },
				yaml            = { "prettier" },
			},
			formatters = {
				prettier = {
					prepend_args = { "--single-quote", "--jsx-single-quote", "--single-attribute-per-line" },
				},
				["blade-formatter"] = {
					prepend_args = { "--wrap-attributes", "force-expand-multiline" },
				},
				pint = {
					command = function(self, ctx)
						local executable = vim.fn.has("win32") == 1 and "pint.bat" or "pint"
						local vendor = vim.fs.find("vendor", {
							path   = ctx.dirname,
							upward = true,
							type   = "directory",
						})[1]
						local local_pint = vendor and vim.fs.joinpath(vendor, "bin", executable)
						return local_pint and vim.fn.executable(local_pint) == 1 and local_pint or executable
					end,
				},
				rustywind = {
					command = vim.fn.has("win32") == 1 and "rustywind.cmd" or "rustywind",
					args    = { "--stdin" },
					stdin   = true,
				},
				ruff_format = {
					command = "ruff",
					args = { "format", "--stdin-filename", "$FILENAME", "--quiet", "-" },
					stdin = true,
				},
			},
			format_on_save = function(bufnr)
				if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
					return
				end

				local name = vim.api.nvim_buf_get_name(bufnr)
				if perf.is_ignored_path(name) then
					return
				end

				if perf.is_large_buffer(bufnr, { max_size = perf.max_autoformat_size, max_lines = 2500 }) then
					return
				end

				local ft = vim.bo[bufnr].filetype
				local slow_filetypes = {
					blade = true,
					php = true,
					svelte = true,
					vue = true,
					css = true,
					html = true,
					javascript = true,
					javascriptreact = true,
					typescript = true,
					typescriptreact = true,
					json = true,
					markdown = true,
					python = true,
					yaml = true,
				}

				local available, has_lsp = require("conform").list_formatters_to_run(bufnr)
				if #available == 0 and not has_lsp then
					return
				end

				return {
					timeout_ms = slow_filetypes[ft] and 5000 or 1200,
					lsp_format = "fallback",
				}
			end,
		},
		config = function(_, opts)
			require("conform").setup(opts)

			vim.api.nvim_create_user_command("FormatDisable", function(args)
				if args.bang then
					vim.b.disable_autoformat = true
				else
					vim.g.disable_autoformat = true
				end
			end, { bang = true, desc = "Disable autoformat globally, or for current buffer with !" })

			vim.api.nvim_create_user_command("FormatEnable", function()
				vim.b.disable_autoformat = false
				vim.g.disable_autoformat = false
			end, { desc = "Enable autoformat" })
		end,
	},

	-- LSP UI yang lebih baik (hover, diagnostics, rename, dll)
	{
		"nvimdev/lspsaga.nvim",
		event = "VeryLazy",
		dependencies = {
			"echasnovski/mini.icons",
			"nvim-treesitter/nvim-treesitter",
		},
		opts = {
			ui               = { border = "single" },
			lightbulb        = { enable = false },
			symbol_in_winbar = {
				enable = true,
				separator = " > ",
				show_file = true,
				folder_level = 0,
				hide_keyword = true,
			},
		},
		config = function(_, opts)
			require("lspsaga").setup(opts)

			-- Tampilkan float diagnostic saat cursor diam (hanya jika di atas error)
			vim.api.nvim_create_autocmd("CursorHold", {
				callback = function()
					local buf = vim.api.nvim_get_current_buf()
					if not vim.api.nvim_buf_is_valid(buf) then
						return
					end
					-- Skip di buffer non-file (Neo-tree, lazy, mason, dll)
					local ft = vim.bo[buf].filetype
					local skip = { "neo-tree", "lazy", "mason", "notify", "minipick", "toggleterm", "help" }
					for _, v in ipairs(skip) do
						if ft == v then
							return
						end
					end

					local cursor = vim.api.nvim_win_get_cursor(0)
					local line = cursor[1] - 1
					local col = cursor[2]

					local diagnostics = vim.diagnostic.get(0, { line = line })

					for _, diagnostic in ipairs(diagnostics) do
						local end_col = diagnostic.end_col or diagnostic.col + 1
						if col >= diagnostic.col and col <= end_col then
							vim.diagnostic.open_float(nil, {
								focusable = false,
								border    = "single",
								source    = "if_many",
								scope     = "cursor",
							})
							return
						end
					end
				end,
			})

			-- Keymaps LSP
			local map = vim.keymap.set
			map("n", "K",          "<cmd>Lspsaga hover_doc<CR>",      { desc = "Hover doc" })
			map("n", "gd",         "<cmd>Lspsaga goto_definition<CR>", { desc = "Goto definition" })
			map("n", "gD",         "<cmd>Lspsaga peek_definition<CR>", { desc = "Peek definition" })
			map("n", "gr",         "<cmd>Lspsaga finder<CR>",          { desc = "Finder" })
			map("n", "<leader>ca", "<cmd>Lspsaga code_action<CR>",     { desc = "Code action" })
			map("n", "<leader>rn", "<cmd>Lspsaga rename<CR>",          { desc = "Rename" })
		end,
	},
}
