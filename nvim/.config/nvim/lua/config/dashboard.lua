local M = {}

local state = {}

local palette = { "DiagnosticError", "DiagnosticWarn", "DiagnosticOk", "DiagnosticInfo", "DiagnosticHint", "Special" }

local states = {
  OPEN = "DiagnosticVirtualTextOk",
  MERGED = "DiagnosticVirtualTextHint",
  CLOSED = "DiagnosticVirtualTextError",
  DRAFT = "DiagnosticVirtualTextWarn",
}

local function run(cmd, cwd)
  local ok, res = pcall(function()
    return vim.system(cmd, { cwd = cwd, text = true }):wait()
  end)
  if not ok or res.code ~= 0 then
    return nil
  end
  return vim.trim(res.stdout)
end

local function refresh()
  vim.schedule(function()
    pcall(Snacks.dashboard.update)
  end)
end

local function fetch_json(cmd, cwd, cb)
  vim.system(cmd, { cwd = cwd, text = true }, function(res)
    local ok, data = pcall(vim.json.decode, res.stdout or "")
    if res.code == 0 and ok then
      cb(data)
    end
  end)
end

local function base_ref(root)
  local head = run({ "git", "rev-parse", "--abbrev-ref", "origin/HEAD" }, root)
  if head and head ~= "origin/HEAD" then
    return head
  end
  for _, ref in ipairs({ "origin/main", "origin/master" }) do
    if run({ "git", "rev-parse", "--verify", "-q", ref }, root) then
      return ref
    end
  end
end

function M.context(cwd)
  local root = run({ "git", "rev-parse", "--show-toplevel" }, cwd)
  if not root then
    return nil
  end
  local branch = run({ "git", "branch", "--show-current" }, cwd) or ""
  local remote = run({ "git", "remote", "get-url", "origin" }, cwd) or ""
  local key = branch:match("%u+%-%d+")
  local base = branch ~= "" and base_ref(root) or nil
  return {
    root = root,
    name = vim.fs.basename(root),
    branch = branch,
    base = base and ("origin/" .. branch) ~= base and base or nil,
    key = key,
    issue = not key and (branch:match("^(%d+)") or branch:match("/(%d+)")) or nil,
    github = remote:find("github.com", 1, true) ~= nil and vim.fn.executable("gh") == 1,
    jira = run({ "git", "config", "--get", "dashboard.jira" }, cwd),
  }
end

