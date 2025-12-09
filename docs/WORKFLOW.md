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
- **Automation is opt-in** via the `idad:auto` label

### Architecture

```
┌─────────────┐
│   GitHub    │
│   Issue     │◄─── User creates issue
│ + idad:auto │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────────────────────────────┐
│              IDAD Automation Pipeline                        │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  1. Issue Review Agent ──► Refines & Classifies              │
│                             Adds type label                   │
│                             Sets state:ready                  │
│                                                               │
│  2. Planner Agent ────────► Creates Implementation Plan      │
│                             Adds to issue body                │
│                             Sets state:implementing           │
│                                                               │
│  3. Implementer Agent ───► Writes Code & Tests               │
│                             Creates PR                        │
│                             Pushes commits                    │
│                                                               │
│  4. CI Workflow ──────────► Runs Tests                       │
│                             Validates Build                   │
│                                                               │
│  5. Reviewer Agent ───────► Code Review                      │
│                             Approves or Requests Changes      │
│                             Sets state:robot-docs             │
│                                                               │
│  6. Documenter Agent ─────► Updates Documentation            │
│                             Finalizes PR                      │
│                             Sets state:human-review           │
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
- Add `idad:auto` label (opt-in to automation)
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
- Dispatcher workflow detects `idad:auto` label
- Triggers Issue Review Agent

**Timeline**: Instant

---

### Step 2: Issue Review Agent

**Purpose**: Refine and classify the issue

**Actions**:
- Reads issue description
- May ask clarifying questions (adds `needs-clarification`)
- Classifies issue type (adds `type:feature`, `type:bug`, etc.)
- Ensures requirements are clear
- Posts refined issue content
- Sets `state:ready`

**Timeline**: 30-60 seconds

**You'll See**:
- Agent comment with clarifications or confirmations
- `type:*` label added
- `state:ready` label added
- Machine-readable `agentlog` block

**Next Step**: Automatically triggers Planner Agent

---

### Step 3: Planner Agent

**Purpose**: Create implementation plan

**Actions**:
- Analyzes issue requirements
- Creates step-by-step implementation plan
- Determines appropriate branch name
- Updates issue body with plan
- Sets `state:implementing`

**Timeline**: 1-2 minutes

**You'll See**:
- Implementation plan added to issue body
- Task breakdown with subtasks
- Branch name specified
- `state:implementing` label

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

**Next Step**: Automatically triggers Implementer Agent

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
- `idad:auto` label on PR

**Next Step**: PR creation triggers CI workflow

---

### Step 5: CI Workflow

**Purpose**: Run tests and validate build

**Actions**:
- Runs on PR open/update
- Executes test suite
- Reports results in PR comments
- On success: Triggers Reviewer Agent
- On failure: Triggers Implementer Agent (to fix)

**Timeline**: < 1 minute (depends on tests)

**You'll See**:
- CI status check on PR
- Comment with test results
- Green check (pass) or red X (fail)

**Next Step**: 
- If pass: Automatically triggers Reviewer Agent
- If fail: Re-triggers Implementer Agent

---

### Step 6: Reviewer Agent

**Purpose**: Perform code review

**Actions**:
- Analyzes PR changes
- Checks code quality
- Validates requirements coverage
- Reviews test adequacy
- Checks for security issues
- Either:
  - **Approves**: Posts approval, sets `state:robot-docs`
  - **Requests Changes**: Posts detailed feedback, adds `needs-changes`

**Timeline**: 30-90 seconds

**Review Criteria**:
- Code quality and structure
- Requirements coverage
- Test adequacy
- Security and error handling
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
  - ✅ Approval + `state:robot-docs` label
  - 🔄 Changes requested + `needs-changes` label

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
- Sets `state:human-review`
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
- `state:human-review` label
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
  - Creates improvement PR
  - Labels: `type:infrastructure` (NOT `idad:auto`)
  - Requires human review

**Timeline**: 1-2 minutes

**You'll See** (if improvements proposed):
- New PR with IDAD improvements
- CI workflow updates
- Agent definition updates
- Requires your review and approval

**Loop Prevention**:
- Skips own PRs (branch starts with `idad/`)
- Skips infrastructure PRs (`type:infrastructure`)
- Never adds `idad:auto` to improvement PRs

---

## Agent Responsibilities

### Issue Review Agent
- **Trigger**: Issue created with `idad:auto`
- **Input**: Raw issue description
- **Output**: Refined issue, type label, state:ready
- **Duration**: 30-60s

### Planner Agent  
- **Trigger**: Issue marked `state:ready`
- **Input**: Refined issue requirements
- **Output**: Implementation plan, state:implementing
- **Duration**: 1-2 minutes

### Implementer Agent
- **Trigger**: Issue marked `state:implementing`
- **Input**: Implementation plan
- **Output**: PR with code and tests
- **Duration**: 1-3 minutes

### Reviewer Agent
- **Trigger**: CI passes on PR
- **Input**: PR code changes
- **Output**: Approval or change requests
- **Duration**: 30-90s

### Documenter Agent
- **Trigger**: PR approved (state:robot-docs)
- **Input**: PR changes
- **Output**: Updated docs, state:human-review
- **Duration**: 30-90s

### IDAD Agent
- **Trigger**: PR merged to main
- **Input**: Merged changes
- **Output**: Improvement PR (if needed)
- **Duration**: 1-2 minutes

---

## Label System

### Type Labels (Classification)
- `type:feature` - New feature
- `type:bug` - Bug fix
- `type:documentation` - Docs only
- `type:epic` - Large feature with sub-issues
- `type:question` - Question or discussion
- `type:infrastructure` - IDAD system changes

### State Labels (Workflow Progress)
- `state:issue-review` - Under issue review
- `state:ready` - Ready for planning
- `state:planning` - Being planned
- `state:implementing` - Being implemented
- `state:robot-review` - Under code review
- `state:robot-docs` - Documentation in progress
- `state:human-review` - Ready for human review

### Control Labels
- `idad:auto` - **Enable automation** (opt-in required)
- `needs-clarification` - Human input needed (pauses automation)
- `needs-changes` - Changes requested by reviewer

### Label State Transitions

```
[Issue Created]
      │
      │ (idad:auto added)
      ▼
 state:issue-review
      │
      │ (Issue Review Agent)
      ▼
  state:ready
      │
      │ (Planner Agent)
      ▼
 state:planning
      │
      ▼
