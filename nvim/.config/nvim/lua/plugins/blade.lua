local devsense = vim.env.HOME
  .. "/.volta/tools/image/packages/devsense-php-ls/lib/node_modules/devsense-php-ls/node_modules/devsense-php-ls-darwin-arm64/dist/devsense.php.ls"

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        intelephense = {
          filetypes = { "php" },
        },
        devsense = {
          mason = false,
          enabled = vim.uv.fs_stat(devsense) ~= nil,
          cmd = { devsense },
          filetypes = { "blade" },
          root_markers = { "composer.json", ".git" },
          init_options = { clientFeatures = {} },
        },
      },
    },
  },
}
