local M = {}

local function exists(path)
  return vim.uv.fs_stat(path) ~= nil
end

function M.ignored(file)
  if file == "" then
    return true
  end
  return vim.system({ "git", "-C", vim.fs.dirname(file), "check-ignore", "-q", file }):wait().code == 0
end

local function walk(file, fn)
  if M.ignored(file) then
    return nil
  end
  for dir in vim.fs.parents(file) do
    if dir == vim.env.HOME then
      return nil
    end
    local result = fn(dir)
    if result ~= nil then
      return result or nil
    end
  end
end

local function match(dir, tool)
  for _, marker in ipairs(tool.markers) do
    if exists(dir .. "/" .. marker) then
      local bin = tool.global and vim.fn.exepath(tool.bin) or dir .. "/" .. tool.bin
      return bin ~= "" and exists(bin) and { name = tool.name, root = dir, config = dir .. "/" .. marker, bin = bin } or false
    end
  end
end

M.tools = {
  pint = { name = "pint", bin = "vendor/bin/pint", markers = { "pint.json" } },
  php_cs_fixer = {
    name = "php_cs_fixer",
    bin = "vendor/bin/php-cs-fixer",
    markers = { ".php-cs-fixer.php", ".php-cs-fixer.dist.php" },
  },
  phpcbf = {
    name = "phpcbf",
    bin = "vendor/bin/phpcbf",
    markers = { "phpcs.xml", "phpcs.xml.dist", ".phpcs.xml", ".phpcs.xml.dist" },
  },
  phpcs = {
    name = "phpcs",
    bin = "vendor/bin/phpcs",
    markers = { "phpcs.xml", "phpcs.xml.dist", ".phpcs.xml", ".phpcs.xml.dist" },
  },
  phpstan = {
    name = "phpstan",
    bin = "vendor/bin/phpstan",
    markers = { "phpstan.neon", "phpstan.neon.dist", "phpstan.dist.neon" },
  },
  blade_formatter = {
    name = "blade-formatter",
    bin = "node_modules/.bin/blade-formatter",
    markers = { ".bladeformatterrc.json", ".bladeformatterrc" },
  },
  yamlfmt = {
    name = "yamlfmt",
    bin = "yamlfmt",
    global = true,
    markers = { ".yamlfmt", ".yamlfmt.yml", ".yamlfmt.yaml", "yamlfmt.yml", "yamlfmt.yaml" },
  },
}

function M.find(file, name)
  return walk(file, function(dir)
    return match(dir, M.tools[name])
  end)
end

function M.blade_formatter(file)
  if M.ignored(file) then
    return nil
  end
  local found = M.find(file, "blade_formatter")
  if found then
    return found
  end
  local bin = vim.fn.exepath("blade-formatter")
  if bin ~= "" then
    return {
      name = "blade-formatter",
      root = vim.fs.dirname(file),
      config = vim.fn.stdpath("config") .. "/bladeformatterrc.json",
      bin = bin,
      fallback = true,
    }
  end
end

function M.php_formatter(file)
  return walk(file, function(dir)
    for _, name in ipairs({ "pint", "php_cs_fixer", "phpcbf" }) do
      local found = match(dir, M.tools[name])
      if found ~= nil then
        return found
      end
    end
    if exists(dir .. "/composer.json") and exists(dir .. "/vendor/bin/pint") then
      return { name = "pint", root = dir, bin = dir .. "/vendor/bin/pint" }
    end
  end)
end

return M
