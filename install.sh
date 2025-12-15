#!/bin/bash
################################################################################
# IDAD Installer
################################################################################
#
# Install IDAD (Issue Driven Agentic Development) into any repository.
#
# USAGE:
#   curl -fsSL https://raw.githubusercontent.com/kidrecursive/IDAD/main/install.sh | bash
#
# Or with options:
#   curl -fsSL https://raw.githubusercontent.com/kidrecursive/IDAD/main/install.sh | bash -s -- --branch main --cli cursor
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
IDAD_REPO="kidrecursive/IDAD"
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
  read REPO < /dev/tty
fi
echo -e "  ${GREEN}✓${NC} Repository: ${REPO}"

echo ""

# CLI Selection
if [ -z "$CLI_TYPE" ]; then
  echo -e "${BLUE}▶ Select your AI CLI tool:${NC}"
  echo ""
  echo "  1) claude  - Claude Code CLI (Anthropic)"
  echo "  2) cursor  - Cursor Agent CLI (cursor-agent)"
  echo "  3) codex   - OpenAI Codex CLI"
  echo ""
  echo -n "Enter choice [1]: "
  read CLI_CHOICE < /dev/tty

  case "$CLI_CHOICE" in
    2|cursor)
      CLI_TYPE="cursor"
      ;;
    3|codex)
      CLI_TYPE="codex"
      ;;
    *)
      CLI_TYPE="claude"
      ;;
  esac
fi

# Set CLI-specific variables
case "$CLI_TYPE" in
  cursor)
    COMMANDS_DIR=".cursor/commands"
    CLI_DISPLAY="Cursor Agent"
    ;;
  codex)
    COMMANDS_DIR=""  # Codex doesn't have slash commands
    CLI_DISPLAY="OpenAI Codex"
    ;;
  *)
    CLI_TYPE="claude"
    COMMANDS_DIR=".claude/commands"
    CLI_DISPLAY="Claude Code"
    ;;
esac

echo -e "  ${GREEN}✓${NC} Selected: ${CLI_DISPLAY}"
echo ""

# Check for existing IDAD installation
if [ -d ".idad" ] || [ -d ".cursor/agents" ] || [ -d ".claude/agents" ] || [ -f ".github/workflows/idad.yml" ]; then
  echo -e "${YELLOW}⚠ IDAD files already exist in this repository${NC}"
  echo -n "Overwrite? (y/N): "
  read OVERWRITE < /dev/tty
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

# Verify required files exist
if [ ! -d "$TEMP_DIR/idad/src/idad" ]; then
  echo -e "${RED}✗ Failed to download IDAD files${NC}"
  exit 1
fi

echo -e "  ${GREEN}✓${NC} Downloaded from ${IDAD_REPO}@${IDAD_BRANCH}"

# Copy files
echo -e "${BLUE}▶ Installing files...${NC}"

# Create directories
mkdir -p .idad/agents
mkdir -p .idad/rules
mkdir -p .idad/commands
mkdir -p .github/workflows
mkdir -p .github/actions/run-idad-agent
if [ -n "$COMMANDS_DIR" ]; then
  mkdir -p "$COMMANDS_DIR"
fi

# Copy IDAD files (unified .idad/ directory)
cp -r "$TEMP_DIR/idad/src/idad/agents/"* .idad/agents/
echo -e "  ${GREEN}✓${NC} .idad/agents/ (9 agent definitions)"

cp "$TEMP_DIR/idad/src/idad/rules/system.md" .idad/rules/
echo -e "  ${GREEN}✓${NC} .idad/rules/system.md"

cp "$TEMP_DIR/idad/src/idad/README.md" .idad/
echo -e "  ${GREEN}✓${NC} .idad/README.md"

# Copy slash commands to .idad/ and CLI-specific directory (if applicable)
cp "$TEMP_DIR/idad/src/idad/commands/"*.md .idad/commands/
echo -e "  ${GREEN}✓${NC} .idad/commands/ (4 slash commands)"

