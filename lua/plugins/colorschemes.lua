-- plugins/colorschemes.lua
-- Semua colorscheme / tema

return {
	{
		"sainnhe/everforest",
		lazy = false,
		priority = 1000,
		init = function()
			vim.o.background = "dark"
			vim.g.everforest_background = "hard"
			vim.g.everforest_enable_italic = 1
			vim.g.everforest_transparent_background = 0
		end,
		config = function()
			require("config.theme").restore()
		end,
	},
	{
		"Aejkatappaja/sora",
		lazy = true,
		opts = {
			transparent = false,
			italic = true,
			italic_comments = true,
		},
		config = function(_, opts)
			require("sora").setup(opts)
		end,
	},
	{
		"ydkulks/cursor-dark.nvim",
		lazy = true,
	},
	{
		"kepano/flexoki-neovim",
		name = "flexoki",
		lazy = true,
	},

	{
		"dgox16/oldworld.nvim",
		lazy = true,
		opts = {
			variant = "default",
		},
	},

	{
		"Everblush/nvim",
		name = "everblush",
		lazy = true,
		opts = {
			transparent_background = false,
			nvim_tree = { contrast = false },
		},
		config = function(_, opts)
			require("everblush").setup(opts)
		end,
	},

	{
		"sainnhe/sonokai",
		lazy = true,
		init = function()
			vim.g.sonokai_style = "atlantis"
			vim.g.sonokai_enable_italic = 1
			vim.g.sonokai_transparent_background = 0
			vim.g.sonokai_colors_override = {
				black = { "#111419", "233" },
				bg_dim = { "#15191F", "234" },
				bg0 = { "#181C22", "235" },
				bg1 = { "#202630", "235" },
				bg2 = { "#252C37", "236" },
				bg3 = { "#2B3340", "236" },
				bg4 = { "#323B49", "237" },
				bg_red = { "#392A30", "52" },
				bg_yellow = { "#373226", "94" },
				bg_green = { "#29352E", "22" },
				bg_blue = { "#273543", "17" },
				bg_purple = { "#312E40", "54" },
			}
		end,
	},

	{
		"aidyak/tokusa",
		lazy = true,
		opts = {},
		config = function(_, opts)
			require("tokusa").setup(opts)
		end,
	},

	{
		"topazape/oldtale.nvim",
		lazy = true,
	},

	{
		"mellow-theme/mellow.nvim",
		lazy = true,
	},

	{ "folke/tokyonight.nvim", lazy = true },
	{ "catppuccin/nvim", name = "catppuccin", lazy = true },
	{
		"rebelot/kanagawa.nvim",
		lazy = true,
		opts = {
			overrides = function(colors)
				return {
					LineNr = { bg = "#1F1F28" },
					SignColumn = { bg = "#1F1F28" },
					CursorLineNr = { bg = "#1F1F28" },
					FoldColumn = { bg = "#1F1F28" },
				}
			end,
		},
	},
	{
		"nlknguyen/papercolor-theme",
		lazy = true,
		init = function()
			vim.o.background = "dark"
		end,
	},
	{
		"slugbyte/lackluster.nvim",
		lazy = true,
		opts = {
			tweak_highlight = {
				Title = {
					fg = "#CCCCCC",
				},

				["@markup.heading"] = {
					fg = "#CCCCCC",
				},

				["@markup.heading.html"] = {
					fg = "#CCCCCC",
				},
			},
		},
	},
	{
		"ficcdaf/ashen.nvim",
		lazy = true,
		opts = {},
	},
	{
		"aktersnurra/no-clown-fiesta.nvim",
		lazy = true,
	},
	{
		"datsfilipe/vesper.nvim",
		lazy = true,
		opts = {
			transparent = false,
			italics = {
				comments = true,
				keywords = true,
				functions = true,
				strings = true,
				variables = true,
			},
			overrides = {},
			palette_overrides = {},
		},
	},

	{
		"kdheepak/monochrome.nvim",
		lazy = true,
		init = function()
			vim.o.background = "dark"
		end,
	},
	{
		"sam4llis/nvim-tundra",
		lazy = true,
	},
	{
		"ellisonleao/gruvbox.nvim",
		lazy = true,
		opts = {
			contrast = "hard",
		},
		init = function()
			vim.o.background = "dark"
		end,
	},
	{
		"aidyak/hitotose.nvim",
		lazy = true,
	},
}
