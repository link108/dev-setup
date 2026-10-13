#!/usr/bin/env bash
# Shared agent skills (github.com/link108/agent-skills) for Claude Code and Codex. Safe to re-run.
#
# ~/.agents/skills -> the repo. Codex reads that path natively; Claude Code only scans
# ~/.claude/skills, so the repo's bin/link-claude-skills links each skill in there, run now
# and from a SessionStart hook so new skills show up after a git pull.
set -euo pipefail

REPO="$HOME/git-repos/link108/agent-skills"
LINK="$HOME/.agents/skills"

if [[ ! -d "$REPO" ]]; then
  echo "==> cloning agent-skills -> $REPO"
  mkdir -p "$(dirname "$REPO")"
  git clone git@github.com:link108/agent-skills.git "$REPO"
fi

if [[ -L "$LINK" && "$(readlink "$LINK")" == "$REPO" ]]; then
  echo "==> ok: $LINK"
else
  mkdir -p "$(dirname "$LINK")"
  if [[ -e "$LINK" || -L "$LINK" ]]; then
    backup="$LINK.bak.$(date +%Y%m%d%H%M%S)"
    echo "==> backing up $LINK -> $backup"
    mv "$LINK" "$backup"
  fi
  ln -s "$REPO" "$LINK"
  echo "==> linked: $LINK -> $REPO"
fi

echo "==> claude: SessionStart hook runs link-claude-skills"
python3 - "$HOME/.claude/settings.json" <<'EOF'
import json, os, sys
path = sys.argv[1]
command = '"$HOME/.agents/skills/bin/link-claude-skills" 2>&1 || true'
settings = json.load(open(path)) if os.path.exists(path) else {}
groups = settings.setdefault("hooks", {}).setdefault("SessionStart", [])
if not any(h.get("command") == command for g in groups for h in g.get("hooks", [])):
    groups.append({"hooks": [{"type": "command", "command": command, "timeout": 10}]})
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        json.dump(settings, f, indent=2)
        f.write("\n")
EOF

"$LINK/bin/link-claude-skills"
echo "==> claude skills: $(find "$HOME/.claude/skills" -maxdepth 1 -type l | wc -l | tr -d ' ') linked"
