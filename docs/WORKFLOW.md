# IDAD Workflow Guide

Complete guide to the IDAD (Issue Driven Agentic Development) workflow.

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Complete Workflow](#complete-workflow)
3. [Agent Responsibilities](#agent-responsibilities)
4. [Label System](#label-system)
5. [Timeline Expectations](#timeline-expectations)
6. [Common Patterns](#common-patterns)

---

## System Overview

IDAD is a fully automated, self-improving GitHub-based agentic coding system where:

- **GitHub Issues** are the specification database
- **Pull Requests** are implementation and review artifacts
- **Agents collaborate** via labels, comments, and workflows
- **System self-improves** through the IDAD Agent
- **Automation is opt-in** via the `idad:issue-review` label
- **Only ONE `idad:*` label** per issue/PR at a time (encapsulates workflow state)

### Architecture

```
┌──────────────────────┐
│      GitHub Issue    │◄─── User creates issue
│ + idad:issue-review  │     (opt-in to automation)
└──────────┬───────────┘
           │
           ▼
┌─────────────────────────────────────────────────────────────┐
│              IDAD Automation Pipeline                        │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  1. Issue Review Agent ──► Analyzes & Validates              │
│                             → idad:planning (ready)          │
│                             → idad:issue-needs-clarification │
│                                                               │
│  2. Planner Agent ────────► Creates Implementation Plan      │
│                             Adds to issue body                │
│                             → idad:human-plan-review         │
│                                                               │
│  3. 👤 Human Plan Review ─► Reviews plan, provides feedback  │
│                             Approves or requests changes      │
│                             (Comment triggers Planner)        │
│                                                               │
│  4. Implementer Agent ───► Writes Code & Tests               │
│                             Creates PR with idad:security-scan│
│                                                               │
│  5. Security Scanner ────► Checks for vulnerabilities        │
│                             → idad:code-review (pass)        │
│                             → idad:implementing (block)       │
│                                                               │
│  6. Reviewer Agent ───────► Code Review                      │
│                             → idad:documenting (approved)     │
│                             → idad:implementing (changes)     │
│                                                               │
│  7. Documenter Agent ─────► Updates Documentation            │
│                             Finalizes PR                      │
│                             → idad:human-pr-review           │
│                                                               │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
                    ┌───────────────┐
                    │  Human Review │
                    │  & Merge PR   │
                    └───────┬───────┘
                            │
                            ▼
                    ┌───────────────┐
                    │  IDAD Agent   │
                    │ (Improvement) │
                    └───────────────┘
```

---

## Complete Workflow

### Step 1: Issue Creation

**User Action**: Create an issue with clear requirements

**Required**:
- Add `idad:issue-review` label (opt-in to automation)
- Provide clear description
- Specify acceptance criteria

**Example**:
```markdown
## Description
Add user authentication feature

## Requirements
- User can register with email/password
- User can log in
- Passwords must be hashed

## Acceptance Criteria
- [ ] Registration form works
- [ ] Login form works
- [ ] Passwords are hashed
```

**What Happens**:
- Issue created in GitHub
- Workflow detects `idad:issue-review` label
- Triggers Issue Review Agent

**Timeline**: Instant

---

### Step 2: Issue Review Agent

**Purpose**: Analyze and validate the issue

**Actions**:
- Reads issue description
- May ask clarifying questions (sets `idad:issue-needs-clarification`)
- Ensures requirements are clear and actionable
- Posts analysis comment
- Sets `idad:planning` when ready

**Timeline**: 30-60 seconds

**You'll See**:
- Agent comment with analysis or clarifying questions
- Label changes to `idad:planning` (ready) or `idad:issue-needs-clarification` (unclear)
- Machine-readable `agentlog` block

**Next Step**: Automatically triggers Planner Agent (or waits for human clarification)

---

### Step 3: Planner Agent

**Purpose**: Create implementation plan

**Actions**:
- Analyzes issue requirements
- Creates step-by-step implementation plan
- Determines appropriate branch name
- Creates feature branch
- Updates issue body with plan
- Sets `idad:human-plan-review`
- **Waits for human approval**

**Timeline**: 1-2 minutes

**You'll See**:
- Implementation plan added to issue body
- Task breakdown with subtasks
- Branch name specified
- `idad:human-plan-review` label
- Comment asking for your review

**Plan Format**:
```markdown
## Implementation Plan

### Overview
[High-level approach]

### Files to Create/Modify
- file1.js - [purpose]
- file2.test.js - [purpose]

### Steps
1. Create base structure
2. Implement core logic
3. Add input validation
4. Write unit tests
5. Update documentation

### Branch
feat/issue-123-description
```

**Next Step**: Waits for human feedback (see Step 3.5)

---

### Step 3.5: Human Plan Review (NEW!)

**Purpose**: Review and approve the implementation plan before coding begins

**Your Actions**:
- Review the implementation plan in the issue body
- Check that files, steps, and approach make sense
- Either:
  - **Approve**: Comment "looks good", "proceed", "LGTM", etc.
  - **Request changes**: Describe what you want changed

**How to Respond**:
```bash
# Approve the plan
gh issue comment 123 --body "Looks good, let's proceed!"

# Request changes
gh issue comment 123 --body "Can we also add error handling for edge cases?"
```

**What Happens**:
- Your comment triggers the Planner agent again
- Planner reads your feedback and either:
  - Updates the plan (if changes requested) → goes to `idad:planning`
  - Triggers Implementer (if approved) → changes to `idad:implementing`

**Timeline**: Depends on you!

**Next Step**: After approval, Planner triggers Implementer Agent

---

### Step 4: Implementer Agent

**Purpose**: Write code and create PR

**Actions**:
- Creates/checks out feature branch
- Implements code according to plan
- Writes comprehensive unit tests
- Runs tests locally to ensure they pass
- Commits with proper git identity
- Pushes to remote
- Creates pull request
- Links PR to issue

**Timeline**: 1-3 minutes (depends on complexity)

**Git Identity**:
```
Author: Implementer Agent <implementer@agents.local>
```

**Git Trailers**:
```
Agent-Type: implementer
Issue: #123
PR: #456
Workflow-Run: 20123456789
```

**You'll See**:
- New PR created
- Code committed to feature branch
- PR description with implementation summary
- Tests included
- `idad:security-scan` label on PR

**Next Step**: PR creation triggers Security Scanner

---

### Step 5: Security Scanner

**Purpose**: Check for security vulnerabilities

**Actions**:
- Analyzes PR changes for security issues
- Checks for hardcoded secrets, SQL injection, XSS, etc.
- Reviews dependencies for known vulnerabilities
- Either:
  - **Passes**: Sets `idad:code-review`, triggers Reviewer Agent
  - **Blocks**: Sets `idad:implementing`, Implementer fixes issues

**Timeline**: 30-60 seconds

**You'll See**:
- Security scan results in PR comment
- Label changes based on scan results

**Next Step**:
- If pass: Automatically triggers Reviewer Agent
- If blocked: Re-triggers Implementer Agent

---

### Step 6: Reviewer Agent

**Purpose**: Perform code review

**Actions**:
- Analyzes PR changes
- Checks code quality
- Validates requirements coverage
- Reviews test adequacy
- Verifies error handling
- Either:
  - **Approves**: Posts approval, sets `idad:documenting`
  - **Requests Changes**: Posts detailed feedback, sets `idad:implementing`

**Timeline**: 30-90 seconds

**Review Criteria**:
- Code quality and structure
- Requirements coverage
- Test adequacy
- Error handling
- Documentation needs
- Best practices

**Git Identity** (if small fixes made):
```
Author: Reviewer Agent <reviewer@agents.local>
```

**You'll See**:
- PR review posted
- Detailed feedback in review comments
- Either:
  - ✅ Approval + `idad:documenting` label
  - 🔄 Changes requested + `idad:implementing` label

**Next Step**:
- If approved: Automatically triggers Documenter Agent
- If changes requested: Re-triggers Implementer Agent

---

### Step 7: Documenter Agent

**Purpose**: Update documentation and finalize PR

**Actions**:
- Analyzes PR changes
- Updates README.md with new features
- Updates API docs if needed
- Adds usage examples
- Cleans up temporary files
- Updates PR description
- Sets `idad:human-pr-review`
- **Does NOT trigger another agent** (end of automation)

**Timeline**: 30-90 seconds

**Git Identity**:
```
Author: Documenter Agent <documenter@agents.local>
```

**You'll See**:
- Documentation commit pushed to PR
- README.md updated
- PR description finalized
- `idad:human-pr-review` label
- Summary comment from agent

**Next Step**: **Human review and merge** (automation complete!)

---

### Step 8: Human Review & Merge

**Your Turn**: Review the completed work

**What to Check**:
- Code quality meets your standards
- Tests are comprehensive
- Documentation is accurate
- No security concerns
- Meets original requirements

**Actions**:
- Review the PR
- Test locally if desired
- Request changes if needed (agents will iterate)
- **Merge the PR** when satisfied

**Timeline**: Your decision

---

### Step 9: IDAD Agent (Post-Merge)

**Purpose**: Analyze for system improvements

**Triggers**: After PR merges to main

**Actions**:
- Analyzes merged changes
- Detects new technologies/frameworks
- Checks if IDAD system needs updates
- If improvements needed:
  - Creates improvement **issue** with `idad:issue-review`
  - Goes through full IDAD workflow
  - Requires human review at each gate

**Timeline**: 1-2 minutes

**You'll See** (if improvements proposed):
- New issue with IDAD improvement proposal
- Issue goes through normal workflow
- Requires your plan approval and PR review

**Loop Prevention**:
- Skips own PRs (branch starts with `idad/`)
- Uses branch naming to prevent infinite loops

---

## Agent Responsibilities

### Issue Review Agent
- **Trigger**: Issue labeled `idad:issue-review`
- **Input**: Raw issue description
- **Output**: Analysis, `idad:planning` (ready) or `idad:issue-needs-clarification` (unclear)
- **Duration**: 30-60s

### Planner Agent
- **Trigger**: Issue labeled `idad:planning` OR comment on `idad:human-plan-review` issue
- **Input**: Issue requirements OR human feedback on plan
- **Output**: Implementation plan, `idad:human-plan-review` (or `idad:implementing` after approval)
- **Duration**: 1-2 minutes

### Implementer Agent
- **Trigger**: Issue labeled `idad:implementing`
- **Input**: Implementation plan
- **Output**: PR with code and tests, `idad:security-scan` on PR
- **Duration**: 1-3 minutes

### Security Scanner
- **Trigger**: PR labeled `idad:security-scan`
- **Input**: PR code changes
- **Output**: `idad:code-review` (pass) or `idad:implementing` (block)
- **Duration**: 30-60s

### Reviewer Agent
- **Trigger**: PR labeled `idad:code-review`
- **Input**: PR code changes
- **Output**: `idad:documenting` (approved) or `idad:implementing` (changes)
- **Duration**: 30-90s

### Documenter Agent
- **Trigger**: PR labeled `idad:documenting`
- **Input**: PR changes
- **Output**: Updated docs, `idad:human-pr-review`
- **Duration**: 30-90s

### IDAD Agent
- **Trigger**: PR merged to main
- **Input**: Merged changes
- **Output**: Improvement issue with `idad:issue-review` (if needed)
- **Duration**: 1-2 minutes

---

## Label System

**Only ONE `idad:*` label per issue/PR at a time.** The label encapsulates the current workflow state.

### IDAD Labels (9 Total)

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

### Label State Transitions

```
[Issue Created]
      │
      │ (user adds idad:issue-review)
      ▼
idad:issue-review
      │
      │ (Issue Review Agent)
      ├─ Ready ────────────► idad:planning
      │
      └─ Unclear ──────────► idad:issue-needs-clarification
                                    │
                                    │ (human clarifies, re-triggers)
                                    └──► idad:issue-review
      │
      ▼
idad:planning
      │
      │ (Planner Agent creates plan)
      ▼
idad:human-plan-review ◄──────────────┐
      │                                │
      │ (Human reviews plan)           │ (changes requested)
      │                                │
      ├─ Approved ─────────────────────┤
      │                                │
      └─ Changes Requested ────────────┘
      │
      │ (Planner triggers Implementer)
      ▼
idad:implementing ◄────────────────────┐
      │                                 │
      │ (Implementer creates PR)        │
      ▼                                 │
idad:security-scan                      │
      │                                 │
      │ (Security Scanner)              │
      ├─ Pass ───► idad:code-review     │
      │                  │              │
      └─ Block ──────────┼──────────────┘
                         │
                         │ (Reviewer Agent)
                         ├─ Approved ──► idad:documenting
                         │                     │
                         └─ Changes ───────────┤
                                               │
                                ▼              │
                         idad:human-pr-review  │
                               │               │
                               │ (Human)       │
                               └─ Comment ─────┘
                               │
                               │ (Approved)
                               ▼
                         [Human Merge]
                               │
                               ▼
                         [IDAD Agent]
```

---

## Timeline Expectations

### Full Pipeline (Happy Path)
- **Total**: ~6-10 minutes + plan review time
- Issue Review: 30-60s
- Planner: 1-2 min
- **Plan Review: depends on you!** 👤
- Implementer: 1-3 min
- CI: < 1 min
- Reviewer: 30-90s
- Documenter: 30-90s

### With Changes Requested
- **Total**: +3-5 minutes per iteration
- Implementer fixes: 1-2 min
- CI: < 1 min
- Reviewer: 30-90s

### Variables Affecting Timeline
- **Complexity**: More complex features take longer
- **Test Suite**: Larger test suites take more time
- **Code Size**: More files = more processing
- **GitHub Actions Load**: Queue times may vary

---

## Common Patterns

### Pattern: Simple Feature Addition
1. Create issue with feature description
2. Add `idad:issue-review` label
3. Wait for plan, approve it
4. Wait ~6-10 minutes for implementation
5. Review and merge PR
6. Done!

**Best for**: Small, well-defined features

---

### Pattern: Bug Fix
1. Create issue with bug description
2. Include reproduction steps
3. Add `idad:issue-review` label
4. Agents will analyze, plan, fix, test, and document
5. Review and merge

**Best for**: Reproducible bugs

---

### Pattern: Epic (Large Feature)
1. Create parent issue describing the epic
2. Add `idad:issue-review` label
3. Planner creates sub-issues with `idad:planning` (well-defined)
4. Each sub-issue follows normal workflow
5. All sub-PRs merge independently

**Best for**: Large features that can be broken down

---

### Pattern: Iterative Refinement
1. Issue created (vague requirements)
2. Issue Review Agent asks clarifying questions
3. Issue gets `idad:issue-needs-clarification` label
4. Human answers questions in comments
5. Issue Review Agent re-analyzes
6. Workflow continues with `idad:planning`

**Best for**: Complex requirements needing discussion

---

### Pattern: Change Requests
1. Reviewer or Security Scanner requests changes
2. PR gets `idad:implementing` label
3. Implementer automatically re-triggered
4. New commits address feedback
5. Security Scanner and Reviewer re-review
6. Eventually approved

**Best for**: Code that needs iteration

---

### Pattern: Human PR Feedback
1. PR reaches `idad:human-pr-review` stage
2. Human reviews and comments with changes
3. Comment triggers Implementer Agent
4. PR cycles back through Security Scanner, Reviewer, Documenter
5. Returns to `idad:human-pr-review` for final approval

**Best for**: PRs needing final human-directed refinements

---

### Pattern: Manual Intervention
1. Any time: Remove current `idad:*` label to pause
2. Make manual changes to issue/PR
3. Add appropriate `idad:*` label back to resume
4. Or close issue to stop completely

**Best for**: Taking manual control when needed

---

### Pattern: Opt-Out
1. Create issue normally
2. **Don't add any `idad:*` label**
3. Work on it manually
4. No automation occurs

**Best for**: Exploratory work, experiments, sensitive changes

---

## Best Practices

### Writing Good Issues

✅ **Do**:
- Be specific about requirements
- Provide acceptance criteria
- Include examples where helpful
- Specify constraints or limitations
- Add `idad:issue-review` when ready for automation

❌ **Don't**:
- Be vague or ambiguous
- Skip acceptance criteria
- Assume implementation details
- Add `idad:issue-review` to sensitive/experimental work

### Monitoring Progress

**Check Issue**: The `idad:*` label shows current state
**Check Workflow Runs**: See agent execution in Actions tab
**Check Comments**: Agents post detailed logs
**Check PR**: See code as it's developed

### When to Intervene

**Pause Automation**: Remove the current `idad:*` label
**Stop Automation**: Remove all `idad:*` labels
**Manual Changes**: Remove label, make changes, add appropriate label back
**Close Issue**: Stops all automation

### Performance Tips

**Faster**: Simpler issues complete faster
**Slower**: Complex features, large test suites
**Optimize**: Break large features into smaller issues

---

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for detailed debugging guide.

**Quick Checks**:
- Issue has an `idad:*` label?
- Workflows running in Actions tab?
- Any error comments from agents?
- Check workflow logs for errors

---

## Next Steps

- **Agent Reference**: See [AGENTS.md](AGENTS.md) for detailed agent documentation
- **Operations Manual**: See [OPERATIONS.md](OPERATIONS.md) for repository management
- **Troubleshooting**: See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for problem solving

---

**Last Updated**: 2025-12-12
**Phase**: 11 - Unified Label System
