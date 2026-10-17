#!/usr/bin/env bash
ctx=$(KUBECONFIG="$HOME/.kube/prod:$HOME/.kube/l3s" kubectl config current-context 2>/dev/null || echo none)
case "$ctx" in
  prod) color="#f38ba8"; border="#f38ba8" ;;
  *) color="#a6e3a1"; border="#6c7086" ;;
esac
tmux set -g pane-active-border-style "bg=#1e1e2e,fg=$border"
left=$'\xee\x82\xb6'
right=$'\xee\x82\xb4'
icon=$'\xf3\xb1\x83\xbe'
printf '#[fg=%s,bg=default]%s#[fg=#11111b,bg=%s]%s #[fg=#cdd6f4,bg=#313244] %s#[fg=#313244,bg=default]%s' "$color" "$left" "$color" "$icon" "$ctx" "$right"
