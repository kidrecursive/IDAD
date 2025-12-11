# IDAD System Testing Plan

Full end-to-end test of the IDAD agent chain in this repository.

## Test Phases

1. **Agent Chain Test** - Create issue → agents process → PR ready for review
2. **Human Review & Merge** - Review and merge the test PR
3. **IDAD Agent Test** - Verify IDAD agent analyzes and proposes improvements
4. **Reporting Agent Test** - Manually trigger reporting agent
5. **Cleanup** - Remove test files

---

## Prerequisites

### 1. Secrets Configured

```bash
# Verify secrets exist
gh secret list
```

Expected:
- `IDAD_APP_ID` - GitHub App ID
- `IDAD_APP_PRIVATE_KEY` - GitHub App private key
- `CURSOR_API_KEY` - Cursor API key

### 2. Repository Setup Complete

Ensure IDAD is installed. If not, run:

```bash
curl -fsSL https://raw.githubusercontent.com/kidrecursive/idad/main/install.sh | bash
```

### 3. Workflow Files Committed

Ensure all changes are committed and pushed to the `main` branch.

---

## Test Scenario

**Feature Request**: Create a simple calculator module with basic arithmetic operations.

This tests:
- Issue Review Agent (classification)
- Planner Agent (implementation plan)
- Implementer Agent (code generation, YAML validation)
- Security Scanner (vulnerability check, triggers Reviewer)
- Reviewer Agent (code review)
- Documenter Agent (documentation update)
- IDAD Agent (system evolution)
- Reporting Agent (metrics generation)

---

## Phase 1: Agent Chain Test

### Step 1: Create Test Issue

```bash
gh issue create \
  --title "Add calculator module with basic arithmetic" \
  --label "idad:auto" \
  --body "## Description

Create a simple calculator module that provides basic arithmetic operations.

## Requirements

- Add function in \`src/calculator.py\`
- Support: add, subtract, multiply, divide
- Handle division by zero gracefully
- Include unit tests in \`tests/test_calculator.py\`

## Acceptance Criteria

- [ ] All four operations work correctly
- [ ] Division by zero raises appropriate error
- [ ] 100% test coverage for calculator module"
```

Record the issue number: `#___`

### Step 2: Monitor Agent Chain

```bash
# Watch workflow runs
gh run list --workflow=idad.yml --limit 10

# View specific run logs
gh run view <run-id> --log
```

### Step 3: Verification Checkpoints

#### ✅ Issue Review Agent
- [ ] Issue has `type:*` label added
- [ ] Issue has `state:ready` label
- [ ] Comment posted with classification summary

#### ✅ Planner Agent
- [ ] Comment posted with implementation plan
- [ ] Plan includes file changes
- [ ] `state:planning` → `state:implementing` transition

#### ✅ Implementer Agent
- [ ] PR created linking to issue
- [ ] Branch created: `feat/issue-<number>-*`
- [ ] Files created with proper structure
- [ ] YAML/JSON files validated before commit
- [ ] Commit has proper trailers

#### ✅ Security Scanner
- [ ] Security scan comment posted
- [ ] No critical/high vulnerabilities (PASS expected)
- [ ] **Directly triggers Reviewer agent** (not relying on CI)

#### ✅ Reviewer Agent
- [ ] Code review comment posted
- [ ] PR approved (or changes requested)
- [ ] `state:robot-review` → `state:robot-docs` transition

#### ✅ Documenter Agent
- [ ] Documentation updated (if applicable)
- [ ] `state:human-review` label added
- [ ] Final summary comment posted

---

## Phase 2: Human Review & Merge

### Step 4: Review the PR

```bash
gh pr view <pr-number>
gh pr diff <pr-number>
```

### Step 5: Merge the PR

```bash
# Merge the PR (triggers IDAD agent)
gh pr merge <pr-number> --squash --delete-branch
```

**Note**: Ensure the PR has `idad:auto` label before merging for IDAD agent to trigger.

---

## Phase 3: IDAD Agent Test

The IDAD agent should automatically trigger after PR merge.

### Step 6: Monitor IDAD Agent

```bash
gh run list --workflow=idad.yml --limit 5
```

#### ✅ IDAD Agent Verification
- [ ] Workflow triggered after merge
- [ ] Analysis comment posted on merged PR
- [ ] If improvements found: PR created on `idad/*` branch
- [ ] Agent file evolution considered (if project patterns detected)

**Expected behavior**: IDAD should analyze the merged code and consider:
- Updating agent definitions with project-specific patterns (e.g., Python conventions)
- Adding directory structure guidelines to implementer
- Updating CI if new languages detected

---

## Phase 4: Reporting Agent Test

### Step 7: Trigger Reporting Agent

```bash
gh workflow run idad.yml -f agent="reporting" -f issue="<issue-number>"
```

#### ✅ Reporting Agent Verification
- [ ] Workflow ran successfully
- [ ] Report issue created with metrics
- [ ] Agent activity summarized

---

## Phase 5: Cleanup

### Step 8: Remove Test Files

```bash
rm -rf src/
rm -rf tests/
rm -f pytest.ini requirements.txt
git add -A
git commit -m "chore: remove test artifacts"
git push
```

### Step 9: Close Test Issues

```bash
gh issue close <issue-number> --reason "completed"
gh issue close <report-issue-number> --reason "completed"
```

---

## Troubleshooting

### Agent Didn't Trigger

```bash
# Check if workflow ran
gh run list --workflow=idad.yml --limit 5

# Manually trigger next agent
gh workflow run idad.yml -f agent="<agent-name>" -f issue="<num>" -f pr="<num>"
```

### Common Issues

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| Workflow skipped | Missing `idad:auto` label | Add label to issue/PR |
| "Agent file not found" | Missing `.cursor/agents/*.md` | Verify files exist |
| "Rules file not found" | Missing `.cursor/rules/system.mdc` | Create rules file |
| YAML validation failed | Malformed workflow file | Check indentation, syntax |
| IDAD didn't trigger on merge | PR missing `idad:auto` label | Add label before merging |
| Security Scanner didn't trigger Reviewer | Agent chain broken | Check security-scanner.md |

---

## Test Log

| Phase | Step | Status | Notes | Timestamp |
|-------|------|--------|-------|-----------|
| **1** | Issue created | ⬜ | Issue #___ | |
| | Issue Review ran | ⬜ | | |
| | Planner ran | ⬜ | | |
| | Implementer ran | ⬜ | | |
| | PR created | ⬜ | PR #___ | |
| | Security Scanner ran | ⬜ | | |
| | Reviewer ran | ⬜ | | |
| | Documenter ran | ⬜ | | |
| | Ready for human review | ⬜ | | |
| **2** | Human review complete | ⬜ | | |
| | PR merged | ⬜ | | |
| **3** | IDAD agent triggered | ⬜ | | |
| | IDAD analysis complete | ⬜ | | |
| **4** | Reporting agent triggered | ⬜ | | |
| | Report generated | ⬜ | | |
| **5** | Test files removed | ⬜ | | |
| | Issues closed | ⬜ | | |

---

## Recent Fixes Applied

Track fixes made during testing iterations:

| Issue | Fix | File(s) |
|-------|-----|---------|
| Security Scanner relied on CI | Now triggers Reviewer directly | `security-scanner.md` |
| IDAD didn't evolve agent files | Added agent evolution logic | `idad.md` |
| No YAML validation | Added validation step | `implementer.md` |
| `edited` trigger caused duplicates | Removed from workflow | `idad.yml` |

---

## Notes

_Record observations during test execution:_

```
[Add notes here]
```
