# IDAD Agent Reference

Complete reference for all IDAD agents.

---

## Table of Contents

1. [Agent Overview](#agent-overview)
2. [Issue Review Agent](#issue-review-agent)
3. [Planner Agent](#planner-agent)
4. [Implementer Agent](#implementer-agent)
5. [Reviewer Agent](#reviewer-agent)
6. [Documenter Agent](#documenter-agent)
7. [IDAD Agent](#idad-agent)
8. [Reporting Agent](#reporting-agent)
9. [Manual Invocation](#manual-invocation)

---

## Agent Overview

IDAD uses 8 specialized agents that collaborate to deliver features:

| Agent | Purpose | Trigger | Duration |
|-------|---------|---------|----------|
| Issue Review | Analyze & validate issues | `idad:issue-review` | 30-60s |
| Planner | Create implementation plan | `idad:planning` OR `idad:human-plan-review` | 1-2 min |
| Implementer | Write code & tests | `idad:implementing` | 1-3 min |
| Security Scanner | Check vulnerabilities | `idad:security-scan` | 30-60s |
| Reviewer | Code review | `idad:code-review` | 30-90s |
| Documenter | Update docs | `idad:documenting` | 30-90s |
| IDAD | System improvements | PR merged | 1-2 min |
| Reporting | Generate metrics | Scheduled/manual | 2-4 min |

**Note**: After Planner creates a plan, a **human review step** is required before Implementer runs.

**Important**: Only ONE `idad:*` label per issue/PR at a time.

---

## Issue Review Agent

### Purpose
Analyzes issue descriptions and validates requirements.

### Trigger
- Event: `issues.labeled`
- Condition: Has `idad:issue-review` label

### Inputs
- Issue number
- Issue title and body
- Issue author

### Outputs
- Analysis comment (or clarifying questions)
- Label transition: `idad:planning` (ready) or `idad:issue-needs-clarification` (unclear)
- Comment with agentlog

### Responsibilities
- Read and understand issue requirements
- Ask clarifying questions if needed
- Ensure requirements are clear and actionable
- Transition to appropriate label

### Decision Logic
- If clear → Set `idad:planning`, trigger Planner
- If unclear → Set `idad:issue-needs-clarification`, post questions
- When human clarifies on `idad:issue-needs-clarification` → Re-analyze

### Git Identity
```
Issue Review Agent <issue-review@agents.local>
```

### Example Comment
```markdown
### 🤖 Issue Review Agent

**Assessment**: The issue description is clear and actionable.

**Next Step**: Planner Agent will create implementation plan

---
```agentlog
agent: issue-review
issue: 123
status: success
timestamp: 2025-12-09T10:00:00Z
```
```

### Manual Invocation
```bash
gh workflow run idad.yml \
  --ref main \
  -f agent="issue-review" \
  -f issue="123" \
  -f pr=""
```

---

## Planner Agent

### Purpose
Creates detailed implementation plans for issues and handles human feedback on plans.

### Trigger
- Condition: Issue has `idad:planning` label (initial planning)
- Condition: Comment on issue with `idad:human-plan-review` label (plan review)
- Modes: Issue mode, Plan Review mode, or Epic mode

### Inputs
- Issue number
- Issue requirements
- Human feedback (in Plan Review mode)

### Outputs
- Implementation plan (added to issue body)
- Branch name
- Label transition: `idad:human-plan-review` (initially) or `idad:implementing` (after approval)
- Comment with agentlog

### Responsibilities
- Analyze requirements
- Create step-by-step plan
- Determine files to create/modify
- Suggest branch name
- Break down into manageable tasks
- **Handle human feedback on plans**
- **Update plans when changes requested**
- **Trigger Implementer only after human approval**

### Modes

**Issue Mode** (default):
- Creates single implementation plan
- Adds plan to issue body
- Creates feature branch
- Sets `idad:human-plan-review`
- **Waits for human approval**

**Plan Review Mode**:
- Triggered when human comments on `idad:human-plan-review` issue
- Reads human feedback
- If changes requested: Updates plan, sets `idad:planning`
- If approved: Triggers Implementer, sets `idad:implementing`

**Epic Mode**:
- Detects epic issues
- Creates multiple sub-issues with `idad:planning` (well-defined)
- Each sub-issue gets own plan
- Links sub-issues to parent
- Each sub-issue follows normal workflow (including plan review)

### Plan Format
```markdown
## Implementation Plan

### Overview
[Approach description]

### Files to Create/Modify
- file1.js - [purpose]
- file2.test.js - [tests]

### Steps
1. Create base structure
2. Implement core logic
3. Add validation
4. Write tests
5. Update docs

### Branch
feat/issue-123-description
```

### Git Identity
```
Planner Agent <planner@agents.local>
```

### Manual Invocation
```bash
gh workflow run idad.yml \
  --ref main \
  -f agent="planner" \
  -f issue="123" \
  -f pr=""
```

---

## Implementer Agent

### Purpose
Implements the plan by writing code and tests.

### Trigger
- Condition: Issue has `idad:implementing` label

### Inputs
- Issue number
- Implementation plan (from issue body)
- Branch name (from plan)

### Outputs
- Feature branch with code
- Unit tests
- Pull request
- Comment with agentlog

### Responsibilities
- Create/checkout feature branch
- Implement code according to plan
- Write comprehensive unit tests
- Run tests locally (must pass!)
- Commit with proper identity
- Push to remote
- Create PR linking to issue
- Trigger next agent

### Code Standards
- Clean, readable code
- Follows existing patterns
- Includes error handling
- Comprehensive tests
- Documentation (code comments)

### Testing Requirement
**Critical**: Must run unit tests before committing
- Tests must pass locally
- If tests fail, fix before committing
- Never push failing tests

### Git Identity
```
Implementer Agent <implementer@agents.local>
```

### Commit Format
```
Add feature implementation

Implements issue #123 requirements.

Changes:
- Created feature module
- Added unit tests
- Updated imports

Agent-Type: implementer
Issue: #123
Workflow-Run: 20123456789
```

### Manual Invocation
```bash
gh workflow run idad.yml \
  --ref main \
  -f agent="implementer" \
  -f issue="123" \
  -f pr=""
```

---

## Security Scanner

### Purpose
Checks PR code for security vulnerabilities.

### Trigger
- Condition: PR has `idad:security-scan` label

### Inputs
- PR number
- PR code changes

### Outputs
- Security scan results comment
- Label transition: `idad:code-review` (pass) or `idad:implementing` (block)
- Comment with agentlog

### Security Checks
- Hardcoded secrets, API keys, credentials
- SQL injection vulnerabilities
- XSS vulnerabilities
- Command injection
- Path traversal
- Insecure dependencies
- OWASP top 10 issues

### Decisions

**Pass**:
- No security issues found
- Sets `idad:code-review`
- Triggers Reviewer Agent

**Block**:
- Security issues detected
- Sets `idad:implementing`
- Triggers Implementer to fix

### Git Identity
```
Security Scanner Agent <security-scanner@agents.local>
```

### Manual Invocation
```bash
gh workflow run idad.yml \
  --ref main \
  -f agent="security-scanner" \
  -f issue="" \
  -f pr="456"
```

---

## Reviewer Agent

### Purpose
Performs code review and quality assessment.

### Trigger
- Condition: PR has `idad:code-review` label

### Inputs
- PR number
- PR code changes
- Issue requirements

### Outputs
- PR review (approve or request changes)
- Review comments
- Label transition: `idad:documenting` (approved) or `idad:implementing` (changes)

### Review Criteria
- **Requirements**: All acceptance criteria met?
- **Code Quality**: Clean, maintainable, follows patterns?
- **Testing**: Comprehensive test coverage?
- **Error Handling**: Edge cases handled?
- **Documentation**: Code comments where needed?

### Decisions

**Approve**:
- All criteria met
- Minor issues acceptable
- Posts approval review
- Sets `idad:documenting`
- Triggers Documenter

**Request Changes**:
- Critical issues found
- Missing requirements
- Inadequate tests
- Posts detailed feedback
- Sets `idad:implementing`
- Triggers Implementer (to fix)

### Git Identity
```
Reviewer Agent <reviewer@agents.local>
```

### Can Make Small Fixes
- Typos
- Formatting
- Comments
- Does NOT make logic changes

### Manual Invocation
```bash
gh workflow run idad.yml \
  --ref main \
  -f agent="reviewer" \
  -f issue="123" \
  -f pr="456"
```

---

## Documenter Agent

### Purpose
Updates documentation and finalizes PR.

### Trigger
- Condition: PR has `idad:documenting` label

### Inputs
- PR number
- PR changes
- Issue requirements

### Outputs
- Updated documentation (README, etc.)
- Finalized PR description
- Label transition: `idad:human-pr-review`
- Summary comment
- **No further agent trigger** (end of automation)

### Responsibilities
- Analyze PR changes
- Update README.md with new features
- Update API docs if needed
- Add usage examples
- Clean up temporary files
- Finalize PR description
- Set `idad:human-pr-review`
- Post summary comment

### Documentation Standards
- Clear and concise
- Follow existing style
- User-facing focus
- Include examples
- Cover edge cases

### Git Identity
```
Documenter Agent <documenter@agents.local>
```

### Commit Format
```
Update documentation for new feature

Adds documentation for feature from PR #456.

Changes:
- Updated README with feature description
- Added usage examples
- Documented API changes

Agent-Type: documenter
Issue: #123
PR: #456
Workflow-Run: 20123456789
```

### Important
**This is the final agent in the automated chain.**
After Documenter completes, the PR is ready for human review.

### Manual Invocation
```bash
gh workflow run idad.yml \
  --ref main \
  -f agent="documenter" \
  -f issue="123" \
  -f pr="456"
```

---

## IDAD Agent

### Purpose
Self-improvement - updates the IDAD system based on repository evolution.

### Trigger
- Event: `pull_request.closed` with `merged == true`
- Conditions:
  - Branch does NOT start with `idad/` (prevents loops)

### Inputs
- PR number
- PR changes
- Files modified

### Outputs
- Improvement issue with `idad:issue-review` (if needed)
- Analysis comment

### Responsibilities
- Analyze merged changes
- Detect new technologies (Python, Go, Rust, etc.)
- Detect new frameworks (Next.js, Docker, etc.)
- Check if CI supports detected technologies
- Check if agents have guidance for technologies
- Create improvement PR if gaps found

### Improvement Targets
- CI workflows (add test support)
- Agent definitions (add best practices)
- Build pipelines (add framework support)

### Loop Prevention
Multiple safeguards prevent infinite loops:
- ✅ Skips branches starting with `idad/`
- ✅ Creates issues (not PRs), going through full workflow
- ✅ Improvement issues require human plan approval and PR review

### Git Identity
```
IDAD Agent <idad@agents.local>
```

### Improvement Issue Format
```markdown
Title: Improve IDAD system: Add Python support
Labels: idad:issue-review

Contains:
- Analysis of detected technologies
- Proposed CI workflow updates
- Proposed agent definition updates
```

### Conservative Approach
IDAD Agent is intentionally conservative:
- Only creates PRs for clear benefits
- Focuses on practical needs
- When in doubt, doesn't create PR

### Manual Invocation
```bash
gh workflow run idad.yml \
  --ref main \
  -f agent="idad" \
  -f issue="" \
  -f pr="456"
```

---

## Reporting Agent

### Purpose
Generate periodic reports with metrics and insights.

### Trigger
- Manual: `workflow_dispatch`
- Scheduled: Cron (optional)

### Inputs
- Report type (weekly, monthly, custom)
- Lookback days (for custom)

### Outputs
- Report issue with metrics
- No PR or branch
- No agent triggering

### Responsibilities
- Query closed issues/PRs in date range
- Extract agentlog blocks
- Aggregate metrics by agent type
- Calculate success rates
- Generate insights
- Create report issue

### Metrics Tracked
- Agent run counts
- Success vs. failure rates
- Average durations
- Quality metrics (clarifications, changes)
- System health (error rates)

### Report Format
```markdown
# IDAD System Report - Weekly

## Summary
- Issues Processed: X
- PRs Created: Y
- Success Rate: Z%

## Agent Activity
[By agent type]

## Quality Metrics
[Clarifications, changes]

## System Health
[Failures, errors]

## Insights
[AI-generated observations]
```

### Git Identity
```
Reporting Agent <reporting@agents.local>
```

### Manual Invocation
```bash
# Weekly report
gh workflow run idad.yml \
  --ref main \
  -f agent="reporting" \
  -f issue="" \
  -f pr=""

# Custom period (set env vars)
REPORT_TYPE=custom LOOKBACK_DAYS=14 \
gh workflow run idad.yml \
  --ref main \
  -f agent="reporting" \
  -f issue="" \
  -f pr=""
```

---

## Manual Invocation

### When to Manually Trigger

- Workflow didn't auto-trigger
- Retry after fixing an issue
- Skip ahead in workflow
- Test specific agent

### General Pattern

```bash
gh workflow run idad.yml \
  --ref main \
  -f agent="<agent-name>" \
  -f issue="<number>" \
  -f pr="<number>"
```

### Agent Names
- `issue-review`
- `planner`
- `implementer`
- `security-scanner`
- `reviewer`
- `documenter`
- `idad`
- `reporting`

### Which Parameters Are Required?

| Agent | issue | pr |
|-------|-------|-----|
| issue-review | ✅ Required | ❌ Empty |
| planner | ✅ Required | ❌ Empty |
| implementer | ✅ Required | ⚠️ Optional |
| security-scanner | ⚠️ Optional | ✅ Required |
| reviewer | ⚠️ Optional | ✅ Required |
| documenter | ⚠️ Optional | ✅ Required |
| idad | ❌ Empty | ✅ Required |
| reporting | ❌ Empty | ❌ Empty |

### Examples

```bash
# Trigger Issue Review for issue #123
gh workflow run idad.yml --ref main \
  -f agent="issue-review" \
  -f issue="123" \
  -f pr=""

# Trigger Implementer (with existing PR)
gh workflow run idad.yml --ref main \
  -f agent="implementer" \
  -f issue="123" \
  -f pr="456"

# Trigger Security Scanner for PR #456
gh workflow run idad.yml --ref main \
  -f agent="security-scanner" \
  -f issue="" \
  -f pr="456"

# Trigger Reviewer for PR #456
gh workflow run idad.yml --ref main \
  -f agent="reviewer" \
  -f issue="" \
  -f pr="456"

# Trigger IDAD Agent to analyze PR #456
gh workflow run idad.yml --ref main \
  -f agent="idad" \
  -f issue="" \
  -f pr="456"

# Trigger Reporting
gh workflow run idad.yml --ref main \
  -f agent="reporting" \
  -f issue="" \
  -f pr=""
```

---

## Agent Definition Files

All agent definitions are in `.cursor/agents/`:

```
.cursor/agents/
├── issue-review.md      # Issue Review Agent
├── planner.md           # Planner Agent
├── implementer.md       # Implementer Agent
├── security-scanner.md  # Security Scanner Agent
├── reviewer.md          # Reviewer Agent
├── documenter.md        # Documenter Agent
├── idad.md              # IDAD Agent
├── reporting.md         # Reporting Agent
└── repository-testing.md # Repository Testing Agent
```

Each file contains:
- Agent purpose and context
- Trigger conditions
- Step-by-step responsibilities
- Decision-making logic
- Examples
- Error handling
- Success criteria

---

## Workflow Chaining

Agents trigger the next agent in the chain via `workflow_dispatch`:

```bash
gh workflow run idad.yml \
  --repo ${{ github.repository }} \
  --ref main \
  -f agent_type="next-agent" \
  -f issue_number="${ISSUE_NUMBER}" \
  -f pr_number="${PR_NUMBER}"
```

### Chain Diagram

```
Issue Review ──► Planner ──► [Human Plan Review] ──► Implementer ──► Security Scanner ──► Reviewer ──┬──► Documenter ──► [Human PR Review]
                    ↑               │                     ↑                    │                     │        │
                    └───────────────┘ (changes)          │                    │                     │        └──► Implementer (human comments)
                                                          │                    └─────────────────────┤
                                                          └────────────────────────────────────────────┘ (changes needed)

[Human Merge] ──► IDAD Agent (creates improvement issue if needed)
```

### Why Explicit Chaining?

- **Observable**: Each step is visible in Actions tab
- **Debuggable**: Can inspect each workflow run
- **Controllable**: Can pause/resume at any step
- **Reliable**: Works around GitHub token limitations

---

## Environment Variables

All agents have access to:

| Variable | Description | Example |
|----------|-------------|---------|
| `GITHUB_TOKEN` | GitHub API auth | (secret) |
| `GITHUB_REPOSITORY` | Repo in owner/repo format | kidrecursive/idad |
| `GITHUB_RUN_ID` | Current workflow run ID | 20123456789 |
| `GITHUB_WORKSPACE` | Workspace directory | /home/runner/work/repo |
| `CURSOR_API_KEY` | Cursor AI auth | (secret) |

---

## Common Operations

All agents use standard operations from `.cursor/rules/system.mdc`:

### Git Operations
- Configure identity
- Commit with trailers
- Push branches
- Create branches

### GitHub CLI Operations
- Create/update issues
- Create/update PRs
- Add/remove labels
- Post comments
- Submit reviews

### Workflow Triggering
- Trigger next agent via `workflow_dispatch`
- Pass issue/PR numbers
- Set agent type

See `.cursor/rules/system.mdc` for complete operation reference.

---

## Machine-Readable Logging

All agents post agentlog blocks:

```markdown
```agentlog
agent: agent-name
issue: 123
pr: 456
status: success|error
duration_ms: 12345
timestamp: 2025-12-09T10:00:00Z
```
```

**Required Fields**:
- `agent`: Agent type
- `status`: success, error, or in-progress
- `timestamp`: ISO 8601 format

**Optional Fields**:
- `issue`: Issue number
- `pr`: PR number
- `duration_ms`: Execution time
- Custom fields as needed

**Purpose**:
- Reporting aggregation
- Debugging
- Metrics tracking
- System observability

---

## Performance Expectations

### Typical Timeline (Simple Feature)
```
00:00 - Issue created
00:01 - Dispatcher triggers
00:01 - Issue Review starts
00:01 - Issue Review completes (45s)
00:02 - Planner starts
00:03 - Planner completes (90s)
00:03 - Implementer starts
00:05 - Implementer completes (120s)
00:05 - CI runs (< 30s)
00:05 - Reviewer starts
00:06 - Reviewer completes (60s)
00:06 - Documenter starts
00:08 - Documenter completes (90s)
00:08 - Ready for human review

Total: ~8 minutes
```

### Factors Affecting Speed
- **Issue Complexity**: More complex = longer
- **Code Size**: More files = more time
- **Tests**: Larger test suites take longer
- **GitHub Queue**: Actions may queue during peak times

---

## Next Steps

- **Workflow Guide**: See [WORKFLOW.md](WORKFLOW.md) for complete workflow
- **Troubleshooting**: See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for debugging
- **Operations**: See [OPERATIONS.md](OPERATIONS.md) for repository management

---

**Last Updated**: 2025-12-12
**Phase**: 11 - Unified Label System
