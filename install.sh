#!/bin/bash
################################################################################
# IDAD Installer
################################################################################
#
# Install IDAD (Issue Driven Agentic Development) into any repository.
#
# USAGE:
#   curl -fsSL https://raw.githubusercontent.com/kidrecursive/idad-cursor/main/install.sh | bash
#
# Or with options:
#   curl -fsSL https://raw.githubusercontent.com/kidrecursive/idad-cursor/main/install.sh | bash -s -- --branch main --cli cursor
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
IDAD_REPO="kidrecursive/idad-cursor"
IDAD_BRANCH="main"
CLI_TYPE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --branch)
      IDAD_BRANCH="$2"
      shift 2
      ;;
    --cli)
      CLI_TYPE="$2"
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

# CLI Selection
if [ -z "$CLI_TYPE" ]; then
  echo -e "${BLUE}▶ Select your AI CLI tool:${NC}"
  echo ""
  echo "  1) cursor  - Cursor Agent CLI (cursor-agent)"
  echo "  2) claude  - Claude Code CLI (Anthropic)"
  echo ""
  echo -n "Enter choice [1]: "
  read CLI_CHOICE
  
  case "$CLI_CHOICE" in
    2|claude)
      CLI_TYPE="claude"
      ;;
    *)
      CLI_TYPE="cursor"
      ;;
  esac
fi

# Set CLI-specific variables
case "$CLI_TYPE" in
  claude)
    CONFIG_DIR=".claude"
    WORKFLOW_FILE="idad-claude.yml"
    API_KEY_SECRET="ANTHROPIC_API_KEY"
    API_KEY_URL="https://console.anthropic.com/settings/keys"
    API_KEY_NAME="Anthropic API"
    RULES_EXT="md"
    CLI_DISPLAY="Claude Code"
    ;;
  *)
    CLI_TYPE="cursor"
    CONFIG_DIR=".cursor"
    WORKFLOW_FILE="idad-cursor.yml"
    API_KEY_SECRET="CURSOR_API_KEY"
    API_KEY_URL="https://cursor.com/settings"
    API_KEY_NAME="Cursor API"
    RULES_EXT="mdc"
    CLI_DISPLAY="Cursor Agent"
    ;;
esac

echo -e "  ${GREEN}✓${NC} Selected: ${CLI_DISPLAY}"
echo ""

# Check for existing IDAD installation
if [ -d "$CONFIG_DIR/agents" ] || [ -d ".cursor/agents" ] || [ -d ".claude/agents" ] || [ -f ".github/workflows/idad.yml" ]; then
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

# Clone just the src files we need (sparse checkout)
git clone --depth 1 --filter=blob:none --sparse \
  "https://github.com/${IDAD_REPO}.git" \
  --branch "$IDAD_BRANCH" \
  "$TEMP_DIR/idad" 2>/dev/null || \
git clone --depth 1 --filter=blob:none --sparse \
  "git@github.com:${IDAD_REPO}.git" \
  --branch "$IDAD_BRANCH" \
  "$TEMP_DIR/idad" 2>/dev/null

cd "$TEMP_DIR/idad"
git sparse-checkout set src 2>/dev/null
cd - > /dev/null

echo -e "  ${GREEN}✓${NC} Downloaded from ${IDAD_REPO}@${IDAD_BRANCH}"

# Copy files
echo -e "${BLUE}▶ Installing files...${NC}"

# Create directories
mkdir -p "$CONFIG_DIR/agents"
mkdir -p "$CONFIG_DIR/rules"
mkdir -p .github/workflows

# Copy agent definitions
cp -r "$TEMP_DIR/idad/src/agents/"* "$CONFIG_DIR/agents/"
echo -e "  ${GREEN}✓${NC} $CONFIG_DIR/agents/ (8 agent definitions)"

# Copy rules file (CLI-specific extension)
cp "$TEMP_DIR/idad/src/rules/system.$RULES_EXT" "$CONFIG_DIR/rules/"
echo -e "  ${GREEN}✓${NC} $CONFIG_DIR/rules/system.$RULES_EXT"

# Copy workflow (CLI-specific) - only idad.yml, CI is created by IDAD agent if needed
cp "$TEMP_DIR/idad/src/workflows/$WORKFLOW_FILE" .github/workflows/idad.yml
echo -e "  ${GREEN}✓${NC} .github/workflows/idad.yml"
echo -e "  ${YELLOW}ℹ${NC}  CI workflow will be created by IDAD agent based on your project"

# Copy CLI-specific extras
if [ "$CLI_TYPE" = "cursor" ]; then
  if [ -f "$TEMP_DIR/idad/src/cursor/README.md" ]; then
    cp "$TEMP_DIR/idad/src/cursor/README.md" "$CONFIG_DIR/"
    echo -e "  ${GREEN}✓${NC} $CONFIG_DIR/README.md"
  fi
elif [ "$CLI_TYPE" = "claude" ]; then
  if [ -f "$TEMP_DIR/idad/src/claude/CLAUDE.md" ]; then
    cp "$TEMP_DIR/idad/src/claude/CLAUDE.md" ./
    echo -e "  ${GREEN}✓${NC} CLAUDE.md"
  fi
fi

echo ""

# Configure secrets
echo -e "${BLUE}▶ Configuring secrets...${NC}"
echo ""

