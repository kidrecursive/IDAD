# Repository Testing Agent

## Purpose

Perform post-installation verification to ensure IDAD is correctly configured and functioning in this repository.

## Context

You are the Repository Testing Agent. Users run you after installing IDAD to verify that:
1. All required files are present
2. GitHub configuration is correct (labels, permissions)
3. Secrets are configured
4. Workflows can be triggered
5. (Optional) End-to-end agent chain works

## How to Run This Agent

### Using Cursor Agent
```bash
cursor-agent -f .cursor/rules/system.mdc -f .cursor/agents/repository-testing.md -p "Run the IDAD repository tests"
```

### Using Claude Code
```bash
claude --system-prompt "$(cat .claude/rules/system.md)" -p "Run the IDAD repository tests. $(cat .claude/agents/repository-testing.md)"
```

---

## Test Procedures

### Test 1: File Structure Verification

Check that all required IDAD files are present.

```bash
echo "=== Test 1: File Structure ==="

# Detect which CLI is configured
if [ -d ".cursor/agents" ]; then
  CONFIG_DIR=".cursor"
  RULES_FILE="system.mdc"
  CLI_TYPE="cursor"
elif [ -d ".claude/agents" ]; then
  CONFIG_DIR=".claude"
  RULES_FILE="system.md"
  CLI_TYPE="claude"
else
  echo "❌ FAIL: No IDAD configuration found (.cursor/ or .claude/)"
  echo "   Run the installer first: curl -fsSL https://raw.githubusercontent.com/kidrecursive/idad-cursor/main/install.sh | bash"
  exit 1
fi

echo "✓ Detected CLI type: $CLI_TYPE"
echo "✓ Config directory: $CONFIG_DIR"

# Check agent files
REQUIRED_AGENTS="issue-review planner implementer security-scanner reviewer documenter idad reporting"
MISSING_AGENTS=""

for agent in $REQUIRED_AGENTS; do
  if [ ! -f "$CONFIG_DIR/agents/${agent}.md" ]; then
    MISSING_AGENTS="$MISSING_AGENTS $agent"
  fi
done

if [ -n "$MISSING_AGENTS" ]; then
  echo "❌ FAIL: Missing agent files:$MISSING_AGENTS"
  exit 1
fi
echo "✓ All 8 agent files present"

# Check rules file
if [ ! -f "$CONFIG_DIR/rules/$RULES_FILE" ]; then
  echo "❌ FAIL: Missing rules file: $CONFIG_DIR/rules/$RULES_FILE"
  exit 1
fi
echo "✓ Rules file present: $CONFIG_DIR/rules/$RULES_FILE"

# Check workflow files
if [ ! -f ".github/workflows/idad.yml" ]; then
  echo "❌ FAIL: Missing workflow: .github/workflows/idad.yml"
  exit 1
fi
echo "✓ IDAD workflow present"

if [ ! -f ".github/workflows/ci.yml" ]; then
  echo "⚠ WARN: Missing CI workflow: .github/workflows/ci.yml (optional)"
else
  echo "✓ CI workflow present"
fi

echo ""
echo "✅ Test 1 PASSED: File structure is correct"
```

### Test 2: Workflow Configuration

Verify the workflow file is correctly configured for the detected CLI.

