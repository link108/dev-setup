return {
	{
		"williamboman/mason.nvim",
		lazy = false,
		config = function()
			require("mason").setup()
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		lazy = false,
		opts = {
     ensure_installed = {"lua_ls", "clangd", "elixirls", "pyright", "ruby_lsp", "tsserver", "gopls", "marksman", "arduino_language_server"},
		},
	},
	{
    -- Language specific changes
		"neovim/nvim-lspconfig",
		lazy = false,
		config = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			local lspconfig = require("lspconfig")

      -- lua
			lspconfig.lua_ls.setup({
        capabilities = capabilities,
			})

      -- c / c++
			lspconfig.clangd.setup({
				capabilities = capabilities,
			})

      -- elixir
			lspconfig.elixirls.setup({
				capabilities = capabilities,
			})

      -- python
			lspconfig.pyright.setup({
				capabilities = capabilities,
			})

      -- ruby
      lspconfig.ruby_lsp.setup({
				capabilities = capabilities,
			})

      -- javascript
      lspconfig.ts_ls.setup({
				capabilities = capabilities,
			})

      -- golang
      lspconfig.gopls.setup({
				capabilities = capabilities,
			})

      -- markdown
      lspconfig.marksman.setup({
				capabilities = capabilities,
			})

      -- TODO fix this
      -- glsl
      lspconfig.glslls.setup({
				capabilities = capabilities,
			})


			vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
			vim.keymap.set("n", "gd", vim.lsp.buf.definition, {})
			vim.keymap.set("n", "gr", vim.lsp.buf.references, {})
			vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, {})
			-- vim.keymap.set({ "n", "v" }, "<leader>rn", vim.lsp.buf.rename, {})
		end,
	},
}
