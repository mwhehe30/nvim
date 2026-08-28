vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.import_file").setup()
require("config.lazy")
if vim.g.neovide then
	vim.o.guifont = "GoogleSansCode NFM:h16"
end
