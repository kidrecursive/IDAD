---
globs:
alwaysApply: true
---

# IDAD System Context

You are an AI agent in the **IDAD (Issue Driven Agentic Development)** system - a fully automated, GitHub-based agentic coding system.

---

## Core Principles

1. **Issue-first**: All work begins with a GitHub Issue
2. **PR-first**: All code changes go through pull requests
3. **Opt-in**: Only process issues/PRs with `idad:auto` label
4. **Traceability**: Every action is logged with agentlog blocks
5. **Agent Chain**: Each agent triggers the next via `gh workflow run`

---

## Agent Chain

```
Issue (idad:auto) → Issue Review → Planner → [Human Plan Review] → Implementer → Security Scanner → [CI] → Reviewer → Documenter → Human
                                        ↑           ↑                                                          |
                                        |           └──── (if changes to plan) ────┘                           |
                                        └────────────────────── (if changes to code) ──────────────────────────┘
```

| Agent | Triggers Next |
|-------|---------------|
| Issue Review | → Planner |
| Planner (new plan) | → **Human Plan Review** (waits for feedback) |
| Planner (approved) | → Implementer |
| Planner (changes) | → (updates plan, waits for feedback) |
| Implementer | → Security Scanner |
| Security Scanner | → (CI runs automatically) |
| CI (on pass) | → Reviewer |
| Reviewer (approved) | → Documenter |
| Reviewer (changes) | → Implementer |
| Documenter | → (end, human review) |
| IDAD | → (creates improvement PR if needed) |

---

## Your Identity

Configure git before any commits:

```bash
git config user.name "<Your Agent Name>"
git config user.email "<your-agent>@agents.local"
```

**Agent Identities**:
| Agent | Email |
|-------|-------|
| Issue Review | `issue-review@agents.local` |
| Planner | `planner@agents.local` |
| Implementer | `implementer@agents.local` |
| Security Scanner | `security-scanner@agents.local` |
| Reviewer | `reviewer@agents.local` |
| Documenter | `documenter@agents.local` |
| IDAD | `idad@agents.local` |

---

## GitHub CLI Operations

### Reading Data

```bash
# Issue details
gh issue view <num> --json title,body,labels,comments

# PR details
gh pr view <num> --json number,title,body,files,labels,headRefName,additions,deletions

# PR diff
gh pr diff <num>

# PR files changed
gh pr view <num> --json files --jq '.files[].path'
```

### Writing Data

```bash
# Edit issue labels
gh issue edit <num> --add-label "label1,label2"
gh issue edit <num> --remove-label "label"

# Comment on issue
gh issue comment <num> --body "message"

# Create PR
gh pr create --title "Title" --body "Body" --base main --label "idad:auto"

# Edit PR labels (use issue edit with PR number)
gh issue edit <pr-num> --add-label "state:robot-review"

# Comment on PR
gh pr comment <num> --body "message"

# Submit PR review
gh pr review <num> --approve --body "Approval message"
gh pr review <num> --request-changes --body "Changes needed"
gh pr review <num> --comment --body "General comment"
```

### Triggering Next Agent

```bash
gh workflow run idad.yml \
  --repo "$REPO" \
  -f agent="<next-agent>" \
  -f issue="<issue-number>" \
  -f pr="<pr-number>"
```

**Important**: Always trigger the next agent explicitly. The GitHub App token allows workflows to trigger other workflows.

---

## Git Operations

### Branch Creation

```bash
# For features
git fetch origin main
git checkout -b feat/issue-<num>-<slug> origin/main
git push -u origin feat/issue-<num>-<slug>

# For bug fixes
git checkout -b fix/issue-<num>-<slug> origin/main
```

### Commits

```bash
git add <files>
git commit --author="<Agent Name> <<agent>@agents.local>" \
  -m "Summary of change

Description of what was done and why.

Agent-Type: <agent>
Issue: #<num>
PR: #<num>
Workflow-Run: <run-id>"
```

### Push

```bash
git push origin <branch-name>
```

---

## Labels System

### Type Labels
- `type:issue` - Standard issue
- `type:epic` - Epic with child issues
- `type:bug` - Bug fix
- `type:documentation` - Documentation update
- `type:question` - Question or discussion
- `type:infrastructure` - IDAD system changes

### State Labels
- `state:issue-review` - Under issue review
- `state:ready` - Ready for planning
- `state:planning` - Being planned
- `state:plan-review` - **Human reviewing implementation plan**
- `state:implementing` - Being implemented
- `state:robot-review` - Under code review
- `state:robot-docs` - Documentation in progress
- `state:human-review` - Ready for human review

### Control Labels
- `idad:auto` - **Enable IDAD automation** (opt-in required)
- `needs-clarification` - Needs human clarification
- `needs-changes` - Changes requested

---

## Agentlog Format

**Always** end your summary comments with a machine-readable agentlog block:

```markdown
---
\`\`\`agentlog
agent: <agent-type>
issue: <number>
pr: <number>
status: success|error|blocked
timestamp: <ISO8601>
\`\`\`
```

### Required Fields
- `agent`: Your agent type (e.g., `issue-review`, `planner`)
- `status`: `success`, `error`, or agent-specific (e.g., `blocked`, `passed`)
- `timestamp`: ISO 8601 format (use `$(date -u +%Y-%m-%dT%H:%M:%SZ)`)

### Optional Fields
- `issue`: Issue number
- `pr`: PR number
- `duration_ms`: Execution time in milliseconds
- Any agent-specific fields

---

## Environment Variables Available

| Variable | Description |
|----------|-------------|
| `AGENT` | Current agent type |
| `ISSUE` | Issue number (may be empty) |
| `PR` | PR number (may be empty) |
| `REPO` | Repository in `owner/repo` format |
| `RUN_ID` | GitHub Actions workflow run ID |
| `MODEL` | AI model being used |

---

## Error Handling

When errors occur:

1. **Post an error comment** explaining what went wrong
2. **Include troubleshooting steps** for humans
3. **Add appropriate labels** (`needs-changes` or similar)
4. **Include agentlog** with `status: error`
5. **Exit with non-zero code** so workflow shows as failed

Example error comment:

```markdown
### ❌ <Agent Name> - Error

**Error**: <Brief description>

**Details**:
\`\`\`
<Error output or details>
\`\`\`

**Recommended Action**: <What human should do>

---
\`\`\`agentlog
agent: <agent>
issue: <num>
status: error
error: <brief error>
timestamp: <ISO8601>
\`\`\`
```

---

## Best Practices

1. **Always use `gh` CLI** for GitHub operations (not raw API calls)
2. **Always configure git identity** before commits
3. **Always include git trailers** in commit messages
4. **Always post agentlog** in summary comments
5. **Always trigger next agent** via `gh workflow run`
6. **Never add `idad:auto`** to infrastructure PRs
7. **Never skip error handling** - post informative comments

---

## Quick Reference

### Trigger Next Agent
```bash
gh workflow run idad.yml -f agent="planner" -f issue="123" -f pr=""
```

### Add Labels
```bash
gh issue edit 123 --add-label "state:ready" --remove-label "state:issue-review"
```

### Post Comment
```bash
gh issue comment 123 --body "### 🤖 Agent Name

Message here

---
\`\`\`agentlog
agent: agent-name
status: success
timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)
\`\`\`"
```

### Commit with Identity
```bash
git config user.name "Planner Agent"
git config user.email "planner@agents.local"
git commit --author="Planner Agent <planner@agents.local>" -m "Message"
```
