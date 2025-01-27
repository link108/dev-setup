return {
  {
    "vim-test/vim-test",
    dependencies = {
      "preservim/vimux"
    },
  },
  { "nvim-neotest/neotest-plenary" },
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",
      "fredrikaverpil/neotest-golang",
      "nvim-neotest/neotest-jest",
      "nvim-neotest/neotest-python",
      "nvim-neotest/neotest-vim-test",
    },
    opts = { adapters = { "neotest-plenary" } },
    config = function()
      require("neotest").setup({
        adapters = {
          require("neotest-python")({
            dap = { justMyCode = false },
          }),
          require("neotest-golang"),
          require("neotest-plenary"),
          require("neotest-jest"),
          require("neotest-vim-test")({
            ignore_file_types = { "python", "vim", "lua", "go" },
          }),
        },
      })
    end,
  },
}


