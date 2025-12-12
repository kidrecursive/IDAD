# IDAD Testing Guide

This document outlines the testing strategy for IDAD, including automated CI tests and manual verification procedures.

---

## Testing Strategy

### Overview

IDAD testing is split into three levels:

1. **Static Analysis** - Validate YAML, markdown, shell scripts
2. **Installation Tests** - Verify installer works for both CLIs
3. **Integration Tests** - Verify agents actually run and produce expected results

### Test Matrix

| Test Type | Cursor CLI | Claude CLI | Automated |
|-----------|------------|------------|-----------|
| YAML validation | ✅ | ✅ | ✅ |
| Shell lint | ✅ | ✅ | ✅ |
| Install (dry-run) | ✅ | ✅ | ✅ |
| Install (real repo) | ✅ | ✅ | ✅ |
| Agent execution | ✅ | ✅ | Manual* |

*Agent execution requires API keys and GitHub App, best tested manually or in dedicated test repos.

---

## Automated Tests (CI)

### Test Workflow

Create `.github/workflows/test.yml` in this repository:

```yaml
name: Test

on:
  push:
    branches: [main]
    paths:
      - 'src/**'
      - 'install.sh'
      - '.github/workflows/test.yml'
  pull_request:
    branches: [main]
    paths:
      - 'src/**'
      - 'install.sh'

jobs:
  # Job 1: Static analysis
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Validate YAML files
        run: |
          echo "Validating workflow YAML files..."
          for file in src/workflows/*.yml; do
            echo "Checking $file"
            python3 -c "import yaml; yaml.safe_load(open('$file'))" || exit 1
          done
          echo "✅ All YAML files valid"
      
      - name: Lint shell script
        uses: ludeeus/action-shellcheck@master
        with:
          scandir: '.'
          files: 'install.sh'
      
      - name: Check markdown links
        uses: gaurav-nelson/github-action-markdown-link-check@v1
        with:
          use-quiet-mode: 'yes'
          folder-path: 'docs/'

  # Job 2: Test installer (Cursor path)
  test-install-cursor:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup test environment
        run: |
          # Create a fake git repo to test installation
          mkdir -p /tmp/test-repo
          cd /tmp/test-repo
          git init
          git config user.email "test@test.com"
          git config user.name "Test"
          echo "# Test" > README.md
          git add . && git commit -m "init"
      
      - name: Test installer (Cursor, dry-run simulation)
        run: |
          cd /tmp/test-repo
          
          # Copy src files to simulate what installer does
          mkdir -p .cursor/agents .cursor/rules .github/workflows
          
          cp $GITHUB_WORKSPACE/src/agents/* .cursor/agents/
          cp $GITHUB_WORKSPACE/src/rules/system.mdc .cursor/rules/
          cp $GITHUB_WORKSPACE/src/workflows/idad-cursor.yml .github/workflows/idad.yml
          cp $GITHUB_WORKSPACE/src/workflows/ci.yml .github/workflows/
          cp $GITHUB_WORKSPACE/src/cursor/README.md .cursor/
          
          # Verify files
          echo "Verifying Cursor installation..."
          test -f .cursor/agents/planner.md || exit 1
          test -f .cursor/agents/implementer.md || exit 1
          test -f .cursor/agents/reviewer.md || exit 1
          test -f .cursor/rules/system.mdc || exit 1
          test -f .github/workflows/idad.yml || exit 1
          
          # Count agent files
          AGENT_COUNT=$(ls .cursor/agents/*.md | wc -l)
          if [ "$AGENT_COUNT" -ne 8 ]; then
            echo "❌ Expected 8 agent files, found $AGENT_COUNT"
            exit 1
          fi
          
          echo "✅ Cursor installation verified"

  # Job 3: Test installer (Claude path)
  test-install-claude:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup test environment
        run: |
          mkdir -p /tmp/test-repo
          cd /tmp/test-repo
          git init
          git config user.email "test@test.com"
          git config user.name "Test"
          echo "# Test" > README.md
          git add . && git commit -m "init"
      
      - name: Test installer (Claude, dry-run simulation)
        run: |
          cd /tmp/test-repo
          
          # Copy src files to simulate what installer does
          mkdir -p .claude/agents .claude/rules .github/workflows
          
          cp $GITHUB_WORKSPACE/src/agents/* .claude/agents/
          cp $GITHUB_WORKSPACE/src/rules/system.md .claude/rules/
          cp $GITHUB_WORKSPACE/src/workflows/idad-claude.yml .github/workflows/idad.yml
          cp $GITHUB_WORKSPACE/src/workflows/ci.yml .github/workflows/
          
          # Verify files
          echo "Verifying Claude installation..."
          test -f .claude/agents/planner.md || exit 1
          test -f .claude/agents/implementer.md || exit 1
          test -f .claude/agents/reviewer.md || exit 1
          test -f .claude/rules/system.md || exit 1
          test -f .github/workflows/idad.yml || exit 1
          
          # Count agent files
          AGENT_COUNT=$(ls .claude/agents/*.md | wc -l)
          if [ "$AGENT_COUNT" -ne 8 ]; then
            echo "❌ Expected 8 agent files, found $AGENT_COUNT"
            exit 1
          fi
          
          echo "✅ Claude installation verified"

  # Job 4: Test workflow dispatch logic
  test-workflow-dispatch:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Validate workflow dispatch inputs
        run: |
          echo "Checking workflow dispatch configuration..."
          
          # Check Cursor workflow
          CURSOR_AGENTS=$(grep -A 20 "options:" src/workflows/idad-cursor.yml | grep "^ *-" | head -8)
          echo "Cursor workflow agents:"
          echo "$CURSOR_AGENTS"
          
          # Check Claude workflow
          CLAUDE_AGENTS=$(grep -A 20 "options:" src/workflows/idad-claude.yml | grep "^ *-" | head -8)
          echo "Claude workflow agents:"
          echo "$CLAUDE_AGENTS"
          
          # Verify both have same agents
          if [ "$(echo "$CURSOR_AGENTS" | sort)" != "$(echo "$CLAUDE_AGENTS" | sort)" ]; then
            echo "❌ Agent lists don't match between workflows"
            exit 1
          fi
          
          echo "✅ Workflow dispatch configuration valid"
```

