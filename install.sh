#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

packages=(atuin direnv ghostty git k9s nvim sesh starship television tmux workmux zsh)

if [[ "${1:-}" == "--brew" ]]; then
  brew bundle --file=Brewfile
fi

for file in "$HOME/.zshrc.local" "$HOME/.gitconfig.local" "$HOME/.config/sesh/local.toml"; do
  if [[ ! -e "$file" ]]; then
    mkdir -p "$(dirname "$file")"
    touch "$file"
    chmod 600 "$file"
  fi
done

stow --restow --target="$HOME" "${packages[@]}"

git config core.hooksPath .githooks

if command -v volta >/dev/null && ! command -v devsense-php-ls >/dev/null; then
  volta install devsense-php-ls
fi
