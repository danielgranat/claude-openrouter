#!/usr/bin/env bash
# PostToolUse hook: estimates context size from transcript and tells Claude to compact.
# Stdout goes into Claude's context — so Claude sees the instruction and can act on it.

MAX_CHARS=800000   # ~200K tokens (rough: 4 chars ≈ 1 token)
WARN_CHARS=600000  # ~150K tokens — early warning

INPUT=$(cat)
TRANSCRIPT=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('transcript_path',''))" 2>/dev/null)

if [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; then
  exit 0
fi

SIZE=$(wc -c < "$TRANSCRIPT")

if [ "$SIZE" -gt "$MAX_CHARS" ]; then
  # Critical — tell Claude to compact NOW
  echo "SYSTEM: Context usage is critical (~$((SIZE / 4000))K tokens estimated, limit ~262K). You MUST run /compact immediately before doing anything else. Tell the user context is being compacted."
  exit 0
elif [ "$SIZE" -gt "$WARN_CHARS" ]; then
  # Warning — notify the user
  echo "SYSTEM: Context is growing large (~$((SIZE / 4000))K tokens estimated). Consider running /compact soon or starting a new session."
  exit 0
fi

exit 0
