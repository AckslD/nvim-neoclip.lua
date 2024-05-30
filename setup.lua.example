return {
	"AckslD/nvim-neoclip.lua",
	dependencies = {
		-- Uncomment for persistent history between sessions
		-- { "kkharji/sqlite.lua", module = "sqlite" },
		{ "nvim-telescope/telescope.nvim" },
		-- {'ibhagwan/fzf-lua'},
	},
	config = function()
		require("neoclip").setup({
			 -- The max number of entries to store (default 1000).
			history = 1000,
			-- If set to true the history is stored on VimLeavePre using sqlite.lua and lazy loaded when querying.
			enable_persistent_history = false,
			-- If set to true, the runtime history is synced with the persistent storage everytime it's changed or queried.
			-- If you often use multiple sessions in parallel and want the history synced you might want to enable this.
			continuous_sync = false,
			keys = {
				telescope = {
					i = {
						select = "<cr>",
						paste = "<c-p>",
						paste_behind = "<c-k>",
						replay = "<c-q>", -- replay a macro
						delete = "<c-d>", -- delete an entry
						edit = "<c-e>", -- edit an entry
						custom = {},
					},
					n = {
						select = "<cr>",
						paste = "p",
						--- It is possible to map to more than one key.
						-- paste = { 'p', '<c-p>' },
						paste_behind = "P",
						replay = "q",
						delete = "d",
						edit = "e",
						custom = {},
					},
				},
				fzf = {
					select = "default",
					paste = "ctrl-p",
					paste_behind = "ctrl-k",
					custom = {},
				},
			},
		})
	end,
}
