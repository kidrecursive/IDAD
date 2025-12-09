# IDAD Operations Manual

Repository setup, management, and maintenance guide for IDAD.

---

## Table of Contents

1. [Initial Setup](#initial-setup)
2. [Label Management](#label-management)
3. [Manual Agent Triggering](#manual-agent-triggering)
4. [Monitoring & Observability](#monitoring--observability)
5. [Maintenance Tasks](#maintenance-tasks)
6. [Backup & Recovery](#backup--recovery)

---

## Initial Setup

### Prerequisites

- GitHub repository with admin access
- GitHub CLI (`gh`) installed and authenticated
- Git installed

### Step 1: Install GitHub CLI

**macOS**:
```bash
brew install gh
```

**Linux**:
```bash
curl -sS https://webi.sh/gh | sh
```

**Windows**:
```bash
winget install GitHub.cli
```

### Step 2: Authenticate

```bash
gh auth login
```

Follow prompts to authenticate with GitHub.

### Step 3: Clone/Create Repository

```bash
# Clone existing repo
git clone https://github.com/owner/repo.git
cd repo

# Or use IDAD as template
# (via GitHub UI: Use this template)
```

### Step 4: Run Setup Script

```bash
curl -fsSL https://raw.githubusercontent.com/kidrecursive/idad/main/install.sh | bash
```

Or specify repository explicitly:
```bash
curl -fsSL https://raw.githubusercontent.com/kidrecursive/idad/main/install.sh | bash owner/repo
```

**What It Does**:
1. Creates 17 IDAD labels
2. Configures GitHub Actions permissions
3. Sets up branch protection on main

**Expected Output**:
```
======================================================================
  IDAD Repository Setup
  Repository: owner/repo
======================================================================

Step 1: Creating IDAD Labels
✅ All 17 labels created successfully!

Step 2: Configuring GitHub Actions Permissions
✅ Workflow permissions updated!

Step 3: Configuring Branch Protection (main)
✅ Branch protection configured for 'main'!

======================================================================
  Setup Complete! ✅
======================================================================
```

### Step 5: Add Cursor API Key

1. Get Cursor API key from Cursor settings
2. Add to GitHub repository secrets:

**Via GitHub UI**:
- Settings → Secrets and variables → Actions
- New repository secret
- Name: `CURSOR_API_KEY`
- Value: [your key]

**Via gh CLI**:
```bash
gh secret set CURSOR_API_KEY
# Paste key when prompted
```

### Step 6: Verify Setup

```bash
# Check labels
gh label list

# Check workflow files
ls .github/workflows/

# Check agent definitions
ls .cursor/agents/

# Test setup
gh workflow run idad.yml --ref main \
  -f agent_type="reporting" \
  -f issue_number="" \
  -f pr_number=""
```

### Step 7: Create First Issue

```bash
gh issue create \
  --title "Add welcome message" \
  --body "Add a simple welcome message to the app" \
  --label "idad:auto,type:feature"
```

Watch the automation work!

---

## Label Management

### View All Labels

```bash
gh label list
```

### Create Missing Label

```bash
gh label create "label-name" \
  --color "0366d6" \
  --description "Description"
```

### Update Label

```bash
gh label edit "label-name" \
  --color "new-color" \
  --description "New description"
```

### Delete Label

```bash
gh label delete "label-name"
```

### Add Label to Issue/PR

```bash
gh issue edit <number> --add-label "label-name"
gh pr edit <number> --add-label "label-name"
```

### Remove Label

```bash
gh issue edit <number> --remove-label "label-name"
gh pr edit <number> --remove-label "label-name"
```

### Bulk Label Operations

```bash
# Add idad:auto to multiple issues
for issue in 123 124 125; do
  gh issue edit $issue --add-label "idad:auto"
done

# Remove needs-changes from all PRs
gh pr list --json number --jq '.[].number' | while read pr; do
  gh pr edit $pr --remove-label "needs-changes" 2>/dev/null || true
done
```

---

## Manual Agent Triggering

### Trigger Any Agent

```bash
gh workflow run idad.yml \
  --ref main \
  -f agent_type="<agent>" \
  -f issue_number="<number>" \
  -f pr_number="<number>"
```

### Common Scenarios

**Re-run Issue Review**:
```bash
gh workflow run idad.yml --ref main \
  -f agent_type="issue-review" \
  -f issue_number="123" \
  -f pr_number=""
```

**Force Planner to Run**:
```bash
gh workflow run idad.yml --ref main \
  -f agent_type="planner" \
  -f issue_number="123" \
  -f pr_number=""
```

**Retry Implementer** (with existing PR):
```bash
gh workflow run idad.yml --ref main \
  -f agent_type="implementer" \
  -f issue_number="123" \
  -f pr_number="456"
```

**Trigger Reviewer** (skip CI):
```bash
gh workflow run idad.yml --ref main \
  -f agent_type="reviewer" \
  -f issue_number="123" \
  -f pr_number="456"
```

**Generate Report**:
```bash
gh workflow run idad.yml --ref main \
  -f agent_type="reporting" \
  -f issue_number="" \
  -f pr_number=""
```

### Watch Workflow Progress

```bash
# List recent runs
gh run list --workflow=idad.yml --limit 5

# Watch specific run
gh run watch <run-id>

# View logs
gh run view <run-id> --log
```

---

## Monitoring & Observability

### Check System Health

```bash
# Recent workflow runs
gh run list --limit 20

# Failed runs only
gh run list --status failure --limit 10

# Specific workflow
gh run list --workflow=idad.yml --limit 10
```

### Check Open Work

```bash
# All open issues with automation
gh issue list --label "idad:auto"

# All open PRs
gh pr list

# Issues by state
gh issue list --label "state:implementing"
gh issue list --label "state:human-review"
```

### Check Recent Activity

```bash
# Recent issues closed
gh issue list --state closed --limit 10

# Recent PRs merged
gh pr list --state merged --limit 10

# Recent workflow runs
gh run list --limit 10 --json conclusion,displayTitle,createdAt
```

### Generate Report

```bash
# Trigger reporting agent for insights
gh workflow run idad.yml --ref main \
  -f agent_type="reporting" \
  -f issue_number="" \
  -f pr_number=""

# View last report
gh issue list --label "type:documentation" --limit 1
```

---

## Maintenance Tasks

### Weekly Maintenance

1. **Review Reports**
   ```bash
   gh issue list --label "type:documentation" --limit 1
   ```

2. **Check for Stuck Workflows**
   ```bash
   gh run list --status in_progress
   ```

3. **Clean Up Stale Branches**
   ```bash
   # List merged branches
   git branch -r --merged origin/main | grep -v "main"
   
   # Delete remote branches
   git push origin --delete branch-name
   ```

4. **Review Failed Runs**
   ```bash
   gh run list --status failure --limit 5
   ```

### Monthly Maintenance

1. **Generate Monthly Report**
   ```bash
   REPORT_TYPE=monthly gh workflow run idad.yml --ref main \
     -f agent_type="reporting" \
     -f issue_number="" \
     -f pr_number=""
   ```

2. **Review IDAD Improvements**
   ```bash
   gh pr list --label "type:infrastructure"
   ```

3. **Update Dependencies** (if any)
   - Review and merge dependabot PRs
   - Update agent definitions if needed

4. **Archive Old Reports**
   - Close old report issues
   - Keep recent ones for reference

### Quarterly Maintenance

1. **System Review**
   - Review agent performance
   - Identify improvement opportunities
   - Update agent definitions

2. **Documentation Update**
   - Update guides based on usage
   - Add new troubleshooting entries
   - Update examples

3. **Cleanup**
   - Archive old issues
   - Clean up labels if needed
   - Remove obsolete branches

---

## Backup & Recovery

### Backup Agent Definitions

```bash
# Backup all agent files
cp -r .cursor/agents/ ~/backups/agents-$(date +%Y%m%d)/

# Or commit to git (already done if using IDAD)
```

### Backup Workflows

```bash
# Backup workflows
cp -r .github/workflows/ ~/backups/workflows-$(date +%Y%m%d)/
```

### Restore Agent Definition

```bash
# If accidentally modified
git restore .cursor/agents/agent-name.md

# Or restore from backup
cp ~/backups/agents-20251209/agent-name.md .cursor/agents/
```

### Restore Workflows

```bash
# Restore from git
git restore .github/workflows/

# Or restore from backup
cp ~/backups/workflows-20251209/*.yml .github/workflows/
```

### Reset Repository Labels

```bash
# Re-run setup script (idempotent)
curl -fsSL https://raw.githubusercontent.com/kidrecursive/idad/main/install.sh | bash
```

### Disaster Recovery

If everything breaks:

1. **Pause Automation**
   ```bash
   # Remove idad:auto from all issues
   gh issue list --label "idad:auto" --json number --jq '.[].number' | \
     while read issue; do
       gh issue edit $issue --remove-label "idad:auto"
     done
   ```

2. **Cancel Running Workflows**
   ```bash
   gh run list --status in_progress --json databaseId --jq '.[].databaseId' | \
     while read run; do
       gh run cancel $run
     done
   ```

3. **Restore from Git**
   ```bash
   # Reset to last known good commit
   git log --oneline -10
   git reset --hard <commit-hash>
   git push origin main --force
   ```

4. **Re-run Setup**
   ```bash
   curl -fsSL https://raw.githubusercontent.com/kidrecursive/idad/main/install.sh | bash
   ```

5. **Test with Simple Issue**
   ```bash
   gh issue create --title "[TEST] Simple test" \
     --body "Test issue" \
     --label "idad:auto,type:feature"
   ```

---

## Advanced Operations

### Modify Branch Protection

```bash
# View current protection
gh api repos/owner/repo/branches/main/protection

# Update required reviews count
gh api repos/owner/repo/branches/main/protection -X PUT --input - <<EOF
{
  "required_pull_request_reviews": {
    "required_approving_review_count": 2
  },
  ...
}
EOF
```

### Enable Admin Enforcement

```bash
# Enforce branch protection for admins (production use)
gh api -X POST repos/owner/repo/branches/main/protection/enforce_admins
```

### Add Required Status Checks

```bash
# Update required checks
gh api repos/owner/repo/branches/main/protection -X PUT --input - <<EOF
{
  "required_status_checks": {
    "strict": false,
    "contexts": ["test", "additional-check"]
  },
  ...
}
EOF
```

### Bulk Close Issues

```bash
# Close multiple test issues
for issue in 45 46 47; do
  gh issue close $issue --comment "Closing test issue"
done
```

### Bulk Close PRs

```bash
# Close multiple test PRs
for pr in 42 43 44; do
  gh pr close $pr --comment "Closing test PR"
done
```

---

## Repository Settings

### Recommended Settings

**Actions → General**:
- Workflow permissions: Read and write ✅
- Allow GitHub Actions to create/approve PRs: ✅

**Branches → Branch protection (main)**:
- Require pull request reviews: ✅ (1 review)
- Require status checks: ✅ (test)
- Require branches to be up to date: ❌
- Require linear history: ❌
- Allow force pushes: ❌
- Allow deletions: ❌

**Security**:
- Secrets: `CURSOR_API_KEY` ✅
- Dependabot: ✅ (recommended)

---

## Monitoring Best Practices

### Daily
- Check for `needs-clarification` issues
- Review `state:human-review` PRs
- Merge approved PRs

### Weekly  
- Review weekly report
- Check for failed workflows
- Clean up merged branches

### Monthly
- Review monthly report
- Update agent definitions if patterns emerge
- Review and merge IDAD improvements

---

## Security Considerations

### Secrets Management
- Never commit `CURSOR_API_KEY`
- Rotate keys periodically
- Use repository secrets (not environment secrets)

### Code Review
- Always review `state:human-review` PRs
- Don't blindly merge automated work
- Check for security issues

### Branch Protection
- Keep branch protection enabled
- Don't disable for convenience
- Use `--admin` only for testing

### Sensitive Operations
- Don't use `idad:auto` for security changes
- Manual review for infrastructure changes
- IDAD improvements always require human review

---

## Quick Reference

### Common Commands

```bash
# Setup
curl -fsSL https://raw.githubusercontent.com/kidrecursive/idad/main/install.sh | bash

# Create issue
gh issue create --title "..." --body "..." --label "idad:auto,type:feature"

# Trigger agent
gh workflow run idad.yml --ref main -f agent_type="..." -f issue_number="..." -f pr_number="..."

# View issue
gh issue view <number>

# View PR
gh pr view <number>

# View workflows
gh run list --limit 10

# Merge PR
gh pr merge <number> --squash

# Generate report
gh workflow run idad.yml --ref main -f agent_type="reporting" -f issue_number="" -f pr_number=""
```

### Emergency Commands

```bash
# Stop everything
gh run list --status in_progress --json databaseId --jq '.[].databaseId' | xargs -I {} gh run cancel {}

# Remove automation from all issues
gh issue list --label "idad:auto" --json number --jq '.[].number' | xargs -I {} gh issue edit {} --remove-label "idad:auto"

# Reset repository
curl -fsSL https://raw.githubusercontent.com/kidrecursive/idad/main/install.sh | bash
```

---

## Support Resources

- **Workflow Guide**: [WORKFLOW.md](WORKFLOW.md)
- **Troubleshooting**: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **Agent Reference**: [AGENTS.md](AGENTS.md)
- **Specification**: [../specs/SPECIFICATION.md](../specs/SPECIFICATION.md)
- **Implementation Plan**: [../specs/PLAN.md](../specs/PLAN.md)

---

**Last Updated**: 2025-12-09  
**Phase**: 10 - Full Workflow Integration