# Check IDAD_APP_ID
if gh secret list --repo "$REPO" 2>/dev/null | grep -q "IDAD_APP_ID"; then
  echo -e "  ${GREEN}✓${NC} IDAD_APP_ID already configured"
else
  echo -e "${YELLOW}IDAD requires a GitHub App for automation${NC}"
  echo ""
  echo "Create a GitHub App at: ${CYAN}https://github.com/settings/apps/new${NC}"
  echo ""
  echo "Required repository permissions:"
  echo "  • Contents: Read and Write"
  echo "  • Issues: Read and Write"
  echo "  • Pull requests: Read and Write"
  echo "  • Actions: Read and Write"
  echo "  • Workflows: Read and Write"
  echo ""
  echo "After creating the app:"
  echo "  1. Generate a private key"
  echo "  2. Install the app on: ${REPO}"
  echo "  3. Note the App ID (shown on app settings page)"
  echo ""
  echo -n "Enter your App ID (or press Enter to skip): "
  read APP_ID
  
  if [ -n "$APP_ID" ]; then
    echo "$APP_ID" | gh secret set IDAD_APP_ID --repo "$REPO"
    echo -e "  ${GREEN}✓${NC} IDAD_APP_ID configured"
  else
    echo -e "  ${YELLOW}⚠${NC} IDAD_APP_ID skipped - add it later with: gh secret set IDAD_APP_ID"
  fi
fi

echo ""

# Check IDAD_APP_PRIVATE_KEY
if gh secret list --repo "$REPO" 2>/dev/null | grep -q "IDAD_APP_PRIVATE_KEY"; then
  echo -e "  ${GREEN}✓${NC} IDAD_APP_PRIVATE_KEY already configured"
else
  echo -e "${YELLOW}Enter the path to your GitHub App private key (.pem file)${NC}"
  echo ""
  echo -n "Path to .pem file (or press Enter to skip): "
  read PEM_PATH
  
  if [ -n "$PEM_PATH" ] && [ -f "$PEM_PATH" ]; then
    gh secret set IDAD_APP_PRIVATE_KEY --repo "$REPO" < "$PEM_PATH"
    echo -e "  ${GREEN}✓${NC} IDAD_APP_PRIVATE_KEY configured"
  elif [ -n "$PEM_PATH" ]; then
    echo -e "  ${RED}✗${NC} File not found: $PEM_PATH"
    echo -e "  ${YELLOW}⚠${NC} Add it later with: gh secret set IDAD_APP_PRIVATE_KEY < path/to/key.pem"
  else
    echo -e "  ${YELLOW}⚠${NC} IDAD_APP_PRIVATE_KEY skipped - add it later with: gh secret set IDAD_APP_PRIVATE_KEY < path/to/key.pem"
  fi
fi

echo ""

# Check CLI-specific API key
if gh secret list --repo "$REPO" 2>/dev/null | grep -q "$API_KEY_SECRET"; then
  echo -e "  ${GREEN}✓${NC} $API_KEY_SECRET already configured"
else
  echo -e "${YELLOW}IDAD uses ${CLI_DISPLAY} for AI agent execution${NC}"
  echo ""
  echo "Get your API key at: ${CYAN}${API_KEY_URL}${NC}"
  echo ""
  echo -n "Paste your ${API_KEY_NAME} key (or press Enter to skip): "
  read -s API_KEY
  echo ""
  
  if [ -n "$API_KEY" ]; then
    echo "$API_KEY" | gh secret set "$API_KEY_SECRET" --repo "$REPO"
    echo -e "  ${GREEN}✓${NC} $API_KEY_SECRET configured"
  else
    echo -e "  ${YELLOW}⚠${NC} $API_KEY_SECRET skipped - add it later with: gh secret set $API_KEY_SECRET"
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
gh label create "state:plan-review" --repo "$REPO" --color "c2e0c6" --description "Human reviewing plan" --force 2>/dev/null || true
gh label create "state:implementing" --repo "$REPO" --color "d93f0b" --description "Being implemented" --force 2>/dev/null || true
gh label create "state:robot-review" --repo "$REPO" --color "5319e7" --description "Under robot code review" --force 2>/dev/null || true
gh label create "state:robot-docs" --repo "$REPO" --color "1d76db" --description "Documenter working" --force 2>/dev/null || true
gh label create "state:human-review" --repo "$REPO" --color "e99695" --description "Ready for human review" --force 2>/dev/null || true
echo -e "  ${GREEN}✓${NC} State labels (8)"

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

git add "$CONFIG_DIR/" .github/workflows/idad.yml
if [ -f "CLAUDE.md" ]; then
  git add CLAUDE.md
fi

if git diff --staged --quiet; then
  echo -e "  ${YELLOW}⚠${NC} No changes to commit (files already exist)"
else
  git commit -m "feat: add IDAD (Issue Driven Agentic Development)

Installed via: curl -fsSL https://raw.githubusercontent.com/${IDAD_REPO}/main/install.sh | bash
CLI: ${CLI_DISPLAY}

Components:
- $CONFIG_DIR/agents/ - 8 AI agent definitions
- $CONFIG_DIR/rules/system.$RULES_EXT - System context
- .github/workflows/idad.yml - Main workflow

Note: CI workflow will be created by IDAD agent based on your project's needs."

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
echo -e "${GREEN}║     CLI: ${CLI_DISPLAY}                                        ${NC}"
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
echo -e "   ${YELLOW}https://github.com/${IDAD_REPO}#readme${NC}"
echo ""
