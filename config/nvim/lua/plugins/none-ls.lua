return {
	"nvimtools/none-ls.nvim",
	dependencies = {
		"nvimtools/none-ls-extras.nvim",
	},
	config = function()
    -- Language specific changes
		local null_ls = require("null-ls")

		null_ls.setup({
			sources = {

        -- golang
        null_ls.builtins.diagnostics.golangci_lint,

        -- lua
				null_ls.builtins.formatting.stylua,

        -- ruby
        null_ls.builtins.diagnostics.rubocop,
        null_ls.builtins.formatting.rubocop,


        -- python
				null_ls.builtins.diagnostics.pylint,
				null_ls.builtins.formatting.black,
				null_ls.builtins.formatting.isort,

        -- js
				null_ls.builtins.formatting.prettier,
        -- require("none-ls.diagnostics.eslint_d"),
			},
		})

		vim.keymap.set("n", "<leader>gf", vim.lsp.buf.format, {})
	end,
}
