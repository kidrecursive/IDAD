#!/bin/bash
################################################################################
# IDAD Installer
################################################################################
#
# Install IDAD (Issue Driven Agentic Development) into any repository.
#
# USAGE:
#   curl -fsSL https://raw.githubusercontent.com/kidrecursive/idad/main/install.sh | bash
#
# Or with options:
#   curl -fsSL https://raw.githubusercontent.com/kidrecursive/idad/main/install.sh | bash -s -- --branch main
#
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Config
IDAD_REPO="kidrecursive/idad"
IDAD_BRANCH="main"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --branch)
      IDAD_BRANCH="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                                                                ║${NC}"
echo -e "${CYAN}║   ${GREEN}IDAD - Issue Driven Agentic Development${CYAN}                    ║${NC}"
echo -e "${CYAN}║   ${NC}cursor-agent implementation${CYAN}                                 ║${NC}"
echo -e "${CYAN}║                                                                ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check prerequisites
echo -e "${BLUE}▶ Checking prerequisites...${NC}"

if ! command -v git &> /dev/null; then
  echo -e "${RED}✗ git is required but not installed${NC}"
  exit 1
fi
echo -e "  ${GREEN}✓${NC} git"

if ! command -v gh &> /dev/null; then
  echo -e "${RED}✗ GitHub CLI (gh) is required but not installed${NC}"
  echo "  Install: https://cli.github.com/"
  exit 1
fi
echo -e "  ${GREEN}✓${NC} gh CLI"

if ! gh auth status &> /dev/null; then
  echo -e "${RED}✗ GitHub CLI not authenticated${NC}"
  echo "  Run: gh auth login"
  exit 1
fi
echo -e "  ${GREEN}✓${NC} gh authenticated"

# Check we're in a git repository
if ! git rev-parse --git-dir &> /dev/null; then
  echo -e "${RED}✗ Not in a git repository${NC}"
  echo "  Run this from the root of your repository"
  exit 1
fi
echo -e "  ${GREEN}✓${NC} git repository"

# Get repository info
REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null || echo "")
if [ -z "$REPO" ]; then
  echo -e "${YELLOW}⚠ Could not detect repository from gh CLI${NC}"
  echo -n "Enter repository (owner/repo): "
  read REPO
fi
echo -e "  ${GREEN}✓${NC} Repository: ${REPO}"

echo ""

