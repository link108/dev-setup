#!/usr/bin/env bash
# Playwright CLI's agent skill for Claude Code and Codex. Safe to re-run; run after mise install.
#
# The skill ships inside the npm:@playwright/cli package (see shared/mise.toml), so re-running
# this after a version bump refreshes it. It's installed as a real dir in ~/.claude/skills
# (link-claude-skills leaves real dirs alone) and Codex gets a link from ~/.codex/skills.
# Not ~/.agents/skills: that's the link108/agent-skills checkout.
set -euo pipefail

MISE="$(command -v mise || echo "$HOME/.local/bin/mise")"

echo "==> claude: playwright-cli skill"
(cd "$HOME" && "$MISE" exec -- playwright-cli install --skills claude --global)

echo "==> codex: link playwright-cli skill"
mkdir -p "$HOME/.codex/skills"
ln -sfn "$HOME/.claude/skills/playwright-cli" "$HOME/.codex/skills/playwright-cli"
