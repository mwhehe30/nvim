local map = vim.keymap.set

local function pick_oldfiles()
	local items = vim.tbl_filter(function(path)
		return vim.fn.filereadable(path) == 1
	end, vim.v.oldfiles)

	require("mini.pick").start({
		source = {
			name = "Old files",
			items = items,
			choose = function(path)
				vim.cmd.edit(vim.fn.fnameescape(path))
			end,
		},
	})
end

local function pick_buffer_lines()
	local bufnr = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local items = {}

	for index, line in ipairs(lines) do
		items[index] = string.format("%d:%s", index, line)
	end

	require("mini.pick").start({
		source = {
			name = "Buffer lines",
			items = items,
			choose = function(item)
				local line = tonumber(item:match("^(%d+):"))
				if line then
					vim.api.nvim_win_set_cursor(0, { line, 0 })
				end
			end,
		},
	})
end

-------------------------------------------------
-- INSERT MODE NAVIGATION (ALT HJKL)
-------------------------------------------------

map("i", "<A-h>", "<Left>",  { desc = "Left" })
map("i", "<A-l>", "<Right>", { desc = "Right" })
map("i", "<A-j>", "<Down>",  { desc = "Down" })
map("i", "<A-k>", "<Up>",    { desc = "Up" })

-- word navigation (sama seperti normal mode b/w/e)
map("i", "<A-b>", "<C-o>b", { desc = "Word backward" })
map("i", "<A-w>", "<C-o>w", { desc = "Word forward" })
map("i", "<A-e>", "<C-o>e", { desc = "Word end" })

-- optional cepat ke awal / akhir baris
map("i", "<C-b>", "<Esc>^i", { desc = "Start line" })
map("i", "<C-e>", "<End>",   { desc = "End line" })

-- exit insert mode
map("i", "jk", "<Esc>", { desc = "Exit insert mode" })

-------------------------------------------------
-- JUMP KE ')'
-------------------------------------------------

-- insert mode jump ke )
map("i", "<A-]>", "<C-o>f)", { desc = "Jump next ')'" })
map("i", "<A-[>", "<C-o>F)", { desc = "Jump prev ')'" })

-------------------------------------------------
-- NORMAL MODE GENERAL
-------------------------------------------------

map("n", ";", ":", { desc = "Command mode" })
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

map("n", "<C-s>", "<cmd>write<cr>", { desc = "Save file" })

map("n", "<leader>n", "<cmd>set number!<cr>", { desc = "Toggle number" })
map("n", "<leader>rN", "<cmd>set relativenumber!<cr>", { desc = "Toggle relative number" })

-------------------------------------------------
-- WINDOW NAVIGATION (CTRL HJKL)
-------------------------------------------------

map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })

-------------------------------------------------
-- BUFFER MANAGEMENT
-------------------------------------------------

map("n", "<leader>b", "<cmd>enew<cr>", { desc = "New buffer" })
-- <leader>x dan <leader>X dihandle oleh mini.bufremove (plugins/ui.lua)
-- <Tab> dan <S-Tab> dihandle oleh mini.pick MRU (plugins/editor.lua)

map("n", "<A-Right>", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "<A-Left>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })

-------------------------------------------------
-- EDITING
-------------------------------------------------

-- Tambah ; di akhir baris (berguna untuk PHP)
map("i", "<A-;>", "<Esc>A;",    { desc = "Append semicolon" })
map("n", "<A-;>", "A;<Esc>",    { desc = "Append semicolon" })

map("n", "<A-Up>", "<cmd>move .-2<cr>==", { desc = "Move line up" })
map("n", "<A-Down>", "<cmd>move .+1<cr>==", { desc = "Move line down" })

map("i", "<A-Up>", "<Esc><cmd>move .-2<cr>==gi", { desc = "Move line up" })
map("i", "<A-Down>", "<Esc><cmd>move .+1<cr>==gi", { desc = "Move line down" })

map("v", "<A-Up>", ":move '<-2<cr>gv=gv", { desc = "Move selection up" })
map("v", "<A-Down>", ":move '>+1<cr>gv=gv", { desc = "Move selection down" })

map("v", "<", "<gv")
map("v", ">", ">gv")

-------------------------------------------------
-- PICKER
-------------------------------------------------

map("n", "<leader>ff", "<cmd>Pick files<cr>", { desc = "Find files" })
map("n", "<leader>fw", "<cmd>Pick grep_live<cr>", { desc = "Live grep" })
map("n", "<leader>fb", "<cmd>Pick buffers<cr>", { desc = "Buffers" })
map("n", "<leader>fh", "<cmd>Pick help<cr>", { desc = "Help tags" })
map("n", "<leader>fo", pick_oldfiles, { desc = "Old files" })
map("n", "<leader>fz", pick_buffer_lines, { desc = "Buffer lines" })

-------------------------------------------------
-- TERMINAL
-------------------------------------------------

map("t", "<C-x>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-------------------------------------------------
-- UTILITIES
-------------------------------------------------

map("n", "<leader>ds", vim.diagnostic.setloclist, { desc = "Diagnostics list" })

map("n", "<leader>ch", "<cmd>WhichKey<cr>", { desc = "WhichKey" })

map("n", "<leader>io", function()
  require("config.image_open").open()
end, { desc = "Open image" })
