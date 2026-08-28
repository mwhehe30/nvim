-- plugins/git.lua
-- Integrasi Git

return {
	-- Git signs di gutter (added/changed/removed lines)
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		keys = {
			{ "<leader>gb", "<cmd>Gitsigns toggle_current_line_blame<cr>", desc = "Toggle git blame" },
		},
		opts = {
			current_line_blame = false,
			current_line_blame_opts = { virt_text_pos = "right_align" },
		},
	},
}