```bash
echo ""
echo "=== Test 2: Workflow Configuration ==="

WORKFLOW=".github/workflows/idad.yml"

# Check workflow references correct paths
if [ "$CLI_TYPE" = "cursor" ]; then
  if ! grep -q '\.cursor/agents' "$WORKFLOW"; then
    echo "❌ FAIL: Workflow doesn't reference .cursor/agents"
    exit 1
  fi
  if ! grep -q '\.cursor/rules' "$WORKFLOW"; then
    echo "❌ FAIL: Workflow doesn't reference .cursor/rules"
    exit 1
  fi
  if ! grep -q 'CURSOR_API_KEY' "$WORKFLOW"; then
    echo "❌ FAIL: Workflow doesn't reference CURSOR_API_KEY"
    exit 1
  fi
  echo "✓ Workflow configured for Cursor"
else
  if ! grep -q '\.claude/agents' "$WORKFLOW"; then
    echo "❌ FAIL: Workflow doesn't reference .claude/agents"
    exit 1
  fi
  if ! grep -q '\.claude/rules' "$WORKFLOW"; then
    echo "❌ FAIL: Workflow doesn't reference .claude/rules"
    exit 1
  fi
  if ! grep -q 'ANTHROPIC_API_KEY' "$WORKFLOW"; then
    echo "❌ FAIL: Workflow doesn't reference ANTHROPIC_API_KEY"
    exit 1
  fi
  echo "✓ Workflow configured for Claude"
fi

# Check workflow has required triggers
if ! grep -q 'workflow_dispatch:' "$WORKFLOW"; then
  echo "❌ FAIL: Workflow missing workflow_dispatch trigger"
  exit 1
fi
echo "✓ Workflow has dispatch trigger"

if ! grep -q 'issues:' "$WORKFLOW"; then
  echo "❌ FAIL: Workflow missing issues trigger"
  exit 1
fi
echo "✓ Workflow has issues trigger"

echo ""
echo "✅ Test 2 PASSED: Workflow configuration is correct"
```

### Test 3: GitHub Labels

Verify required labels exist in the repository.

```bash
echo ""
echo "=== Test 3: GitHub Labels ==="

# Get repository
REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null)
if [ -z "$REPO" ]; then
  echo "❌ FAIL: Could not determine repository. Are you in a git repo with a remote?"
  exit 1
fi
echo "✓ Repository: $REPO"

# Check required labels
REQUIRED_LABELS="idad:auto type:issue type:bug state:issue-review state:ready state:planning state:implementing state:robot-review state:human-review needs-clarification needs-changes"
MISSING_LABELS=""

EXISTING_LABELS=$(gh label list --repo "$REPO" --json name -q '.[].name' 2>/dev/null)

for label in $REQUIRED_LABELS; do
  if ! echo "$EXISTING_LABELS" | grep -q "^${label}$"; then
    MISSING_LABELS="$MISSING_LABELS $label"
  fi
done

if [ -n "$MISSING_LABELS" ]; then
  echo "❌ FAIL: Missing labels:$MISSING_LABELS"
  echo ""
  echo "   To create missing labels, run the installer again or create manually:"
  echo "   gh label create \"idad:auto\" --color \"c5def5\" --description \"Enable IDAD automation\""
  exit 1
fi

LABEL_COUNT=$(echo "$EXISTING_LABELS" | grep -E "(idad:|type:|state:|needs-)" | wc -l)
echo "✓ Found $LABEL_COUNT IDAD labels"

echo ""
echo "✅ Test 3 PASSED: Required labels exist"
```

### Test 4: Repository Secrets

Check that required secrets are configured (without revealing values).

```bash
echo ""
echo "=== Test 4: Repository Secrets ==="

REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null)
SECRET_LIST=$(gh secret list --repo "$REPO" 2>/dev/null)

# Check GitHub App secrets
if ! echo "$SECRET_LIST" | grep -q "IDAD_APP_ID"; then
  echo "❌ FAIL: Missing secret: IDAD_APP_ID"
  echo "   Add with: gh secret set IDAD_APP_ID"
  exit 1
fi
echo "✓ IDAD_APP_ID is set"

if ! echo "$SECRET_LIST" | grep -q "IDAD_APP_PRIVATE_KEY"; then
  echo "❌ FAIL: Missing secret: IDAD_APP_PRIVATE_KEY"
  echo "   Add with: gh secret set IDAD_APP_PRIVATE_KEY < path/to/key.pem"
  exit 1
fi
echo "✓ IDAD_APP_PRIVATE_KEY is set"

# Check CLI-specific API key
if [ "$CLI_TYPE" = "cursor" ]; then
  if ! echo "$SECRET_LIST" | grep -q "CURSOR_API_KEY"; then
    echo "❌ FAIL: Missing secret: CURSOR_API_KEY"
    echo "   Add with: gh secret set CURSOR_API_KEY"
    exit 1
  fi
  echo "✓ CURSOR_API_KEY is set"
else
  if ! echo "$SECRET_LIST" | grep -q "ANTHROPIC_API_KEY"; then
    echo "❌ FAIL: Missing secret: ANTHROPIC_API_KEY"
    echo "   Add with: gh secret set ANTHROPIC_API_KEY"
    exit 1
  fi
  echo "✓ ANTHROPIC_API_KEY is set"
fi

echo ""
echo "✅ Test 4 PASSED: Required secrets are configured"
```

