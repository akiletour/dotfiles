#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title Worktree from tab
# @raycast.mode compact
# @raycast.packageName Worktrees
# @raycast.icon 🌳
# @raycast.argument1 { "type": "text", "placeholder": "URL ou clé Jira", "optional": true }
# @raycast.description Open a workmux worktree for the Jira ticket or PR in the active Chrome tab

set -o pipefail
/opt/homebrew/bin/bash "$HOME/.local/bin/tab-wt" ${1:+"$1"} 2>&1 | tail -1
