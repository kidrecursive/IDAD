# IDAD Quick Start Guide

Get up and running with IDAD in under 5 minutes!

---

## What is IDAD?

**IDAD (Issue Driven Agentic Development)** is a self-improving, AI-driven GitHub automation system where AI agents automatically:

1. 📝 Review and refine your issues
2. 🗺️ Create implementation plans
3. 💻 Write code and tests
4. ✅ Run CI and review code
5. 📚 Update documentation
6. 🔄 Improve themselves

You create an issue → AI agents deliver a ready-to-merge PR!

---

## Prerequisites

- GitHub repository with admin access
- [GitHub CLI](https://cli.github.com/) installed
- [Cursor API key](https://cursor.com/settings)

---

## 5-Minute Setup

### Step 1: Install IDAD CLI

Add the IDAD CLI to your PATH:

```bash
# From your repository root
export PATH="$PATH:$(pwd)/.idad/bin"

# Or add to your shell profile for permanent access
echo 'export PATH="$PATH:/path/to/your/repo/.idad/bin"' >> ~/.zshrc
# (or ~/.bashrc for bash)
```

Verify installation:

```bash
idad version
```

### Step 2: Run Setup

```bash
idad setup
```

This will:
- ✅ Create 17 IDAD labels
- ✅ Configure GitHub Actions permissions
- ✅ Set up branch protection

### Step 3: Add Cursor API Key

Get your key from [cursor.com/settings](https://cursor.com/settings), then:

```bash
gh secret set CURSOR_API_KEY
# Paste your key when prompted
```

### Step 4: Create Your First Issue

```bash
idad new "Add welcome message"
```

You'll be prompted for:
- **Type**: feature (press Enter for default)
- **Description**: Describe what you want (press Ctrl+D when done)

Example:
```
Type: [feature/bug/documentation/epic] (default: feature)
[Press Enter]

Description (press Ctrl+D when done):
---
Add a simple welcome message function that greets users by name.

Requirements:
- Function should take a name parameter
- Return "Hello, [name]!"
- Handle empty/null input gracefully
[Press Ctrl+D]
```

### Step 5: Watch It Work! 🎉

```bash
# Watch progress live
idad watch 1

# Or check status
idad status 1
```

Within ~6-10 minutes, you'll have:
- ✅ Refined issue with clear requirements
- ✅ Detailed implementation plan
- ✅ Complete code with tests
- ✅ Pull request ready for review
- ✅ Updated documentation

---

## What Happens Next?

The IDAD agents work through your issue automatically:

```
Issue Created (#1)
    ↓
Issue Review Agent (30-60s)
    ├─ Refines requirements
    ├─ Classifies type
    └─ Marks as ready
    ↓
Planner Agent (1-2 min)
    ├─ Creates implementation plan
    ├─ Breaks down into steps
    ├─ Creates feature branch
    └─ Waits for your approval
    ↓
👤 You Review the Plan
    ├─ Comment "looks good" to approve
    └─ Or describe changes you want
    ↓
Implementer Agent (1-3 min)
    ├─ Writes code
    ├─ Creates comprehensive tests
    ├─ Creates pull request
    └─ Pushes commits
    ↓
CI Workflow (< 1 min)
    └─ Runs tests
    ↓
Reviewer Agent (30-90s)
    ├─ Reviews code quality
    ├─ Checks requirements
    └─ Approves (or requests changes)
    ↓
Documenter Agent (30-90s)
    ├─ Updates README
    ├─ Adds examples
    └─ Finalizes PR
    ↓
Ready for Your Review! 🎉
```

### Your Turn

1. **Review the plan** - Check the implementation approach
2. **Approve the plan** - Comment "looks good" or similar
3. **Wait for code** - Implementer writes the code
4. **Review the PR** - Check the code and docs
5. **Merge it** - When you're happy with it
6. **Done!** - Feature is live

---

## Common Commands

### Creating Issues

```bash
# Interactive creation
idad new "Your feature title"

# View all active issues
idad list

# Check specific issue status
idad status 123
```

### Monitoring

```bash
# Watch issue progress live
idad watch 123

# List all active IDAD issues
idad list

# View workflow logs
idad logs <run-id>
```

### Manual Control

```bash
# Pause automation
idad pause 123

# Resume automation
idad resume 123

# Retry current step
idad retry 123

# Manually trigger specific agent
idad trigger planner 123
```

### Documentation

```bash
# Quick start (this guide)
idad docs quickstart

# Complete workflow guide
idad docs workflow

# Agent reference
idad docs agents

# Troubleshooting
idad docs troubleshooting

# Operations manual
idad docs operations
```

---

## Example: Full Workflow

Let's create a real feature:

```bash
# 1. Create issue
idad new "Add user authentication"

# When prompted:
Type: feature
Description:
Add basic user authentication with email/password.

Requirements:
- User registration endpoint
- Login endpoint
- Password hashing
- JWT token generation
- Input validation
[Ctrl+D]

# Output:
✅ Issue #47 created!

Watch progress:
  idad watch 47
  idad status 47

# 2. Watch it work
idad watch 47

# You'll see:
# - Issue Review Agent refines requirements (1 min)
# - Planner Agent creates implementation plan (2 min)
# - Implementer Agent writes code and tests (3 min)
# - CI runs tests (1 min)
# - Reviewer Agent reviews code (1 min)
# - Documenter Agent updates docs (1 min)

# 3. Review and merge
gh pr view 48 --web
gh pr merge 48 --squash

# Done! Feature is live.
```

---

## Tips for Success

### Write Clear Issues

✅ **Good:**
```
Title: Add email validation
Description:
Validate email addresses on user registration.

Requirements:
- Check format (regex)
- Check MX records
- Return clear error messages

Acceptance Criteria:
- Invalid emails rejected
- Valid emails accepted
- Informative error messages
```

❌ **Not Great:**
```
Title: Fix emails
Description: Emails don't work
```

### Use Labels Wisely

- `idad:auto` - **Required** for automation
- `type:feature` - Auto-added by Issue Review Agent
- `state:*` - Track progress automatically

### Monitor Progress

```bash
# Quick status check
idad status

# Live monitoring
idad watch 123

# Check workflows
gh run list --limit 5
```

### Pause When Needed

```bash
# Need to make manual changes?
idad pause 123
# Make your changes
idad resume 123
```

---

## Troubleshooting

### Issue: Nothing happens after creating issue

**Check:**
1. Does issue have `idad:auto` label?
2. Are workflows running? `gh run list`
3. Is `CURSOR_API_KEY` set? `gh secret list`

**Fix:**
```bash
# Add label if missing
gh issue edit 123 --add-label "idad:auto"

# Manually trigger
idad trigger issue-review 123
```

### Issue: Workflow stuck

**Check:**
```bash
# View recent runs
gh run list --limit 5

# Check logs
idad logs <run-id>
```

**Fix:**
```bash
# Retry current step
idad retry 123
```

### Issue: Want to make manual changes

```bash
# Pause automation
idad pause 123

# Make your changes
# ... edit issue, add comments, etc ...

# Resume when ready
idad resume 123
```

---

## Next Steps

### Learn More

- **[Complete Workflow Guide](WORKFLOW.md)** - Detailed walkthrough
- **[Agent Reference](AGENTS.md)** - All agents documented
- **[Troubleshooting](TROUBLESHOOTING.md)** - Problem solving
- **[Operations Manual](OPERATIONS.md)** - Repository management

### Advanced Usage

- **Epic Features** - Break large features into sub-issues
- **System Reports** - `idad report weekly`
- **Custom Workflows** - Modify agents for your needs
- **Self-Improvement** - IDAD automatically improves itself

### Get Help

- 📚 **Read the docs**: `idad docs workflow`
- 🔍 **Search issues**: Check if others had similar problems
- 💬 **Ask questions**: Create an issue without `idad:auto`

---

## What You've Learned

✅ Install and setup IDAD  
✅ Create your first automated issue  
✅ Monitor workflow progress  
✅ Review and merge automated PRs  
✅ Use CLI commands  

**You're ready to build with IDAD!** 🚀

---

**Time to complete**: < 5 minutes  
**What you get**: Fully automated development workflow  
**Next**: Create more issues and watch IDAD work!

---

**Version**: 1.0.0  
**Last Updated**: 2025-12-09
