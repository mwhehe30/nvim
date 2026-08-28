-- config/lsp.lua
-- Setup semua LSP server
-- Stack: Laravel (PHP 8.4 + Blade + Livewire), React, Vite, Next.js

local capabilities = require("blink.cmp").get_lsp_capabilities()
local util         = require("lspconfig.util")
local perf         = require("config.performance")

-- Helper: resolved path to Mason-installed binary
local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
local win = vim.fn.has("win32") == 1
local function mason_cmd(name)
	return { mason_bin .. "/" .. name .. (win and ".cmd" or ""), "--stdio" }
end

if capabilities.workspace then
	capabilities.workspace.didChangeWatchedFiles = nil
end

local vue_plugin_path = vim.fs.joinpath(
	vim.fn.stdpath("data"),
	"mason",
	"packages",
	"vue-language-server",
	"node_modules",
	"@vue",
	"language-server"
)
local vue_tsserver_path = vim.fs.joinpath(
	vim.fn.stdpath("data"),
	"mason",
	"packages",
	"vue-language-server",
	"node_modules",
	"typescript",
	"lib",
	"tsserver.js"
)

-- typescript-language-server memecah path memakai separator native platform.
-- vim.fs.joinpath() menghasilkan forward slash di Windows, sehingga instalasi
-- TypeScript yang sebenarnya valid dapat dianggap tidak valid.
if vim.fn.has("win32") == 1 then
	vue_tsserver_path = vue_tsserver_path:gsub("/", "\\")
end
local vue_ts_plugin = vim.uv.fs_stat(vue_plugin_path) and {
	{
		name = "@vue/typescript-plugin",
		location = vue_plugin_path,
		languages = { "vue" },
	},
} or nil
local tsserver = vim.uv.fs_stat(vue_tsserver_path) and { path = vue_tsserver_path } or nil

-- Pastikan Neovim kenal .blade.php sebagai filetype "blade"
vim.filetype.add({
	pattern = { [".*%.blade%.php"] = "blade" },
	-- extension = {
	-- 	vue = "vue",
	-- },
})

-- on_attach: hanya keymap yang TIDAK ditangani lspsaga
local on_attach = function(_, bufnr)
	local map = function(lhs, rhs, desc)
		vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = desc })
	end

	map("gI", vim.lsp.buf.implementation, "Go to implementation")
	map("<leader>D", vim.lsp.buf.type_definition, "Go to type definition")
	map("<leader>wa", vim.lsp.buf.add_workspace_folder, "Add workspace folder")
	map("<leader>wr", vim.lsp.buf.remove_workspace_folder, "Remove workspace folder")
	map("<leader>wl", function()
		print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
	end, "List workspace folders")

	map("[d", function()
		vim.diagnostic.jump({ count = -1, float = true })
	end, "Prev diagnostic")
	map("]d", function()
		vim.diagnostic.jump({ count = 1, float = true })
	end, "Next diagnostic")
end

local eslint_fix_group = vim.api.nvim_create_augroup("UserEslintFixAll", { clear = true })

local function should_skip_save_action(bufnr)
	local name = vim.api.nvim_buf_get_name(bufnr)
	return perf.is_ignored_path(name)
		or perf.is_large_buffer(bufnr, { max_size = perf.max_autoformat_size, max_lines = 2500 })
end

local function read_package_json(path)
	local ok, content = pcall(vim.fn.readfile, path)
	if not ok or not content then
		return nil
	end

	local decoded_ok, package_json = pcall(vim.json.decode, table.concat(content, "\n"))
	if not decoded_ok or type(package_json) ~= "table" then
		return nil
	end

	return package_json
end

local function package_has_dependency(package_json, names)
	for _, key in ipairs({ "dependencies", "devDependencies", "peerDependencies", "optionalDependencies" }) do
		local deps = package_json[key]
		if type(deps) == "table" then
			for _, name in ipairs(names) do
				if deps[name] then
					return true
				end
			end
		end
	end

	return false
end

local function package_has_tailwind(path)
	local package_json = read_package_json(path)
	return package_json and package_has_dependency(package_json, {
		"tailwindcss",
		"@tailwindcss/vite",
		"@tailwindcss/postcss",
		"@tailwindcss/cli",
	})
