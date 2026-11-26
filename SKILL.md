---
name: dev-team
description: Start, resume or end a tmux team of Claude sessions (gateway, planner, coders, issues, reviewer, comments) for any project, new or existing. Use when the user types /dev-team, asks to start or work on a project with the team, or says to end, stop or wrap up the team session.
---

## Start or resume

```bash
~/.claude/skills/dev-team/launch.sh [project-dir] [--lite]
```

- `project-dir` defaults to the current directory. If the user names a project that doesn't exist yet, confirm the full path once, then pass it: the script creates the folder and runs `git init`.
- `--lite` starts 3 panes (gateway, coder, reviewer) instead of 8. Use it when the user asks for a small team or a quick job.
- If the project has notes from an earlier session (`~/.claude/dev-team/<session>/`), every pane reads its own notes first and the gateway opens with where things were left.

Tell the user the one line the script prints. Inside tmux it switches their client to the team; outside it prints `tmux attach -t dev-<project>`. Pane 1 is the gateway; the user talks to it. Don't start any work yourself.

## End

The user tells the gateway "end the session" (or "wrap up", "stop for today"). The gateway has every pane write its notes, writes the session summary, then closes the tmux session.

If the gateway is stuck, or the user says to kill it now:

```bash
~/.claude/skills/dev-team/stop.sh [project-dir] --now
```

`--now` closes the session without notes. Without `--now`, stop.sh asks the gateway to wrap up.