---

## Integration Tests (Downstream Repos)

For full integration testing, use dedicated test repositories.

### Option A: Manual Test Repos

Create two test repositories:
- `your-org/idad-test-cursor` - For Cursor CLI testing
- `your-org/idad-test-claude` - For Claude CLI testing

**Test procedure:**

```bash
# 1. Clone test repo
git clone https://github.com/your-org/idad-test-cursor
cd idad-test-cursor

# 2. Clear any existing IDAD files
rm -rf .cursor .claude .github/workflows/idad.yml

# 3. Run installer
curl -fsSL https://raw.githubusercontent.com/kidrecursive/idad-cursor/main/install.sh | bash -s -- --cli cursor

# 4. Verify installation
ls -la .cursor/agents/
cat .github/workflows/idad.yml | head -20

# 5. Create test issue (requires secrets configured)
gh issue create --title "Test: $(date)" --label "idad:auto" --body "Automated test"

# 6. Watch workflow
gh run list --workflow=idad.yml --limit 3
```

### Option B: Automated Test Repos (Advanced)

Add a workflow that tests against real repos:

```yaml
# .github/workflows/integration-test.yml
name: Integration Test

on:
  workflow_dispatch:
    inputs:
      test_repo:
        description: 'Test repository (owner/repo)'
        required: true
      cli:
        description: 'CLI to test'
        required: true
        type: choice
        options:
          - cursor
          - claude

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Clone test repo
        run: |
          gh repo clone ${{ inputs.test_repo }} test-repo
        env:
          GH_TOKEN: ${{ secrets.TEST_REPO_TOKEN }}
      
      - name: Clear existing IDAD
        run: |
          cd test-repo
          rm -rf .cursor .claude .github/workflows/idad.yml .github/workflows/ci.yml
          git add -A
          git commit -m "Clear IDAD for testing" || true
          git push
      
      - name: Run installer
        run: |
          cd test-repo
          curl -fsSL https://raw.githubusercontent.com/${{ github.repository }}/main/install.sh | bash -s -- --cli ${{ inputs.cli }}
        env:
          GH_TOKEN: ${{ secrets.TEST_REPO_TOKEN }}
      
      - name: Verify installation
        run: |
          cd test-repo
          
          if [ "${{ inputs.cli }}" = "cursor" ]; then
            test -d .cursor/agents || exit 1
            test -f .cursor/rules/system.mdc || exit 1
          else
            test -d .claude/agents || exit 1
            test -f .claude/rules/system.md || exit 1
          fi
          
          test -f .github/workflows/idad.yml || exit 1
          echo "✅ Installation verified"
```

