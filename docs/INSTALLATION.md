# IDAD Installation Guide

Complete guide to installing and configuring IDAD in your repository.

---

## Table of Contents

1. [New Repository (Template)](#new-repository-template)
2. [Existing Repository](#existing-repository)
3. [Prerequisites](#prerequisites)
4. [Installation Steps](#installation-steps)
5. [Configuration](#configuration)
6. [Verification](#verification)
7. [Troubleshooting](#troubleshooting)

---

## New Repository (Template)

The fastest way to get started with IDAD!

### Step 1: Use Template

1. Go to [github.com/kidrecursive/idad](https://github.com/kidrecursive/idad)
2. Click **"Use this template"**
3. Choose **"Create a new repository"**
4. Name your repository
5. Click **"Create repository"**

### Step 2: Clone Repository

```bash
git clone https://github.com/your-username/your-repo.git
cd your-repo
```

### Step 3: Add CLI to PATH

```bash
# Temporary (current session only)
export PATH="$PATH:$(pwd)/.idad/bin"

# Permanent (add to shell profile)
echo "export PATH=\"\$PATH:$PWD/.idad/bin\"" >> ~/.zshrc
# Or for bash:
echo "export PATH=\"\$PATH:$PWD/.idad/bin\"" >> ~/.bashrc

# Reload shell
source ~/.zshrc  # or source ~/.bashrc
```

### Step 4: Run Setup

```bash
idad setup
```

### Step 5: Add Cursor API Key

```bash
gh secret set CURSOR_API_KEY
# Paste your key from https://cursor.com/settings
```

### Step 6: Done!

```bash
# Create your first issue
idad new "Add your feature"
```

**Total time**: < 5 minutes ✅

---

## Existing Repository

Add IDAD to an existing project.

### Step 1: Download IDAD Files

**Option A: Manual Download**

Download these directories and files from [github.com/kidrecursive/idad](https://github.com/kidrecursive/idad):

```
.cursor/                # Agent definitions and rules
.github/workflows/      # Workflow files
.github/idad/           # IDAD documentation
```

**Option B: Git Subtree** (Advanced)

```bash
git subtree add \
  --prefix=idad-files \
  https://github.com/kidrecursive/idad.git main \
  --squash

# Then move files to correct locations
mv idad-files/.cursor .
mv idad-files/.github .
rm -rf idad-files
```

**Option C: Direct Clone**

```bash
# In a temporary directory
git clone https://github.com/kidrecursive/idad.git idad-temp
cd idad-temp

# Copy files to your repository
cp -r .cursor /path/to/your/repo/
cp -r .github /path/to/your/repo/

# Clean up
cd ..
rm -rf idad-temp
```

### Step 2: Add CLI to PATH

```bash
cd /path/to/your/repo

# Temporary
export PATH="$PATH:$(pwd)/.idad/bin"

# Permanent
echo "export PATH=\"\$PATH:$PWD/.idad/bin\"" >> ~/.zshrc
source ~/.zshrc
```

### Step 3: Run Setup

```bash
idad setup
```

### Step 4: Configure Secrets

```bash
gh secret set CURSOR_API_KEY
```

### Step 5: Test

```bash
idad new "Test IDAD integration"
idad watch 1
```

---

## Prerequisites

### Required

1. **Git** (version 2.0+)
   ```bash
   git --version
   ```
   Install: https://git-scm.com/downloads

2. **GitHub CLI** (version 2.0+)
   ```bash
   gh --version
   ```
   Install: https://cli.github.com/

3. **GitHub Repository** with admin access
   - Public or private
   - GitHub Actions enabled

4. **Cursor API Key**
   - Get from: https://cursor.com/settings
   - Required for AI agent execution

5. **GitHub App** (for automation)
   - Create at: https://github.com/settings/apps
   - See setup instructions below

### Optional

6. **Shell**: bash or zsh (macOS/Linux)
   - Windows: Use Git Bash or WSL

6. **Editor**: Any (Cursor IDE recommended)

---

## Installation Steps

### 1. Install GitHub CLI

**macOS:**
```bash
brew install gh
```

**Linux:**
```bash
curl -sS https://webi.sh/gh | sh
```

**Windows:**
```bash
winget install GitHub.cli
```

**Verify:**
```bash
gh --version
```

### 2. Authenticate GitHub CLI

```bash
gh auth login
```

Follow prompts:
- Choose: GitHub.com
- Protocol: HTTPS or SSH
- Authenticate: Browser or Token

**Verify:**
```bash
gh auth status
```

### 3. Clone/Create Repository

**Option A: Template**
```bash
gh repo create your-repo --template kidrecursive/idad --public
git clone https://github.com/your-username/your-repo.git
cd your-repo
```

**Option B: Existing Repo**
```bash
cd your-existing-repo
# Download IDAD files (see above)
```

### 4. Add IDAD CLI to PATH

**Method 1: Shell Profile (Permanent)**

```bash
# For zsh (macOS default)
echo 'export PATH="$PATH:/path/to/your/repo/.idad/bin"' >> ~/.zshrc
source ~/.zshrc

# For bash
echo 'export PATH="$PATH:/path/to/your/repo/.idad/bin"' >> ~/.bashrc
source ~/.bashrc
```

**Method 2: Symlink (Global)**

```bash
sudo ln -s /path/to/your/repo/.idad/bin/idad /usr/local/bin/idad
```

**Method 3: Session Only**

```bash
export PATH="$PATH:/path/to/your/repo/.idad/bin"
```

**Verify:**
```bash
idad version
# Should output: idad version 1.0.0
```

### 5. Run Repository Setup

```bash
idad setup
```

This creates:
- 17 IDAD labels
- GitHub Actions permissions
- Branch protection rules

**Expected Output:**
```
🤖 IDAD Repository Setup

ℹ️  Repository: your-username/your-repo

======================================================================
  IDAD Repository Setup
  Repository: your-username/your-repo
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

✅ Setup complete!

Next steps:
  1. Add CURSOR_API_KEY to repository secrets
     gh secret set CURSOR_API_KEY

  2. Create your first issue:
     idad new "Add welcome message"

  3. Learn more:
     idad docs quickstart
```

### 6. Add GitHub App and API Credentials

#### Create the GitHub App

1. Go to [GitHub App Settings](https://github.com/settings/apps/new)
2. Fill in:
   - **Name**: `IDAD Automation`
   - **Homepage URL**: `https://github.com/your-username/your-repo`
   - **Webhook**: Uncheck "Active"
3. Set **Repository Permissions**:
   - Contents: Read and Write
   - Issues: Read and Write
   - Pull requests: Read and Write
   - Actions: Read and Write
   - Workflows: Read and Write
4. Click **"Create GitHub App"**
5. Note the **App ID** displayed on the page
6. Scroll to "Private keys" and click **"Generate a private key"**
7. Save the downloaded `.pem` file

#### Install the App

1. Go to your app's settings
2. Click **"Install App"**
3. Select **"Only select repositories"**
4. Choose your repository
5. Click **"Install"**

#### Add Secrets

```bash
# Add App ID
gh secret set IDAD_APP_ID
# Enter the numeric App ID when prompted

# Add Private Key (from .pem file)
gh secret set IDAD_APP_PRIVATE_KEY < ~/Downloads/your-app-name.YYYY-MM-DD.private-key.pem

# Add Cursor API key
gh secret set CURSOR_API_KEY
# Paste your key from https://cursor.com/settings
```

**Verify:**
```bash
gh secret list
# Should show: IDAD_APP_ID, IDAD_APP_PRIVATE_KEY, CURSOR_API_KEY
```

---

## Configuration

### GitHub Actions Permissions

Verify in: Settings → Actions → General

**Workflow permissions:**
- ✅ Read and write permissions
- ✅ Allow GitHub Actions to create and approve pull requests

### Branch Protection

Verify in: Settings → Branches → Branch protection rules (main)

**Required:**
- ✅ Require pull request before merging
- ✅ Require approvals: 1
- ✅ Require status checks to pass: `test`
- ❌ Require branches to be up to date: Not required

### Labels

Verify labels exist:

```bash
gh label list
```

**Should include:**
- `idad:auto` (opt-in trigger)
- `type:*` (feature, bug, documentation, epic, question, infrastructure)
- `state:*` (issue-review, ready, planning, implementing, robot-review, robot-docs, human-review)
- `needs-clarification`, `needs-changes`

---

## Verification

### 1. Check CLI Installation

```bash
idad version
# Output: idad version 1.0.0

idad help
# Should show help text
```

### 2. Check GitHub Setup

```bash
# In repository
gh repo view

# Check labels
gh label list | grep -E "(idad|type:|state:)"

# Check workflows
ls .github/workflows/
# Should show: idad.yml, dispatcher.yml, ci.yml

# Check agents
ls .cursor/agents/
# Should show 7 agent .md files
```

### 3. Test with Example Issue

```bash
idad new "Test IDAD installation"

# When prompted:
Type: feature
Description:
This is a test issue to verify IDAD is working correctly.
[Ctrl+D]

# Watch it work
idad watch 1
```

**Expected:**
- Issue created with `idad:auto` label
- Dispatcher workflow runs
- Issue Review Agent executes
- Labels change: `state:issue-review` → `state:ready`
- Planner Agent executes
- Implementation plan added to issue

**If this works**, IDAD is installed correctly! ✅

---

## Troubleshooting

### CLI Not Found

**Problem:** `idad: command not found`

**Solution:**
```bash
# Check PATH
echo $PATH | grep idad

# If not in PATH, add it
export PATH="$PATH:/path/to/your/repo/.idad/bin"

# Make permanent
echo 'export PATH="$PATH:/path/to/your/repo/.idad/bin"' >> ~/.zshrc
source ~/.zshrc

# Or use full path
/path/to/your/repo/.idad/bin/idad help
```

### GitHub CLI Not Authenticated

**Problem:** `gh: not authenticated`

**Solution:**
```bash
gh auth login
# Follow prompts to authenticate
```

### Setup Script Fails

**Problem:** Permission errors during `idad setup`

**Solution:**
```bash
# Check you're in repository root
pwd

# Check you have admin access
gh repo view --json viewerPermission

# Run with explicit repo
curl -fsSL https://raw.githubusercontent.com/kidrecursive/idad/main/install.sh | bash owner/repo
```

### Workflows Not Running

**Problem:** Created issue but nothing happens

**Solution:**
```bash
# 1. Check label
gh issue view 1 --json labels
# Should have idad:auto

# 2. Check workflows
gh run list --limit 5
# Should show recent runs

# 3. Check Actions enabled
gh repo view --json hasIssuesEnabled,hasWikiEnabled

# 4. Manually trigger
idad trigger issue-review 1
```

### Missing Agent Files

**Problem:** Agent definition files not found

**Solution:**
```bash
# Check files exist
ls -la .cursor/agents/

# Should have:
# - issue-review.md
# - planner.md
# - implementer.md
# - reviewer.md
# - documenter.md
# - idad.md
# - reporting.md

# If missing, re-download from template
```

---

## Platform-Specific Notes

### macOS

- Default shell: zsh (use `~/.zshrc`)
- GitHub CLI: Install via Homebrew
- No issues expected

### Linux

- Default shell: bash (use `~/.bashrc`)
- GitHub CLI: Install via package manager
- May need to install `jq` for CLI tool

### Windows

- Use Git Bash or WSL (Windows Subsystem for Linux)
- PowerShell support: Limited (bash script)
- Recommended: Use WSL with Ubuntu

---

## Uninstallation

To remove IDAD:

```bash
# 1. Remove from PATH
# Edit ~/.zshrc or ~/.bashrc and remove idad PATH line

# 2. Delete files
rm -rf .cursor
rm -rf .github/idad
rm .github/workflows/idad.yml
rm .github/workflows/ci.yml

# 3. Delete labels (optional)
gh label delete "idad:auto"
# ... repeat for all idad labels

# 4. Remove secrets
gh secret delete IDAD_APP_ID
gh secret delete IDAD_APP_PRIVATE_KEY
gh secret delete CURSOR_API_KEY

# 5. Uninstall GitHub App (optional)
# Go to https://github.com/settings/installations
# Find IDAD Automation and click "Configure" → "Uninstall"

# 6. Delete GitHub App (optional)
# Go to https://github.com/settings/apps
# Find IDAD Automation and click "Edit" → "Delete GitHub App"

# 7. Remove branch protection (optional)
# Via GitHub UI: Settings → Branches
```

---

## Next Steps

After installation:

1. **Read Quick Start**: `idad docs quickstart`
2. **Create First Issue**: `idad new "Your feature"`
3. **Read Workflow Guide**: `idad docs workflow`
4. **Explore Commands**: `idad help`

---

**Installation Time**: 5-10 minutes  
**Difficulty**: Easy  
**Requirements**: Git, GitHub CLI, GitHub App, Cursor API key

**Need help?** Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

**Version**: 1.0.0  
**Last Updated**: 2025-12-09
