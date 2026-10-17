return {
  {
    "olimorris/neotest-phpunit",
  },
  {
    "nvim-neotest/neotest-jest",
    jestConfigFile = function(file)
      if string.find(file, "/packages/") then
        return string.match(file, "(.-/[^/]+/)src") .. "jest.config.js"
      end

      return vim.fn.getcwd() .. "/jest.config.js"
    end,
  },
  {
    "nvim-neotest/neotest",
    opts = { adapters = { "neotest-jest", "neotest-phpunit" } },
  },
}
