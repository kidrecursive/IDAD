# IDAD Troubleshooting Guide

Common issues and solutions for the IDAD system.

---

## Table of Contents

1. [Quick Diagnostics](#quick-diagnostics)
2. [Workflow Not Starting](#workflow-not-starting)
3. [Agent-Specific Issues](#agent-specific-issues)
4. [Workflow Stuck](#workflow-stuck)
5. [GitHub Actions Problems](#github-actions-problems)
6. [Permission Issues](#permission-issues)
7. [GitHub App Issues](#github-app-issues)
8. [Manual Recovery](#manual-recovery)
9. [Debugging Tools](#debugging-tools)

---

## Quick Diagnostics

### Is It Working?

**Check 1: Labels**
```bash
gh issue view <issue-number> --json labels
```
- Should have an `idad:*` label showing current state
- Only ONE `idad:*` label at a time

**Check 2: Workflows**
```bash
gh run list --workflow=idad.yml --limit 5
```
- Should see recent runs
- Check for failures

**Check 3: Comments**
```bash
gh issue view <issue-number>
```
- Agents post comments with `agentlog` blocks
- Check for error messages

---

## Workflow Not Starting

### Issue: Created issue but nothing happens

**Cause 1: Missing `idad:issue-review` label**

**Solution**:
```bash
gh issue edit <issue-number> --add-label "idad:issue-review"
```

The `idad:issue-review` label is required (opt-in by design).

---

**Cause 2: Workflow not triggered**

**Check**:
```bash
gh run list --workflow=idad.yml --limit 1
```

**Solution**: Manually trigger Issue Review Agent:
```bash
gh workflow run idad.yml \
  --ref main \
  -f agent="issue-review" \
  -f issue="<number>" \
  -f pr=""
```

---

**Cause 3: GitHub Actions disabled**

**Check**: Settings → Actions → General

**Solution**: Enable GitHub Actions for the repository

---

## Agent-Specific Issues

### Issue Review Agent

**Problem**: Agent doesn't transition to `idad:planning`

**Debug**:
```bash
gh run view <run-id> --log | grep "Issue Review"
```

**Common Causes**:
- Issue description too vague
- Agent asks for clarification (check comments)
- Workflow error (check logs)

**Solution**:
- If `idad:issue-needs-clarification` label: Answer questions in comments, agent will re-analyze
- If error: Check workflow logs for details
- Manual trigger if needed:
```bash
gh workflow run idad.yml \
  --ref main \
  -f agent="issue-review" \
  -f issue="<number>" \
  -f pr=""
```

---

### Planner Agent

**Problem**: No implementation plan added to issue

**Debug**:
```bash
gh issue view <issue-number> | grep "Implementation Plan"
gh run list --workflow=idad.yml --limit 5
```

**Common Causes**:
- Issue not marked `idad:planning`
- Agent not triggered
- Workflow failure

**Solution**: Manual trigger:
```bash
gh workflow run idad.yml \
  --ref main \
  -f agent="planner" \
  -f issue="<number>" \
  -f pr=""
```

---

**Problem**: Issue stuck in `idad:human-plan-review`

**Debug**:
```bash
gh issue view <issue-number> --json labels
gh issue view <issue-number> --comments | tail -20
```

**Common Causes**:
- Waiting for your approval (this is expected!)
- Your approval comment wasn't detected
- Workflow not triggered by your comment

**Solution**:
1. **Check if it's waiting for you**: If you see "Human Review Required" in the comments, comment with approval:
   ```bash
   gh issue comment <issue-number> --body "Looks good, proceed!"
   ```

2. **If already commented**: Manually trigger Planner to re-process:
   ```bash
   gh workflow run idad.yml \
     --ref main \
     -f agent="planner" \
     -f issue="<number>" \
     -f pr=""
   ```

3. **Skip plan review** (force proceed): Update labels manually:
   ```bash
   gh issue edit <issue-number> \
     --remove-label "idad:human-plan-review" \
     --add-label "idad:implementing"
   gh workflow run idad.yml \
     --ref main \
     -f agent="implementer" \
     -f issue="<number>" \
     -f pr=""
   ```

---

### Implementer Agent

**Problem**: No PR created

**Debug**:
```bash
gh pr list --state open --limit 5
gh run view <run-id> --log | grep "Implementer"
```

**Common Causes**:
- Branch already exists
- Push failed
- Test failures
- GitHub API errors

**Solutions**:

**If branch exists**:
```bash
# Delete branch and retry
git push origin --delete feat/issue-<number>-description
gh workflow run idad.yml \
  --ref main \
  -f agent="implementer" \
  -f issue="<number>" \
  -f pr=""
```

**If tests failed**: Check workflow logs, fix locally if needed

---

### Security Scanner

**Problem**: Scan not running

**Debug**:
```bash
gh pr view <pr-number> --json labels
gh run list --workflow=idad.yml --limit 5
```

**Common Causes**:
- PR doesn't have `idad:security-scan` label
- Agent not triggered
- Workflow failure

**Solution**: Manual trigger:
```bash
gh workflow run idad.yml \
  --ref main \
  -f agent="security-scanner" \
  -f issue="" \
  -f pr="<pr-number>"
```

---

### Reviewer Agent

**Problem**: Review not posted

**Debug**:
```bash
gh pr view <pr-number>
gh run list --workflow=idad.yml --limit 5
```

**Common Causes**:
- PR doesn't have `idad:code-review` label
- Agent not triggered
- GitHub API rate limit

**Solution**: Manual trigger:
```bash
gh workflow run idad.yml \
  --ref main \
  -f agent="reviewer" \
  -f issue="<issue-number>" \
  -f pr="<pr-number>"
```

---

### Documenter Agent

**Problem**: Documentation not updated

**Debug**:
```bash
gh pr view <pr-number>
gh pr diff <pr-number> | grep README
```

**Common Causes**:
- PR not approved (still in `idad:code-review`)
- Agent not triggered
- No docs to update (empty commit)

**Solution**: Manual trigger:
```bash
gh workflow run idad.yml \
  --ref main \
  -f agent="documenter" \
  -f issue="<issue-number>" \
  -f pr="<pr-number>"
```

---

### IDAD Agent

**Problem**: No improvement issue after merge

**Expected Behavior**: IDAD only creates issues when it detects system improvements needed

**Not a bug if**:
- No new technologies detected
- CI already supports the technology
- Branch started with `idad/` (loop prevention)

**Debug**:
```bash
gh run list --workflow=idad.yml --event pull_request --limit 5
```

---

## Workflow Stuck

### Issue: Agent seems to be running forever

**Check**:
```bash
gh run list --workflow=idad.yml --limit 1 --json status,conclusion
```

**If `in_progress` for > 10 minutes**: Likely stuck

**Solution 1**: Cancel and retry
```bash
# Get run ID
gh run list --workflow=idad.yml --limit 1

# Cancel it
gh run cancel <run-id>

# Manually trigger next step
gh workflow run idad.yml \
  --ref main \
  -f agent_type="<agent-type>" \
  -f issue_number="<number>" \
  -f pr_number="<pr-number>"
```

**Solution 2**: Check GitHub Actions status
- GitHub may be experiencing outages
- Check https://www.githubstatus.com

---

### Issue: Workflow not progressing to next agent

**Cause**: Agent didn't trigger next agent

**Check workflow logs**:
```bash
gh run view <run-id> --log | grep "workflow run"
```

**Solution**: Manually trigger next agent based on current label:

**If `idad:planning`**: Trigger Planner
**If `idad:implementing`**: Trigger Implementer
**If `idad:security-scan`**: Trigger Security Scanner
**If `idad:code-review`**: Trigger Reviewer
**If `idad:documenting`**: Trigger Documenter

---

## GitHub Actions Problems

### Issue: Workflow fails with "Resource not accessible"

**Cause**: Insufficient permissions

**Check**: Repository Settings → Actions → General → Workflow permissions

**Should be**:
- Read and write permissions: ✅ Enabled
- Allow GitHub Actions to create and approve pull requests: ✅ Enabled

**Solution**: Update settings and retry workflow

---

### Issue: "Workflow file not found"

**Cause**: Workflow files not on `main` branch

**Solution**: Ensure these files exist on `main`:
- `.github/workflows/idad.yml`
- `.github/actions/run-idad-agent/action.yml`

---

### Issue: Concurrency conflicts

**Symptoms**: Multiple agents running for same issue

**Cause**: Concurrency group not working

**Solution**: Wait for current run to complete, then:
```bash
# Cancel all runs for an issue
gh run list --workflow=idad.yml | grep "issue-<number>" | awk '{print $7}' | xargs -I {} gh run cancel {}
```

Then manually trigger the correct next step.

---

## Permission Issues

### Issue: "Branch protection" preventing merge

**Cause**: Branch protection requires reviews

**Solution 1** (for testing): Use `--admin` flag
```bash
gh pr merge <pr-number> --squash --admin
```

**Solution 2** (production): Get required reviews

**Solution 3**: Temporarily disable branch protection for testing

---

### Issue: Agent can't push to branch

**Cause**: `GITHUB_TOKEN` limitations

**Common with**: PR creation, label changes not triggering workflows

**Workaround**: Manual empty commit push after PR creation:
```bash
git checkout <branch>
git commit --allow-empty -m "Trigger workflows"
git push
```

**Note**: IDAD uses GitHub App tokens which should handle this automatically. If you're still seeing this issue, check your GitHub App configuration in [GitHub App Issues](#github-app-issues).

---

### Issue: Can't create/update labels

**Cause**: Insufficient permissions

**Check**: Workflow has:
```yaml
permissions:
  issues: write
  pull-requests: write
```

---

## GitHub App Issues

### Issue: "Resource not accessible by integration"

**Cause**: The GitHub App doesn't have required permissions or isn't installed on the repository.

**Solution**:
1. Go to your app's settings: https://github.com/settings/apps
2. Verify permissions include:
   - Contents: Read and Write
   - Issues: Read and Write
   - Pull requests: Read and Write
   - Actions: Read and Write
   - Workflows: Read and Write
3. Check installation:
   - Go to "Install App" in sidebar
   - Verify your repository is selected

---

### Issue: "Could not create token for app"

**Cause**: Invalid App ID or private key.

**Solution**:
```bash
# Verify secrets are set
gh secret list  # Should show IDAD_APP_ID and IDAD_APP_PRIVATE_KEY

# Re-add the App ID
gh secret set IDAD_APP_ID
# Enter the numeric App ID when prompted

# Re-add the private key (ensure it's the full .pem contents)
gh secret set IDAD_APP_PRIVATE_KEY < path/to/private-key.pem
```

---

### Issue: Actions not appearing as bot

**Expected**: Actions should appear as `IDAD Automation[bot]` (or your app name).

**Check**: Verify the workflow is using the app token:
```bash
gh secret list
# Should show IDAD_APP_ID and IDAD_APP_PRIVATE_KEY
```

If secrets are present but actions still appear as a user, check that the workflow is using `actions/create-github-app-token@v1` correctly.

---

### Issue: Token expired mid-workflow

**Cause**: GitHub App installation tokens are valid for 1 hour.

**Solution**: This is rare but can happen for very long-running agents. The workflow generates a fresh token for each job, so this typically isn't an issue. If you encounter this, the agent can be re-triggered:

```bash
gh workflow run idad.yml \
  --ref main \
  -f agent="<agent-type>" \
  -f issue="<number>" \
  -f pr="<pr-number>"
```

---

## Manual Recovery

### Reset Issue to Start Over

```bash
# Remove all idad labels
gh issue edit <issue-number> \
  --remove-label "idad:issue-review" \
  --remove-label "idad:issue-needs-clarification" \
  --remove-label "idad:planning" \
  --remove-label "idad:human-plan-review" \
  --remove-label "idad:implementing"

# Add idad:issue-review to restart
gh issue edit <issue-number> --add-label "idad:issue-review"
```

---

### Skip to Specific Agent

```bash
# Set appropriate label
gh issue edit <issue-number> --add-label "idad:planning"

# Trigger specific agent
gh workflow run idad.yml \
  --ref main \
  -f agent="planner" \
  -f issue="<number>" \
  -f pr=""
```

---

### Close and Clean Up

```bash
# Close issue
gh issue close <issue-number>

# Close PR if exists
gh pr close <pr-number>

# Delete branch
git push origin --delete feat/issue-<number>-name
```

---

### Re-run Failed Workflow

```bash
# Get run ID
gh run list --workflow=idad.yml --limit 5

# Re-run
gh run rerun <run-id>
```

---

## Debugging Tools

### View Workflow Logs

```bash
# List recent runs
gh run list --workflow=idad.yml --limit 10

# View specific run
gh run view <run-id>

# View logs
gh run view <run-id> --log

# Search logs
gh run view <run-id> --log | grep "error"
```

---

### Check Issue State

```bash
# Full issue details
gh issue view <issue-number>

# Just labels
gh issue view <issue-number> --json labels --jq '.labels[].name'

# Comments only
gh issue view <issue-number> --json comments --jq '.comments[].body'
```

---

### Check PR State

```bash
# Full PR details
gh pr view <pr-number>

# PR status
gh pr view <pr-number> --json state,labels,reviews

# PR files
gh pr view <pr-number> --json files --jq '.files[].path'

# PR diff
gh pr diff <pr-number>
```

---

### Check All Workflows for Issue

```bash
# All runs mentioning issue number
gh run list --workflow=idad.yml | grep "<issue-number>"

# Recent runs with status
gh run list --workflow=idad.yml --limit 10 --json conclusion,status,displayTitle
```

---

### Extract agentlog Blocks

```bash
# From issue
gh issue view <issue-number> --json comments --jq '.comments[].body' | grep -Pzo '```agentlog.*?```'

# From PR
gh pr view <pr-number> --json comments --jq '.comments[].body' | grep -Pzo '```agentlog.*?```'
```

---

## Common Error Messages

### "Agent definition file not found"

**Cause**: Agent file missing

**Check**:
```bash
ls .idad/agents/
```

**Should have**:
- issue-review.md
- planner.md
- implementer.md
- security-scanner.md
- reviewer.md
- documenter.md
- idad.md
- reporting.md
- repository-testing.md

---

### "Could not determine branch name"

**Cause**: Implementer can't find branch from Planner

**Solution**: Check issue body for implementation plan with branch name

**Manual fix**:
- Ensure Planner ran successfully
- Check issue body has `### Branch` section
- If not, manually add branch name to issue

---

### "gh: command not found"

**Cause**: GitHub CLI not installed in workflow

**Check**: `.github/workflows/idad.yml` should have `gh` available

**This shouldn't happen** in GitHub Actions (gh is pre-installed)

---

### "cursor-agent: command not found" / "claude: command not found" / "codex: command not found"

**Cause**: CLI not installed or not in PATH

**Solution**: The composite action `.github/actions/run-idad-agent/action.yml` handles CLI installation automatically. If you see this error:

1. Verify the composite action exists:
   ```bash
   ls .github/actions/run-idad-agent/action.yml
   ```

2. Check which CLI is configured in your workflow:
   ```bash
   grep "cli:" .github/workflows/idad.yml
   ```

3. Ensure the correct API key secret is set:
   ```bash
   gh secret list | grep -E "(ANTHROPIC|CURSOR|OPENAI)"
   ```

---

### "API rate limit exceeded"

**Cause**: Too many GitHub API calls

**Solution**: Wait 1 hour or use personal access token

**Prevention**: Don't trigger too many workflows simultaneously

---

## Getting Help

### Information to Collect

When asking for help, provide:

1. **Issue/PR Number**
2. **Current State** (labels)
3. **Workflow Run ID** 
4. **Error Message** (from logs)
5. **Timeline** (when did it stop progressing?)

Example:
```
Issue: #123
Current State: idad:implementing
Last Agent: Planner (completed)
Expected: Implementer should run
Workflow Run: 20123456789
Error: [paste error from logs]
CLI: Claude Code
```

### Where to Get Help

- Check this troubleshooting guide
- Review workflow logs
- Check [WORKFLOW.md](WORKFLOW.md) for expected behavior
- Check [AGENTS.md](AGENTS.md) for agent details

---

## CLI-Specific Issues

### Codex-Specific Issues

**Problem**: Slash commands don't work with Codex

**This is expected behavior.** OpenAI Codex doesn't support slash commands.

**Solution**: Use `@.idad/README.md` to reference IDAD in your Codex session:
```
@.idad/README.md Create an issue for adding dark mode
```

---

**Problem**: Codex authentication fails

**Check**:
```bash
gh secret list | grep OPENAI_API_KEY
```

**Solution**:
```bash
# Re-add the OpenAI API key
gh secret set OPENAI_API_KEY
```

---

### Claude Code-Specific Issues

**Problem**: Authentication using OAuth token fails

**Solution**: You can use either `ANTHROPIC_API_KEY` (standard API key) or `ANTHROPIC_AUTH_TOKEN` (OAuth). Try switching:
```bash
# If using OAuth, try API key instead
gh secret set ANTHROPIC_API_KEY

# Get your token from claude auth status
claude auth status
```

---

### Cursor-Specific Issues

**Problem**: Cursor Agent model not found

**Solution**: Verify model names match Cursor's expected format:
```bash
# Check current model setting
gh variable list | grep IDAD_MODEL

# Update if needed (Cursor uses different model names)
gh variable set IDAD_MODEL_PLANNER --body "opus-4.5"
gh variable set IDAD_MODEL_IMPLEMENTER --body "sonnet-4.5"
```

---

## Slash Command Issues

### Problem: Slash commands not appearing

**Check**:
```bash
# Verify slash command files exist
ls .claude/commands/idad-*.md 2>/dev/null  # For Claude Code
ls .cursor/commands/idad-*.md 2>/dev/null  # For Cursor
```

**Solution**: Re-copy from source:
```bash
# Copy from .idad/commands/ to CLI-specific directory
cp .idad/commands/idad-*.md .claude/commands/   # For Claude Code
cp .idad/commands/idad-*.md .cursor/commands/   # For Cursor
```

---

### Problem: Slash command fails to execute

**Common Causes**:
- Not in a git repository
- GitHub CLI not authenticated

**Solution**:
```bash
# Verify git repo
git rev-parse --git-dir

# Check GitHub CLI auth
gh auth status

# Re-authenticate if needed
gh auth login
```

---

## Prevention Tips

### Write Clear Issues
- Specific requirements
- Clear acceptance criteria
- Realistic scope

### Monitor Progress
- Check labels periodically
- Watch for `idad:issue-needs-clarification`
- Review agent comments
- Use `/idad-monitor` slash command (Claude Code/Cursor)

### Start Small
- Test with simple issues first
- Build confidence before complex features
- Learn the workflow patterns

### Use Opt-In Wisely
- Only add `idad:issue-review` when ready
- Remove the label to pause if needed
- Can always work manually

---

**Last Updated**: 2025-12-12
**Phase**: 11 - Unified Label System
