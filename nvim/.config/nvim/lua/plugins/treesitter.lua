return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.filetype.add({ pattern = { [".*%.blade%.php"] = "blade" } })

      local parsers = require("nvim-treesitter.parsers")
      if parsers.get_parser_configs then
        local parser_config = parsers.get_parser_configs()
        parser_config.blade = {
          install_info = {
            url = "https://github.com/EmranMR/tree-sitter-blade",
            files = { "src/parser.c" },
            branch = "main",
          },
          filetype = "blade",
        }
      end

      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "blade" })

      pcall(vim.treesitter.language.register, "blade", "blade")
    end,
  },
}
