# IDAD - Issue Driven Agentic Development

This repository uses IDAD for automated issue-to-PR workflows.

## Quick Start

### Create an Issue (Triggers Automation)

```bash
gh issue create \
  --title "Add feature X" \
  --label "idad:issue-review" \
  --body "Description of what you want..."
```

### Monitor Workflows

```bash
gh run list --workflow=idad.yml --limit 5
gh run watch
```

---

## Workflow Labels

| Label | Meaning |
|-------|---------|
| `idad:issue-review` | **Add this to start** - Issue Review agent analyzes |
| `idad:issue-needs-clarification` | Waiting for your clarification |
| `idad:planning` | Planner agent creating implementation plan |
| `idad:human-plan-review` | **Review the plan** - approve or request changes |
| `idad:implementing` | Implementer agent writing code |
| `idad:security-scan` | Security Scanner checking for vulnerabilities |
| `idad:code-review` | Reviewer agent analyzing code |
| `idad:documenting` | Documenter agent updating docs |
| `idad:human-pr-review` | **Final review** - merge when ready |

---

## Agents

| Agent | File | Purpose |
|-------|------|---------|
| Issue Review | `agents/issue-review.md` | Analyzes and validates issues |
| Planner | `agents/planner.md` | Creates implementation plans |
| Implementer | `agents/implementer.md` | Writes code and tests |
| Security Scanner | `agents/security-scanner.md` | Checks for vulnerabilities |
| Reviewer | `agents/reviewer.md` | Performs code review |
| Documenter | `agents/documenter.md` | Updates documentation |
| IDAD | `agents/idad.md` | Creates improvement issues |

---

## Local CLI Usage

### Slash Commands (Claude Code & Cursor)

After installation, these commands are available in your CLI:

| Command | Purpose | Example |
|---------|---------|---------|
| `/idad-create-issue` | Create a new IDAD issue | `/idad-create-issue Add user authentication` |
| `/idad-monitor` | Check workflow status | `/idad-monitor 123` |
| `/idad-approve-plan` | Review and approve plans | `/idad-approve-plan 123` |
| `/idad-run-agent` | Run agent locally (testing) | `/idad-run-agent planner 123` |

> **Note:** OpenAI Codex doesn't support slash commands. Use the `.idad/run.sh` script or reference this README directly.

### Using the Run Script (All CLIs, including Codex)

```bash
# Run an agent locally
.idad/run.sh <agent> [issue] [pr]

# Examples
IDAD_CLI=codex .idad/run.sh planner 123
IDAD_CLI=claude .idad/run.sh implementer 123 456
```

### Alternative: Direct Reference

If slash commands aren't available, reference this README directly:

```
@.idad/README.md <your request>
```

Examples:
- `@.idad/README.md Create an issue for adding search functionality`
- `@.idad/README.md What's the status of issue 123?`
- `@.idad/README.md Help me review the plan for issue 123`

---

## Common Workflows

### Start a New Feature

1. Create the issue:
   ```
   /idad-create-issue Add dark mode support
   ```

2. Monitor progress:
   ```
   /idad-monitor 123
   ```

3. When plan is ready, review and approve:
   ```
   /idad-approve-plan 123
   ```

4. After PR is created, review and merge via GitHub

### Check What's Happening

```
/idad-monitor
```

Shows recent workflow runs and their status.

### Debug a Stuck Issue

1. Check status:
   ```
   /idad-monitor 123
   ```

2. If needed, run agent locally:
   ```
   /idad-run-agent planner 123
   ```

---

## Authentication

### Claude Code

**Option 1: API Key (Recommended)**
```bash
gh secret set ANTHROPIC_API_KEY
# Get your key: https://console.anthropic.com/settings/keys
```

**Option 2: OAuth Token**
```bash
gh secret set ANTHROPIC_AUTH_TOKEN
```

### Cursor Agent

```bash
gh secret set CURSOR_API_KEY
# Get your key: https://cursor.com/settings
```

### OpenAI Codex

```bash
gh secret set OPENAI_API_KEY
# Get your key: https://platform.openai.com/api-keys
```

---

## Configuration

### Select CLI

```bash
gh variable set IDAD_CLI --body "claude"   # or "cursor" or "codex"
```

### Configure Models

```bash
# Claude Code format
gh variable set IDAD_MODEL_PLANNER --body "claude-opus-4-5-20251101"

# Cursor format
gh variable set IDAD_MODEL_PLANNER --body "opus-4.5"

# Codex format
gh variable set IDAD_MODEL_PLANNER --body "gpt-5-codex"
```

---

## Environment Setup

For local agent runs, ensure these are available:

```bash
# GitHub CLI authenticated
gh auth status

# For Claude Code
export ANTHROPIC_API_KEY=<your-key>
# Or
export ANTHROPIC_AUTH_TOKEN=<your-token>

# For Cursor
export CURSOR_API_KEY=<your-key>

# For Codex
export OPENAI_API_KEY=<your-key>
```

---

## Troubleshooting

**"Command not found"**
- Slash commands are in `.claude/commands/` or `.cursor/commands/`
- Re-run installer or manually copy from `.idad/commands/`

**"gh: command not found"**
- Install GitHub CLI: https://cli.github.com/
- Authenticate: `gh auth login`

**"Permission denied" on local agent run**
- Local runs don't have GitHub App permissions
- Some operations (label changes, PR creation) may fail
- Use for testing only; real workflow should run via GitHub Actions

---

## Learn More

- [IDAD Repository](https://github.com/kidrecursive/IDAD)
- [GitHub CLI Documentation](https://cli.github.com/manual/)
