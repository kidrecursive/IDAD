#!/bin/bash
################################################################################
# IDAD Local Agent Runner
################################################################################
#
# Run an IDAD agent locally for testing or debugging.
#
# Usage:
#   ./.idad/run.sh <agent> [issue-number] [pr-number]
#
# Examples:
#   ./.idad/run.sh planner 123
#   ./.idad/run.sh implementer 123 456
#   IDAD_CLI=cursor ./.idad/run.sh reviewer "" 456
#
################################################################################

set -e

AGENT=$1
ISSUE=${2:-""}
PR=${3:-""}
CLI=${IDAD_CLI:-claude}

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_FILE="${SCRIPT_DIR}/agents/${AGENT}.md"
RULES_FILE="${SCRIPT_DIR}/rules/system.md"

# Validate agent
if [[ -z "$AGENT" ]]; then
  echo -e "${RED}Error: Agent name required${NC}"
  echo ""
  echo "Usage: $0 <agent> [issue] [pr]"
  echo ""
  echo "Available agents:"
  ls "${SCRIPT_DIR}/agents/"*.md 2>/dev/null | xargs -n1 basename | sed 's/.md$//' | sed 's/^/  /'
  exit 1
fi

if [[ ! -f "$AGENT_FILE" ]]; then
  echo -e "${RED}Error: Unknown agent '${AGENT}'${NC}"
  echo ""
  echo "Available agents:"
  ls "${SCRIPT_DIR}/agents/"*.md 2>/dev/null | xargs -n1 basename | sed 's/.md$//' | sed 's/^/  /'
  exit 1
fi

# Get repo info
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")
if [[ -z "$REPO" ]]; then
  echo -e "${YELLOW}Warning: Could not detect repository${NC}"
fi

# Export environment
export ISSUE PR REPO
export RUN_ID="local-$(date +%s)"

echo -e "${GREEN}IDAD Local Agent Runner${NC}"
echo "────────────────────────────────────────"
echo "  Agent:  $AGENT"
echo "  CLI:    $CLI"
echo "  Issue:  ${ISSUE:-none}"
echo "  PR:     ${PR:-none}"
echo "  Repo:   ${REPO:-unknown}"
echo "────────────────────────────────────────"
echo ""
echo -e "${YELLOW}Warning: Local runs don't have GitHub App permissions.${NC}"
echo -e "${YELLOW}Some operations may fail. Use for testing only.${NC}"
echo ""

# Run agent
if [[ "$CLI" == "cursor" ]]; then
  echo -e "${GREEN}Running with Cursor Agent...${NC}"
  echo ""
  cursor-agent \
    -f "$RULES_FILE" \
    -f "$AGENT_FILE" \
    -p "Execute your responsibilities now."

elif [[ "$CLI" == "codex" ]]; then
  echo -e "${GREEN}Running with OpenAI Codex...${NC}"
  echo ""

  # Codex uses AGENTS.md for system instructions
  # Copy rules to AGENTS.md in current directory for discovery
  ORIG_DIR=$(pwd)
  cp "$RULES_FILE" "$ORIG_DIR/AGENTS.md"
  trap "rm -f '$ORIG_DIR/AGENTS.md'" EXIT

  codex exec \
    --full-auto \
    --ask-for-approval never \
    "$(cat "$AGENT_FILE")

Execute your responsibilities now."

else
  echo -e "${GREEN}Running with Claude Code...${NC}"
  echo ""
  claude \
    --system-prompt "$(cat "$RULES_FILE")" \
    --print \
    -p "$(cat "$AGENT_FILE")

Execute your responsibilities now."
fi
