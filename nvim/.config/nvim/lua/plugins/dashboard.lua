return {
  "folke/snacks.nvim",
  opts = function(_, opts)
    local d = require("config.dashboard")
    opts.dashboard = opts.dashboard or {}
    opts.dashboard.width = 64
    opts.dashboard.preset = opts.dashboard.preset or {}
    opts.dashboard.preset.keys = {
      { icon = "󰚩 ", key = "c", desc = "Claude Code", action = d.claude },
      { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
      { icon = " ", key = "/", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
      { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles', { filter = { cwd = true } })" },
      { icon = " ", key = "D", desc = "Branch Changes", action = d.branch_changes, enabled = d.has_changes },
      { icon = " ", key = "p", desc = "Pull Request", action = d.open_pr, enabled = d.has_pr },
      { icon = " ", key = "i", desc = "Ticket", action = d.open_ticket, enabled = d.has_ticket },
      { icon = " ", key = "g", desc = "Lazygit", action = ":lua Snacks.lazygit()" },
      { icon = " ", key = "s", desc = "Restore Session", section = "session" },
      { icon = " ", key = ",", desc = "Config", action = ":lua Snacks.dashboard.pick('files', { cwd = vim.fn.stdpath('config') })" },
      { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
      { icon = " ", key = "R", desc = "Reload", action = d.reload },
      { icon = " ", key = "q", desc = "Quit", action = ":qa" },
    }
    opts.dashboard.sections = {
      d.header,
      d.ticket,
      d.conversations_section,
      { section = "keys", gap = 0, padding = 1 },
      { section = "startup" },
    }
  end,
}