if [ -n "$COMMANDS_DIR" ]; then
  cp "$TEMP_DIR/idad/src/idad/commands/"*.md "$COMMANDS_DIR/"
  echo -e "  ${GREEN}✓${NC} $COMMANDS_DIR/ (slash commands for ${CLI_DISPLAY})"
else
  echo -e "  ${YELLOW}ℹ${NC}  Codex CLI doesn't support slash commands - use .idad/run.sh instead"
fi

# Copy composite action for CLI abstraction
cp "$TEMP_DIR/idad/src/actions/run-idad-agent/action.yml" .github/actions/run-idad-agent/
echo -e "  ${GREEN}✓${NC} .github/actions/run-idad-agent/ (composite action)"

# Copy unified workflow
cp "$TEMP_DIR/idad/src/workflows/idad.yml" .github/workflows/idad.yml
echo -e "  ${GREEN}✓${NC} .github/workflows/idad.yml"
echo -e "  ${YELLOW}ℹ${NC}  CI workflow will be created by IDAD agent based on your project"

echo ""

# Set IDAD_CLI variable
echo -e "${BLUE}▶ Configuring repository variables...${NC}"

gh variable set IDAD_CLI --repo "$REPO" --body "$CLI_TYPE" 2>/dev/null && \
  echo -e "  ${GREEN}✓${NC} IDAD_CLI = $CLI_TYPE" || \
  echo -e "  ${YELLOW}⚠${NC} Could not set IDAD_CLI variable (set manually: gh variable set IDAD_CLI --body \"$CLI_TYPE\")"

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
  echo -e "Create a GitHub App at: ${CYAN}https://github.com/settings/apps/new${NC}"
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
  read APP_ID < /dev/tty

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
  read PEM_PATH < /dev/tty

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

# Configure CLI-specific authentication
if [[ "$CLI_TYPE" == "claude" ]]; then
  # Claude Code supports both API key and OAuth token
  HAS_API_KEY=$(gh secret list --repo "$REPO" 2>/dev/null | grep -q "ANTHROPIC_API_KEY" && echo "yes" || echo "no")
  HAS_AUTH_TOKEN=$(gh secret list --repo "$REPO" 2>/dev/null | grep -q "ANTHROPIC_AUTH_TOKEN" && echo "yes" || echo "no")

  if [[ "$HAS_API_KEY" == "yes" ]]; then
    echo -e "  ${GREEN}✓${NC} ANTHROPIC_API_KEY already configured"
  elif [[ "$HAS_AUTH_TOKEN" == "yes" ]]; then
    echo -e "  ${GREEN}✓${NC} ANTHROPIC_AUTH_TOKEN already configured"
  else
    echo -e "${YELLOW}Claude Code supports two authentication methods:${NC}"
    echo ""
    echo "  1) API Key (ANTHROPIC_API_KEY) - Direct API access"
    echo "     Get yours at: https://console.anthropic.com/settings/keys"
    echo ""
    echo "  2) Auth Token (ANTHROPIC_AUTH_TOKEN) - OAuth/Bearer token"
    echo "     For OAuth-based authentication flows"
    echo ""
    echo -n "Which authentication method? [1=API Key, 2=Auth Token]: "
    read AUTH_CHOICE < /dev/tty

    if [[ "$AUTH_CHOICE" == "2" ]]; then
      echo -n "Paste your Auth Token (or press Enter to skip): "
      read -s AUTH_TOKEN < /dev/tty
      echo ""
      if [ -n "$AUTH_TOKEN" ]; then
        echo "$AUTH_TOKEN" | gh secret set ANTHROPIC_AUTH_TOKEN --repo "$REPO"
        echo -e "  ${GREEN}✓${NC} ANTHROPIC_AUTH_TOKEN configured"
      else
        echo -e "  ${YELLOW}⚠${NC} Auth token skipped - add it later with: gh secret set ANTHROPIC_AUTH_TOKEN"
      fi
    else
      echo -n "Paste your API Key (or press Enter to skip): "
      read -s API_KEY < /dev/tty
      echo ""
      if [ -n "$API_KEY" ]; then
        echo "$API_KEY" | gh secret set ANTHROPIC_API_KEY --repo "$REPO"
        echo -e "  ${GREEN}✓${NC} ANTHROPIC_API_KEY configured"
      else
        echo -e "  ${YELLOW}⚠${NC} API key skipped - add it later with: gh secret set ANTHROPIC_API_KEY"
      fi
    fi
  fi