---

## Manual Testing with Test Repositories

This section provides step-by-step procedures for setting up and using dedicated test repositories.

### Setting Up Test Repositories

#### Step 1: Create Test Repos

Create two empty repositories for testing:

```bash
# Create Cursor test repo
gh repo create idad-test-cursor --public --description "IDAD test repo (Cursor)" --clone
cd idad-test-cursor
echo "# IDAD Test - Cursor" > README.md
git add . && git commit -m "init" && git push
cd ..

# Create Claude test repo
gh repo create idad-test-claude --public --description "IDAD test repo (Claude)" --clone
cd idad-test-claude
echo "# IDAD Test - Claude" > README.md
git add . && git commit -m "init" && git push
cd ..
```

#### Step 2: Create GitHub App (One-Time Setup)

You need ONE GitHub App that can be installed on both test repos:

1. Go to https://github.com/settings/apps/new
2. **Name**: `IDAD Test Automation`
3. **Homepage URL**: `https://github.com/YOUR_USERNAME`
4. **Webhook**: Uncheck "Active"
5. **Repository Permissions**:
   - Contents: Read and Write
   - Issues: Read and Write
   - Pull requests: Read and Write
   - Actions: Read and Write
   - Workflows: Read and Write
6. Click **Create GitHub App**
7. Note the **App ID**
8. Generate and download a **Private Key** (.pem file)
9. Click **Install App** → Select both test repos

#### Step 3: Add Secrets to Test Repos

```bash
# For Cursor test repo
cd idad-test-cursor
gh secret set IDAD_APP_ID           # Enter your App ID
gh secret set IDAD_APP_PRIVATE_KEY < ~/path/to/private-key.pem
gh secret set CURSOR_API_KEY        # Enter your Cursor API key
cd ..

# For Claude test repo
cd idad-test-claude
gh secret set IDAD_APP_ID           # Same App ID
gh secret set IDAD_APP_PRIVATE_KEY < ~/path/to/private-key.pem
gh secret set ANTHROPIC_API_KEY     # Enter your Anthropic API key
cd ..
```

---

### Test Procedure: Fresh Installation

Use this procedure to test a clean installation from scratch.

#### Cursor CLI Test

```bash
cd idad-test-cursor

# 1. Clean slate - remove any existing IDAD files
rm -rf .cursor .claude .github/workflows/idad.yml .github/workflows/ci.yml
git add -A && git commit -m "Clean slate for testing" && git push || true

# 2. Run the installer (from the branch you want to test)
# For main branch:
curl -fsSL https://raw.githubusercontent.com/kidrecursive/idad-cursor/main/install.sh | bash -s -- --cli cursor

# For a specific branch:
curl -fsSL https://raw.githubusercontent.com/kidrecursive/idad-cursor/YOUR_BRANCH/install.sh | bash -s -- --cli cursor --branch YOUR_BRANCH

# 3. Verify files were created
echo "=== Checking files ==="
ls -la .cursor/agents/
ls -la .cursor/rules/
ls -la .github/workflows/

# 4. Verify workflow content
echo "=== Workflow header ==="
head -50 .github/workflows/idad.yml

# 5. Push changes
git push
```

#### Claude CLI Test

```bash
cd idad-test-claude

# 1. Clean slate
rm -rf .cursor .claude .github/workflows/idad.yml .github/workflows/ci.yml
git add -A && git commit -m "Clean slate for testing" && git push || true

# 2. Run the installer
curl -fsSL https://raw.githubusercontent.com/kidrecursive/idad-cursor/main/install.sh | bash -s -- --cli claude

# 3. Verify files
echo "=== Checking files ==="
ls -la .claude/agents/
ls -la .claude/rules/
ls -la .github/workflows/

# 4. Verify workflow content
echo "=== Workflow header ==="
head -50 .github/workflows/idad.yml

# 5. Push changes
git push
```

---

### Test Procedure: Agent Execution

After installation, test that agents actually run.

#### Test Issue Review Agent

