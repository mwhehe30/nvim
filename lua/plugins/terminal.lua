-- plugins/terminal.lua
-- Terminal terintegrasi di dalam Neovim

local function new_terminal(direction)
	local Terminal = require("toggleterm.terminal").Terminal
	Terminal:new({ direction = direction, hidden = false }):open()
end

return {
	{
		"akinsho/toggleterm.nvim",
		version = "*",
		cmd     = "ToggleTerm",
		keys    = {
			{
				"<leader>h",
				function() new_terminal("horizontal") end,
				desc = "New horizontal terminal",
			},
			{
				"<leader>v",
				function() new_terminal("vertical") end,
				desc = "New vertical terminal",
			},
			{ "<leader>pt", "<cmd>TermSelect<cr>", desc = "Pick terminal" },
			{
				"<A-h>",
				"<cmd>ToggleTerm direction=horizontal<cr>",
				mode = { "n", "t" },
				desc = "Toggle horizontal terminal",
			},
			{
				"<A-v>",
				"<cmd>ToggleTerm direction=vertical size=80<cr>",
				mode = { "n", "t" },
				desc = "Toggle vertical terminal",
			},
			{
				"<A-i>",
				"<cmd>ToggleTerm direction=float<cr>",
				mode = { "n", "t" },
				desc = "Toggle floating terminal",
			},
		},
		opts = {
			open_mapping = nil,
			direction    = "float",
			float_opts   = { border = "single" },
		},
	},
}