end

local function package_has_eslint(path)
	local package_json = read_package_json(path)
	if not package_json then
		return false
	end

	return type(package_json.eslintConfig) == "table"
		or package_has_dependency(package_json, {
			"eslint",
			"@eslint/js",
			"typescript-eslint",
			"@typescript-eslint/eslint-plugin",
			"@typescript-eslint/parser",
			"eslint-config-next",
		})
end

local function eslint_root(bufnr, on_dir)
	local fname = vim.api.nvim_buf_get_name(bufnr)
	local config_root = util.root_pattern(
		".eslintrc",
		".eslintrc.js",
		".eslintrc.cjs",
		".eslintrc.json",
		"eslint.config.js",
		"eslint.config.cjs",
		"eslint.config.mjs",
		"eslint.config.ts",
		"eslint.config.cts",
		"eslint.config.mts"
	)(fname)

	if config_root then
		on_dir(config_root)
		return
	end

	local package_json = vim.fs.find("package.json", {
		path = fname,
		upward = true,
		type = "file",
	})[1]

	if package_json and package_has_eslint(package_json) then
		on_dir(vim.fs.dirname(package_json))
	end
end

local function tailwind_root(bufnr, on_dir)
	local fname = vim.api.nvim_buf_get_name(bufnr)
	local config_root = util.root_pattern(
		"tailwind.config.js",
		"tailwind.config.cjs",
		"tailwind.config.mjs",
		"tailwind.config.ts",
		"postcss.config.js",
		"postcss.config.cjs",
		"postcss.config.mjs",
		"postcss.config.ts"
	)(fname)

	if config_root then
		on_dir(config_root)
		return
	end

	local package_json = vim.fs.find("package.json", {
		path = fname,
		upward = true,
		type = "file",
	})[1]

	if package_json and package_has_tailwind(package_json) then
		on_dir(vim.fs.dirname(package_json))
	end
end