```bash
cd idad-test-cursor  # or idad-test-claude

# Create a test issue
gh issue create \
  --title "Test: Add greeting function" \
  --label "idad:auto" \
  --body "Create a simple greeting function that takes a name and returns 'Hello, {name}!'

Requirements:
- Function should be exported
- Add unit tests
- Handle edge cases (empty name, null)"

# Note the issue number
ISSUE_NUM=$(gh issue list --limit 1 --json number -q '.[0].number')
echo "Created issue #$ISSUE_NUM"

# Watch the workflow
echo "Waiting for workflow to start..."
sleep 5
gh run list --workflow=idad.yml --limit 3

# Watch specific run
RUN_ID=$(gh run list --workflow=idad.yml --limit 1 --json databaseId -q '.[0].databaseId')
gh run watch $RUN_ID
```

#### Test Full Agent Chain

```bash
# After Issue Review completes, manually trigger subsequent agents if needed:

# Trigger Planner
gh workflow run idad.yml -f agent="planner" -f issue="$ISSUE_NUM"

# Wait and check
sleep 30
gh run list --workflow=idad.yml --limit 3

# After Planner creates a plan, trigger Implementer
gh workflow run idad.yml -f agent="implementer" -f issue="$ISSUE_NUM"

# Check for PR
gh pr list

# After PR is created, trigger Security Scanner
PR_NUM=$(gh pr list --limit 1 --json number -q '.[0].number')
gh workflow run idad.yml -f agent="security-scanner" -f issue="$ISSUE_NUM" -f pr="$PR_NUM"

# Continue through the chain...
gh workflow run idad.yml -f agent="reviewer" -f issue="$ISSUE_NUM" -f pr="$PR_NUM"
gh workflow run idad.yml -f agent="documenter" -f issue="$ISSUE_NUM" -f pr="$PR_NUM"
```

#### Verify Results

```bash
# Check issue comments
gh issue view $ISSUE_NUM --comments

# Check PR
gh pr view $PR_NUM

# Check PR comments
gh pr view $PR_NUM --comments

# Check workflow runs
gh run list --workflow=idad.yml --limit 10
```

---

### Test Procedure: Reinstallation / Upgrade

Test upgrading from an existing installation.

```bash
cd idad-test-cursor

# 1. Verify existing installation
ls .cursor/agents/
cat .github/workflows/idad.yml | grep -E "(MODEL_|name:)"

# 2. Run installer again (should detect existing files)
curl -fsSL https://raw.githubusercontent.com/kidrecursive/idad-cursor/main/install.sh | bash -s -- --cli cursor
# Answer 'y' to overwrite prompt

# 3. Verify files were updated
git status
git diff

# 4. Commit and push
git add -A && git commit -m "Upgrade IDAD" && git push
```

---

### Test Procedure: Switching CLIs

Test switching from Cursor to Claude (or vice versa).

```bash
cd idad-test-cursor  # Has Cursor installed

# 1. Note existing setup
ls -la .cursor/ .claude/ 2>/dev/null || true

# 2. Install Claude (different CLI)
curl -fsSL https://raw.githubusercontent.com/kidrecursive/idad-cursor/main/install.sh | bash -s -- --cli claude
# Answer 'y' to overwrite

# 3. Verify Claude files exist
ls -la .claude/agents/
ls -la .claude/rules/

# 4. Verify workflow uses Claude
grep "ANTHROPIC_API_KEY" .github/workflows/idad.yml
grep ".claude/" .github/workflows/idad.yml

# 5. Note: Old .cursor/ files may still exist - that's OK
# The workflow determines which CLI is used
```

---

### Quick Verification Commands

Handy commands to quickly verify an installation:

```bash
# Check which CLI is configured
if grep -q "CURSOR_API_KEY" .github/workflows/idad.yml; then
  echo "Configured for: Cursor"
  echo "Config dir: .cursor/"
elif grep -q "ANTHROPIC_API_KEY" .github/workflows/idad.yml; then
  echo "Configured for: Claude"
  echo "Config dir: .claude/"
fi

# Count agent files
echo "Agent files:"
ls .cursor/agents/*.md 2>/dev/null | wc -l || echo "0 in .cursor"
ls .claude/agents/*.md 2>/dev/null | wc -l || echo "0 in .claude"

# Check secrets are set
echo "Secrets configured:"
gh secret list

# Check labels exist
echo "IDAD labels:"
gh label list | grep -E "(idad|type:|state:)" | wc -l

# Check recent workflow runs
echo "Recent runs:"
gh run list --workflow=idad.yml --limit 5 2>/dev/null || echo "No idad.yml workflow"
```