### Test 5: GitHub Actions Permissions

Verify repository has correct Actions permissions.

```bash
echo ""
echo "=== Test 5: Actions Permissions ==="

REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null)

# Check workflow permissions (requires admin access)
PERMS=$(gh api "repos/$REPO/actions/permissions/workflow" 2>/dev/null || echo "")

if [ -z "$PERMS" ]; then
  echo "⚠ WARN: Could not check workflow permissions (may need admin access)"
  echo "   Manually verify: Settings → Actions → General → Workflow permissions"
  echo "   Should be: Read and write permissions"
else
  DEFAULT_PERMS=$(echo "$PERMS" | jq -r '.default_workflow_permissions' 2>/dev/null)
  CAN_APPROVE=$(echo "$PERMS" | jq -r '.can_approve_pull_request_reviews' 2>/dev/null)
  
  if [ "$DEFAULT_PERMS" != "write" ]; then
    echo "⚠ WARN: Workflow permissions are '$DEFAULT_PERMS', should be 'write'"
    echo "   Fix: Settings → Actions → General → Workflow permissions → Read and write"
  else
    echo "✓ Workflow permissions: write"
  fi
  
  if [ "$CAN_APPROVE" != "true" ]; then
    echo "⚠ WARN: Workflows cannot approve PRs"
    echo "   Fix: Settings → Actions → General → Allow GitHub Actions to approve PRs"
  else
    echo "✓ Workflows can approve PRs"
  fi
fi

echo ""
echo "✅ Test 5 PASSED: Actions permissions checked"
```

### Test 6: Workflow Trigger Test (Optional)

Actually trigger a workflow to verify it runs. **This creates real workflow runs.**

```bash
echo ""
echo "=== Test 6: Workflow Trigger Test ==="
echo "⚠ This test will trigger a real workflow run."
echo ""

read -p "Run trigger test? (y/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "Skipped trigger test"
else
  REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null)
  
  # Trigger the reporting agent (least disruptive - just creates a report)
  echo "Triggering reporting agent..."
  gh workflow run idad.yml --repo "$REPO" -f agent="reporting" -f issue="" -f pr=""
  
  if [ $? -eq 0 ]; then
    echo "✓ Workflow triggered successfully"
    echo ""
    echo "Check status with: gh run list --workflow=idad.yml --limit 3"
    
    # Wait a moment and check
    sleep 3
    echo ""
    echo "Recent workflow runs:"
    gh run list --workflow=idad.yml --repo "$REPO" --limit 3
  else
    echo "❌ FAIL: Could not trigger workflow"
    echo "   Check that the workflow file exists and has workflow_dispatch enabled"
    exit 1
  fi
fi

echo ""
echo "✅ Test 6 PASSED: Workflow trigger test"
```

### Test 7: Full End-to-End Pipeline Test

This comprehensive test creates a real issue and monitors the entire IDAD agent chain from start to finish. It includes human gates where you'll need to take action.

**⚠️ This test will:**
- Create a real issue with `idad:auto` label
- Trigger all agents in sequence
- Create a real branch and PR
- Require your approval at certain gates

## Your Responsibilities

When prompted by this test, you are acting as the agent. You should:

1. **Run the test setup commands** provided below
2. **Monitor workflow runs** using the `gh` CLI
3. **Wait for each agent** to complete before proceeding
4. **Take action at human gates** (approve PR, merge PR)
5. **Verify expected outcomes** at each step
6. **Clean up** the test issue and PR when done

---

## Step-by-Step End-to-End Test

### Step 1: Create Test Issue

First, create the test issue that will trigger the IDAD pipeline:

