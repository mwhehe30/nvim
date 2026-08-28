-- plugins/vimwiki.lua
-- Task management & notes pribadi dengan Vimwiki (format .wiki)
-- Path wiki mengikuti folder project yang sedang dibuka (cwd saat Neovim start)

return {
	{
		"vimwiki/vimwiki",
		ft  = "vimwiki",
		cmd = {
			"VimwikiIndex",
			"VimwikiTabIndex",
			"VimwikiUISelect",
			"VimwikiDiaryIndex",
			"VimwikiDiaryGenerateLinks",
			"VimwikiSearch",
			"VimwikiBacklinks",
			"VimwikiGenerateLinks",
		},
		-- vimwiki_list HARUS di-set di init (sebelum plugin load), bukan di
		-- config — kalau di config, plugin sudah keburu load dan setting
		-- syntax/ext tidak terbaca (vimwiki/vimwiki#1319).
		init = function()
			vim.g.vimwiki_list = {
				{
					path   = vim.fn.getcwd() .. "/", -- wiki = folder project saat nvim dibuka
					syntax = "default",              -- format asli vimwiki (.wiki), bukan markdown
					ext    = ".wiki",
				},
			}
		end,
		keys = {
			{ "<leader>ww", "<cmd>VimwikiIndex<cr>",     desc = "Vimwiki: index" },
			{ "<leader>wt", "<cmd>VimwikiTabIndex<cr>",  desc = "Vimwiki: index (tab baru)" },
			{ "<leader>ws", "<cmd>VimwikiUISelect<cr>",  desc = "Vimwiki: pilih wiki" },
			{ "<leader>wd", "<cmd>VimwikiDiaryIndex<cr>", desc = "Vimwiki: diary index" },
		},
	},
}