state:implementing
      │
      │ (Implementer Agent creates PR)
      ▼
state:robot-review
      │
      │ (Reviewer Agent)
      ├─ Approved ──────► state:robot-docs
      │                         │
      │                         │ (Documenter Agent)
      │                         ▼
      │                   state:human-review ──► [Human Merge]
      │
      └─ Changes Requested ──► needs-changes
                                    │
                                    │ (back to Implementer)
                                    └─► state:implementing
```

---

## Timeline Expectations

### Full Pipeline (Happy Path)
- **Total**: ~6-10 minutes
- Issue Review: 30-60s
- Planner: 1-2 min
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
2. Add `idad:auto` label
3. Wait ~6-10 minutes
4. Review and merge PR
5. Done!

**Best for**: Small, well-defined features

---

### Pattern: Bug Fix
1. Create issue with bug description
2. Include reproduction steps
3. Add `idad:auto` and `type:bug` labels
4. Agents will fix, test, and document
5. Review and merge

**Best for**: Reproducible bugs

---

### Pattern: Epic (Large Feature)
1. Create parent issue with `type:epic`
2. Add `idad:auto` label
3. Planner creates sub-issues
4. Each sub-issue follows normal workflow
5. All sub-PRs merge independently

**Best for**: Large features that can be broken down

---

### Pattern: Iterative Refinement
1. Issue created (vague requirements)
2. Issue Review Agent asks clarifying questions
3. Issue gets `needs-clarification` label
4. Human answers questions in comments
5. Remove `needs-clarification` when ready
6. Workflow continues

**Best for**: Complex requirements needing discussion

---

### Pattern: Change Requests
1. Reviewer requests changes
2. PR gets `needs-changes` label
3. Implementer automatically re-triggered
4. New commits address feedback
5. Reviewer re-reviews
6. Eventually approved

**Best for**: Code that needs iteration

---

### Pattern: Manual Intervention
1. Any time: Remove `idad:auto` to pause
2. Make manual changes to issue/PR
3. Add `idad:auto` back to resume
4. Or close issue to stop completely

**Best for**: Taking manual control when needed

---

### Pattern: Opt-Out
1. Create issue normally
2. **Don't add `idad:auto` label**
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
- Add `idad:auto` when ready for automation

❌ **Don't**:
- Be vague or ambiguous
- Skip acceptance criteria
- Assume implementation details
- Add `idad:auto` to sensitive/experimental work

### Monitoring Progress

**Check Issue**: Labels show current state
**Check Workflow Runs**: See agent execution in Actions tab
**Check Comments**: Agents post detailed logs
**Check PR**: See code as it's developed

### When to Intervene

**Pause Automation**: Add `needs-clarification` label
**Stop Automation**: Remove `idad:auto` label
**Manual Changes**: Pause automation, make changes, resume
**Close Issue**: Stops all automation

### Performance Tips

**Faster**: Simpler issues complete faster
**Slower**: Complex features, large test suites
**Optimize**: Break large features into smaller issues

---

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for detailed debugging guide.

**Quick Checks**:
- Issue has `idad:auto` label?
- Workflows running in Actions tab?
- Any error comments from agents?
- Check workflow logs for errors

---

## Next Steps

- **Agent Reference**: See [AGENTS.md](AGENTS.md) for detailed agent documentation
- **Operations Manual**: See [OPERATIONS.md](OPERATIONS.md) for repository management
- **Troubleshooting**: See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for problem solving

---

**Last Updated**: 2025-12-09  
**Phase**: 10 - Full Workflow Integration
