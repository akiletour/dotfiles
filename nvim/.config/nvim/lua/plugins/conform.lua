local project = require("config.project")

local function php(ctx)
  return project.php_formatter(ctx.filename) or {}
end

local function found(name)
  return function(_, ctx)
    return project.find(ctx.filename, name) or {}
  end
end

local function blade(_, ctx)
  return project.blade_formatter(ctx.filename) or {}
end

local yaml = found("yamlfmt")

local function when(name, formatter)
  return function(bufnr)
    return project.find(vim.api.nvim_buf_get_name(bufnr), name) and { formatter } or {}
  end
end

local no_lsp_format = { "vtsls" }

return {
  {
    "conform.nvim",
    opts = {
      formatters_by_ft = {
        php = function(bufnr)
          local formatter = project.php_formatter(vim.api.nvim_buf_get_name(bufnr))
          return formatter and { formatter.name } or {}
        end,
        blade = function(bufnr)
          return project.blade_formatter(vim.api.nvim_buf_get_name(bufnr)) and { "blade-formatter" } or {}
        end,
        yaml = when("yamlfmt", "yamlfmt"),
      },
      formatters = {
        pint = {
          command = function(_, ctx)
            return php(ctx).bin
          end,
          cwd = function(_, ctx)
            return php(ctx).root
          end,
          args = function(_, ctx)
            local config = php(ctx).config
            return config and { "--config", config, "$FILENAME" } or { "$FILENAME" }
          end,
        },
        php_cs_fixer = {
          command = function(_, ctx)
            return php(ctx).bin
          end,
          cwd = function(_, ctx)
            return php(ctx).root
          end,
          args = function(_, ctx)
            return { "fix", "--config", php(ctx).config, "$FILENAME" }
          end,
        },
        phpcbf = {
          command = function(_, ctx)
            return php(ctx).bin
          end,
          cwd = function(_, ctx)
            return php(ctx).root
          end,
          args = function(_, ctx)
            return { "--standard=" .. php(ctx).config, "$FILENAME" }
          end,
        },
        ["blade-formatter"] = {
          command = function(self, ctx)
            return blade(self, ctx).bin
          end,
          cwd = function(self, ctx)
            return blade(self, ctx).root
          end,
          args = function(self, ctx)
            local formatter = blade(self, ctx)
            return formatter.fallback and { "--stdin", "--config", formatter.config } or { "--stdin" }
          end,
        },
        yamlfmt = {
          command = function(self, ctx)
            return yaml(self, ctx).bin
          end,
          cwd = function(self, ctx)
            return yaml(self, ctx).root
          end,
          args = function(self, ctx)
            return { "-conf", yaml(self, ctx).config, "-" }
          end,
        },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "blade-formatter" } },
  },
  {
    "neovim/nvim-lspconfig",
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "blade",
        callback = function(args)
          local formatter = project.blade_formatter(vim.api.nvim_buf_get_name(args.buf))
          if formatter and formatter.fallback then
            vim.b[args.buf].autoformat = false
          end
        end,
      })
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and vim.tbl_contains(no_lsp_format, client.name) then
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.documentRangeFormattingProvider = false
          end
        end,
      })
    end,
    opts = {
      servers = {
        oxfmt = { enabled = false },
        intelephense = {
          settings = { intelephense = { format = { enable = false } } },
        },
        yamlls = {
          settings = { yaml = { format = { enable = false } } },
        },
      },
    },
  },
}
