#!/usr/bin/env bash
# Start (or resume) the agent team for one project in a detached tmux session.
# Usage: launch.sh [project-dir] [--lite]
#   project-dir  defaults to the current directory; created with `git init` if missing
#   --lite       3 panes (gateway, coder, reviewer) instead of 8
set -euo pipefail

lite=0 arg=""
for a in "$@"; do case $a in --lite) lite=1 ;; *) arg=$a ;; esac; done
arg=${arg:-$PWD}
if [ ! -d "$arg" ]; then mkdir -p "$arg" && git -C "$arg" init -q && echo "new project: $arg"; fi
dir=$(cd "$arg" && pwd)
proj=$(basename "$dir")
s=$(printf 'dev-%s' "$proj" | tr '.:' '--')
notes="$HOME/.claude/dev-team/$s"
mkdir -p "$notes"

# Inside tmux, `attach` refuses to nest; switch the current client instead.
go() {
  if [ -n "${TMUX:-}" ]; then
    tmux switch-client -t "$s" && echo "$1: switched to $s (back: tmux switch-client -l)"
  else
    echo "$1: tmux attach -t $s"
  fi
}

if tmux has-session -t "$s" 2>/dev/null; then
  go "already running"
  exit 0
fi

# role  model  effort
if [ $lite -eq 1 ]; then
  team=(
    "gateway  claude-opus-5-5 medium"
    "coder    claude-opus-5-5 medium"
    "reviewer claude-opus-5-5 medium"
  )
else
  team=(
    "gateway      claude-opus-5-5   medium"
    "planner      claude-fable-5-2  xhigh"
    "coder-hard   claude-opus-5-5   high"
    "coder-medium claude-opus-5-5   medium"
    "coder-easy   claude-sonnet-5-5 high"
    "issues       claude-sonnet-5-5 medium"
    "reviewer     claude-opus-5-5   medium"
    "comments     claude-haiku-5-5  medium"
  )
fi
roles=$(for t in "${team[@]}"; do read -r r _ <<<"$t"; printf '%s ' "$r"; done)
names=$(for r in $roles; do printf '%s-%s ' "$proj" "$r"; done)
run=$(mktemp -d "${TMPDIR:-/tmp}/$s.XXXX")

role_text() {
  case $1 in
  gateway) cat <<EOF
