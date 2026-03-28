# syntax=docker/dockerfile:1
# check=skip=SecretsUsedInArgOrEnv
FROM node:22-slim

# Install Claude Code and jq (for status line)
RUN apt-get update && apt-get install -y jq && rm -rf /var/lib/apt/lists/*
RUN npm install -g @anthropic-ai/claude-code

# OpenRouter configuration
ENV ANTHROPIC_BASE_URL="https://openrouter.ai/api"
ENV ANTHROPIC_API_KEY=""

# Create non-root user
RUN useradd -m -s /bin/bash claude
USER claude

# Bake settings, hooks, and status line into the image
RUN mkdir -p /home/claude/.claude/hooks
COPY --chown=claude:claude .opclaude/.claude.json /home/claude/.claude.json
COPY --chown=claude:claude .opclaude/settings.json /home/claude/.claude/settings.json
COPY --chown=claude:claude .opclaude/hooks/context-monitor.sh /home/claude/.claude/hooks/context-monitor.sh
COPY --chown=claude:claude .opclaude/hooks/statusline.sh /home/claude/.claude/hooks/statusline.sh
RUN chmod +x /home/claude/.claude/hooks/context-monitor.sh /home/claude/.claude/hooks/statusline.sh

WORKDIR /workspace

ENTRYPOINT ["claude", "--dangerously-skip-permissions"]
