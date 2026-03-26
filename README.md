# Claude Code via OpenRouter (Docker)

Run Claude Code in a Docker container, routed through OpenRouter with free models. No changes to your local machine's Claude installation.

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

On first run, Claude will ask for theme and permissions. In persistent mode (`--persist`), those choices are saved to `~/.opclaude/` and reused for future runs. In ephemeral mode, they're lost when the container exits.

## Usage

```bash
cd ~/my-project
opclaude           # Ephemeral mode (isolated, no persistence)
opclaude --persist # Persistent mode (shares settings/hooks/plugins/sessions)
```

This mounts the current directory as `/workspace` inside the container. Claude runs with `--dangerously-skip-permissions` (safe — it's in a disposable container).

### Modes
- **Ephemeral mode** (`opclaude`): Starts with a clean Claude Code configuration each time. No data persists between runs. Ideal for isolated experimentation.
- **Persistent mode** (`opclaude --persist`): Shares settings, hooks, plugins, and session history between runs via `~/.opclaude/`. Still isolated from your host's `~/.claude`.

## How it works

```
opclaude (alias)
  └─ Docker container (node:22-slim)
       ├─ Claude Code CLI
       ├─ OpenRouter API routing (env vars from .env)
       ├─ Model config (configurable in .env)
       └─ ~/.claude in container (see volume mounts below)
```

### Volume Mounts

**Ephemeral mode** (`opclaude`):
- `$(pwd)` → `/workspace` (your current directory)
- Project `.claude/settings.json` → `/home/claude/.claude/settings.json` (rw)
- Project `.claude/hooks` → `/home/claude/.claude/hooks` (rw)
- *No persistence*: Changes are lost when container exits

**Persistent mode** (`opclaude --persist`):
- `$(pwd)` → `/workspace` (your current directory)
- `~/.opclaude/` → `/home/claude/.claude/` (rw, entire config dir)
- *Persistence*: Sessions, plugins, settings, and history survive between runs
- On first `--persist` run, `~/.opclaude/` is seeded from the project's `.claude/` defaults

### Files

| File | Purpose |
|------|---------|
| `Dockerfile` | Container image with Claude Code + non-root user |
| `opclaude` | Launch script (volume mounts, env config) |
| `setup.sh` | Adds `opclaude` alias to `~/.zshrc` |
| `.env.example` | Template for API key and model config |
| `.claude/settings.json` | Claude Code settings (trusted dirs, hooks) |
| `.claude/hooks/context-monitor.sh` | PostToolUse hook that warns when approaching token limit |

### Configuration

**Change the model** — edit `.env`:
```bash
ANTHROPIC_DEFAULT_SONNET_MODEL=nvidia/nemotron-3-super-120b-a12b:free
```

**Edit Claude settings** — modify `.claude/settings.json`. Changes take effect on next run (no rebuild needed).

**Rebuild the image** — only needed if you change the `Dockerfile`:
```bash
docker build -t claude-openrouter .
```

### Context monitoring

A PostToolUse hook estimates token usage from the transcript file size:
- **~150K tokens** — warning message to Claude
- **~200K tokens** — urgent message telling Claude to run `/compact`

Thresholds can be adjusted in `.claude/hooks/context-monitor.sh` (`WARN_CHARS` and `MAX_CHARS`).

### Caveats

- Free non-Anthropic models may not fully support Claude Code's tool use and system prompts
- The context monitor uses a rough char-to-token ratio (4:1) — it's an estimate, not exact
- Persistent mode uses `~/.opclaude/` (separate from your host `~/.claude`) — seeded from project defaults on first run
