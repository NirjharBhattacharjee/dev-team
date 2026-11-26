#!/usr/bin/env bash
# End a project's team session.
# Usage: stop.sh [project-dir] [--now]
#   without --now  asks the gateway to wrap up (notes, then it closes the session)
#   --now          closes every pane right away, no notes
set -euo pipefail

now=0 arg=""
for a in "$@"; do case $a in --now) now=1 ;; *) arg=$a ;; esac; done
dir=$(cd "${arg:-$PWD}" && pwd)
s=$(printf 'dev-%s' "$(basename "$dir")" | tr '.:' '--')

tmux has-session -t "$s" 2>/dev/null || { echo "no session $s"; exit 0; }

if [ $now -eq 1 ]; then
  # Run from the tmux server, detached, so the gateway calling this can finish its command first.
  tmux run-shell -b "sleep 2; tmux kill-session -t '$s'"
  echo "closing $s; notes in ~/.claude/dev-team/$s/"
else
  gw=$(tmux list-panes -t "$s" -F '#{pane_id}' | head -1)
  tmux send-keys -t "$gw" -l 'end the session'
  tmux send-keys -t "$gw" Enter
  echo "asked the gateway of $s to wrap up"
fi