```bash
# Get repo info
REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner')
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
echo "Repository: $REPO"
echo "Test ID: $TIMESTAMP"

# Create the test issue
ISSUE_NUM=$(gh issue create \
  --title "IDAD E2E Test: Add test greeting function ($TIMESTAMP)" \
  --label "idad:auto" \
  --body "## Description

This is an automated end-to-end test of the IDAD pipeline.

**Test ID**: $TIMESTAMP

## Requirements

Create a simple greeting function:
- Create a file \`src/greeting.js\` (or appropriate for this repo)
- Function \`greet(name)\` that returns \`Hello, {name}!\`
- Handle edge case: if name is empty, return \`Hello, World!\`
- Add unit tests in \`tests/greeting.test.js\`

## Acceptance Criteria

- [ ] Function is exported
- [ ] Returns correct greeting
- [ ] Handles empty name
- [ ] Unit tests pass

---
*IDAD E2E Test - Created by repository-testing agent*" \
  --json number -q '.number')

echo ""
echo "✅ Created test issue #$ISSUE_NUM"
echo "   View: gh issue view $ISSUE_NUM"
echo ""
```

### Step 2: Monitor Issue Review Agent

The Issue Review agent should trigger automatically. Monitor its progress:

```bash
echo "=== Step 2: Issue Review Agent ==="
echo "Waiting for Issue Review workflow to start..."
sleep 5

# Check for running/recent workflows
gh run list --workflow=idad.yml --limit 5

# Wait for it to complete (poll every 30 seconds)
echo ""
echo "Monitoring workflow... (Ctrl+C to stop watching)"
echo "Run this to watch: gh run watch \$(gh run list --workflow=idad.yml --limit 1 --json databaseId -q '.[0].databaseId')"
```

**Expected outcome:**
- Issue gets `type:issue` label added
- Issue gets `state:ready` label
- Comment from Issue Review agent with analysis
- Planner agent triggered automatically

**Verify:**
```bash
# Check issue labels
gh issue view $ISSUE_NUM --json labels -q '.labels[].name'

# Check for agent comment
gh issue view $ISSUE_NUM --comments | tail -50
```

### Step 3: Monitor Planner Agent

The Planner should run automatically after Issue Review:

```bash
echo "=== Step 3: Planner Agent ==="
echo "Waiting for Planner workflow..."

gh run list --workflow=idad.yml --limit 5
```

**Expected outcome:**
- Issue gets `state:planning` label (briefly)
- Implementation plan comment added to issue
- Feature branch created: `feat/issue-{NUM}-*`
- Implementer agent triggered

**Verify:**
```bash
# Check for implementation plan in comments
gh issue view $ISSUE_NUM --comments | grep -A 50 "Implementation Plan"

# Check for branch
git fetch origin
git branch -r | grep "feat/issue-$ISSUE_NUM"
```

### Step 4: Monitor Implementer Agent

The Implementer creates the actual code and PR:

```bash
echo "=== Step 4: Implementer Agent ==="
echo "Waiting for Implementer workflow..."

gh run list --workflow=idad.yml --limit 5

# This may take several minutes as it writes code and tests
```

**Expected outcome:**
- Code files created on feature branch
- Tests written
- PR created with implementation details
- `state:implementing` label on issue (briefly)
- Security Scanner triggered

**Verify:**
```bash
# Check for PR
PR_NUM=$(gh pr list --head "feat/issue-$ISSUE_NUM" --json number -q '.[0].number')
echo "PR created: #$PR_NUM"

# View PR
gh pr view $PR_NUM
```

### Step 5: Monitor Security Scanner

Security Scanner checks the PR for vulnerabilities:

```bash
echo "=== Step 5: Security Scanner ==="
echo "Waiting for Security Scanner workflow..."

gh run list --workflow=idad.yml --limit 5
```

**Expected outcome:**
- Security analysis comment on PR
- No critical vulnerabilities (for this simple test)
- CI triggered (runs automatically on PR)

**Verify:**
```bash
# Check PR comments for security scan
gh pr view $PR_NUM --comments | grep -A 20 "Security"
```

### Step 6: Wait for CI

CI runs automatically when PR is created:

```bash
echo "=== Step 6: CI ==="
echo "Waiting for CI workflow..."

# Watch CI status
gh pr checks $PR_NUM --watch
```

**Expected outcome:**
- CI workflow runs
- Tests pass (if Implementer wrote correct tests)
- Reviewer agent triggered after CI passes

### Step 7: Monitor Reviewer Agent

Reviewer performs code review:

```bash
echo "=== Step 7: Reviewer Agent ==="
echo "Waiting for Reviewer workflow..."

gh run list --workflow=idad.yml --limit 5
```

