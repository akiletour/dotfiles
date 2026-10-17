local project = require("config.project")

local function current(name)
  return project.find(vim.api.nvim_buf_get_name(0), name) or {}
end

local phpstan_env = {
  HOME = vim.env.HOME,
  PATH = vim.env.PATH,
  TMPDIR = vim.env.TMPDIR,
  LANG = vim.env.LANG,
  DATABASE_USER = "phpstan",
  DATABASE_PASSWORD = "phpstan",
  DATABASE_SERVICE = "localhost:5432",
  DATABASE_NAME = "phpstan",
}

return {
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        php = { "phpcs", "phpstan" },
      },
      linters = {
        phpcs = {
          condition = function(ctx)
            return project.find(ctx.filename, "phpcs") ~= nil
          end,
          cmd = function()
            return current("phpcs").bin
          end,
          args = {
            "-q",
            "--report=json",
            function()
              return "--standard=" .. current("phpcs").config
            end,
            function()
              return "--stdin-path=" .. vim.api.nvim_buf_get_name(0)
            end,
            "-",
          },
        },
        phpstan = {
          condition = function(ctx)
            return project.find(ctx.filename, "phpstan") ~= nil
          end,
          cmd = function()
            return current("phpstan").bin
          end,
          args = {
            "analyse",
            "--error-format=json",
            "--no-progress",
            "--memory-limit=1G",
            "-c",
            function()
              return current("phpstan").config
            end,
          },
          env = phpstan_env,
        },
      },
    },
  },
}
