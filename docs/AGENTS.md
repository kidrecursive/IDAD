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

IDAD uses 7 specialized agents that collaborate to deliver features:

| Agent | Purpose | Trigger | Duration |
|-------|---------|---------|----------|
| Issue Review | Refine & classify issues | Issue created | 30-60s |
| Planner | Create implementation plan | state:ready | 1-2 min |
| Implementer | Write code & tests | state:implementing | 1-3 min |
| Reviewer | Code review | CI passes | 30-90s |
| Documenter | Update docs | PR approved | 30-90s |
| IDAD | System improvements | PR merged | 1-2 min |
| Reporting | Generate metrics | Scheduled/manual | 2-4 min |

---

## Issue Review Agent

### Purpose
Refines issue descriptions and classifies issues by type.

### Trigger
- Event: `issues.opened`
- Condition: Has `idad:auto` label

### Inputs
- Issue number
- Issue title and body
- Issue author

### Outputs
- Refined issue description (or clarifying questions)
- Type label (`type:feature`, `type:bug`, etc.)
- State label (`state:ready` or `needs-clarification`)
- Comment with agentlog

### Responsibilities
- Read and understand issue requirements
- Ask clarifying questions if needed
- Classify issue type
- Ensure requirements are clear and actionable
- Set appropriate labels

### Decision Logic
- If clear → Add type label, set `state:ready`
- If unclear → Add `needs-clarification`, post questions
- If question/discussion → Add `type:question`, may close

### Git Identity
```
Issue Review Agent <issue-review@agents.local>
```

### Example Comment
```markdown
### 🤖 Issue Review Agent

**Classification**: Feature

**Assessment**: The issue description is clear and actionable.

**Type**: type:feature
**Next Step**: Planner Agent will create implementation plan

---
```agentlog
agent: issue-review
issue: 123
status: success
classification: feature
timestamp: 2025-12-09T10:00:00Z
```
```

### Manual Invocation
```bash
gh workflow run idad.yml \
  --ref main \
  -f agent_type="issue-review" \
  -f issue_number="123" \
  -f pr_number=""
```

---

## Planner Agent

### Purpose
Creates detailed implementation plans for issues.

### Trigger
- Condition: Issue has `state:ready` label
- Modes: Issue mode or Epic mode

### Inputs
- Issue number
- Issue requirements
- Issue type

### Outputs
- Implementation plan (added to issue body)
- Branch name
- State label (`state:implementing`)
- Comment with agentlog

### Responsibilities
- Analyze requirements
- Create step-by-step plan
- Determine files to create/modify
- Suggest branch name
- Break down into manageable tasks

### Modes

**Issue Mode** (default):
- Creates single implementation plan
- Adds plan to issue body
- Triggers Implementer

**Epic Mode** (`type:epic`):
- Creates multiple sub-issues
- Each sub-issue gets own plan
- Links sub-issues to parent
- Each sub-issue follows normal workflow

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
  -f agent_type="planner" \
  -f issue_number="123" \
  -f pr_number=""
```

---

## Implementer Agent

### Purpose
Implements the plan by writing code and tests.

### Trigger
- Condition: Issue has `state:implementing` label

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
  -f agent_type="implementer" \
  -f issue_number="123" \
  -f pr_number=""
```

---

## Reviewer Agent

### Purpose
Performs code review and quality assessment.

### Trigger
- Condition: CI passes on PR
- PR has automated labels

### Inputs
- PR number
- PR code changes
- Issue requirements

### Outputs
- PR review (approve or request changes)
- Review comments
- State label update
- Triggers next agent

### Review Criteria
- **Requirements**: All acceptance criteria met?
- **Code Quality**: Clean, maintainable, follows patterns?
- **Testing**: Comprehensive test coverage?
- **Security**: No vulnerabilities or hardcoded secrets?
- **Error Handling**: Edge cases handled?
- **Documentation**: Code comments where needed?

### Decisions

**Approve**:
- All criteria met
- Minor issues acceptable
- Posts approval review
- Sets `state:robot-docs`
- Triggers Documenter

**Request Changes**:
- Critical issues found
- Missing requirements
- Inadequate tests
- Posts detailed feedback
- Adds `needs-changes`
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
  -f agent_type="reviewer" \
  -f issue_number="123" \
  -f pr_number="456"
