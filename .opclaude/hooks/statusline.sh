#!/bin/bash
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name // "unknown"')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')

# Colors
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
DIM='\033[2m'
RESET='\033[0m'

# Bar color based on context usage
if [ "$PCT" -ge 90 ]; then BAR_COLOR="$RED"
elif [ "$PCT" -ge 70 ]; then BAR_COLOR="$YELLOW"
else BAR_COLOR="$GREEN"; fi

# Progress bar (20 chars)
FILLED=$((PCT * 20 / 100))
EMPTY=$((20 - FILLED))
printf -v FILL "%${FILLED}s"
printf -v PAD "%${EMPTY}s"
BAR="${FILL// /█}${PAD// /░}"

COST_FMT=$(printf '$%.4f' "$COST")

echo -e "${CYAN}⚡ OpenRouter${RESET} ${DIM}·${RESET} ${MODEL} ${DIM}·${RESET} ${BAR_COLOR}${BAR}${RESET} ${PCT}% ctx ${DIM}·${RESET} ${YELLOW}${COST_FMT}${RESET}"