local servers = {
	-- ───────────────────────────────────────────
	-- Lua
	-- ───────────────────────────────────────────
	lua_ls = {
		cmd = mason_cmd("lua-language-server"),
		settings = {
			Lua = {
				diagnostics = { globals = { "vim" } },
				workspace   = { checkThirdParty = false },
				telemetry   = { enable = false },
			},
		},
	},

	-- ───────────────────────────────────────────
	-- ESLint
	-- Support: Laravel (resources/js), Vite, Next.js
	-- ───────────────────────────────────────────
	eslint = {
		cmd = mason_cmd("vscode-eslint-language-server"),
		filetypes = {
			"javascript",
			"javascriptreact",
			"typescript",
			"typescriptreact",
			"vue",
		},
		root_dir = eslint_root,
		settings = {
			workingDirectory = { mode = "auto" },
			format = false,
			validate = "on",
		},
		on_attach = function(client, bufnr)
			on_attach(client, bufnr)

			vim.api.nvim_buf_create_user_command(bufnr, "LspEslintFixAll", function()
				-- Async: tidak memblokir editor saat save
				vim.lsp.buf_request(bufnr, "workspace/executeCommand", {
					command = "eslint.applyAllFixes",
					arguments = {
						{
							uri = vim.uri_from_bufnr(bufnr),
							version = vim.lsp.util.buf_versions[bufnr],
						},
					},
				})
			end, { desc = "Apply all ESLint fixes" })

			vim.api.nvim_create_autocmd("BufWritePre", {
				group = eslint_fix_group,
				buffer = bufnr,
				callback = function()
					if vim.g.disable_eslint_fix_on_save or vim.b[bufnr].disable_eslint_fix_on_save then
						return
					end
					if should_skip_save_action(bufnr) then
						return
					end
					pcall(vim.cmd.LspEslintFixAll)
				end,
			})
		end,
	},

	-- ───────────────────────────────────────────
	-- HTML: .html + blade (untuk autocomplete atribut)
	-- ───────────────────────────────────────────
	html = {
		cmd = mason_cmd("vscode-html-language-server"),
		filetypes = { "html", "blade" },
	},

	-- ───────────────────────────────────────────
	-- CSS: tambah scss/less/blade
	-- ───────────────────────────────────────────
	cssls = {
		cmd = mason_cmd("vscode-css-language-server"),
		filetypes = { "css", "scss", "less", "blade" },
	},

	-- ───────────────────────────────────────────
	-- JSON: schema untuk file populer
	-- ───────────────────────────────────────────
	jsonls = {
		cmd = mason_cmd("vscode-json-language-server"),
		settings = {
			json = {
				schemas = {
					{ fileMatch = { "package.json" },                    url = "https://json.schemastore.org/package.json" },
					{ fileMatch = { "tsconfig*.json" },                  url = "https://json.schemastore.org/tsconfig.json" },
					{ fileMatch = { "composer.json" },                   url = "https://json.schemastore.org/composer.json" },
					{ fileMatch = { ".eslintrc", ".eslintrc.json" },     url = "https://json.schemastore.org/eslintrc.json" },
					{ fileMatch = { ".prettierrc", ".prettierrc.json" }, url = "https://json.schemastore.org/prettierrc.json" },
					{ fileMatch = { ".babelrc", ".babelrc.json" },       url = "https://json.schemastore.org/babelrc.json" },
				},
				validate = { enable = true },
			},
		},
	},

	-- ───────────────────────────────────────────
	-- PHP + Blade (Laravel 11, PHP 8.4)
	-- ───────────────────────────────────────────
	intelephense = {
		cmd = mason_cmd("intelephense"),
		filetypes = { "php", "blade" },
		-- Blade filetype harus dikirim sebagai "php" ke LSP server,
		-- karena Intelephense tidak mengenal languageId "blade"
		get_language_id = function(_, filetype)
			if filetype == "blade" then return "php" end
			return filetype
		end,
		settings  = {
			intelephense = {
				filetypes = { "php", "blade" },
				files     = {
					associations = { "*.php", "*.blade.php" },
					maxSize      = 5000000,
				},
				stubs = {
					"apache", "bcmath", "bz2", "calendar", "com_dotnet",
					"core", "ctype", "curl", "date", "dba", "dom",
					"enchant", "exif", "ffi", "fileinfo", "filter",
					"ftp", "gd", "gettext", "gmp", "hash", "iconv",
					"imap", "intl", "json", "ldap", "libxml", "mbstring",
					"meta", "mysqli", "oci8", "odbc", "openssl", "pcntl",
					"pcre", "pdo", "pgsql", "phar", "posix", "pspell",
					"readline", "reflection", "session", "simplexml",
					"snmp", "soap", "sockets", "sodium", "spl", "sqlite3",
					"standard", "superglobals", "sysvmsg", "sysvsem",
					"sysvshm", "tidy", "tokenizer", "xml", "xmlreader",
					"xmlrpc", "xmlwriter", "xsl", "zip", "zlib",
				},
				environment  = { phpVersion = "8.4" },
				diagnostics  = { enable = true },
				completion   = { fullyQualifyGlobalConstantsAndFunctions = false },
			},
		},
	},

	-- ───────────────────────────────────────────
	-- Tailwind CSS
	-- Support: Blade, React, Next.js, Vite
	-- ───────────────────────────────────────────
	tailwindcss = {
		cmd = mason_cmd("tailwindcss-language-server"),
		root_dir = tailwind_root,
		filetypes = {
			"blade", "css", "html",
			"javascript", "javascriptreact",
			"typescript", "typescriptreact",
			"svelte", "vue", "astro",
		},
		settings = {
			tailwindCSS = {
				includeLanguages = {
					blade = "html",
				},
			},
		},
	},

	-- ───────────────────────────────────────────
	-- Emmet
	-- ───────────────────────────────────────────
	emmet_language_server = {
		cmd = mason_cmd("emmet-language-server"),
		filetypes = {
			"blade", "css", "html",
			"javascriptreact", "typescriptreact",
			"less", "sass", "scss", "vue",
		},
	},

	-- ───────────────────────────────────────────
	-- Vue
	-- ───────────────────────────────────────────
	vue_ls = {
		cmd = mason_cmd("vue-language-server"),
		filetypes = { "vue" },
	},

	-- ───────────────────────────────────────────
	-- Python (via uv)
	-- ───────────────────────────────────────────
	pyright = {
		cmd = mason_cmd("pyright-langserver"),
		root_dir = function(bufnr, on_dir)
			local fname = vim.api.nvim_buf_get_name(bufnr)
			-- Prioritaskan project marker uv/pip, fallback ke root_pattern biasa
			local root = util.root_pattern(
				"pyproject.toml",
				"setup.py",
				"setup.cfg",
				"requirements.txt",
				"uv.lock",
				"Pipfile",
				".git"
			)(fname)
			if root then
				on_dir(root)
			end
		end,
		settings = {
			python = {
				analysis = {
					typeCheckingMode = "basic",
					autoSearchPaths = true,
					useLibraryCodeForTypes = true,
					diagnosticMode = "openFilesOnly",
				},
			},
		},
	},

	-- ───────────────────────────────────────────
	-- TypeScript / JavaScript
	-- Support: React (Laravel), Vite, Next.js, Vue
	-- ───────────────────────────────────────────
	ts_ls = {
		cmd = mason_cmd("typescript-language-server"),
		-- Jangan fallback ke cwd; itu bisa membuat tsserver scan folder terlalu luas.
		root_dir = function(bufnr, on_dir)
			local fname = vim.api.nvim_buf_get_name(bufnr)
			local root = util.root_pattern(
				"tsconfig.json",
				"tsconfig.base.json",
				"jsconfig.json",
				"package.json",
				"package-lock.json",
				"yarn.lock",
				"pnpm-lock.yaml",
				"bun.lockb",
				"bun.lock",
				".git"
			)(fname)
			if not root then
				return
			end
			on_dir(root)
		end,
		filetypes = {
			"javascript", "javascriptreact",
			"typescript", "typescriptreact",
			"vue",
		},
		init_options = {
			hostInfo = "neovim",
			preferences = {
				includeCompletionsForModuleExports    = true,
				includeCompletionsForImportStatements = true,
				includePackageJsonAutoImports         = "auto",
				importModuleSpecifierPreference       = "non-relative",
				disableAutomaticTypingAcquisition     = true,
			},
			plugins = vue_ts_plugin,
			tsserver = tsserver,
		},
		settings = {
			typescript = {
				format = { enable = false },
				inlayHints = {
					includeInlayEnumMemberValueHints            = true,
					includeInlayFunctionLikeReturnTypeHints     = true,
					includeInlayFunctionParameterTypeHints      = true,
					includeInlayParameterNameHints              = "literals",
					includeInlayPropertyDeclarationTypeHints    = true,
					includeInlayVariableTypeHints               = false,
				},
			},
			javascript = {
				format = { enable = false },
				inlayHints = {
					includeInlayEnumMemberValueHints            = true,
					includeInlayFunctionLikeReturnTypeHints     = true,
					includeInlayFunctionParameterTypeHints      = true,
					includeInlayParameterNameHints              = "literals",
					includeInlayPropertyDeclarationTypeHints    = true,
					includeInlayVariableTypeHints               = false,
				},
			},
		},
	},
}

local server_order = {
	"lua_ls",
	"eslint",
	"html",
	"cssls",
	"jsonls",
	"intelephense",
	"tailwindcss",
	"emmet_language_server",
	"ts_ls",
	"vue_ls",
	"pyright",
}

for _, name in ipairs(server_order) do
	local config = servers[name]
	if config then
		config.capabilities = capabilities
		config.on_attach = config.on_attach or on_attach
		vim.lsp.config(name, config)
	end
end

vim.lsp.enable(server_order)

-- ───────────────────────────────────────────
-- Keymap khusus TypeScript/JavaScript
-- ───────────────────────────────────────────
local function source_action(kind)
	vim.lsp.buf.code_action({
		apply   = true,
		context = { only = { kind }, diagnostics = {} },
	})
end

vim.api.nvim_create_autocmd("FileType", {
	pattern  = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
	callback = function(args)
		vim.keymap.set("n", "<leader>ci", function()
			source_action("source.addMissingImports.ts")
		end, { buffer = args.buf, desc = "Add missing imports" })
		vim.keymap.set("n", "<leader>co", function()
			source_action("source.organizeImports.ts")
		end, { buffer = args.buf, desc = "Organize imports" })
	end,
})