elif [[ "$CLI_TYPE" == "cursor" ]]; then
  # Cursor uses CURSOR_API_KEY
  if gh secret list --repo "$REPO" 2>/dev/null | grep -q "CURSOR_API_KEY"; then
    echo -e "  ${GREEN}✓${NC} CURSOR_API_KEY already configured"
  else
    echo -e "${YELLOW}Cursor Agent requires an API key${NC}"
    echo ""
    echo -e "Get your API key at: ${CYAN}https://cursor.com/settings${NC}"
    echo ""
    echo -n "Paste your Cursor API key (or press Enter to skip): "
    read -s API_KEY < /dev/tty
    echo ""

    if [ -n "$API_KEY" ]; then
      echo "$API_KEY" | gh secret set CURSOR_API_KEY --repo "$REPO"
      echo -e "  ${GREEN}✓${NC} CURSOR_API_KEY configured"
    else
      echo -e "  ${YELLOW}⚠${NC} CURSOR_API_KEY skipped - add it later with: gh secret set CURSOR_API_KEY"
    fi
  fi
else
  # Codex uses OPENAI_API_KEY
  if gh secret list --repo "$REPO" 2>/dev/null | grep -q "OPENAI_API_KEY"; then
    echo -e "  ${GREEN}✓${NC} OPENAI_API_KEY already configured"
  else
    echo -e "${YELLOW}OpenAI Codex requires an API key${NC}"
    echo ""
    echo -e "Get your API key at: ${CYAN}https://platform.openai.com/api-keys${NC}"
    echo ""
    echo -n "Paste your OpenAI API key (or press Enter to skip): "
    read -s API_KEY < /dev/tty
    echo ""

    if [ -n "$API_KEY" ]; then
      echo "$API_KEY" | gh secret set OPENAI_API_KEY --repo "$REPO"
      echo -e "  ${GREEN}✓${NC} OPENAI_API_KEY configured"
    else
      echo -e "  ${YELLOW}⚠${NC} OPENAI_API_KEY skipped - add it later with: gh secret set OPENAI_API_KEY"
    fi
  fi
fi

echo ""

# Create labels
echo -e "${BLUE}▶ Creating labels...${NC}"

# IDAD workflow labels (9 total)
gh label create "idad:issue-review" --repo "$REPO" --color "c5def5" --description "Issue Review Agent analyzing" --force 2>/dev/null || true
gh label create "idad:issue-needs-clarification" --repo "$REPO" --color "d93f0b" --description "Issue needs human clarification" --force 2>/dev/null || true
gh label create "idad:planning" --repo "$REPO" --color "fbca04" --description "Planner Agent creating plan" --force 2>/dev/null || true
gh label create "idad:human-plan-review" --repo "$REPO" --color "c2e0c6" --description "Human reviewing implementation plan" --force 2>/dev/null || true
gh label create "idad:implementing" --repo "$REPO" --color "d93f0b" --description "Implementer Agent writing code" --force 2>/dev/null || true
gh label create "idad:security-scan" --repo "$REPO" --color "5319e7" --description "Security Scanner analyzing PR" --force 2>/dev/null || true
gh label create "idad:code-review" --repo "$REPO" --color "5319e7" --description "Reviewer Agent reviewing PR" --force 2>/dev/null || true
gh label create "idad:documenting" --repo "$REPO" --color "1d76db" --description "Documenter Agent updating docs" --force 2>/dev/null || true
gh label create "idad:human-pr-review" --repo "$REPO" --color "e99695" --description "Final human review before merge" --force 2>/dev/null || true
echo -e "  ${GREEN}✓${NC} IDAD labels (9)"

