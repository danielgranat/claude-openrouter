#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SHELL_RC="$HOME/.zshrc"

# Ensure ~/.claude exists for first-time users
mkdir -p "$HOME/.opclaude"

ALIAS_LINE="alias opclaude='${SCRIPT_DIR}/opclaude'"

if grep -qF 'alias opclaude=' "$SHELL_RC" 2>/dev/null; then
  sed -i '' "s|^alias opclaude=.*|${ALIAS_LINE}|" "$SHELL_RC"
  echo "Updated opclaude alias in $SHELL_RC"
else
  echo "" >> "$SHELL_RC"
  echo "# Claude Code via OpenRouter (Docker)" >> "$SHELL_RC"
  echo "$ALIAS_LINE" >> "$SHELL_RC"
  echo "Added opclaude alias to $SHELL_RC"
fi

echo ""
echo "Run: source $SHELL_RC"
echo "Then use 'opclaude' from any directory."
echo ""
