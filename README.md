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
bin/         inr-worktree and swarm, see below
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
