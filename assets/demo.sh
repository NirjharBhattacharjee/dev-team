#!/usr/bin/env bash
# A scripted replay of a dev-team session, recorded into demo.gif by record.py.
# Not a real run: real panes would show real code and use real usage.
B=$'\e[38;2;57;255;20m' M=$'\e[38;2;0;200;83m' D=$'\e[38;2;24;110;48m' L=$'\e[38;2;182;255;59m' W=$'\e[38;2;210;255;210m' R=$'\e[0m' BOLD=$'\e[1m'
at() { printf '\e[%d;%dH' "$1" "$2"; }
roles=(gateway planner coder-hard coder-medium coder-easy issues reviewer comments)
models=(opus fable opus opus sonnet sonnet opus haiku)
PW=25 TOP=3 PH=6

box() { # idx
  local i=$1 x=$((1 + ($1 % 4) * PW)) y=$((TOP + ($1 / 4) * PH)) r
  at $y $x; printf '%s┌─%s%s%s %s' "$D" "$B$BOLD" "${roles[$i]}" "$R$D" "$(printf '%*s' $((PW - 4 - ${#roles[$i]})) '' | tr ' ' '─')┐"
  for r in 1 2 3 4; do at $((y + r)) $x; printf '│%*s│' $((PW - 2)) ''; done
  at $((y + 5)) $x; printf '└%s┘%s' "$(printf '%*s' $((PW - 2)) '' | tr ' ' '─')" "$R"
  at $((y + 1)) $((x + 2)); printf '%s%s%s' "$D" "${models[$i]}" "$R"
  st $i "${D}○ idle"
}
st() { # idx text
  local x=$((3 + ($1 % 4) * PW)) y=$((TOP + ($1 / 4) * PH + 3))
  at $y $x; printf '%-*s' $((PW - 4)) ''; at $y $x; printf '%s%s' "$2" "$R"
}
feed=()
log() { # from to text
  feed+=("$(printf '%s%-12s%s→ %s%-12s %s%s' "$M" "$1" "$D" "$M" "$2" "$W" "$3")")
  local n=${#feed[@]} s=0 k; [ $n -gt 9 ] && s=$((n - 9))
  for ((k = s; k < n; k++)); do at $((17 + k - s)) 2; printf '\e[K%s%s' "${feed[$k]}" "$R"; done
}
type_cmd() { local s=$1 k; for ((k = 0; k < ${#s}; k++)); do printf '%s' "${s:k:1}"; sleep 0.04; done; }

printf '\e[?25l\e[2J'; at 1 1
printf '%s~/code/my-app %s❯ %s' "$M" "$L" "$W"; type_cmd '/dev-team'; sleep 0.5
printf '\r\n%sstarted: switched to dev-my-app%s' "$D" "$R"; sleep 0.8
printf '\e[2J'; at 1 2; printf '%s%sdev-my-app%s%s  ·  8 Claude sessions  ·  you talk to the gateway%s' "$B" "$BOLD" "$R" "$D" "$R"
for i in 0 1 2 3 4 5 6 7; do box $i; sleep 0.08; done
at 16 2; printf '%s── messages ──────────────────────────────────────────────────────────────────────────────────────%s' "$D" "$R"
sleep 0.6

at 27 2; printf '%syou ❯ %s' "$L" "$W"; type_cmd 'add user accounts'; sleep 0.4; at 27 2; printf '\e[K'
st 0 "${B}● routing"; log you gateway "add user accounts"; sleep 0.5
st 1 "${B}● planning…"; log gateway planner "TASK plan: user accounts"; sleep 1.0
st 1 "${M}✓ PLAN · 4 tasks"; log planner gateway "PLAN docs PR #3 · 4 tasks in merge order"; sleep 0.6
st 5 "${B}● filing…"; sleep 0.5; st 5 "${M}✓ #4 #5 #6 #7"; log issues gateway "ISSUES #4 #5 #6 #7"; sleep 0.6
st 2 "${B}● #4 auth flow"; log gateway coder-hard "TASK #4 sign-in and sessions"; sleep 1.1
st 2 "${M}✓ PR #8 · CI ✓"; log coder-hard gateway "DONE #4 · PR #8 · CI passed"; sleep 0.5
st 6 "${B}● reviewing #8"; log gateway reviewer "REVIEW #8"; sleep 1.0
st 6 "${M}✓ 1 real fix"; log reviewer gateway "FINDINGS #8 · 1 real fix, 2 small"; sleep 0.5
st 2 "${B}● fixing #8"; log gateway coder-hard "FIXES #8 · one push"; sleep 0.8
st 2 "${M}✓ #8 · CI ✓"; log coder-hard gateway "DONE #8 · fixes in · CI passed"; sleep 0.5
st 0 "${L}✓ merged #8"; log gateway main "squash-merged #8 ✓"; sleep 0.4
st 4 "${B}● #5 settings page"; log gateway coder-easy "TASK #5 settings page"; sleep 1.2

at 27 2; printf '%syou ❯ %s' "$L" "$W"; type_cmd 'end the session'; sleep 0.4; at 27 2; printf '\e[K'
st 0 "${B}● wrapping up"; log gateway all "WRAP UP"; sleep 0.5
for i in 1 2 3 4 5 6 7; do st $i "${M}✓ saved"; sleep 0.12; done
log all gateway "SAVED ×7 · notes in ~/.claude/dev-team/"; sleep 0.5
st 0 "${M}✓ session.md"; log gateway you "closing all panes"; sleep 1.0

printf '\e[2J'; at 1 1
printf '%s~/code/my-app %s❯ %s' "$M" "$L" "$W"; sleep 0.4; type_cmd '/dev-team'; sleep 0.4
printf '\r\n%sresumed: switched to dev-my-app%s\r\n\r\n' "$D" "$R"; sleep 0.6
printf '%s gateway ❯ %sWe left off with #8 merged and #5 half done on agent/settings\r\n' "$B" "$W"; sleep 0.3
printf '%s           %s(WIP committed). Next: finish #5, then #6 and #7. Go?%s\r\n' "$B" "$W" "$R"
sleep 2.5
printf '\e[?25h'