**Expected outcome:**
- Code review comment on PR
- PR approved OR changes requested
- If approved: Documenter triggered
- If changes requested: Issue gets `needs-changes` label

**Verify:**
```bash
# Check PR reviews
gh pr view $PR_NUM --json reviews -q '.reviews[].state'

# Check PR comments
gh pr view $PR_NUM --comments | tail -50
```

### Step 8: Monitor Documenter Agent

Documenter updates documentation if needed:

```bash
echo "=== Step 8: Documenter Agent ==="
echo "Waiting for Documenter workflow..."

gh run list --workflow=idad.yml --limit 5
```

**Expected outcome:**
- Documentation review/updates
- PR gets `state:human-review` label
- Comment indicating ready for human review

**Verify:**
```bash
# Check labels
gh pr view $PR_NUM --json labels -q '.labels[].name'

# Should include state:human-review
```

### Step 9: Human Gate - Review and Merge

**🛑 HUMAN ACTION REQUIRED**

At this point, you need to:

1. **Review the PR** - Verify the code looks correct:
   ```bash
   # View PR diff
   gh pr diff $PR_NUM
   
   # View files changed
   gh pr view $PR_NUM --json files -q '.files[].path'
   ```

2. **Approve if not already approved** (Reviewer should have done this):
   ```bash
   gh pr review $PR_NUM --approve --body "LGTM - E2E test verification"
   ```

3. **Merge the PR**:
   ```bash
   gh pr merge $PR_NUM --squash --delete-branch
   ```

### Step 10: Monitor IDAD Self-Improvement Agent (Optional)

After merge, the IDAD agent may run to analyze the completed work:

```bash
echo "=== Step 10: IDAD Agent (Post-Merge) ==="
echo "Watching for IDAD self-improvement workflow..."

# This triggers on PR merge with idad:auto label
gh run list --workflow=idad.yml --limit 5
```

### Step 11: Verify Completion & Clean Up

**Verify the test completed successfully:**

```bash
echo "=== Final Verification ==="

# Issue should be closed (auto-closed by PR merge)
gh issue view $ISSUE_NUM --json state -q '.state'
# Expected: CLOSED

# Check all workflows completed
gh run list --workflow=idad.yml --limit 10

# Verify the code was merged
git pull origin main
ls -la src/greeting.js 2>/dev/null || echo "File location may vary"
```

**Clean up test artifacts (optional):**

```bash
# Delete the test file if you don't want to keep it
git rm src/greeting.js tests/greeting.test.js 2>/dev/null
git commit -m "chore: remove E2E test files"
git push

# Or keep them as proof the test worked!
```

---

## End-to-End Test Summary

After completing all steps, you should have verified:

| Step | Agent | Expected Outcome |
|------|-------|------------------|
| 1 | - | Test issue created |
| 2 | Issue Review | Issue classified, labels added |
| 3 | Planner | Implementation plan created |
| 4 | Implementer | Code written, PR created |
| 5 | Security Scanner | Security analysis complete |
| 6 | CI | Tests pass |
| 7 | Reviewer | Code review complete |
| 8 | Documenter | Docs updated, ready for human |
| 9 | **Human** | PR approved and merged |
| 10 | IDAD | Self-improvement analysis |
| 11 | - | Issue closed, code merged |

**Report results:**

```markdown
### 🧪 End-to-End Test Results

**Repository**: $REPO
**Test ID**: $TIMESTAMP  
**Issue**: #$ISSUE_NUM
**PR**: #$PR_NUM

| Agent | Status | Duration |
|-------|--------|----------|
| Issue Review | ✅ | ~2 min |
| Planner | ✅ | ~3 min |
| Implementer | ✅ | ~5 min |
| Security Scanner | ✅ | ~2 min |
| CI | ✅ | ~1 min |
| Reviewer | ✅ | ~2 min |
| Documenter | ✅ | ~2 min |
| Human Review | ✅ | manual |
| IDAD | ✅ | ~2 min |

**Total Pipeline Time**: ~20 minutes + human review

**Result**: ✅ IDAD is fully operational!

---
```agentlog
agent: repository-testing
test: end-to-end
status: success
issue: $ISSUE_NUM
pr: $PR_NUM
agents_verified: 8
timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)
```
```