echo ""

# Configure permissions
echo -e "${BLUE}▶ Configuring repository...${NC}"

gh api repos/${REPO}/actions/permissions/workflow -X PUT \
  -F default_workflow_permissions=write \
  -F can_approve_pull_request_reviews=true 2>/dev/null && \
  echo -e "  ${GREEN}✓${NC} Workflow permissions" || \
  echo -e "  ${YELLOW}⚠${NC} Could not set workflow permissions (may need admin access)"

echo ""

# Branch protection
echo -e "${BLUE}▶ Branch protection${NC}"
echo ""
echo "IDAD works best with branch protection on 'main' to require PRs"
echo "and prevent direct pushes or force pushes."
echo ""
echo -n "Configure branch protection now? (y/N): "
read PROTECT_BRANCH < /dev/tty

if [[ "$PROTECT_BRANCH" =~ ^[Yy]$ ]]; then
  # Get default branch
  DEFAULT_BRANCH=$(gh repo view --json defaultBranchRef -q '.defaultBranchRef.name' 2>/dev/null || echo "main")

  # Use JSON input for proper type handling
  if gh api repos/${REPO}/branches/${DEFAULT_BRANCH}/protection -X PUT \
    -H "Accept: application/vnd.github+json" \
    --input - 2>/dev/null <<EOF
{
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": false,
    "require_code_owner_reviews": false,
    "required_approving_review_count": 1
  },
  "enforce_admins": null,
  "restrictions": null,
  "required_status_checks": null,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_linear_history": false,
  "lock_branch": false,
  "allow_fork_syncing": true
}
EOF
  then
    echo -e "  ${GREEN}✓${NC} Branch protection enabled on '${DEFAULT_BRANCH}'"
  else
    echo -e "  ${YELLOW}⚠${NC} Could not set branch protection (may need admin access)"
  fi
else
  echo -e "  ${YELLOW}⚠${NC} Skipped - configure manually in repository settings"
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
echo "1. Review and commit the IDAD files:"
if [ -n "$COMMANDS_DIR" ]; then
  echo -e "   ${YELLOW}git add .idad/ $COMMANDS_DIR/ .github/ && git commit -m 'feat: add IDAD'${NC}"
else
  echo -e "   ${YELLOW}git add .idad/ .github/ && git commit -m 'feat: add IDAD'${NC}"
fi
echo ""
echo "2. Push and merge to main (workflows must be in main to trigger):"
echo -e "   ${YELLOW}git push && gh pr create --fill && gh pr merge --auto --squash${NC}"
echo -e "   Or if on main: ${YELLOW}git push${NC}"
echo ""
echo "3. Install your GitHub App on this repository:"
echo -e "   ${YELLOW}https://github.com/settings/apps${NC} → Your App → Install App → Select ${REPO}"
echo ""
if [ -n "$COMMANDS_DIR" ]; then
  echo "4. Try the slash commands locally:"
  echo -e "   ${YELLOW}/idad-create-issue Add a new feature${NC}"
  echo -e "   ${YELLOW}/idad-monitor${NC}"
else
  echo "4. Reference the IDAD README in your Codex session:"
  echo -e "   ${YELLOW}@.idad/README.md Create an issue for adding a new feature${NC}"
fi
echo ""
echo "5. Create your first automated issue:"
echo -e "   ${YELLOW}gh issue create --title 'My feature' --label 'idad:issue-review' --body 'Description'${NC}"
echo ""
echo "6. Watch the agents work:"
echo -e "   ${YELLOW}gh run list --workflow=idad.yml --limit 5${NC}"
echo ""
echo "7. Read the docs:"
echo -e "   ${YELLOW}https://github.com/${IDAD_REPO}#readme${NC}"
echo ""
