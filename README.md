# IDAD - Issue Driven Agentic Development

### `cursor-agent` Implementation

🤖 **Fully automated, self-improving GitHub-based agentic coding system**

Create issues, get PRs automatically. AI agents handle the entire development workflow.

> **Other Implementations:**
> - [`claude-code`](https://github.com/kidrecursive/idad) - Uses Anthropic's Claude Code CLI

---

## How It Works

```
You create an issue with idad:auto label
         ↓
🤖 Issue Review Agent → refines and classifies
         ↓
🤖 Planner Agent → creates implementation plan
         ↓
🤖 Implementer Agent → writes code and tests
         ↓
🔒 Security Scanner → checks for vulnerabilities
         ↓
✅ CI → runs tests
         ↓
🤖 Reviewer Agent → performs code review
         ↓
🤖 Documenter Agent → updates documentation
         ↓
👤 You review and merge the PR
```

---

## Install

Add IDAD to any existing repository with one command:

```bash
curl -fsSL https://raw.githubusercontent.com/kidrecursive/idad/main/install.sh | bash
```

The installer will:
- Download IDAD agent definitions and workflows
- Guide you through GitHub App and API key setup
- Configure repository labels and permissions
- Commit the files to your repo

### Try It

```bash
# Create your first automated issue
gh issue create --title "Add hello world feature" --label "idad:auto" --body "Create a simple hello world function with tests."

# Watch the agents work
gh run list --workflow=idad.yml --limit 5
```

---

## GitHub App Setup (Required)

IDAD requires a **GitHub App** to enable workflows to trigger other workflows and perform automated actions.

### Step 1: Create the GitHub App

1. Go to: [GitHub App Settings](https://github.com/settings/apps/new) (or your org's settings)
2. Configure:
   - **Name**: `IDAD Automation` (or your preferred name)
   - **Homepage URL**: Your repository URL
   - **Webhook**: Uncheck "Active" (not needed)
3. **Repository Permissions**:
   | Permission | Access |
   |------------|--------|
   | Contents | Read and Write |
   | Issues | Read and Write |
   | Pull requests | Read and Write |
   | Actions | Read and Write |
   | Workflows | Read and Write |
4. **Where can this app be installed?**: Only on this account
5. Click **"Create GitHub App"**

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
# Get your App ID from the app's settings page (shown at top)
gh secret set IDAD_APP_ID

# Add the private key from your .pem file
gh secret set IDAD_APP_PRIVATE_KEY < path/to/private-key.pem
```

> **Note**: The private key is multi-line. Use file redirection as shown above, or paste carefully when prompted.

---

## Agents

Agents run via the [`cursor-agent`](https://docs.cursor.com/agent/cli) CLI.

| Agent | Purpose | Model (default) |
|-------|---------|-----------------|
| **Issue Review** | Refine and classify issues | sonnet-4.5 |
| **Planner** | Create implementation plans | opus-4.5 |
| **Implementer** | Write code and tests | sonnet-4.5 |
| **Security Scanner** | Check for vulnerabilities | sonnet-4.5 |
| **Reviewer** | Perform code review | sonnet-4.5 |
| **Documenter** | Update documentation | sonnet-4.5 |
| **IDAD** | Self-improvement | opus-4.5 |

### Configure Models

Models are those [available in Cursor](https://docs.cursor.com/settings/models).

```bash
gh variable set IDAD_MODEL_PLANNER --body "opus-4.5"
gh variable set IDAD_MODEL_IMPLEMENTER --body "sonnet-4.5"
```

---

## Labels

Add `idad:auto` to any issue to enable automation.

| Label | Purpose |
|-------|---------|
| `idad:auto` | **Enable automation** (required) |
| `type:issue` | Standard feature |
| `type:bug` | Bug fix |
| `type:epic` | Large feature (creates sub-issues) |
| `needs-clarification` | Waiting for human input |
| `needs-changes` | Code changes requested |

---

## Manual Triggers

```bash
# Trigger specific agent
gh workflow run idad.yml -f agent="planner" -f issue="123"

# Re-run implementer on existing PR
gh workflow run idad.yml -f agent="implementer" -f issue="123" -f pr="456"

# Trigger security scan
gh workflow run idad.yml -f agent="security-scanner" -f pr="456"
```

---

## File Structure

```
.cursor/
├── rules/
│   └── system.mdc         # Shared agent context
├── agents/
│   ├── issue-review.md
│   ├── planner.md
│   ├── implementer.md
│   ├── security-scanner.md
│   ├── reviewer.md
│   ├── documenter.md
│   └── idad.md
└── README.md

.github/
├── workflows/
│   ├── idad.yml           # Main agent workflow
│   └── ci.yml             # CI template
└── idad/docs/             # Documentation
```

---

## Documentation

- [Quick Start](.github/idad/docs/QUICKSTART.md)
- [Installation](.github/idad/docs/INSTALLATION.md)
- [Workflow Guide](.github/idad/docs/WORKFLOW.md)
- [Agent Reference](.github/idad/docs/AGENTS.md)
- [Troubleshooting](.github/idad/docs/TROUBLESHOOTING.md)

---

## Adding to Existing Repository

**Recommended**: Use the installer:

```bash
curl -fsSL https://raw.githubusercontent.com/kidrecursive/idad/main/install.sh | bash
```

**Manual**: Copy these to your repo:
- `.cursor/` (agents and rules)
- `.github/workflows/idad.yml`
- `.github/workflows/ci.yml`

Then add secrets (`IDAD_APP_ID`, `IDAD_APP_PRIVATE_KEY`, `CURSOR_API_KEY`) and create labels manually.

---

## Security

- **GitHub App**: Scoped to specific repositories only
- **Private Key**: Stored securely as repository secret
- **Installation Tokens**: Auto-generated, short-lived (1 hour)
- **Security Scanner**: Checks for vulnerabilities before review
- **Opt-in Only**: Automation requires explicit `idad:auto` label
- **Bot Identity**: All actions clearly attributed to `IDAD[bot]`

---

## License

MIT

---

**Created with ❤️ by AI agents, for human developers**

*This is the `cursor-agent` implementation. See also: [idad](https://github.com/kidrecursive/idad) for the `claude-code` implementation.*
