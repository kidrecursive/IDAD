# IDAD - Issue Driven Agentic Development

**Fully automated, self-improving GitHub-based agentic coding system**

Create issues, get PRs automatically. AI agents handle the entire development workflow with human review gates at plan and PR stages.

Supports [Claude Code](https://claude.ai/code), [Cursor Agent](https://docs.cursor.com/agent/cli), and [OpenAI Codex](https://openai.com/index/introducing-codex/) CLIs.

---

## How It Works

```
You create an issue with idad:issue-review label
         ↓
🤖 Issue Review Agent → analyzes and validates
         ↓
🤖 Planner Agent → creates implementation plan
         ↓
👤 You review the plan → approve or request changes
         ↓
🤖 Implementer Agent → writes code and tests
         ↓
🔒 Security Scanner → checks for vulnerabilities
         ↓
🤖 Reviewer Agent → performs code review
         ↓
🤖 Documenter Agent → updates documentation
         ↓
👤 You review and merge the PR
         ↓
🤖 IDAD Agent → analyzes for system improvements
```

**Two human gates**: You approve the plan before coding starts, then review the final PR before merge.

**Only ONE `idad:*` label per issue/PR at a time** — the label encapsulates the workflow state.

---

## Install

Add IDAD to any existing repository:

```bash
curl -fsSL https://raw.githubusercontent.com/kidrecursive/IDAD/main/install.sh | bash
```

The installer will:
- Ask which AI CLI you want to use (Claude Code, Cursor, or Codex)
- Download IDAD agent definitions, rules, and workflow
- Install slash commands for local CLI usage
- Guide you through GitHub App and API key setup
- Configure repository labels and permissions

### CLI Options

| CLI | Command | Authentication |
|-----|---------|----------------|
| **Claude Code** | `claude` | `ANTHROPIC_API_KEY` or `ANTHROPIC_AUTH_TOKEN` |
| **Cursor Agent** | `cursor-agent` | `CURSOR_API_KEY` |
| **OpenAI Codex** | `codex` | `OPENAI_API_KEY` |

Install with a specific CLI:

```bash
curl -fsSL https://...install.sh | bash -s -- --cli claude
curl -fsSL https://...install.sh | bash -s -- --cli cursor
curl -fsSL https://...install.sh | bash -s -- --cli codex
```

### Try It

```bash
# Create your first automated issue
gh issue create \
  --title "Add hello world feature" \
  --label "idad:issue-review" \
  --body "Create a simple hello world function with tests."

# Watch the agents work
gh run list --workflow=idad.yml --limit 5
```

---

## GitHub App Setup

IDAD requires a GitHub App to enable workflows to trigger other workflows.

### 1. Create the App

Go to [GitHub App Settings](https://github.com/settings/apps/new) and configure:
- **Name**: `IDAD Automation`
- **Homepage URL**: Your repository URL
- **Webhook**: Uncheck "Active"

**Repository Permissions**:
| Permission | Access |
|------------|--------|
| Contents | Read and Write |
| Issues | Read and Write |
| Pull requests | Read and Write |
| Actions | Read and Write |
| Workflows | Read and Write |

### 2. Generate Private Key & Install

On the app's settings page, generate a private key and save the `.pem` file. Then install the app on your repository.

### 3. Add Secrets

```bash
# GitHub App credentials
gh secret set IDAD_APP_ID
gh secret set IDAD_APP_PRIVATE_KEY < path/to/private-key.pem

# AI CLI API key (choose based on your CLI)
gh secret set ANTHROPIC_API_KEY     # Claude Code (API key)
gh secret set ANTHROPIC_AUTH_TOKEN  # Claude Code (OAuth - alternative)
gh secret set CURSOR_API_KEY        # Cursor Agent
gh secret set OPENAI_API_KEY        # OpenAI Codex
```

---

## Agents

| Agent | Purpose |
|-------|---------|
| **Issue Review** | Analyze and validate issues |
| **Planner** | Create implementation plans |
| **Implementer** | Write code and tests |
| **Security Scanner** | Check for vulnerabilities |
| **Reviewer** | Perform code review |
| **Documenter** | Update documentation |
| **IDAD** | Self-improvement after merges |
| **Reporting** | Generate metrics reports |

### Model Configuration

The installer configures models based on your CLI:

| CLI | Default Model | Planner & IDAD Model |
|-----|---------------|----------------------|
| **Claude Code** | `claude-haiku-4-5-20251001` | `claude-opus-4-5-20251101` |
| **Cursor** | `sonnet-4.5` | `opus-4.5` |
| **Codex** | `gpt-5.2` | `gpt-5.1-codex-max` |

Override any agent's model:

```bash
gh variable set IDAD_MODEL_REVIEWER --body "claude-sonnet-4-5-20250929"
gh variable set IDAD_MODEL_DEFAULT --body "your-model-name"
```

Available variables: `IDAD_MODEL_DEFAULT`, `IDAD_MODEL_PLANNER`, `IDAD_MODEL_IMPLEMENTER`, `IDAD_MODEL_REVIEWER`, `IDAD_MODEL_SECURITY`, `IDAD_MODEL_DOCUMENTER`, `IDAD_MODEL_ISSUE_REVIEW`, `IDAD_MODEL_IDAD`, `IDAD_MODEL_REPORTING`

---

## Labels

Add `idad:issue-review` to any issue to start automation. **Only ONE `idad:*` label at a time.**

| Label | Purpose |
|-------|---------|
| `idad:issue-review` | **Start automation** (opt-in) |
| `idad:issue-needs-clarification` | Issue needs human input |
| `idad:planning` | Planner creating plan |
| `idad:human-plan-review` | **Waiting for plan approval** |
| `idad:implementing` | Implementer writing code |
| `idad:security-scan` | Security Scanner analyzing |
| `idad:code-review` | Reviewer analyzing |
| `idad:documenting` | Documenter updating docs |
| `idad:human-pr-review` | **Final human review** |

---

## Local Usage

IDAD includes slash commands for Claude Code and Cursor:

| Command | Purpose |
|---------|---------|
| `/idad-create-issue` | Create issues with guided questions |
| `/idad-monitor` | Check workflow status |
| `/idad-approve-plan` | Review and approve plans |
| `/idad-run-agent` | Run agent locally (testing) |

For Codex (no slash commands), reference the README directly:
```
@.idad/README.md Create an issue for adding dark mode
```

---

## Manual Triggers

```bash
# Trigger specific agent on issue
gh workflow run idad.yml -f agent="planner" -f issue="123"

# Trigger agent on PR
gh workflow run idad.yml -f agent="security-scanner" -f pr="456"

# Re-run implementer with both issue and PR
gh workflow run idad.yml -f agent="implementer" -f issue="123" -f pr="456"
```

---

## File Structure

```
.idad/                          # IDAD configuration
├── agents/                     # Agent definitions (8 agents)
├── rules/system.md             # System rules
├── commands/                   # Slash command source files
└── README.md                   # Local usage docs

.github/
├── actions/run-idad-agent/     # Composite action
└── workflows/idad.yml          # Main workflow

.claude/commands/               # Claude Code slash commands
.cursor/commands/               # Cursor slash commands
```

---

## Documentation

- **[Quick Start](docs/QUICKSTART.md)** — Get running in 5 minutes
- **[Installation](docs/INSTALLATION.md)** — Detailed setup guide
- **[Workflow Guide](docs/WORKFLOW.md)** — Complete workflow walkthrough
- **[Agent Reference](docs/AGENTS.md)** — All agents documented
- **[Operations](docs/OPERATIONS.md)** — Maintenance and management
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** — Problem solving

---

## Security

- **Human Review Gates**: Plan approval and PR review required before merge
- **GitHub App**: Scoped to specific repositories only
- **Private Key**: Stored securely as repository secret
- **Security Scanner**: Checks for vulnerabilities before review
- **Opt-in Only**: Requires explicit `idad:issue-review` label
- **Bot Identity**: All actions attributed to agent emails

---

## License

MIT

---

**Created with ❤️ by AI agents, for human developers**