---

### Cleanup Test Repos

To reset a test repo for fresh testing:

```bash
cd idad-test-cursor

# Option A: Remove IDAD files only
rm -rf .cursor .claude .github/workflows/idad.yml .github/workflows/ci.yml
git add -A && git commit -m "Remove IDAD for fresh test" && git push

# Option B: Nuclear option - reset to initial commit
git log --oneline | tail -1  # Find first commit
git reset --hard <first-commit-hash>
git push --force

# Option C: Delete and recreate repo
cd ..
gh repo delete idad-test-cursor --yes
gh repo create idad-test-cursor --public --clone
```

---

## Manual Testing Checklist

### Pre-release Checklist

Before releasing a new version, verify:

#### Installer
- [ ] `install.sh` runs without errors
- [ ] CLI selection prompt works
- [ ] `--cli cursor` flag works
- [ ] `--cli claude` flag works
- [ ] Files are copied to correct locations
- [ ] Commit is created with correct message
- [ ] Labels are created
- [ ] Secrets prompts work correctly

#### Cursor Installation
- [ ] `.cursor/agents/` contains 8 files
- [ ] `.cursor/rules/system.mdc` exists
- [ ] `.github/workflows/idad.yml` is correct workflow
- [ ] Model defaults are `sonnet-4.5`/`opus-4.5`
- [ ] `CURSOR_API_KEY` secret is prompted

#### Claude Installation
- [ ] `.claude/agents/` contains 8 files
- [ ] `.claude/rules/system.md` exists
- [ ] `.github/workflows/idad.yml` is correct workflow
- [ ] Model defaults are `claude-sonnet-4-*`/`claude-opus-4-*`
- [ ] `ANTHROPIC_API_KEY` secret is prompted

#### Agent Execution (requires API keys)
- [ ] Issue Review agent runs on new issue
- [ ] Planner agent creates implementation plan
- [ ] Implementer agent creates PR
- [ ] Security Scanner runs on PR
- [ ] Reviewer agent reviews PR
- [ ] Documenter agent updates docs
- [ ] Agent chain completes end-to-end

---

## Test Data

### Sample Test Issue

```markdown
Title: Add greeting function

Body:
Create a simple greeting function that:
- Takes a name parameter
- Returns "Hello, {name}!"
- Include unit tests

Acceptance criteria:
- Function is exported
- Tests cover edge cases (empty name, special characters)
```

### Expected Outcomes

1. **Issue Review**: Adds `type:issue` label, refines description
2. **Planner**: Creates implementation plan with file list
3. **Implementer**: Creates branch, writes code, creates PR
4. **Security Scanner**: Checks for vulnerabilities
5. **Reviewer**: Reviews code, approves or requests changes
6. **Documenter**: Updates README if needed

---

## Debugging

### Common Issues

**Installer fails to clone:**
```bash
# Check if repo is accessible
curl -I https://github.com/kidrecursive/idad-cursor

# Try SSH instead of HTTPS
git clone git@github.com:kidrecursive/idad-cursor.git
```

**Workflow doesn't trigger:**
```bash
# Check if label exists
gh label list | grep idad:auto

# Check workflow file
cat .github/workflows/idad.yml | head -30

# Manually trigger
gh workflow run idad.yml -f agent="issue-review" -f issue="1"
```

**Agent fails:**
```bash
# Check workflow run logs
gh run list --workflow=idad.yml
gh run view <run-id> --log

# Check secrets
gh secret list
```

---

## CI Status

After implementing the test workflow, add a badge to README:

```markdown
[![Test](https://github.com/kidrecursive/idad-cursor/actions/workflows/test.yml/badge.svg)](https://github.com/kidrecursive/idad-cursor/actions/workflows/test.yml)
```

---

## Test Schedule

| Test Type | Frequency | Trigger |
|-----------|-----------|---------|
| Lint/Static | Every PR | Automatic |
| Install simulation | Every PR | Automatic |
| Integration (manual) | Before release | Manual |
| Full agent chain | Monthly | Manual |

---

*Last updated: 2025-12-11*
