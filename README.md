# dotfiles

My macOS setup. I spend my days in WordPress (Bedrock and Radicle) and Symfony codebases, and the rest of the time poking at a small K3S cluster, so most of what's here is about those two things.

Everything is linked into `$HOME` with [GNU Stow](https://www.gnu.org/software/stow/). No framework, no plugin manager for zsh, nothing that runs on its own after install.

## Install

```sh
git clone git@github.com:akiletour/dotfiles.git ~/dotfiles
~/dotfiles/install.sh --brew
```

`--brew` runs `brew bundle` first. Drop it if the tools are already there and you only want the links.

The script also creates three empty private files (see below), points git at the repo's hooks, and installs the DEVSENSE PHP language server through Volta if it's missing.

To unlink a package: `stow --delete --target="$HOME" <package>`.

## What's inside

Each top-level directory is a Stow package that mirrors `$HOME`.

```
bin/         inr-worktree, tab-wt and swarm, see below
zsh/         .zshrc, .zshenv, .aliases
tmux/        .tmux.conf, status bar and clipboard scripts
nvim/        LazyVim
git/         .gitconfig, .gitignore_global
ghostty/     terminal config and a background shader
starship/    prompt, with the Kubernetes context in red on prod
sesh/        tmux session picker
workmux/     one tmux window per git worktree, Claude Code on top
television/  fuzzy pickers for git, docker and k8s
k9s/         aliases
d4s/         read-only config for d4s
atuin/       shell history
direnv/      use_php helper for per-project PHP versions
raycast/     Script Commands, not stowed
Brewfile
```

## The parts worth reading

### Neovim follows the project, not me

The PHP setup picks its tools from the project you're in, so a save never reformats a file against rules the team didn't choose.

| The project has | On save | Diagnostics |
| --- | --- | --- |
| `pint.json` | `vendor/bin/pint` | |
| `.php-cs-fixer(.dist).php` | `vendor/bin/php-cs-fixer` | |
| `phpcs.xml(.dist)` | `vendor/bin/phpcbf` | `vendor/bin/phpcs` |
| `phpstan(.dist).neon` | | `vendor/bin/phpstan` |
| none of these | nothing | nothing |

It only ever runs binaries from the project's own `vendor/bin`, never a global install, so the version matches CI. Files ignored by git (`public/wp`, plugins, uploads) are never formatted. LSP formatting is off for intelephense, vtsls and yamlls, because it kicked in as a fallback and rewrote files nobody asked it to touch.

Prettier and yamlfmt follow the same rule and only run when the repo has a config for them.

### PHP inside Blade templates

`.php` files get [Intelephense](https://intelephense.com). Blade files get the free [DEVSENSE](https://www.devsense.com) language server, which understands the PHP inside `{{ }}` and directives: completion, go to definition, hover, and the type of `$term` inside `@foreach (get_terms() as $term)`. I haven't found anything else in the Neovim world that does this.

Blade formatting uses blade-formatter with Tailwind class sorting. Since none of my projects ship a Blade config, it's manual (`<leader>cf`) unless the project has its own `.bladeformatterrc.json`, in which case it runs on save with that config.

### A prompt before touching prod

`kubectl` is a shell function. It reads the effective context, `--context` included, and asks for confirmation on `prod` for anything that isn't a read (`get`, `describe`, `logs` and friends). `exec` and `port-forward` count as writes. The tmux status bar and the Starship prompt both turn red on prod, which catches me more often than the prompt does.

Docker gets the same treatment for Swarm servers. `swarm add <host>` creates a Docker context over SSH and tags it `swarm`, and from then on `docker --context <host>` asks before anything that isn't a read. The host list lives in those contexts, so no server name ends up in this repo.

`swarm` opens [d4s](https://github.com/jr-k/d4s) on one of them. It's k9s for Docker: same layout, `:services`, `:stacks`, `:nodes`, `:tasks`, live logs. Its config sets `readOnly`, which in v0.49 only blocks delete, restart and scale to zero. Stop, prune, scale, edit and shell still go through, behind d4s's own confirmation, and none of it goes through the shell prompt.

The television channels were trimmed to the ones I use, with their delete, discard and merge actions removed. `kubectl exec` from the pod picker asks first on prod too, since it doesn't go through the shell function.

### One Docker stack per worktree

My local stack runs every project on `https://<project>.inr.local` through OrbStack, and the project name comes from a `.env.inr` file that git ignores. A fresh worktree has no `.env.inr`, so it can't start.

`bin/inr-worktree` fills that gap from workmux hooks, and only in repos that have a `.env.inr`:

- `post_create` copies `.env.inr` with a project name of `<project>-<worktree>`, drops the keys listed in `.inr/worktree.exclude`, and copies the ignored files listed in `.inr/worktree.copy` (JWT keys, `.env.local`).
- The shell pane under the agent runs `inr-worktree up`, which restores the main checkout's latest database snapshot, then starts the stack.
- `pre_remove` tears it down with its volumes when the worktree is merged or removed.

`inr-worktree prune` lists stacks whose directory is gone and asks before deleting each one.

Some client projects run on a shared Makefile stack instead, where every container, domain and database name comes from `PROJECT_NAME` in `docker/.env`. Set `WORKTREE_MAKE_STACK_VAR` in `~/.zshrc.local` to the variable their Makefile includes, and the same hooks write a `docker/.env.local` with a per-worktree name, copy the ignored `.env*.local` files and JWT keys, clone the main checkout's Postgres database, and tear it all down on remove. Nothing is added to the client's repo: every file it writes is already in their `.gitignore`, and its state lives in `.git/worktrees/`.

When an OAuth provider only accepts the main domain as a callback, `inr-worktree focus` stops the main checkout's app and web containers and serves the worktree on that domain, still with its own database. `inr-worktree unfocus` gives the domain back, and removing the worktree does it too.

### A worktree from the Chrome tab

`bin/tab-wt` opens a workmux worktree for whatever is in the active Chrome tab: a Jira ticket, a GitHub PR or a Bitbucket PR. `raycast/tab-wt.sh` puts it on a Raycast hotkey, and it also takes a URL or a bare ticket key (`PROJ-123`) as argument.

- A Jira ticket picks its repo in this order: a repo named in the ticket title (that's how a shared bundle is found, whatever the project key), then the project key in `~/.config/tab-wt/projects`, then the repo with the most branches for that key. With several candidates a dialog asks, with an "Autre dépôt…" entry listing every repo of the organisation. An existing branch for the ticket is reused, and one that already has a worktree opens straight away.
- A new branch is `<prefix>/<KEY>-<english-slug>`: the feature prefix configured for the Jira instance, or `fix/` for a Bug or an Anomalie. Claude translates the title into the slug, and the plain slug of the original title is the fallback when it can't. It always starts from the remote default branch, never `develop` or `release`.
- A PR checks out its source branch: `workmux add --pr` on GitHub, the branch name from the Bitbucket API otherwise.
- The worktree is named after the ticket key, so it lands in `<repo>__worktrees/proj-123` and the `wm-proj-123` window.

`--dry-run` prints the repo, branch, base and target without creating anything. `--prompt` hands the ticket to the agent pane.

Both config files live in `~/.config/tab-wt/` and stay out of the repo, since they name client instances and repos. `instances` has one line per Jira site: host, Composio account, organisation directory under `~/www`, feature prefix.

```
acme.atlassian.net  acme  Acme  feature
```

Jira and Bitbucket go through the Composio REST API, with each account's key in the macOS Keychain:

```sh
security add-generic-password -U -s tab-wt-composio-acme -a api_key -w '<ak_...>'
security add-generic-password -U -s tab-wt-composio-acme -a user_id -w '<user id>'
```

In Raycast, add `~/dotfiles/raycast` under Extensions → Script Commands → Add Directories.

`projects` has one line per Jira project key, followed by its repos relative to `~/www`:

```
PROJ   Acme/api Acme/front
SITE   Clients/acme-site
```

A key with a single repo never asks. Leave shared bundles out, the title rule already finds them.

### tmux

Prefix is `C-a`. Most bindings open a popup and close it when you quit:

| Key | Opens |
| --- | --- |
| `C-a g` | lazygit in the current directory |
| `C-a K` | k9s, all namespaces |
| `C-a D` | lazydocker |
| `C-a S` | d4s on a Swarm server, picked with fzf |
| `C-a t` | television |
| `C-a T` | sesh session picker |
| `C-a W` | workmux dashboard |
| `C-a *` | toggle synchronized panes |

## Private files

These never go in the repo. `install.sh` creates them empty, with `600` permissions, when they don't exist.

| File | Holds |
| --- | --- |
| `~/.zshrc.local` | API keys and anything specific to a machine or a client |
| `~/.gitconfig.local` | name, email and signing key, pulled in by `[include]` |
| `~/.config/sesh/local.toml` | my own tmux sessions, imported by `sesh.toml` |

## Keeping secrets out

A pre-commit hook in `.githooks` runs [gitleaks](https://github.com/gitleaks/gitleaks) on staged changes and refuses the commit if it finds anything. `install.sh` sets `core.hooksPath`, so a fresh clone has it too. The `.gitignore` also blocks the usual suspects: `*.local`, `.env*`, keys, kubeconfigs, `hosts.yml`.

It's a safety net, not a guarantee. If you fork this, read what you commit.