function M.banner(name)
  local out = vim.fn.executable("figlet") == 1 and run({ "figlet", "-w", "200", "-f", "small", name })
  if not out then
    return { { name, hl = "SnacksDashboardHeader" } }
  end
  local text = {}
  local lines = vim.split(out, "\n")
  for i, line in ipairs(lines) do
    for col = 1, #line do
      text[#text + 1] = { line:sub(col, col), hl = palette[math.floor((col - 1) / 3) % #palette + 1] }
    end
    if i < #lines then
      text[#text + 1] = { "\n" }
    end
  end
  return text
end

local function project_dir(cwd)
  return vim.fs.joinpath(vim.env.HOME, ".claude", "projects", (cwd:gsub("[^%w]", "-")))
end

local function age(sec)
  local d = os.time() - sec
  if d < 3600 then
    return math.max(1, math.floor(d / 60)) .. "min"
  elseif d < 86400 then
    return math.floor(d / 3600) .. "h"
  end
  return math.floor(d / 86400) .. "j"
end

local function shorten(text, width)
  text = vim.trim((text:gsub("%s+", " ")))
  if vim.fn.strdisplaywidth(text) > width then
    text = vim.fn.strcharpart(text, 0, width - 1) .. "…"
  end
  return text
end

function M.conversations(cwd, limit, cb)
  local dir = project_dir(cwd)
  if not vim.uv.fs_stat(dir) then
    return cb({})
  end
  local files = {}
  for name, kind in vim.fs.dir(dir) do
    if kind == "file" and name:match("%.jsonl$") then
      local path = vim.fs.joinpath(dir, name)
      local stat = vim.uv.fs_stat(path)
      if stat then
        files[#files + 1] = { id = (name:gsub("%.jsonl$", "")), path = path, mtime = stat.mtime.sec }
      end
    end
  end
  table.sort(files, function(a, b)
    return a.mtime > b.mtime
  end)
  files = vim.list_slice(files, 1, limit * 2)
  if #files == 0 then
    return cb({})
  end
  local pending = #files
  local function done()
    pending = pending - 1
    if pending > 0 then
      return
    end
    local found = vim.tbl_filter(function(f)
      return f.title ~= nil
    end, files)
    cb(vim.list_slice(found, 1, limit))
  end
  for _, f in ipairs(files) do
    vim.system({ "grep", "-hE", '"type":"last-prompt"|"entrypoint":"sdk', f.path }, { text = true }, function(res)
      local last, sdk
      for line in (res.stdout or ""):gmatch("[^\n]+") do
        if line:find('"entrypoint":"sdk', 1, true) then
          sdk = true
        end
        if line:find('"type":"last-prompt"', 1, true) then
          last = line
        end
      end
      local ok, data = pcall(vim.json.decode, last or "")
      if not sdk and ok and type(data) == "table" and type(data.lastPrompt) == "string" and data.lastPrompt ~= "" then
        f.title = data.lastPrompt
      end
      done()
    end)
  end
end

local function ensure()
  local cwd = vim.fn.getcwd()
  if state.cwd == cwd then
    return state
  end
  state = { cwd = cwd, ctx = M.context(cwd), convos = {} }
  local s = state
  local ctx = s.ctx
  s.banner = M.banner(ctx and ctx.name or vim.fs.basename(cwd))
  M.conversations(ctx and ctx.root or cwd, 5, function(list)
    s.convos = list
    refresh()
  end)
  if ctx and ctx.github and ctx.branch ~= "" then
    fetch_json({ "gh", "pr", "view", "--json", "number,title,state,isDraft,url" }, ctx.root, function(pr)
      s.pr = pr
      refresh()
    end)
    if ctx.issue then
      fetch_json({ "gh", "issue", "view", ctx.issue, "--json", "number,title,state,url" }, ctx.root, function(issue)
        s.issue = issue
        refresh()
      end)
    end
  end
  return s
end

local function chip(text, label, hl)
  if #text > 0 then
    text[#text + 1] = { " " }
  end
  text[#text + 1] = { " " .. label .. " ", hl = hl }
end

function M.header()
  return { text = ensure().banner, align = "center", width = 2000, padding = 1 }
end

function M.ticket()
  local s = ensure()
  local ctx = s.ctx
  if not ctx or ctx.branch == "" then
    return nil
  end
  local title = (s.pr and s.pr.title) or (s.issue and s.issue.title) or ctx.branch
  local chips = {}
  if ctx.key then
    chip(chips, ctx.key, "DiagnosticVirtualTextInfo")
  end
  if s.issue then
    chip(chips, "Issue #" .. s.issue.number, "DiagnosticVirtualTextInfo")
    chip(chips, s.issue.state, states[s.issue.state] or "DiagnosticVirtualTextInfo")
  end
  if s.pr then
    local pr_state = s.pr.isDraft and s.pr.state == "OPEN" and "DRAFT" or s.pr.state
    chip(chips, "PR #" .. s.pr.number, "DiagnosticVirtualTextHint")
    chip(chips, pr_state, states[pr_state] or "DiagnosticVirtualTextInfo")
  end
  local text = { { shorten(title, 70), hl = "Title" } }
  if #chips > 0 then
    text[#text + 1] = { "\n" }
    vim.list_extend(text, chips)
  end
  return { text = text, align = "center", width = 2000, padding = 1 }
end

local function claude(args)
  local ctx = ensure().ctx
  local root = ctx and ctx.root or vim.fn.getcwd()
  local cmd = vim.list_extend({ "claude" }, args or {})
  if vim.env.TMUX then
    vim.system(vim.list_extend({ "tmux", "split-window", "-h", "-c", root }, cmd))
  else
    Snacks.terminal(cmd, { cwd = root })
  end
end

function M.conversations_section()
  local s = ensure()
  if #s.convos == 0 then
    return nil
  end
  local section = { title = "Conversations Claude", icon = "󰭹 ", indent = 2, padding = 1 }
  for _, c in ipairs(s.convos) do
    section[#section + 1] = {
      icon = "󰭻 ",
      desc = shorten(c.title, 40) .. "  " .. age(c.mtime),
      autokey = true,
      action = function()
        claude({ "--resume", c.id })
      end,
    }
  end
  return section
end

function M.branch_changes()
  local ctx = ensure().ctx
  if not ctx or not ctx.base then
    return vim.notify("Pas de branche de base trouvée", vim.log.levels.WARN)
  end
  local out = run({ "git", "diff", "--name-only", "--merge-base", ctx.base }, ctx.root) or ""
  local items = {}
  for file in out:gmatch("[^\n]+") do
    local path = vim.fs.joinpath(ctx.root, file)
    if vim.uv.fs_stat(path) then
      items[#items + 1] = { file = path, text = file }
    end
  end
  if #items == 0 then
    return vim.notify("Aucun changement depuis " .. ctx.base)
  end
  Snacks.picker({ title = "Changements depuis " .. ctx.base, items = items, format = "file" })
end

function M.open_pr()
  local pr = ensure().pr
  if pr then
    vim.ui.open(pr.url)
  end
end

function M.open_ticket()
  local s = ensure()
  if s.issue then
    vim.ui.open(s.issue.url)
  elseif s.ctx and s.ctx.key and s.ctx.jira then
    vim.ui.open(s.ctx.jira:gsub("/$", "") .. "/browse/" .. s.ctx.key)
  end
end

function M.has_pr()
  return ensure().pr ~= nil
end

function M.has_ticket()
  local s = ensure()
  return s.issue ~= nil or (s.ctx ~= nil and s.ctx.key ~= nil and s.ctx.jira ~= nil)
end

function M.has_changes()
  local ctx = ensure().ctx
  return ctx ~= nil and ctx.base ~= nil
end

function M.claude()
  claude()
end

function M.reload()
  state = {}
  pcall(Snacks.dashboard.update)
end

return M