You are the gateway, pane 1. The user talks only to you. Turn each request into work for your peers and send it with SendMessage.
- New project, new feature or unclear scope: the planner first. When the user approves the plan, the issues pane opens the issues.
- Each issue: rate it hard, medium or easy and send it to the matching coder. An open PR: the reviewer. Text the user will read (PR bodies, replies to review comments): the comments pane.
- Roles that aren't on this team ($roles): do that work yourself.
- Run one coder at a time unless two tasks touch separate files. Agree the merge order with the user before coding starts, then keep going through the plan without stopping between milestones unless you're blocked.
- Merging: the first time work reaches a PR in a project, ask the user once whether you may merge reviewed, CI-green PRs yourself, and save the answer to memory. Until they say yes, never merge. When you merge: check the head SHA, mergeStateStatus CLEAN and passing checks; retarget any PR stacked on the branch to main first (deleting a base branch closes the PR on top of it); then \`gh pr merge <n> --squash --delete-branch\` and \`git pull --ff-only\`.
- Before giving a pane a new task, clear it while it's idle: \`tmux send-keys -t <pane-id> -l /clear; tmux send-keys -t <pane-id> Enter\` (no Escape). Pane ids are in $run/panes.txt.
- Keep the project's memory up to date (merged, in flight, next, decisions the user made) so "what's up" and "how much is left" come from what you know. Check GitHub only when something is due. Give the user one status message per batch.
- If a peer's name stops working, ListAgents shows its current name.

Ending: when the user says to end, stop or wrap up the session:
1. Tell the user in one line that you're wrapping up.
2. SendMessage "WRAP UP" to every peer, and wait for each to answer "saved". If one doesn't answer, read its pane with \`tmux capture-pane -p -t <pane-id> -S -200\` and write its notes yourself.
3. Write $notes/session.md: date, what's merged, what's in flight (PR, branch, which pane, its state), what's next in order, decisions the user made, and things only the user can do. Write it so a fresh gateway can carry on from it alone.
4. Run \`~/.claude/skills/dev-team/stop.sh '$dir' --now\`. It closes every pane, this one included.
EOF
  ;;
  planner) cat <<'EOF'
You are the planner. You plan the build: PRDs, ERDs, product scope and design. Write them under docs/ in the repo, on a branch, through a PR like any other change. If the project has no AGENTS.md or README, the first plan adds them: what the project is, what lives here, its hard invariants and its checks (format, lint, tests). Split the work into tasks small enough for PRs under 30 files, each rated hard, medium or easy, with the order they should merge in. Send the plan to the gateway and wait for approval. Don't write app code.
EOF
  ;;
  coder*) cat <<'EOF'
You are a coder. Take one issue at a time from the gateway. Follow the project's AGENTS.md: a worktree in .worktrees/, branch agent/<name> from origin/main, run its checks, commit with `git commit -s`, open a PR that closes the issue. Wait for CI with one background `gh pr checks <n> --watch`. Report the PR URL and head SHA to the gateway once, or the reason if you're blocked.
- The shell's working directory resets between commands: cd into the worktree in every command that needs it, and use literal absolute paths, not $TMPDIR.
- Stage files by name, never `git add -A`. Never commit a file you didn't create, such as the owner's untracked notes. Never commit to main.
- Batch every fix from a review round into one push.
EOF
  ;;
  issues) cat <<'EOF'
You are the issues pane. Turn the planner's approved plan into GitHub issues with `gh issue create`: one per task, with acceptance criteria, its difficulty, and what it depends on. Send the gateway the list of issue numbers in merge order. Don't create issues for a plan the gateway hasn't approved.
EOF
  ;;
  reviewer) cat <<'EOF'
You are the reviewer. Review the PRs the gateway sends you. Run a local /code-review at medium effort right away; if a bot reviewer such as CodeRabbit has already commented, triage its comments into the same list. Check the project's hard invariants in AGENTS.md on every PR. Report one list to the gateway: real fixes first, then small items, then what you checked. No progress messages.
EOF
  ;;
  comments) cat <<'EOF'
You are the comments pane. You write the text people will read: PR descriptions, replies to review comments, issue comments, commit messages when asked. Run it through /unslop if the project asks for it. Post only what the gateway hands you, and confirm back once when it's posted.
EOF
  ;;
  esac
}

common="Project: $proj ($dir). You are one of ${#team[@]} Claude sessions in tmux session $s. Message your peers with SendMessage, using these names: $names
Stay idle until you are given a task. Don't send progress chatter: report once, when done or blocked. Follow ~/.claude/CLAUDE.md and the project's AGENTS.md; they win over anything here.
Notes between sessions live in $notes/. When the gateway sends \"WRAP UP\": stop what you're doing; commit any unfinished work in your worktree locally (\`git commit -s -m 'WIP: ...'\`, don't push); write $notes/<your role>.md with your task, branch, worktree and PR, what's done, what's left, decisions and gotchas (write \"idle\" if you had no task); then answer the gateway \"saved\" once."

resume=0
[ -f "$notes/session.md" ] && resume=1

i=0
for t in "${team[@]}"; do
  read -r role model effort <<<"$t"
  {
    printf '%s\n\n%s' "$common" "$(role_text "$role")"
    if [ $resume -eq 1 ]; then
      printf '\n\nA previous session left notes. Before anything else, read %s/session.md' "$notes"
      [ -f "$notes/$role.md" ] && printf ' and %s/%s.md' "$notes" "$role"
      printf '. Then stay idle until the gateway gives you a task.'
    fi
  } >"$run/$role.md"
  # Full auto: no permission prompts. The user asked for this on 2026-11-25.
  # --add-dir: the parent folder (sibling repos) and temp files, so reads there don't ask.
  # Planner: when Fable's limit is hit, fall back to Opus 5.5 (tried again each turn).
  fb=""; [ "$role" = planner ] && fb="--fallback-model claude-opus-5-5"
  first_prompt=""
  [ "$role" = gateway ] && [ $resume -eq 1 ] &&
    first_prompt="'Read your notes and tell me in a few lines where we left off and what you plan to do next. Wait for my go before starting work.'"
  cmd="claude --name '$proj-$role' --model $model $fb --effort $effort --dangerously-skip-permissions --add-dir '$(dirname "$dir")' --add-dir '${TMPDIR:-/tmp}' --append-system-prompt-file '$run/$role.md' $first_prompt"
  if [ $i -eq 0 ]; then
    first=$(tmux new-session -d -P -F "#{pane_id}" -s "$s" -c "$dir" -x 240 -y 60 "$cmd")
  else
    tmux split-window -t "$s" -c "$dir" "$cmd"
    tmux select-layout -t "$s" tiled >/dev/null # room for the next split
  fi
  tmux select-pane -t "$s" -T "$role"
  echo "$role $(tmux display -p -t "$s" '#{pane_id}')" >>"$run/panes.txt"
  i=$((i + 1))
done

# Even grid for 8 panes: 4 columns x 2 rows, panes in team order, row by row.
grid4x2() {
  local W H w h1 h2 ids l c x
  read -r W H <<<"$(tmux display -p -t "$s" '#{window_width} #{window_height}')"
  w=$(((W - 3) / 4)) h1=$(((H - 1) / 2)) h2=$((H - 1 - (H - 1) / 2))
  ids=($(tmux list-panes -t "$s" -F '#{pane_id}' | tr -d %))
  row() { # y height first-id-index; last column takes the leftover width
    local out="" k cw
    for k in 0 1 2 3; do
      x=$((k * (w + 1))); cw=$w; [ $k -eq 3 ] && cw=$((W - x))
      out+="${cw}x$2,$x,$1,${ids[$3 + k]},"
    done
    printf '%s' "${out%,}"
  }
  l="${W}x$H,0,0[${W}x$h1,0,0{$(row 0 $h1 0)},${W}x$h2,0,$((h1 + 1)){$(row $((h1 + 1)) $h2 4)}]"
  c=$(python3 -c 'import sys;c=0
for ch in sys.argv[1]: c=((c>>1)+((c&1)<<15)+ord(ch))&0xffff
print("%04x"%c)' "$l")
  tmux select-layout -t "$s" "$c,$l" >/dev/null
}

tmux set -t "$s" pane-border-status top >/dev/null
if [ $lite -eq 1 ]; then tmux select-layout -t "$s" even-horizontal >/dev/null; else grid4x2; fi
tmux select-pane -t "$first"
go "$([ $resume -eq 1 ] && echo resumed || echo started)"
