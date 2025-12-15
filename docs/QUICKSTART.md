# IDAD Quick Start Guide

Get up and running with IDAD in under 5 minutes!

---

## What is IDAD?

**IDAD (Issue Driven Agentic Development)** is a self-improving, AI-driven GitHub automation system where AI agents automatically:

1. Review and refine your issues
2. Create implementation plans
3. Write code and tests
4. Run security scans and code review
5. Update documentation
6. Improve themselves

You create an issue → AI agents deliver a ready-to-merge PR!

---

## Prerequisites

- GitHub repository with admin access
- [GitHub CLI](https://cli.github.com/) installed and authenticated
- AI CLI API key (one of):
  - [Claude Code](https://claude.ai/code) - `ANTHROPIC_API_KEY` or `ANTHROPIC_AUTH_TOKEN`
  - [Cursor Agent](https://cursor.com/settings) - `CURSOR_API_KEY`
  - [OpenAI Codex](https://platform.openai.com/api-keys) - `OPENAI_API_KEY`

---

## 5-Minute Setup

### Step 1: Install IDAD

```bash
curl -fsSL https://raw.githubusercontent.com/kidrecursive/IDAD/main/install.sh | bash
```

The installer will:
- Ask which AI CLI you want to use (Claude Code, Cursor, or Codex)
- Download IDAD agent definitions, rules, and workflow
- Install slash commands for local CLI usage
- Guide you through GitHub App and API key setup

### Step 2: Commit and Push

```bash
git add .idad/ .github/
# Also add CLI-specific command directories if created:
git add .claude/commands/ 2>/dev/null || true
git add .cursor/commands/ 2>/dev/null || true

git commit -m "feat: add IDAD automation"
git push
```

### Step 3: Add Secrets

```bash
# GitHub App credentials (required)
gh secret set IDAD_APP_ID
gh secret set IDAD_APP_PRIVATE_KEY < path/to/private-key.pem

# AI CLI API key (choose based on your CLI)
gh secret set ANTHROPIC_API_KEY     # For Claude Code (API key)
gh secret set ANTHROPIC_AUTH_TOKEN  # For Claude Code (OAuth - alternative)
gh secret set CURSOR_API_KEY        # For Cursor Agent
gh secret set OPENAI_API_KEY        # For OpenAI Codex
```

### Step 4: Create Your First Issue

```bash
gh issue create \
  --title "Add hello world feature" \
  --label "idad:issue-review" \
  --body "Create a simple hello world function with tests."
```

### Step 5: Watch It Work!

```bash
# Watch the agents work
gh run list --workflow=idad.yml --limit 5

# View workflow details
gh run view
```

Within ~6-10 minutes, you'll have:
- Analyzed issue ready for planning
- Detailed implementation plan (awaiting your approval)
- Complete code with tests (after approval)
- Security-scanned and reviewed PR
- Updated documentation

---

## What Happens Next?

The IDAD agents work through your issue automatically:

```
Issue Created (#1) + idad:issue-review label
    ↓
Issue Review Agent (30-60s)
    ├─ Analyzes requirements
    ├─ Validates clarity
    └─ → idad:planning
    ↓
Planner Agent (1-2 min)
    ├─ Creates implementation plan
    ├─ Breaks down into steps
    ├─ Creates feature branch
    └─ → idad:human-plan-review
    ↓
👤 You Review the Plan
    ├─ Comment "looks good" to approve
    └─ Or describe changes you want
    ↓
Implementer Agent (1-3 min)
    ├─ Writes code
    ├─ Creates comprehensive tests
    ├─ Creates pull request
    └─ → idad:security-scan on PR
    ↓
Security Scanner (30-60s)
    ├─ Checks for vulnerabilities
    └─ → idad:code-review (or back to implementing)
    ↓
Reviewer Agent (30-90s)
    ├─ Reviews code quality
    ├─ Checks requirements
    └─ → idad:documenting (or back to implementing)
    ↓
Documenter Agent (30-90s)
    ├─ Updates README
    ├─ Adds examples
    └─ → idad:human-pr-review
    ↓
Ready for Your Review!
```

### Your Turn

1. **Review the plan** - Check the implementation approach
2. **Approve the plan** - Comment "looks good" or similar
3. **Wait for code** - Implementer writes the code
4. **Review the PR** - Check the code and docs
5. **Merge it** - When you're happy with it
6. **Done!** - Feature is live

---

## Local Usage with Slash Commands

IDAD includes slash commands for local CLI sessions (Claude Code and Cursor):

| Command | Purpose |
|---------|---------|
| `/idad-create-issue` | Create issues with guided questions |
| `/idad-monitor` | Check workflow status for issues/PRs |
| `/idad-approve-plan` | Review and approve implementation plans |
| `/idad-run-agent` | Run an agent locally for testing |

Example usage in your CLI:
```bash
# In Claude Code or Cursor, type:
/idad-create-issue add user authentication

# Or for Codex (no slash commands), reference the README:
@.idad/README.md Let's create an issue for adding dark mode
```

---

## Common Operations

### Creating Issues

```bash
# Create with label (starts automation)
gh issue create \
  --title "Your feature title" \
  --label "idad:issue-review" \
  --body "Detailed description..."

# Or use slash command in your CLI
/idad-create-issue
```

### Monitoring Progress

```bash
# List active workflow runs
gh run list --workflow=idad.yml --limit 5

# View specific run details
gh run view <run-id>

# View run logs
gh run view <run-id> --log

# Or use slash command
/idad-monitor
```

### Manual Triggers

```bash
# Trigger specific agent
gh workflow run idad.yml -f agent="planner" -f issue="123" -f pr=""

# Re-run implementer on existing PR
gh workflow run idad.yml -f agent="implementer" -f issue="123" -f pr="456"

# Trigger security scan
gh workflow run idad.yml -f agent="security-scanner" -f issue="" -f pr="456"
```

### Pausing Automation

```bash
# Remove the idad:* label to pause
gh issue edit 123 --remove-label "idad:planning"

# Re-add to resume
gh issue edit 123 --add-label "idad:planning"
```

---

## Tips for Success

### Write Clear Issues

**Good:**
```
Title: Add email validation
Description:
Validate email addresses on user registration.

Requirements:
- Check format (regex)
- Check MX records
- Return clear error messages

Acceptance Criteria:
- Invalid emails rejected
- Valid emails accepted
- Informative error messages
```

**Not Great:**
```
Title: Fix emails
Description: Emails don't work
```

### Use Labels Wisely

- `idad:issue-review` - **Required** to start automation
- Only ONE `idad:*` label at a time
- Label shows current workflow state

### Monitor Progress

```bash
# Quick status check
gh run list --workflow=idad.yml --limit 5

# Check workflows with details
gh run view

# Use slash command for interactive monitoring
/idad-monitor
```

---

## Troubleshooting

### Issue: Nothing happens after creating issue

**Check:**
1. Does issue have `idad:issue-review` label?
2. Are workflows running? `gh run list`
3. Is your API key set? `gh secret list`

**Fix:**
```bash
# Add label if missing
gh issue edit 123 --add-label "idad:issue-review"

# Manually trigger the workflow
gh workflow run idad.yml -f agent="issue-review" -f issue="123" -f pr=""
```

### Issue: Workflow failed

**Check:**
```bash
# View recent runs
gh run list --workflow=idad.yml --limit 5

# Check logs for failed run
gh run view <run-id> --log-failed
```

**Fix:**
```bash
# Re-run failed workflow
gh run rerun <run-id>
```

### Issue: Want to make manual changes

```bash
# Remove label to pause automation
gh issue edit 123 --remove-label "idad:implementing"

# Make your changes
# ... edit code, add comments, etc ...

# Re-add label when ready to continue
gh issue edit 123 --add-label "idad:implementing"
```

---

## Next Steps

### Learn More

- **[Installation Guide](INSTALLATION.md)** - Detailed setup instructions
- **[Complete Workflow Guide](WORKFLOW.md)** - Detailed walkthrough
- **[Agent Reference](AGENTS.md)** - All agents documented
- **[Troubleshooting](TROUBLESHOOTING.md)** - Problem solving
- **[Operations Manual](OPERATIONS.md)** - Repository management

### Verify Installation

Run the repository testing agent to verify everything is configured:

```bash
# Use slash command in your CLI
/idad-run-agent repository-testing
```

This verifies:
- All agent files are present
- Workflow is correctly configured
- GitHub labels exist
- Secrets are configured
- Actions permissions are set

---

## What You've Learned

- Install and setup IDAD
- Create your first automated issue
- Monitor workflow progress
- Use slash commands for local interaction
- Review and merge automated PRs

**You're ready to build with IDAD!**

---

**Time to complete**: < 5 minutes
**What you get**: Fully automated development workflow
**Next**: Create more issues and watch IDAD work!