# Check for existing IDAD installation
if [ -d ".cursor/agents" ] || [ -f ".github/workflows/idad.yml" ]; then
  echo -e "${YELLOW}⚠ IDAD files already exist in this repository${NC}"
  echo -n "Overwrite? (y/N): "
  read OVERWRITE
  if [[ ! "$OVERWRITE" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
  fi
  echo ""
fi

# Download IDAD files
echo -e "${BLUE}▶ Downloading IDAD files...${NC}"

TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Clone just the files we need (sparse checkout)
git clone --depth 1 --filter=blob:none --sparse \
  "git@github.com:${IDAD_REPO}.git" \
  --branch "$IDAD_BRANCH" \
  "$TEMP_DIR/idad" 2>/dev/null

cd "$TEMP_DIR/idad"
git sparse-checkout set .cursor .github/workflows 2>/dev/null
cd - > /dev/null

echo -e "  ${GREEN}✓${NC} Downloaded from ${IDAD_REPO}@${IDAD_BRANCH}"

# Copy files
echo -e "${BLUE}▶ Installing files...${NC}"

# Create directories
mkdir -p .cursor/agents
mkdir -p .cursor/rules
mkdir -p .github/workflows

# Copy agent definitions
cp -r "$TEMP_DIR/idad/.cursor/agents/"* .cursor/agents/
echo -e "  ${GREEN}✓${NC} .cursor/agents/ (8 agent definitions)"

# Copy rules
cp -r "$TEMP_DIR/idad/.cursor/rules/"* .cursor/rules/
echo -e "  ${GREEN}✓${NC} .cursor/rules/system.mdc"

# Copy workflows
cp "$TEMP_DIR/idad/.github/workflows/idad.yml" .github/workflows/
cp "$TEMP_DIR/idad/.github/workflows/ci.yml" .github/workflows/
echo -e "  ${GREEN}✓${NC} .github/workflows/ (idad.yml, ci.yml)"

# Copy .cursor README
if [ -f "$TEMP_DIR/idad/.cursor/README.md" ]; then
  cp "$TEMP_DIR/idad/.cursor/README.md" .cursor/
fi

echo ""

# Configure secrets
echo -e "${BLUE}▶ Configuring secrets...${NC}"
echo ""

# Check IDAD_PAT
if gh secret list --repo "$REPO" 2>/dev/null | grep -q "IDAD_PAT"; then
  echo -e "  ${GREEN}✓${NC} IDAD_PAT already configured"
else
  echo -e "${YELLOW}IDAD requires a Fine-Grained Personal Access Token (PAT)${NC}"
  echo ""
  echo "Create one at: ${CYAN}https://github.com/settings/tokens?type=beta${NC}"
  echo ""
  echo "Required permissions:"
  echo "  • Contents: Read and Write"
  echo "  • Issues: Read and Write"
  echo "  • Pull requests: Read and Write"
  echo "  • Actions: Read and Write"
  echo "  • Workflows: Read and Write"
  echo ""
  echo "Repository access: Only select repositories → ${REPO}"
  echo ""
  echo -n "Paste your PAT (or press Enter to skip): "
  read -s PAT_TOKEN
  echo ""
  
  if [ -n "$PAT_TOKEN" ]; then
    echo "$PAT_TOKEN" | gh secret set IDAD_PAT --repo "$REPO"
    echo -e "  ${GREEN}✓${NC} IDAD_PAT configured"
  else
    echo -e "  ${YELLOW}⚠${NC} IDAD_PAT skipped - add it later with: gh secret set IDAD_PAT"
  fi
fi

echo ""

# Check CURSOR_API_KEY
if gh secret list --repo "$REPO" 2>/dev/null | grep -q "CURSOR_API_KEY"; then
  echo -e "  ${GREEN}✓${NC} CURSOR_API_KEY already configured"
else
  echo -e "${YELLOW}IDAD uses Cursor for AI agent execution${NC}"
  echo ""
  echo "Get your API key at: ${CYAN}https://cursor.com/settings${NC}"
  echo ""
  echo -n "Paste your Cursor API key (or press Enter to skip): "
  read -s CURSOR_KEY
  echo ""
  
  if [ -n "$CURSOR_KEY" ]; then
    echo "$CURSOR_KEY" | gh secret set CURSOR_API_KEY --repo "$REPO"
    echo -e "  ${GREEN}✓${NC} CURSOR_API_KEY configured"
  else
    echo -e "  ${YELLOW}⚠${NC} CURSOR_API_KEY skipped - add it later with: gh secret set CURSOR_API_KEY"
  fi
fi

echo ""

# Create labels
echo -e "${BLUE}▶ Creating labels...${NC}"

# Type labels
gh label create "type:issue" --repo "$REPO" --color "0366d6" --description "Standard issue" --force 2>/dev/null || true
gh label create "type:epic" --repo "$REPO" --color "0366d6" --description "Epic with child issues" --force 2>/dev/null || true
gh label create "type:bug" --repo "$REPO" --color "d73a4a" --description "Bug fix" --force 2>/dev/null || true
gh label create "type:documentation" --repo "$REPO" --color "7057ff" --description "Documentation update" --force 2>/dev/null || true
gh label create "type:question" --repo "$REPO" --color "cc317c" --description "Question or discussion" --force 2>/dev/null || true
gh label create "type:infrastructure" --repo "$REPO" --color "fbca04" --description "Infrastructure changes" --force 2>/dev/null || true
echo -e "  ${GREEN}✓${NC} Type labels (6)"

# State labels
gh label create "state:issue-review" --repo "$REPO" --color "bfdadc" --description "Under issue review" --force 2>/dev/null || true
gh label create "state:ready" --repo "$REPO" --color "0e8a16" --description "Ready for planning" --force 2>/dev/null || true
gh label create "state:planning" --repo "$REPO" --color "fbca04" --description "Being planned" --force 2>/dev/null || true
gh label create "state:implementing" --repo "$REPO" --color "d93f0b" --description "Being implemented" --force 2>/dev/null || true
gh label create "state:robot-review" --repo "$REPO" --color "5319e7" --description "Under robot code review" --force 2>/dev/null || true
gh label create "state:robot-docs" --repo "$REPO" --color "1d76db" --description "Documenter working" --force 2>/dev/null || true
gh label create "state:human-review" --repo "$REPO" --color "e99695" --description "Ready for human review" --force 2>/dev/null || true
echo -e "  ${GREEN}✓${NC} State labels (7)"

# Control labels
gh label create "idad:auto" --repo "$REPO" --color "c5def5" --description "Enable IDAD automation (opt-in)" --force 2>/dev/null || true
gh label create "needs-clarification" --repo "$REPO" --color "d93f0b" --description "Needs human clarification" --force 2>/dev/null || true
gh label create "needs-changes" --repo "$REPO" --color "d93f0b" --description "Changes requested" --force 2>/dev/null || true
echo -e "  ${GREEN}✓${NC} Control labels (3)"

echo ""

# Configure permissions
echo -e "${BLUE}▶ Configuring repository...${NC}"

gh api repos/${REPO}/actions/permissions/workflow -X PUT \
  -F default_workflow_permissions=write \
  -F can_approve_pull_request_reviews=true 2>/dev/null && \
  echo -e "  ${GREEN}✓${NC} Workflow permissions" || \
  echo -e "  ${YELLOW}⚠${NC} Could not set workflow permissions (may need admin access)"

echo ""

# Commit files
echo -e "${BLUE}▶ Committing IDAD files...${NC}"

git add .cursor/ .github/workflows/idad.yml .github/workflows/ci.yml

if git diff --staged --quiet; then
  echo -e "  ${YELLOW}⚠${NC} No changes to commit (files already exist)"
else
  git commit -m "feat: add IDAD (Issue Driven Agentic Development)

Installed via: curl -fsSL https://raw.githubusercontent.com/${IDAD_REPO}/main/install.sh | bash

Components:
- .cursor/agents/ - 8 AI agent definitions
- .cursor/rules/system.mdc - System context
- .github/workflows/idad.yml - Main workflow
- .github/workflows/ci.yml - CI template"

  echo -e "  ${GREEN}✓${NC} Changes committed"
  
  echo ""
  echo -n "Push to remote? (Y/n): "
  read PUSH_CONFIRM
  if [[ ! "$PUSH_CONFIRM" =~ ^[Nn]$ ]]; then
    git push
    echo -e "  ${GREEN}✓${NC} Pushed to remote"
  fi
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                                ║${NC}"
echo -e "${GREEN}║   ✓ IDAD Installation Complete!                               ║${NC}"
echo -e "${GREEN}║                                                                ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Next steps:${NC}"
echo ""
echo "1. Create your first automated issue:"
echo -e "   ${YELLOW}gh issue create --title 'My feature' --label 'idad:auto' --body 'Description'${NC}"
echo ""
echo "2. Watch the agents work:"
echo -e "   ${YELLOW}gh run list --workflow=idad.yml --limit 5${NC}"
echo ""
echo "3. Read the docs:"
echo -e "   ${YELLOW}https://github.com/kidrecursive/idad/blob/main/docs/QUICKSTART.md${NC}"
echo ""
