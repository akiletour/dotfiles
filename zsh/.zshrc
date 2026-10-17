setopt prompt_subst
fpath=("$HOME/.local/share/zsh/site-functions" $fpath)
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
autoload bashcompinit && bashcompinit
autoload -Uz compinit
compinit
source <(kubectl completion zsh)
compdef kubecolor=kubectl

source /opt/homebrew/opt/fzf-tab/share/fzf-tab/fzf-tab.zsh
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --icons=always $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -1 --color=always --icons=always $realpath'
zstyle ':fzf-tab:*' use-fzf-default-opts yes
zstyle ':fzf-tab:*' switch-group '<' '>'

source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
bindkey '^w' autosuggest-execute
bindkey '^e' autosuggest-accept
bindkey '^u' autosuggest-toggle
bindkey '^L' vi-forward-word
bindkey '^k' up-line-or-search
bindkey '^j' down-line-or-search

eval "$(starship init zsh)"
export STARSHIP_CONFIG=~/.config/starship/starship.toml

export LANG=fr_FR.UTF-8
export EDITOR=/opt/homebrew/bin/nvim

HISTFILE=~/.zsh_history
HISTSIZE=1000000000
SAVEHIST=1000000000
setopt SHARE_HISTORY HIST_IGNORE_DUPS

source ~/.aliases

bindkey jj vi-cmd-mode

### FZF ###
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow'
source <(fzf --zsh)

export PATH=/opt/homebrew/bin:$PATH

export XDG_CONFIG_HOME="$HOME/.config"
. "$HOME/.atuin/bin/env"


eval "$(zoxide init zsh)"
eval "$(atuin init zsh)"
eval "$(direnv hook zsh)"

export PNPM_HOME="$HOME/Library/pnpm"
export BUN_INSTALL="$HOME/.bun"
export PATH="$HOME/.local/bin:$PNPM_HOME:$BUN_INSTALL/bin:$HOME/.strix/bin:/opt/homebrew/opt/gnu-sed/libexec/gnubin:$HOME/Library/Python/3.9/bin:/Applications/Ghostty.app/Contents/MacOS:$HOME/.antigravity/antigravity/bin:$PATH"
[ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"

alias claude-mem='$HOME/.bun/bin/bun "$HOME/.claude/plugins/marketplaces/thedotmack/plugin/scripts/worker-service.cjs"'

[ -f ~/.zshrc.local ] && source ~/.zshrc.local

source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
