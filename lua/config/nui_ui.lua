local M = {}

local function window_options()
	return {
		winblend = 0,
		winhighlight = table.concat({
			"Normal:Normal",
			"NormalFloat:Normal",
			"FloatBorder:Normal",
			"FloatTitle:Normal",
			"CursorLine:Visual",
			"Pmenu:Normal",
			"PmenuSel:Visual",
		}, ","),
	}
end

local function border(title)
	return {
		style = "single",
		text = title and title ~= "" and {
			top = " " .. title .. " ",
			top_align = "left",
		} or nil,
	}
end

function M.setup()
	local Input = require("nui.input")
	local Menu = require("nui.menu")
	local event = require("nui.utils.autocmd").event

	vim.ui.input = function(opts, on_confirm)
		opts = opts or {}

		local input = Input({
			position = "50%",
			size = {
				width = math.min(math.max(#(opts.default or ""), 24), math.max(vim.o.columns - 8, 24)),
			},
			border = border(opts.prompt or "Input"),
			win_options = window_options(),
		}, {
			prompt = "> ",
			default_value = opts.default or "",
			on_submit = function(value)
				on_confirm(value)
			end,
			on_close = function()
				on_confirm(nil)
			end,
		})

		input:mount()
		input:map("n", "<Esc>", function()
			input:unmount()
			on_confirm(nil)
		end, { noremap = true })
		input:map("i", "<Esc>", function()
			input:unmount()
			on_confirm(nil)
		end, { noremap = true })
		input:on(event.BufLeave, function()
			input:unmount()
		end)
	end

	vim.ui.select = function(items, opts, on_choice)
		opts = opts or {}

		local lines = {}
		for index, item in ipairs(items) do
			local text = opts.format_item and opts.format_item(item) or tostring(item)
			lines[index] = Menu.item(text, { value = item, index = index })
		end

		local menu = Menu({
			position = "50%",
			size = {
				width = math.min(math.max(32, math.floor(vim.o.columns * 0.4)), math.max(vim.o.columns - 8, 32)),
				height = math.min(math.max(#items, 1), math.max(vim.o.lines - 8, 1)),
			},
			border = border(opts.prompt or "Select"),
			win_options = window_options(),
		}, {
			lines = lines,
			max_width = math.max(vim.o.columns - 10, 20),
			keymap = {
				focus_next = { "j", "<Down>", "<Tab>" },
				focus_prev = { "k", "<Up>", "<S-Tab>" },
				close = { "<Esc>", "q" },
				submit = { "<CR>", "<Space>" },
			},
			on_close = function()
				on_choice(nil, nil)
			end,
			on_submit = function(item)
				on_choice(item.value, item.index)
			end,
		})

		menu:mount()
		menu:on(event.BufLeave, function()
			menu:unmount()
		end)
	end
end

return M
