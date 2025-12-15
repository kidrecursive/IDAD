# IDAD Installation Guide

Complete guide to installing and configuring IDAD in your repository.

---

## Table of Contents

1. [Quick Install](#quick-install)
2. [Prerequisites](#prerequisites)
3. [CLI Options](#cli-options)
4. [GitHub App Setup](#github-app-setup)
5. [Configuration](#configuration)
6. [Verification](#verification)
7. [Troubleshooting](#troubleshooting)
8. [Uninstallation](#uninstallation)

---

## Quick Install

Add IDAD to any existing repository with one command:

```bash
curl -fsSL https://raw.githubusercontent.com/kidrecursive/IDAD/main/install.sh | bash
```

The installer will:
1. Check prerequisites (git, gh CLI)
2. Ask which AI CLI you want to use
3. Download agent definitions and workflows
4. Guide you through secrets setup
5. Create labels and configure permissions
6. Commit files to your repo

**Total time**: ~5 minutes

---

## Prerequisites

### Required

1. **Git** (version 2.0+)
   ```bash
   git --version
   ```
   Install: https://git-scm.com/downloads

2. **GitHub CLI** (version 2.0+)
   ```bash
   gh --version
   ```
   Install: https://cli.github.com/

3. **GitHub Repository** with admin access
   - Public or private
   - GitHub Actions enabled

4. **AI CLI API Key** (one of these):
   - **Claude Code**: Get from https://console.anthropic.com/settings/keys (`ANTHROPIC_API_KEY`) or use OAuth (`ANTHROPIC_AUTH_TOKEN`)
   - **Cursor Agent**: Get from https://cursor.com/settings (`CURSOR_API_KEY`)
   - **OpenAI Codex**: Get from https://platform.openai.com/api-keys (`OPENAI_API_KEY`)

5. **GitHub App** (for automation)
   - Create at: https://github.com/settings/apps
   - See [GitHub App Setup](#github-app-setup) below

### Optional

- **Shell**: bash or zsh (macOS/Linux)
- Windows: Use Git Bash or WSL

---

## CLI Options

IDAD supports three AI CLI tools:

| CLI | Command | API Secret |
|-----|---------|------------|
| **Claude Code** | `claude` | `ANTHROPIC_API_KEY` or `ANTHROPIC_AUTH_TOKEN` |
| **Cursor Agent** | `cursor-agent` | `CURSOR_API_KEY` |
| **OpenAI Codex** | `codex` | `OPENAI_API_KEY` |

All IDAD configuration lives in `.idad/` regardless of which CLI you use.

### Install with Specific CLI

```bash
# Interactive (will prompt)
curl -fsSL https://raw.githubusercontent.com/kidrecursive/IDAD/main/install.sh | bash

# Claude Code (explicit)
curl -fsSL https://raw.githubusercontent.com/kidrecursive/IDAD/main/install.sh | bash -s -- --cli claude

# Cursor Agent (explicit)
curl -fsSL https://raw.githubusercontent.com/kidrecursive/IDAD/main/install.sh | bash -s -- --cli cursor

# OpenAI Codex (explicit)
curl -fsSL https://raw.githubusercontent.com/kidrecursive/IDAD/main/install.sh | bash -s -- --cli codex
```

### Files Installed

```
.idad/                          # CLI-agnostic IDAD configuration
├── agents/
│   ├── issue-review.md
│   ├── planner.md
│   ├── implementer.md
│   ├── security-scanner.md
│   ├── reviewer.md
│   ├── documenter.md
│   ├── idad.md
│   ├── reporting.md
│   └── repository-testing.md
├── rules/
│   └── system.md               # System context
├── commands/                   # Slash command source files
│   ├── idad-create-issue.md
│   ├── idad-monitor.md
│   ├── idad-approve-plan.md
│   └── idad-run-agent.md
└── README.md                   # Local usage documentation

.claude/commands/               # Claude Code slash commands (copies)
└── idad-*.md

.cursor/commands/               # Cursor slash commands (copies)
└── idad-*.md

.github/
├── actions/
│   └── run-idad-agent/        # Composite action for CLI abstraction
│       └── action.yml
└── workflows/
    └── idad.yml               # Unified workflow
```

**Notes:**
- All IDAD configuration lives in `.idad/` regardless of which CLI you use
- CLI-specific command directories are created for slash command support (except Codex, which doesn't support slash commands)
- CI workflow is NOT installed by default. The IDAD agent analyzes your project after the first PR merges and creates an appropriate CI workflow based on your project's languages and testing frameworks

---

## GitHub App Setup

IDAD requires a GitHub App to enable workflows to trigger other workflows.

### Step 1: Create the GitHub App

1. Go to [GitHub App Settings](https://github.com/settings/apps/new)
2. Fill in:
   - **Name**: `IDAD Automation`
   - **Homepage URL**: Your repository URL
   - **Webhook**: Uncheck "Active"
3. Set **Repository Permissions**:

   | Permission | Access |
   |------------|--------|
   | Contents | Read and Write |
   | Issues | Read and Write |
   | Pull requests | Read and Write |
   | Actions | Read and Write |
   | Workflows | Read and Write |

4. **Where can this app be installed?**: Only on this account
5. Click **"Create GitHub App"**
6. Note the **App ID** displayed on the page

### Step 2: Generate Private Key

1. On the app's settings page, scroll to **"Private keys"**
2. Click **"Generate a private key"**
3. Save the downloaded `.pem` file securely

### Step 3: Install the App

1. Go to your app's settings page
2. Click **"Install App"** in the sidebar
3. Choose **"Only select repositories"**
4. Select your target repository
5. Click **"Install"**

### Step 4: Add Secrets

```bash
# App ID (from app settings page)
gh secret set IDAD_APP_ID
# Enter the numeric App ID when prompted

# Private Key (from .pem file)
gh secret set IDAD_APP_PRIVATE_KEY < ~/Downloads/your-app.private-key.pem

# AI CLI API Key (choose based on your CLI)
gh secret set ANTHROPIC_API_KEY     # For Claude Code (API key)
gh secret set ANTHROPIC_AUTH_TOKEN  # For Claude Code (OAuth - alternative)
gh secret set CURSOR_API_KEY        # For Cursor Agent
gh secret set OPENAI_API_KEY        # For OpenAI Codex
```

> **Claude Code Authentication**: You can use either `ANTHROPIC_API_KEY` (standard API key) or `ANTHROPIC_AUTH_TOKEN` (OAuth bearer token from `claude auth status`). Only one is required.

### Verify Secrets

```bash
gh secret list
# Should show: IDAD_APP_ID, IDAD_APP_PRIVATE_KEY, and your CLI API key
```

---

## Configuration

### GitHub Actions Permissions

The installer configures these automatically. To verify:

1. Go to: Settings → Actions → General
2. **Workflow permissions**: Read and write permissions ✅
3. **Allow GitHub Actions to create and approve pull requests** ✅

### Labels

The installer creates these 9 labels automatically:

**IDAD workflow labels:**
| Label | Purpose |
|-------|---------|
| `idad:issue-review` | Issue Review Agent analyzing |
| `idad:issue-needs-clarification` | Issue needs human input |
| `idad:planning` | Planner creating plan |
| `idad:human-plan-review` | Human reviewing plan |
| `idad:implementing` | Implementer writing code |
| `idad:security-scan` | Security Scanner analyzing |
| `idad:code-review` | Reviewer Agent reviewing |
| `idad:documenting` | Documenter updating docs |
| `idad:human-pr-review` | Final human review |

**Important**: Only ONE `idad:*` label per issue/PR at a time.

Verify:
```bash
gh label list | grep "idad:"
```

### Model Configuration

Override default models via repository variables:

```bash
# For Cursor Agent
gh variable set IDAD_MODEL_PLANNER --body "opus-4.5"
gh variable set IDAD_MODEL_IMPLEMENTER --body "sonnet-4.5"

# For Claude Code
gh variable set IDAD_MODEL_PLANNER --body "claude-opus-4-20250514"
gh variable set IDAD_MODEL_IMPLEMENTER --body "claude-sonnet-4-20250514"
```

---

## Verification

### 1. Check Files Exist

```bash
# Check IDAD configuration
ls .idad/agents/
# Should show 9 .md files

ls .idad/commands/
# Should show 4 slash command files

# Check workflow and composite action
ls .github/workflows/idad.yml
ls .github/actions/run-idad-agent/action.yml

# Check CLI-specific slash commands (if applicable)
ls .claude/commands/idad-*.md 2>/dev/null
ls .cursor/commands/idad-*.md 2>/dev/null
```

### 2. Check Secrets

```bash
gh secret list
# Should show: IDAD_APP_ID, IDAD_APP_PRIVATE_KEY, and your CLI API key
```

### 3. Test with Example Issue

```bash
gh issue create \
  --title "Test IDAD installation" \
  --label "idad:issue-review" \
  --body "This is a test issue to verify IDAD is working."

# Watch the workflow
gh run list --workflow=idad.yml --limit 5
```

**Expected:**
1. Issue created with `idad:issue-review` label
2. IDAD workflow triggers
3. Issue Review Agent runs
4. Label changes to `idad:planning`
5. Planner Agent runs
6. Implementation plan added to issue
7. Label changes to `idad:human-plan-review` (waits for your approval)

---

## Troubleshooting

### Installer Fails

**Problem:** Permission errors or clone fails

**Solution:**
```bash
# Check you're in a git repository
git rev-parse --git-dir

# Check GitHub CLI is authenticated
gh auth status

# Check you have admin access
gh repo view --json viewerPermission
```

### Workflow Not Running

**Problem:** Created issue but nothing happens

**Solution:**
```bash
# 1. Check label exists
gh issue view <num> --json labels

# 2. Check workflow exists
ls .github/workflows/idad.yml

# 3. Check secrets exist
gh secret list

# 4. Manually trigger
gh workflow run idad.yml -f agent="issue-review" -f issue="<num>"

# 5. Check workflow logs
gh run list --workflow=idad.yml --limit 5
gh run view <run-id> --log
```

### Agent Fails

**Problem:** Agent runs but fails

**Solution:**
```bash
# Check workflow run logs
gh run view <run-id> --log

# Common issues:
# - Missing API key (ANTHROPIC_API_KEY, CURSOR_API_KEY, or OPENAI_API_KEY)
# - Missing agent files in .idad/agents/
# - Invalid model name
```

### API Key Issues

**Problem:** Authentication errors

**Solution:**
```bash
# Verify secret exists
gh secret list | grep -E "(CURSOR|ANTHROPIC|OPENAI)"

# Re-add secret (choose based on your CLI)
gh secret set ANTHROPIC_API_KEY     # Claude Code
gh secret set ANTHROPIC_AUTH_TOKEN  # Claude Code (OAuth)
gh secret set CURSOR_API_KEY        # Cursor Agent
gh secret set OPENAI_API_KEY        # OpenAI Codex
```

---

## Uninstallation

To remove IDAD:

```bash
# 1. Delete IDAD files
rm -rf .idad
rm -rf .claude/commands/idad-*.md
rm -rf .cursor/commands/idad-*.md
rm -rf .github/actions/run-idad-agent
rm .github/workflows/idad.yml
# Note: If IDAD created a ci.yml, you may want to keep it or remove it:
# rm .github/workflows/ci.yml

# 2. Remove secrets
gh secret delete IDAD_APP_ID
gh secret delete IDAD_APP_PRIVATE_KEY
gh secret delete ANTHROPIC_API_KEY      # if used
gh secret delete ANTHROPIC_AUTH_TOKEN   # if used
gh secret delete CURSOR_API_KEY         # if used
gh secret delete OPENAI_API_KEY         # if used

# 3. Delete labels (optional)
gh label delete "idad:issue-review"
gh label delete "idad:issue-needs-clarification"
gh label delete "idad:planning"
gh label delete "idad:human-plan-review"
gh label delete "idad:implementing"
gh label delete "idad:security-scan"
gh label delete "idad:code-review"
gh label delete "idad:documenting"
gh label delete "idad:human-pr-review"

# 4. Uninstall GitHub App (optional)
# Go to https://github.com/settings/installations
# Find IDAD Automation → Configure → Uninstall
```

---

## Platform Notes

### macOS
- Default shell: zsh
- GitHub CLI: `brew install gh`
- No issues expected

### Linux
- Default shell: bash
- GitHub CLI: See https://cli.github.com/
- No issues expected

### Windows
- Use Git Bash or WSL
- PowerShell: Limited support
- Recommended: WSL with Ubuntu

---

## Next Steps

After installation:

1. **Create your first issue:**
   ```bash
   gh issue create --title "My feature" --label "idad:issue-review" --body "Description"
   ```

2. **Watch agents work:**
   ```bash
   gh run list --workflow=idad.yml --limit 5
   ```

3. **Read the docs:**
   - [Quick Start](QUICKSTART.md)
   - [Workflow Guide](WORKFLOW.md)
   - [Agent Reference](AGENTS.md)

---

**Installation Time**: ~5 minutes  
**Difficulty**: Easy  
**Requirements**: Git, GitHub CLI, GitHub App, API key

**Need help?** Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

**Last Updated**: 2025-12-12
