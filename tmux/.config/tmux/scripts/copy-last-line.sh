#!/usr/bin/env bash
tmux capture-pane -p -t "${1:-}" \
  | grep -v '^[[:space:]]*$' \
  | sed '$d' | sed '$d' \
  | grep -v '^❯' \
  | tail -n 1 \
  | sed 's/[[:space:]]*$//' \
  | tr -d '\n' \
  | pbcopy
