# Claude Code via OpenRouter (Docker)

Run Claude Code in a Docker container, routed through OpenRouter. No changes to your local machine's Claude installation.

## Why

If you use Claude Code with an Anthropic account, switching to OpenRouter means logging out, reconfiguring, and reversing it all when you switch back. This setup avoids that entirely:

- **Instant switching** — run `opclaude` for OpenRouter models, run `claude` for your regular account. No login/logout dance.
- **Sandboxed execution** — runs in a disposable Docker container, so `--dangerously-skip-permissions` is safe. Your host machine is untouched.
- **Any model** — use any model available on your OpenRouter account (free or paid).

## Prerequisites

- Docker
- `jq` (for the model picker)
- [gum](https://github.com/charmbracelet/gum) (optional — nicer interactive picker, falls back to numbered list)

## Setup

1. **Configure your API key:**
   ```bash
   cp .env.example .env
   # Edit .env with your OpenRouter API key
   ```
2. **Build the Docker image:**
   ```bash
   docker build -t claude-openrouter .
   ```
3. **Run setup to add the shell alias:**
   ```bash
   ./setup.sh
   source ~/.zshrc
   ```

## Usage

```bash
cd ~/my-project
opclaude                          # New session (history saved to .opclaude/sessions/)
opclaude --resume                 # Pick from previous sessions interactively
opclaude -c                       # Continue the most recent session
opclaude --incognito              # Ephemeral session, no history saved
opclaude --session-dir ~/my-dir   # Override where sessions are stored
```

This mounts the current directory as `/workspace` inside the container. Claude runs with `--dangerously-skip-permissions` (safe — it's in a disposable container).

Onboarding prompts (theme, trust, permissions) are pre-configured in the Docker image — no first-run setup needed.

### Session persistence

Sessions are automatically persisted to `.opclaude/sessions/` in your project directory. When a container exits, your conversation history is preserved and can be resumed in a new container.

Use `--session-dir <path>` to override the storage location, or `--incognito` to disable persistence entirely.

Consider adding `.opclaude/` to your project's `.gitignore`.

## How it works

```
opclaude (alias)
  └─ Docker container (node:22-slim)
       ├─ Claude Code CLI (--dangerously-skip-permissions)
       ├─ OpenRouter API routing (env vars from .env)
       ├─ Model config (configurable in .env)
       ├─ Settings + hooks (baked into image)
       └─ Workspace mounted from host (project settings via .claude/)
```

### Files

| File | Purpose |
|------|---------|
| `Dockerfile` | Container image with Claude Code, non-root user, settings, and hooks |
| `opclaude` | Launch script (volume mounts, env config) |
| `setup.sh` | Adds `opclaude` alias to `~/.zshrc` |
| `.env.example` | Template for API key and model config |
| `.opclaude/settings.json` | Claude Code settings (trusted dirs, hooks) — baked into image |
| `.opclaude/hooks/context-monitor.sh` | PostToolUse hook that warns when approaching token limit |
| `.opclaude/hooks/statusline.sh` | Status line showing model, context usage, and session cost |
| `.opclaude/.claude.json` | Minimal preferences to skip onboarding prompts |
| `models.json` | Catalog of available OpenRouter models for the picker |

### Configuration

**Change the model** — the selected model is saved to `.env` and reused on subsequent runs:
```bash
opclaude --setup                                # Interactive picker
opclaude --model google/gemini-2.5-pro-preview  # Set directly
```

On first run (no model in `.env`), the picker launches automatically. Uses [gum](https://github.com/charmbracelet/gum) if installed, otherwise falls back to a numbered list. Models are defined in `models.json`.

**Edit Claude settings** — modify `.opclaude/settings.json` and rebuild the image.

**Project-level settings** — add a `.claude/settings.json` in your project directory. It will be picked up automatically since the workspace is mounted.

**Rebuild the image** — needed when you change the `Dockerfile` or `.opclaude/` files:
```bash
docker build -t claude-openrouter .
```

### Context monitoring

A PostToolUse hook estimates token usage from the transcript file size:
- **~150K tokens** — warning message to Claude
- **~200K tokens** — urgent message telling Claude to run `/compact`

Thresholds can be adjusted in `.opclaude/hooks/context-monitor.sh` (`WARN_CHARS` and `MAX_CHARS`).

### Caveats

- Non-Anthropic models may not fully support Claude Code's tool use and system prompts
- The context monitor uses a rough char-to-token ratio (4:1) — it's an estimate, not exact
