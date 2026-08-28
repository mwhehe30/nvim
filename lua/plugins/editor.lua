-- plugins/editor.lua
-- Fitur editing: file tree, fuzzy finder, treesitter, pairs, autotag

local mru_order = {}
local mru_group = vim.api.nvim_create_augroup("UserMruBuf", { clear = true })
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
	group = mru_group,
	callback = function(args)
		local b = args.buf
		if not vim.api.nvim_buf_is_valid(b) or vim.bo[b].buftype ~= "" then return end
		if vim.api.nvim_buf_get_name(b) == "" then return end
		for i, v in ipairs(mru_order) do
			if v == b then table.remove(mru_order, i); break end
		end
		table.insert(mru_order, 1, b)
	end,
})

local function buffer_switcher_mru()
	local pick = require("mini.pick")
	local bufs = {}
	local seen = {}
	-- 1) MRU order dulu
	for _, b in ipairs(mru_order) do
		if vim.api.nvim_buf_is_valid(b) and vim.bo[b].buftype == "" then
			local n = vim.api.nvim_buf_get_name(b)
			if n ~= "" then bufs[#bufs + 1] = n; seen[b] = true end
		end
end
	-- 2) buffer sisanya
	for _, b in ipairs(vim.api.nvim_list_bufs()) do
		if not seen[b] and vim.api.nvim_buf_is_valid(b) and vim.bo[b].buftype == "" then
			local n = vim.api.nvim_buf_get_name(b)
			if n ~= "" then bufs[#bufs + 1] = n end
		end
	end
	pick.start({ source = { name = "Buffers (MRU)", items = bufs } })
end

local perf = require("config.performance")

local function start_treesitter(bufnr, force)
	bufnr = bufnr or vim.api.nvim_get_current_buf()

	if not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end

	if not force and perf.is_large_buffer(bufnr) then
		if vim.b[bufnr].large_file_treesitter_prompted then
			return
		end

		vim.b[bufnr].large_file_treesitter_prompted = true
		local name = vim.api.nvim_buf_get_name(bufnr)
		local size = perf.file_size(name)
		local lines = vim.api.nvim_buf_line_count(bufnr)

		vim.schedule(function()
			vim.notify(
				string.format(
					"File besar terdeteksi (%d lines, %.1f KB). Treesitter dimatikan dulu biar ringan.",
					lines,
					size / 1024
				),
				vim.log.levels.WARN
			)

			vim.ui.select({ "Nyalakan Treesitter", "Tetap ringan" }, {
				prompt = "Treesitter untuk buffer ini?",
			}, function(choice)
				if choice == "Nyalakan Treesitter" and vim.api.nvim_buf_is_valid(bufnr) then
					pcall(vim.treesitter.start, bufnr)
					vim.b[bufnr].ts_highlight_disabled = false
					vim.notify("Treesitter dinyalakan untuk buffer ini", vim.log.levels.INFO)
				end
			end)
		end)

		vim.b[bufnr].ts_highlight_disabled = true
		return
	end

	pcall(vim.treesitter.start, bufnr)
	vim.b[bufnr].ts_highlight_disabled = false
end

return {
	-- File explorer
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		cmd = "Neotree",
		keys = {
			{
				"<C-n>",
				"<cmd>Neotree toggle right<cr>",
				desc = "Toggle Neo-tree",
			},
			{
				"<leader>e",
				"<cmd>Neotree reveal right<cr>",
				desc = "Reveal file in Neo-tree",
			},
		},
		dependencies = {
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			"echasnovski/mini.icons",
		},
		opts = {
			close_if_last_window = true,
			popup_border_style = "single",
			enable_git_status = true,
			enable_diagnostics = true,
			-- Catatan: posisi "selalu di kanan" dijamin oleh autocmd di
			-- lua/config/autocmds.lua (UserNeoTreeRight) yang bekerja untuk SEMUA
			-- kondisi, termasuk bug close_if_last_window yang memakai
			-- 'rightbelow vertical split' (tree jadi di kiri).
			filesystem = {
				bind_to_cwd = false,
				follow_current_file = { enabled = true, leave_dirs_open = false },
				filtered_items = {
					hide_dotfiles = false,
					hide_by_name = { "node_modules" },
				},
				use_libuv_file_watcher = false,
			},
			window = {
				position = "right",
				width = 32,
				mappings = {
					["<CR>"] = "open_or_image",
					["e"] = "rename",
					["I"] = "import_from_clipboard",
				},
			},
			commands = {
				open_or_image = function(state)
					require("config.image_open").neo_tree_enter(state)
				end,
				import_from_clipboard = function(state)
					local node = state.tree:get_node()
					local target = node.path
					if node.type ~= "directory" then
						target = vim.fn.fnamemodify(target, ":h")
					end
					require("config.import_file").from_clipboard(target)
					require("neo-tree.sources.manager").refresh(state.name)
				end,
			},
		},
	},

	-- Fuzzy finder
	{
		"echasnovski/mini.pick",
		version = "*",
		cmd = { "Pick" },
		keys = {
			{ "<Tab>", buffer_switcher_mru, desc = "Buffer list (MRU)" },
			{ "<S-Tab>", buffer_switcher_mru, desc = "Buffer list (MRU)" },
			{
				"<leader>th",
				function()
					local themes = {
						"everforest",
						"sora",
						"cursor-dark",
						"flexoki",
						"oldworld",
						"everblush",
						"sonokai",
						"tokyonight",
						"catppuccin",
						"kanagawa",
						"tokusa",
						"oldtale",
						"mellow",
						"PaperColor",
						"lackluster",
						"ashen",
						"no-clown-fiesta",
						"vesper",
						"monochrome",
						"tundra",
						"gruvbox",
						"hitotose",
					}

					require("lazy").load({
						plugins = {
							"sora",
							"cursor-dark.nvim",
							"flexoki",
							"oldworld.nvim",
							"everblush",
							"sonokai",
							"tokyonight.nvim",
							"catppuccin",
							"kanagawa.nvim",
							"tokusa",
							"oldtale.nvim",
							"mellow.nvim",
							"papercolor-theme",
							"lackluster.nvim",
							"ashen.nvim",
							"no-clown-fiesta.nvim",
							"vesper.nvim",
							"monochrome.nvim",
							"nvim-tundra",
							"gruvbox.nvim",
							"hitotose.nvim",
						},
					})
					vim.ui.select(themes, { prompt = "Choose theme" }, function(choice)
						if choice then
							pcall(vim.cmd.colorscheme, choice)
						end
					end)
				end,
				desc = "Choose theme",
			},
		},
		opts = {
			window = {
				config = function()
					local height = math.floor(0.75 * vim.o.lines)
					local width = math.floor(0.75 * vim.o.columns)
					return {
						anchor = "NW",
						height = height,
						width = width,
						row = math.floor(0.5 * (vim.o.lines - height)),
						col = math.floor(0.5 * (vim.o.columns - width)),
						border = "single",
					}
				end,
			},
		},
		config = function(_, opts)
			require("mini.pick").setup(opts)
		end,
	},

	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		event = { "BufReadPost", "BufNewFile" },
		cmd = { "TreesitterInstallCore" },

		config = function()
			vim.api.nvim_create_user_command("TreesitterInstallCore", function()
				require("nvim-treesitter").install({
					"lua",
					"vim",
					"vimdoc",
					"html",
					"css",
					"javascript",
					"typescript",
					"tsx",
					"json",
					"markdown",
					"php",
					"blade",
					"vue",
					"python",
					"yaml",
				})
			end, { desc = "Install core Treesitter parsers" })

			vim.api.nvim_create_user_command("TSForceStart", function()
				start_treesitter(0, true)
			end, { desc = "Force enable Treesitter for current buffer" })

			vim.api.nvim_create_user_command("TSStop", function()
				pcall(vim.treesitter.stop, 0)
				vim.b.ts_highlight_disabled = true
			end, { desc = "Stop Treesitter for current buffer" })

			vim.api.nvim_create_autocmd("FileType", {
				callback = function(args)
					start_treesitter(args.buf, false)
				end,
			})
		end,
	},

	-- Blade syntax support
	{
		"jwalton512/vim-blade",
		ft = "blade",
	},

	-- Alpine.js: syntax highlighting, snippets, magic property completion
	-- x-data, x-show, @click, :class, $el, $refs, dll
	-- Snippets load otomatis via luasnip.loaders.from_vscode
	{
		"connorontheweb/alpinejs.nvim",
		ft = { "blade", "html", "javascript", "typescript", "vue" },
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"L3MON4D3/LuaSnip",
		},
		opts = {},
	},

	-- Blade navigation & autocomplete untuk Laravel
	-- Autocomplete: <x-component>, <livewire:>, @include, route(), view(), config(), env()
	-- Navigation: gf untuk jump ke component/view/route
	{
		"RicardoRamirezR/blade-nav.nvim",
		ft = { "blade", "php" },
		opts = {
			close_tag_on_complete = false, -- nvim-ts-autotag sudah handle ini
			integrations = {
				cmp = false, -- tidak pakai nvim-cmp, pakai blink
				blink = true,
				coq = false,
			},
		},
	},

	-- Auto-close HTML/JSX tags
	{
		"windwp/nvim-ts-autotag",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			opts = {
				enable_close = true,
				enable_rename = true,
				enable_close_on_slash = false,
			},
		},
	},

	-- Navigasi cepat ke mana saja di layar
	-- s{2 huruf} → jump | S → treesitter jump | r → remote operator
	{
		"folke/flash.nvim",
		event = "VeryLazy",
		opts = {
			modes = {
				-- Enhanced f/t/F/T bawaan vim
				char = { enabled = true },
				-- Search / dengan flash labels
				search = { enabled = true },
			},
		},
		keys = {
			{
				"s",
				function()
					require("flash").jump()
				end,
				mode = { "n", "x", "o" },
				desc = "Flash jump",
			},
			{
				"S",
				function()
					require("flash").treesitter()
				end,
				mode = { "n", "x", "o" },
				desc = "Flash treesitter",
			},
			{
				"r",
				function()
					require("flash").remote()
				end,
				mode = "o",
				desc = "Flash remote",
			},
			{
				"R",
				function()
					require("flash").treesitter_search()
				end,
				mode = { "o", "x" },
				desc = "Flash treesitter search",
			},
			{
				"<C-s>",
				function()
					require("flash").toggle()
				end,
				mode = "c",
				desc = "Toggle flash search",
			},
		},
	},

	-- Auto-close brackets, quotes, dan backspace hapus pasangan (mini.pairs)
	{
		"echasnovski/mini.pairs",
		version = "*",
		event = "InsertEnter",
		config = function()
			require("mini.pairs").setup()

			-- Matikan pasangan otomatis di buffer khusus
			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "minipick", "neo-tree" },
				callback = function()
					vim.b.minipairs_disable = true
				end,
			})

			-- Perilaku ala VSCode: Enter di antara pasangan yang sebaris SELALU
			-- split jadi 3 baris — kurung ({}, (), []) ATAU tag HTML/JSX
			-- (<div>|</div>) — dengan baris tengah ter-indent. Mapping ini
			-- menggantikan map_cr mini.pairs (yang mengandalkan autoindent dan
			-- tidak konsisten saat kursor dipindah, bukan hasil ketikan).
			-- Catatan: edit buffer tidak boleh dilakukan langsung di mapping expr
			-- (textlock), jadi eksekusi split lewat <Cmd>lua<CR> (command mode).
			-- `close` bisa berupa 1 karakter kurung (mis. "}") atau string tag
			-- tutup (mis. "</div>").
			_G.nvim_split_pair = function(close)
				local row, col = unpack(vim.api.nvim_win_get_cursor(0))
				local line = vim.api.nvim_get_current_line()
				local indent = vim.fn.indent(row)
				local inner = indent + vim.fn.shiftwidth()
				-- buang penutup beserta isi baris mulai kursor, lalu tulis:
				-- baris sisa + baris tengah + (penutup + sisa baris setelah penutup)
				local after = line:sub(col + #close + 1)
				local l2 = line:sub(1, col)
				vim.api.nvim_buf_set_lines(
					0,
					row - 1,
					row,
					false,
					{ l2, string.rep(" ", inner), string.rep(" ", indent) .. close .. after }
				)
				vim.api.nvim_win_set_cursor(0, { row + 1, inner })
			end

			-- Deteksi pasangan tag yang membungkus kursor di baris yang sama,
			-- mis. kursor di antara <div> dan </div>. Return penutup "</nama>"
			-- kalau nama tag pembuka dan penutup cocok, selain itu nil.
			local function closing_tag_at(line, col)
				if line:sub(col, col) ~= ">" then
					return nil
				end
				local rest = line:sub(col + 1)
				local close = rest:match("^(</[%w%-]+>)")
				if not close then
					return nil
				end
				-- cari '<' terakhir sebelum kursor untuk dapat tag pembuka
				local before = line:sub(1, col - 1)
				local pos_after_lt = before:match(".*<()")
				if not pos_after_lt then
					return nil
				end
				local open_name = before:sub(pos_after_lt - 1):match("^<([%w%-]+)")
				local close_name = close:match("^</([%w%-]+)>")
				if open_name and open_name == close_name then
					return close
				end
				return nil
			end

			-- Satu-satunya pemilik <CR> di insert mode:
			--   1. di antara pasangan tag sebaris   -> split 3 baris (ala VSCode)
			--   2. di antara pasangan kurung sebaris -> split 3 baris (ala VSCode)
			--   3. menu completion blink terbuka     -> accept
			--   4. selain itu                        -> newline biasa (indent baris
			--      baru diatur indentexpr treesitter)
			vim.keymap.set("i", "<CR>", function()
				local _, col = unpack(vim.api.nvim_win_get_cursor(0))
				local line = vim.api.nvim_get_current_line()
				local prev = line:sub(col, col)
				local cur = line:sub(col + 1, col + 1)
				-- tag HTML/JSX: <div>|</div> -> 3 baris
				local close_tag = closing_tag_at(line, col)
				if close_tag then
					return "<Cmd>lua _G.nvim_split_pair('" .. close_tag .. "')<CR>"
				end
				-- kurung: {|} (|) [|] -> 3 baris
				for _, p in ipairs({ { "{", "}" }, { "(", ")" }, { "[", "]" } }) do
					if prev == p[1] and cur == p[2] then
						return "<Cmd>lua _G.nvim_split_pair('" .. p[2] .. "')<CR>"
					end
				end
				local ok, blink = pcall(require, "blink.cmp")
				if ok and blink.is_menu_visible() then
					return "<Cmd>lua require('blink.cmp').accept()<CR>"
				end
				return "<CR>"
			end, { expr = true, noremap = true, desc = "Enter: split kurung/tag / accept completion / newline" })
		end,
	},

	-- Comment/uncomment stabil untuk semua filetype
	-- gcc        → toggle comment baris
	-- gc{motion} → toggle comment dengan motion | contoh: gc3j = comment 3 baris ke bawah
	-- gc (visual)→ toggle comment seleksi
	{
		"echasnovski/mini.comment",
		version = "*",
		event = { "BufReadPost", "BufNewFile" },

		dependencies = {
			"JoosepAlviste/nvim-ts-context-commentstring",
		},

		config = function()
			require("ts_context_commentstring").setup({
				enable_autocmd = false,
			})

			require("mini.comment").setup({
				options = {
					custom_commentstring = function()
						local ok, commentstring =
							pcall(require("ts_context_commentstring.internal").calculate_commentstring)

						if ok and commentstring then
							return commentstring
						end

						return vim.bo.commentstring
					end,
				},
			})
		end,
	},

	-- Tambah/ubah/hapus surrounding: quotes, brackets, tags HTML
	-- ys{motion}{char}  → tambah  | contoh: ysiw" → bungkus kata dengan "
	-- cs{old}{new}      → ganti   | contoh: cs"'  → ganti " jadi '
	-- ds{char}          → hapus   | contoh: ds"   → hapus surrounding "
	-- S{char} (visual)  → bungkus seleksi
	{
		"kylechui/nvim-surround",
		event = "VeryLazy",
		version = "*",
		opts = {},
	},

	-- Riwayat undo visual (tree)
	{
		"mbbill/undotree",
		cmd = "UndotreeToggle",
		keys = {
			{ "<leader>u", "<cmd>UndotreeToggle<cr>", desc = "Undotree" },
		},
	},
}
