-- plugins/extras.lua
-- Plugin tambahan: markdown, image preview, console log, AI completion

return {
	-- Render markdown dengan highlight di buffer
	{
		"MeanderingProgrammer/render-markdown.nvim",
		ft = "markdown",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"echasnovski/mini.icons",
		},
		keys = {
			{ "<leader>mp", "<cmd>RenderMarkdown toggle<cr>",  desc = "Toggle markdown render" },
			{ "<leader>me", "<cmd>RenderMarkdown enable<cr>",  desc = "Enable markdown render" },
			{ "<leader>md", "<cmd>RenderMarkdown disable<cr>", desc = "Disable markdown render" },
			{ "<leader>ma", "o- [ ] ", ft = "markdown", desc = "Add markdown checkbox" },
			{
				"<leader>mt",
				function()
					local line = vim.api.nvim_get_current_line()
					local toggled

					if line:find("^(%s*[-*+]%s+)%[ %]") then
						toggled = line:gsub("^(%s*[-*+]%s+)%[ %]", "%1[x]", 1)
					elseif line:find("^(%s*[-*+]%s+)%[[xX]%]") then
						toggled = line:gsub("^(%s*[-*+]%s+)%[[xX]%]", "%1[ ]", 1)
					end

					if not toggled then
						vim.notify("No markdown checkbox on current line", vim.log.levels.INFO)
						return
					end

					vim.api.nvim_set_current_line(toggled)
				end,
				ft = "markdown",
				desc = "Toggle markdown checkbox",
			},
		},
		opts = {},
	},

	-- Console.log helper untuk JavaScript/TypeScript
	{
		"chriswritescode-dev/consolelog.nvim",
		cmd = {
			"ConsoleLogToggle", "ConsoleLogClear", "ConsoleLogRun",
			"ConsoleLogInspect", "ConsoleLogInspectAll", "ConsoleLogInspectBuffer",
			"ConsoleLogDebugToggle", "ConsoleLogStatus", "ConsoleLogReload",
			"ConsoleLogDebug", "ConsoleLogDebugClear",
		},
		keys = {
			{ "<leader>lt", "<cmd>ConsoleLogToggle<cr>",         desc = "Toggle ConsoleLog" },
			{ "<leader>lr", "<cmd>ConsoleLogRun<cr>",            desc = "Run file" },
			{ "<leader>lx", "<cmd>ConsoleLogClear<cr>",          desc = "Clear outputs" },
			{ "<leader>li", "<cmd>ConsoleLogInspect<cr>",        desc = "Inspect at cursor" },
			{ "<leader>la", "<cmd>ConsoleLogInspectAll<cr>",     desc = "Inspect all" },
			{ "<leader>lb", "<cmd>ConsoleLogInspectBuffer<cr>",  desc = "Inspect buffer" },
			{ "<leader>ld", "<cmd>ConsoleLogDebugToggle<cr>",    desc = "Toggle debug" },
			{ "<leader>ls", "<cmd>ConsoleLogStatus<cr>",         desc = "Show status" },
			{ "<leader>lR", "<cmd>ConsoleLogReload<cr>",         desc = "Reload" },
			{ "<leader>lg", "<cmd>ConsoleLogDebug<cr>",          desc = "Open debug log" },
			{ "<leader>lG", "<cmd>ConsoleLogDebugClear<cr>",     desc = "Clear debug log" },
		},
		opts = {
			auto_enable = false,
			display = {
				virtual_text     = true,
				virtual_text_pos = "eol",
			},
			history = {
				enabled        = true,
				show_indicator = true,
				max_entries    = 10,
			},
		},
	},

	-- AI completion (Codeium)
	{
		"monkoose/neocodeium",
		event  = "VeryLazy",
		config = function()
			local neocodeium = require("neocodeium")
			neocodeium.setup({ manual = true, show_label = true })

			vim.keymap.set("i", "<A-f>", neocodeium.accept,       { desc = "Accept AI suggestion" })
			vim.keymap.set("i", "<A-W>", neocodeium.accept_word,   { desc = "Accept AI word" })
			vim.keymap.set("i", "<A-a>", neocodeium.accept_line,   { desc = "Accept AI line" })
			vim.keymap.set("i", "<A-n>", neocodeium.cycle_or_complete,       { desc = "Next AI suggestion" })
			vim.keymap.set("i", "<A-p>", function() neocodeium.cycle_or_complete(-1) end, { desc = "Prev AI suggestion" })
			vim.keymap.set("i", "<C-]>", neocodeium.clear,         { desc = "Clear AI suggestion" })
		end,
	},
}