```

---

## Documenter Agent

### Purpose
Updates documentation and finalizes PR.

### Trigger
- Condition: PR has `state:robot-docs` label

### Inputs
- PR number
- PR changes
- Issue requirements

### Outputs
- Updated documentation (README, etc.)
- Finalized PR description
- State label (`state:human-review`)
- Summary comment
- **No further agent trigger** (end of automation)

### Responsibilities
- Analyze PR changes
- Update README.md with new features
- Update API docs if needed
- Add usage examples
- Clean up temporary files
- Finalize PR description
- Set `state:human-review`
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
  -f agent_type="documenter" \
  -f issue_number="123" \
  -f pr_number="456"
```

---

## IDAD Agent

### Purpose
Self-improvement - updates the IDAD system based on repository evolution.

### Trigger
- Event: `pull_request.closed` with `merged == true`
- Conditions:
  - PR has `idad:auto` label
  - PR does NOT have `type:infrastructure`
  - Branch does NOT start with `idad/`

### Inputs
- PR number
- PR changes
- Files modified

### Outputs
- Improvement PR (if needed)
- Analysis comment
- No label changes

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
- ✅ Skips PRs with `type:infrastructure`
- ✅ Skips PRs without `idad:auto`
- ✅ Never adds `idad:auto` to improvement PRs
- ✅ Improvement PRs require human review

### Git Identity
```
IDAD Agent <idad@agents.local>
```

### Improvement PR Format
```
Title: Improve IDAD system: Add Python support
Branch: idad/improve-1234567890
Labels: type:infrastructure (NO idad:auto)
Base: main

Contains:
- CI workflow updates
- Agent definition updates
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
  -f agent_type="idad" \
  -f issue_number="" \
  -f pr_number="456"
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
  -f agent_type="reporting" \
  -f issue_number="" \
  -f pr_number=""

# Custom period (set env vars)
REPORT_TYPE=custom LOOKBACK_DAYS=14 \
gh workflow run idad.yml \
  --ref main \
  -f agent_type="reporting" \
  -f issue_number="" \
  -f pr_number=""
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
  -f agent_type="<agent-name>" \
  -f issue_number="<number>" \
  -f pr_number="<number>"
```

### Agent Names
- `issue-review`
- `planner`
- `implementer`
- `reviewer`
- `documenter`
- `idad`
- `reporting`

### Which Parameters Are Required?

| Agent | issue_number | pr_number |
|-------|--------------|-----------|
| issue-review | ✅ Required | ❌ Empty |
| planner | ✅ Required | ❌ Empty |
| implementer | ✅ Required | ⚠️ Optional |
| reviewer | ⚠️ Optional | ✅ Required |
| documenter | ⚠️ Optional | ✅ Required |
| idad | ❌ Empty | ✅ Required |
| reporting | ❌ Empty | ❌ Empty |

### Examples

```bash
# Trigger Issue Review for issue #123
gh workflow run idad.yml --ref main \
  -f agent_type="issue-review" \
  -f issue_number="123" \
  -f pr_number=""

# Trigger Implementer (with existing PR)
gh workflow run idad.yml --ref main \
  -f agent_type="implementer" \
  -f issue_number="123" \
  -f pr_number="456"

# Trigger Reviewer for PR #456
gh workflow run idad.yml --ref main \
  -f agent_type="reviewer" \
  -f issue_number="" \
  -f pr_number="456"

# Trigger IDAD Agent to analyze PR #456
gh workflow run idad.yml --ref main \
  -f agent_type="idad" \
  -f issue_number="" \
  -f pr_number="456"

# Trigger Reporting
gh workflow run idad.yml --ref main \
  -f agent_type="reporting" \
  -f issue_number="" \
  -f pr_number=""
```

---

## Agent Definition Files

All agent definitions are in `.cursor/agents/`:

```
.cursor/agents/
├── issue-review.md    # Issue Review Agent (300+ lines)
├── planner.md         # Planner Agent (700+ lines)
├── implementer.md     # Implementer Agent (600+ lines)
├── reviewer.md        # Reviewer Agent (600+ lines)
├── documenter.md      # Documenter Agent (700+ lines)
├── idad.md            # IDAD Agent (500+ lines)
└── reporting.md       # Reporting Agent (600+ lines)
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
Issue Review ──► Planner ──► Implementer ──► CI ──► Reviewer ──┬──► Documenter ──► [Human]
                                                                │
                                                                └──► Implementer (if changes needed)

[Human Merge] ──► IDAD Agent (analyzes for improvements)
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

**Last Updated**: 2025-12-09  
**Phase**: 10 - Full Workflow Integration
