return {
  "mfussenegger/nvim-dap",
  dependencies = {
    "nvim-neotest/nvim-nio",
    "rcarriga/nvim-dap-ui",
    "leoluz/nvim-dap-go",
    "mfussenegger/nvim-dap-python",
    "suketa/nvim-dap-ruby",
  },

  config = function()
    -- Language specific changes
    -- https://github.com/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation
    local dap = require("dap")
    local dapui = require("dapui")
    local dappython = require("dap-python")
    local dapgo = require("dap-go")
    local dapruby = require("dap-ruby")

    dapruby.setup()
    dapui.setup()
    dapgo.setup()
    dappython.setup("~/.virtualenvs/debugpy/bin/python")

    -- Setup listeners
    dap.listeners.before.attach.dapui_config = function()
      dapui.open()
    end
    dap.listeners.before.launch.dapui_config = function()
      dapui.open()
    end
    dap.listeners.before.event_terminated.dapui_config = function()
      dapui.close()
    end
    dap.listeners.before.event_exited.dapui_config = function()
      dapui.close()
    end

    vim.keymap.set("n", "<Leader>dt", dap.toggle_breakpoint, {})
    vim.keymap.set("n", "<Leader>dc", dap.continue, {})
    vim.keymap.set("n", "<Leader>dl", dappython.test_method, {})
  end,
}
