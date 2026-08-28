-- plugins/ui.lua
-- Komponen antarmuka: statusline, indent scope, which-key, icons

return {
	{
		"MunifTanjim/nui.nvim",
		lazy = false,
		priority = 900,
		config = function()
			require("config.nui_ui").setup()
		end,
	},

	{
		"echasnovski/mini.icons",
		lazy = false,
		priority = 1000,
		config = function()
			require("mini.icons").setup()
			MiniIcons.mock_nvim_web_devicons()
		end,
	},

	{
		"nvim-lualine/lualine.nvim",
		event = "VeryLazy",
		dependencies = { "echasnovski/mini.icons" },
		opts = function()
			local function python_venv()
				if vim.bo.filetype ~= "python" then return "" end
				local path = vim.env.CONDA_DEFAULT_ENV or vim.env.VIRTUAL_ENV
				return path and ("venv: " .. vim.fn.fnamemodify(path, ":t")) or ""
			end

			local function lsp_clients()
				local names = {}
				for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
					names[#names + 1] = client.name
				end
				return #names > 0 and ("LSP: " .. table.concat(names, ", ")) or ""
			end

			local function lazy_updates()
				local ok, status = pcall(require, "lazy.status")
				return ok and status.has_updates() and ("updates: " .. status.updates()) or ""
			end

			return {
				options = {
					theme = "auto",
					globalstatus = true,
					disabled_filetypes = { statusline = { "dashboard", "alpha", "starter" } },
					component_separators = { left = "", right = "" },
					section_separators = { left = "", right = "" },
				},
				sections = {
					lualine_a = { { "mode", icon = "", fmt = string.lower } },
					lualine_b = {
						{ "branch", icon = "" },
						{ "diff", symbols = { added = "+", modified = "~", removed = "-" } },
					},
					lualine_c = {
						{
							"filename",
							path = 1,
							shorting_target = 40,
							symbols = { modified = " [+]", readonly = " [RO]", unnamed = "[No Name]" },
						},
					},
					lualine_x = {
						python_venv,
						{ "diagnostics", symbols = { error = "E:", warn = "W:", info = "I:", hint = "H:" } },
						lazy_updates,
						lsp_clients,
					},
					lualine_y = {
						{ "filetype", icon_only = false },
						{ "progress" },
					},
					lualine_z = { { "location" } },
				},
				inactive_sections = {
					lualine_a = {},
					lualine_b = { "filename" },
					lualine_c = {},
					lualine_x = { "location" },
					lualine_y = {},
					lualine_z = {},
				},
			}
		end,
	},

	{
		"echasnovski/mini.indentscope",
		version = "*",
		event = { "BufReadPost", "BufNewFile" },
		opts = {
			symbol = "│",
			options = { try_as_border = true },
		},
		init = function()
			vim.api.nvim_create_autocmd("FileType", {
				group = vim.api.nvim_create_augroup("UserMiniIndentscope", { clear = true }),
				pattern = {
					"help",
					"dashboard",
					"neo-tree",
					"Trouble",
					"lazy",
					"mason",
					"notify",
					"toggleterm",
				},
				callback = function()
					vim.b.miniindentscope_disable = true
				end,
			})
		end,
	},

	{
		"echasnovski/mini.bufremove",
		version = "*",
		keys = {
			{
				"<leader>x",
				function() require("mini.bufremove").delete(0, false) end,
				desc = "Close buffer (keep window)",
			},
			{
				"<leader>X",
				function() require("mini.bufremove").delete(0, true) end,
				desc = "Force close buffer",
			},
		},
	},

	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {
			spec = {
				{ "<leader>b", group = "Buffer" },
				{ "<leader>c", group = "Code" },
				{ "<leader>d", group = "Diagnostics" },
				{ "<leader>f", group = "Find / Format" },
				{ "<leader>g", group = "Git" },
				{ "<leader>l", group = "Log / Console" },
				{ "<leader>i", group = "Image" },
				{ "<leader>r", group = "Rename / Numbers" },
				{ "<leader>t", group = "Theme / Tools" },
				{ "<leader>w", group = "Workspace" },
			},
		},
	},
}
