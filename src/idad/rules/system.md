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
3. **Opt-in**: Add `idad:issue-review` label to start automation
4. **Single Label**: Only ONE `idad:*` label per issue/PR at a time
5. **Traceability**: Every action is logged with agentlog blocks
6. **Agent Chain**: Each agent transitions the label to trigger the next

---

## Agent Chain & Label Flow

```
idad:issue-review → idad:planning → idad:human-plan-review → idad:implementing
        ↓                                    ↑ (human approves)      ↓
idad:issue-needs-clarification ←─────────────┘ (human requests)  idad:security-scan
        ↓ (human clarifies)                                         ↓
idad:issue-review ←──────────────────────────────────────────── idad:code-review
                                                                    ↓
                                              idad:implementing ← (changes)
                                                    ↓ (approved)
                                              idad:documenting
                                                    ↓
                                              idad:human-pr-review
                                                    ↓ (human comments)
                                              idad:implementing (loops back)
```

| Agent | Label Transitions |
|-------|-------------------|
| Issue Review | `idad:issue-review` → `idad:planning` OR `idad:issue-needs-clarification` |
| Planner (new) | `idad:planning` → `idad:human-plan-review` |
| Planner (approved) | `idad:human-plan-review` → `idad:implementing` |
| Planner (changes) | `idad:human-plan-review` → `idad:planning` |
| Implementer | Creates PR with `idad:security-scan` |
| Security Scanner (pass) | `idad:security-scan` → `idad:code-review` |
| Security Scanner (block) | `idad:security-scan` → `idad:implementing` |
| Reviewer (approved) | `idad:code-review` → `idad:documenting` |
| Reviewer (changes) | `idad:code-review` → `idad:implementing` |
| Documenter | `idad:documenting` → `idad:human-pr-review` |
| Human PR comment | `idad:human-pr-review` → `idad:implementing` |
| IDAD | Creates issue with `idad:issue-review` if improvements needed |

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
gh pr create --title "Title" --body "Body" --base main --label "idad:security-scan"

# Edit PR labels
gh pr edit <pr-num> --remove-label "idad:security-scan" --add-label "idad:code-review"

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

## Labels System (9 Labels)

**Only ONE `idad:*` label per issue/PR at a time.**

| Label | Purpose | Set By |
|-------|---------|--------|
| `idad:issue-review` | Issue Review Agent analyzing | User (opt-in) |
| `idad:issue-needs-clarification` | Issue needs human input | Issue Review Agent |
| `idad:planning` | Planner creating plan | Issue Review Agent |
| `idad:human-plan-review` | Human reviewing plan | Planner Agent |
| `idad:implementing` | Implementer writing code | Planner / Reviewer / Security / Human |
| `idad:security-scan` | Security Scanner analyzing | Implementer Agent |
| `idad:code-review` | Reviewer Agent reviewing | Security Scanner |
| `idad:documenting` | Documenter updating docs | Reviewer Agent |
| `idad:human-pr-review` | Final human review | Documenter Agent |

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
3. **Transition to appropriate label** (e.g., back to `idad:implementing`)
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
5. **Always transition to next label** to trigger next agent
6. **Only ONE `idad:*` label** at a time - remove old before adding new
7. **Never skip error handling** - post informative comments

---

## Quick Reference

### Transition Labels (Triggers Next Agent)
```bash
# Issue labels
gh issue edit 123 --remove-label "idad:issue-review" --add-label "idad:planning"

# PR labels
gh pr edit 456 --remove-label "idad:security-scan" --add-label "idad:code-review"
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