---

## Troubleshooting E2E Test

### Workflow doesn't trigger

```bash
# Check issue has correct label
gh issue view $ISSUE_NUM --json labels

# Manually trigger if needed
gh workflow run idad.yml -f agent="issue-review" -f issue="$ISSUE_NUM"
```

### Agent fails

```bash
# Get the failed run ID
RUN_ID=$(gh run list --workflow=idad.yml --status failure --limit 1 --json databaseId -q '.[0].databaseId')

# View logs
gh run view $RUN_ID --log-failed
```

### PR not created

```bash
# Check Implementer logs
gh run list --workflow=idad.yml --limit 10

# Look for branch
git fetch origin
git branch -r | grep issue-$ISSUE_NUM

# Manually trigger Implementer if needed
gh workflow run idad.yml -f agent="implementer" -f issue="$ISSUE_NUM"
```

### CI fails

```bash
# View CI logs
gh pr checks $PR_NUM

# The Implementer may have written incorrect code
# Check the diff and potentially fix manually or re-trigger
```

---

## Running All Tests

Execute all verification tests (excluding optional ones):

```bash
#!/bin/bash
set -e

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║           IDAD Repository Verification Tests                   ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Run Tests 1-5 (non-destructive)
# Test 1: File Structure
# Test 2: Workflow Configuration  
# Test 3: GitHub Labels
# Test 4: Repository Secrets
# Test 5: Actions Permissions

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "                    All Tests Complete                          "
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Summary:"
echo "  ✅ File structure verified"
echo "  ✅ Workflow configuration verified"
echo "  ✅ Labels verified"
echo "  ✅ Secrets verified"
echo "  ✅ Permissions checked"
echo ""
echo "Optional tests (run manually):"
echo "  - Test 6: Workflow trigger test"
echo "  - Test 7: End-to-end test"
echo ""
echo "Your IDAD installation is ready to use!"
echo ""
echo "Next steps:"
echo "  1. Create an issue with 'idad:auto' label"
echo "  2. Watch agents process it: gh run list --workflow=idad.yml"
```

---

## Test Results Format

When you run these tests, report results in this format:

```markdown
### 🧪 Repository Verification Results

**Repository**: owner/repo
**CLI Type**: cursor | claude
**Timestamp**: YYYY-MM-DD HH:MM:SS

| Test | Status | Details |
|------|--------|---------|
| File Structure | ✅ PASS | 8 agents, rules, workflows |
| Workflow Config | ✅ PASS | Correct paths and secrets |
| GitHub Labels | ✅ PASS | 16 labels found |
| Secrets | ✅ PASS | All 3 secrets configured |
| Permissions | ✅ PASS | Write access enabled |
| Trigger Test | ⏭ SKIP | Optional |
| E2E Test | ⏭ SKIP | Optional |

**Overall**: ✅ READY

---
```agentlog
agent: repository-testing
status: success
tests_passed: 5
tests_skipped: 2
cli_type: cursor
timestamp: 2025-12-11T12:00:00Z
```
```

---

## Troubleshooting

### "No IDAD configuration found"

Run the installer:
```bash
curl -fsSL https://raw.githubusercontent.com/kidrecursive/idad-cursor/main/install.sh | bash
```

### "Missing secret: X"

Add the missing secret:
```bash
gh secret set IDAD_APP_ID
gh secret set IDAD_APP_PRIVATE_KEY < path/to/key.pem
gh secret set CURSOR_API_KEY  # or ANTHROPIC_API_KEY
```

### "Missing labels"

Re-run the installer (it creates labels), or create manually:
```bash
gh label create "idad:auto" --color "c5def5" --description "Enable IDAD automation"
```

### "Could not trigger workflow"

1. Check workflow file exists: `ls .github/workflows/idad.yml`
2. Check it has `workflow_dispatch:` trigger
3. Check you have write access to the repo
4. Check GitHub Actions is enabled for the repo

---

## Remember

This agent helps users verify their IDAD installation is complete and working. Run all non-destructive tests (1-5) first. Only run tests 6-7 if you want to actually trigger workflows and create issues.

After successful verification, users can confidently create issues with the `idad:auto` label knowing the agent chain will work.
