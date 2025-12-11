# PLAN: Repository Restructure for Multi-CLI Support

## Overview

This plan outlines foundational changes to restructure the IDAD repository to:
1. Move installable/template files to a `src/` folder
2. Add support for Claude Code CLI as an alternative to Cursor

## Goals

1. **Clean Structure**: All installable files in `src/`
2. **Multi-CLI Support**: Support both `cursor-agent` and `claude` CLIs
3. **Installer Choice**: Let users choose their preferred CLI during installation

## Key Principles

- **Native Locations**: Each CLI uses its native file locations when installed
  - Cursor: `.cursor/agents/`, `.cursor/rules/`
  - Claude Code: `.claude/agents/`, `.claude/rules/`
- **Agent Parity**: Agent definition files (`.md`) are identical between CLIs
- **Workflow Differences**: The `idad.yml` workflow differs by CLI invocation
- **Reporting Flexibility**: Reporting agent may have CLI-specific variations

---

## Current Structure

```
idad-cursor/
├── .cursor/
│   ├── agents/                   # Agent definitions (8 files)
│   ├── rules/
│   │   └── system.mdc
│   └── README.md
├── .github/
│   └── workflows/
│       ├── idad.yml
│       └── ci.yml
├── docs/
├── install.sh
└── README.md
```

---

## Proposed Structure

```
idad-cursor/
├── src/                         # 📦 ALL INSTALLABLE FILES
│   ├── agents/                  # Shared agent definitions (CLI-agnostic)
│   │   ├── documenter.md
│   │   ├── idad.md
│   │   ├── implementer.md
│   │   ├── issue-review.md
│   │   ├── planner.md
│   │   ├── reporting.md
│   │   ├── reviewer.md
│   │   └── security-scanner.md
│   ├── rules/
│   │   ├── system.mdc           # Cursor format
│   │   └── system.md            # Claude format
│   ├── workflows/
│   │   ├── idad-cursor.yml      # Cursor-specific workflow
│   │   ├── idad-claude.yml      # Claude Code-specific workflow
│   │   └── ci.yml               # Shared CI template
│   ├── cursor/                  # Cursor-specific extras
│   │   └── README.md            # → .cursor/README.md
│   └── claude/                  # Claude-specific extras
│       └── CLAUDE.md            # → CLAUDE.md (optional)
│
├── docs/                        # Documentation (unchanged)
├── install.sh                   # Updated installer with CLI choice
├── README.md                    # Updated to reflect both CLIs
└── ...
```

**Note**: The `.cursor/` and `.github/workflows/` directories are removed from the repo root. They only exist in `src/` as templates.

---

## CLI Comparison

| Aspect | Cursor | Claude Code |
|--------|--------|-------------|
| **CLI Name** | `cursor-agent` | `claude` |
| **Installation** | `curl -fsSL https://cursor.com/install \| bash` | `curl -fsSL https://claude.ai/install.sh \| bash` |
| **Config Dir** | `.cursor/` | `.claude/` |
| **Agent Files** | `.cursor/agents/*.md` | `.claude/agents/*.md` |
| **Rules File** | `.cursor/rules/system.mdc` | `.claude/rules/system.md` |
| **API Key Secret** | `CURSOR_API_KEY` | `ANTHROPIC_API_KEY` |
| **API Key URL** | https://cursor.com/settings | https://console.anthropic.com/settings/keys |

### Invocation

**Cursor:**
```bash
cursor-agent \
  --model "$MODEL" \
  -f "$RULES_FILE" \
  -f "$AGENT_FILE" \
  -p "$PROMPT"
```

**Claude Code:**
```bash
claude \
  --model "$MODEL" \
  --system-prompt "$(cat $RULES_FILE)" \
  --print \
  --dangerously-skip-permissions \
  -p "$PROMPT

$(cat $AGENT_FILE)"
```

---

## Detailed Changes

### Phase 1: Create `src/` Structure

#### 1.1 Create directories
```bash
mkdir -p src/agents
mkdir -p src/rules
mkdir -p src/workflows
mkdir -p src/cursor
mkdir -p src/claude
```

#### 1.2 Move agent files
```bash
mv .cursor/agents/* src/agents/
```

#### 1.3 Move/create rules files
```bash
mv .cursor/rules/system.mdc src/rules/system.mdc
# Create Claude version (may be identical content, different extension)
cp src/rules/system.mdc src/rules/system.md
```

#### 1.4 Move workflow files
```bash
mv .github/workflows/idad.yml src/workflows/idad-cursor.yml
mv .github/workflows/ci.yml src/workflows/ci.yml
```

#### 1.5 Move cursor extras
```bash
mv .cursor/README.md src/cursor/README.md
```

#### 1.6 Clean up old directories
```bash
rm -rf .cursor
rm -rf .github/workflows
rmdir .github 2>/dev/null || true
```

---

### Phase 2: Create Claude Code Workflow

Create `src/workflows/idad-claude.yml` - similar to cursor workflow but with:
- Claude CLI installation instead of Cursor
- `ANTHROPIC_API_KEY` instead of `CURSOR_API_KEY`
- Different CLI invocation syntax
- Agent/rules files in `.claude/` instead of `.cursor/`

See full workflow in Appendix A.

---

### Phase 3: Update Installer

#### 3.1 Add CLI Selection

```bash
echo ""
echo -e "${BLUE}▶ Select your AI CLI tool:${NC}"
echo ""
echo "  1) cursor  - Cursor Agent CLI"
echo "  2) claude  - Claude Code CLI (Anthropic)"
echo ""
echo -n "Enter choice [1]: "
read CLI_CHOICE

case "$CLI_CHOICE" in
  2|claude)
    CLI_TYPE="claude"
    CONFIG_DIR=".claude"
    WORKFLOW_FILE="idad-claude.yml"
    API_KEY_SECRET="ANTHROPIC_API_KEY"
    API_KEY_URL="https://console.anthropic.com/settings/keys"
    RULES_EXT="md"
    ;;
  *)
    CLI_TYPE="cursor"
    CONFIG_DIR=".cursor"
    WORKFLOW_FILE="idad-cursor.yml"
    API_KEY_SECRET="CURSOR_API_KEY"
    API_KEY_URL="https://cursor.com/settings"
    RULES_EXT="mdc"
    ;;
esac
```

#### 3.2 Update Sparse Checkout

```bash
git sparse-checkout set src
```

#### 3.3 Update File Copy Logic

```bash
# Create native directories
mkdir -p "$CONFIG_DIR/agents"
mkdir -p "$CONFIG_DIR/rules"
mkdir -p .github/workflows

# Copy agent files
cp -r "$TEMP_DIR/idad/src/agents/"* "$CONFIG_DIR/agents/"

# Copy rules file (CLI-specific extension)
cp "$TEMP_DIR/idad/src/rules/system.$RULES_EXT" "$CONFIG_DIR/rules/"

# Copy workflow
cp "$TEMP_DIR/idad/src/workflows/$WORKFLOW_FILE" .github/workflows/idad.yml
cp "$TEMP_DIR/idad/src/workflows/ci.yml" .github/workflows/

# Copy extras
if [ "$CLI_TYPE" = "cursor" ]; then
  cp "$TEMP_DIR/idad/src/cursor/README.md" "$CONFIG_DIR/"
elif [ "$CLI_TYPE" = "claude" ]; then
  [ -f "$TEMP_DIR/idad/src/claude/CLAUDE.md" ] && cp "$TEMP_DIR/idad/src/claude/CLAUDE.md" ./
fi
```

#### 3.4 Update Secret Prompts

Use `$API_KEY_SECRET` and `$API_KEY_URL` variables set during CLI selection.

#### 3.5 Update Commit Message

```bash
git commit -m "feat: add IDAD (Issue Driven Agentic Development)

Installed via: curl -fsSL https://raw.githubusercontent.com/${IDAD_REPO}/main/install.sh | bash
CLI: $CLI_TYPE

Components:
- $CONFIG_DIR/agents/ - 8 AI agent definitions
- $CONFIG_DIR/rules/system.$RULES_EXT - System context
- .github/workflows/idad.yml - Main workflow
- .github/workflows/ci.yml - CI template"
```

---

### Phase 4: Update Documentation

#### 4.1 Update README.md
- Add CLI selection section
- Document both Cursor and Claude Code options
- Update file structure diagram

#### 4.2 Update docs/INSTALLATION.md
- Add CLI selection instructions
- Document API key setup for both CLIs

---

## Implementation Checklist

### Phase 1: Structure
- [ ] Create `src/agents/` and move all 8 agent files
- [ ] Create `src/rules/system.mdc` (move from `.cursor/rules/`)
- [ ] Create `src/rules/system.md` (Claude format)
- [ ] Create `src/workflows/idad-cursor.yml` (move from `.github/workflows/idad.yml`)
- [ ] Create `src/workflows/ci.yml` (move from `.github/workflows/`)
- [ ] Create `src/cursor/README.md` (move from `.cursor/`)
- [ ] Create `src/claude/` directory
- [ ] Remove `.cursor/` directory
- [ ] Remove `.github/workflows/` directory

### Phase 2: Claude Workflow
- [ ] Create `src/workflows/idad-claude.yml`
- [ ] Update model names for Claude (sonnet-4, opus-4)
- [ ] Update CLI invocation syntax

### Phase 3: Installer
- [ ] Add CLI selection prompt
- [ ] Update sparse checkout path
- [ ] Update file copy logic for native locations
- [ ] Update secret configuration
- [ ] Update commit message
- [ ] Test cursor installation path
- [ ] Test claude installation path

### Phase 4: Documentation
- [ ] Update README.md
- [ ] Update docs/INSTALLATION.md

---

## Appendix A: Claude Code Workflow

```yaml
name: IDAD

on:
  issues:
    types: [opened, labeled]
  pull_request:
    types: [closed]
  workflow_dispatch:
    inputs:
      agent:
        description: 'Agent to run'
        required: true
        type: choice
        options:
          - issue-review
          - planner
          - implementer
          - security-scanner
          - reviewer
          - documenter
          - idad
          - reporting
      issue:
        description: 'Issue number'
        type: string
        default: ''
      pr:
        description: 'PR number'
        type: string
        default: ''

env:
  MODEL_DEFAULT: ${{ vars.IDAD_MODEL_DEFAULT || 'sonnet-4' }}
  MODEL_PLANNER: ${{ vars.IDAD_MODEL_PLANNER || 'opus-4' }}
  MODEL_IMPLEMENTER: ${{ vars.IDAD_MODEL_IMPLEMENTER || 'sonnet-4' }}
  MODEL_REVIEWER: ${{ vars.IDAD_MODEL_REVIEWER || 'sonnet-4' }}
  MODEL_SECURITY: ${{ vars.IDAD_MODEL_SECURITY || 'sonnet-4' }}
  MODEL_DOCUMENTER: ${{ vars.IDAD_MODEL_DOCUMENTER || 'sonnet-4' }}
  MODEL_ISSUE_REVIEW: ${{ vars.IDAD_MODEL_ISSUE_REVIEW || 'sonnet-4' }}
  MODEL_IDAD: ${{ vars.IDAD_MODEL_IDAD || 'opus-4' }}

permissions:
  contents: write
  issues: write
  pull-requests: write
  actions: write
  workflows: write

concurrency:
  group: idad-${{ github.event.issue.number || github.event.pull_request.number || inputs.issue || inputs.pr || github.run_id }}
  cancel-in-progress: false

jobs:
  dispatch:
    runs-on: ubuntu-latest
    outputs:
      agent: ${{ steps.resolve.outputs.agent }}
      issue: ${{ steps.resolve.outputs.issue }}
      pr: ${{ steps.resolve.outputs.pr }}
      model: ${{ steps.resolve.outputs.model }}
      skip: ${{ steps.resolve.outputs.skip }}
    
    steps:
      - name: Get IDAD GitHub App token
        id: app-token
        uses: actions/create-github-app-token@v1
        with:
          app-id: ${{ secrets.IDAD_APP_ID }}
          private-key: ${{ secrets.IDAD_APP_PRIVATE_KEY }}

      - name: Resolve agent and context
        id: resolve
        env:
          GH_TOKEN: ${{ steps.app-token.outputs.token }}
        run: |
          # (Same dispatch logic as Cursor workflow)
          SKIP="true"
          AGENT=""
          ISSUE=""
          PR=""
          
          if [[ "${{ github.event_name }}" == "workflow_dispatch" ]]; then
            AGENT="${{ inputs.agent }}"
            ISSUE="${{ inputs.issue }}"
            PR="${{ inputs.pr }}"
            SKIP="false"
          elif [[ "${{ github.event_name }}" == "issues" && "${{ github.event.action }}" == "opened" ]]; then
            LABELS='${{ toJson(github.event.issue.labels.*.name) }}'
            if echo "$LABELS" | grep -q "idad:auto"; then
              AGENT="issue-review"
              ISSUE="${{ github.event.issue.number }}"
              SKIP="false"
            fi
          elif [[ "${{ github.event_name }}" == "issues" && "${{ github.event.action }}" == "labeled" ]]; then
            if [[ "${{ github.event.label.name }}" == "idad:auto" ]]; then
              AGENT="issue-review"
              ISSUE="${{ github.event.issue.number }}"
              SKIP="false"
            fi
          elif [[ "${{ github.event_name }}" == "pull_request" && "${{ github.event.action }}" == "closed" ]]; then
            if [[ "${{ github.event.pull_request.merged }}" == "true" ]]; then
              LABELS='${{ toJson(github.event.pull_request.labels.*.name) }}'
              BRANCH="${{ github.event.pull_request.head.ref }}"
              if [[ "$BRANCH" =~ ^idad/ ]]; then
                echo "Skipping IDAD's own branch"
              elif echo "$LABELS" | grep -q "type:infrastructure"; then
                echo "Skipping infrastructure PR"
              elif echo "$LABELS" | grep -q "idad:auto"; then
                AGENT="idad"
                PR="${{ github.event.pull_request.number }}"
                SKIP="false"
              fi
            fi
          fi
          
          case "$AGENT" in
            planner)          MODEL="${{ env.MODEL_PLANNER }}" ;;
            implementer)      MODEL="${{ env.MODEL_IMPLEMENTER }}" ;;
            reviewer)         MODEL="${{ env.MODEL_REVIEWER }}" ;;
            security-scanner) MODEL="${{ env.MODEL_SECURITY }}" ;;
            documenter)       MODEL="${{ env.MODEL_DOCUMENTER }}" ;;
            issue-review)     MODEL="${{ env.MODEL_ISSUE_REVIEW }}" ;;
            idad)             MODEL="${{ env.MODEL_IDAD }}" ;;
            *)                MODEL="${{ env.MODEL_DEFAULT }}" ;;
          esac
          
          echo "agent=$AGENT" >> $GITHUB_OUTPUT
          echo "issue=$ISSUE" >> $GITHUB_OUTPUT
          echo "pr=$PR" >> $GITHUB_OUTPUT
          echo "model=$MODEL" >> $GITHUB_OUTPUT
          echo "skip=$SKIP" >> $GITHUB_OUTPUT

  agent:
    needs: dispatch
    if: needs.dispatch.outputs.skip != 'true'
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Get IDAD GitHub App token
        id: app-token
        uses: actions/create-github-app-token@v1
        with:
          app-id: ${{ secrets.IDAD_APP_ID }}
          private-key: ${{ secrets.IDAD_APP_PRIVATE_KEY }}
      
      - name: Cache Claude Code CLI
        id: cache-claude
        uses: actions/cache@v4
        with:
          path: ~/.local
          key: ${{ runner.os }}-claude-cli-v1
          restore-keys: |
            ${{ runner.os }}-claude-cli-
      
      - name: Install Claude Code CLI
        if: steps.cache-claude.outputs.cache-hit != 'true'
        run: |
          curl -fsSL https://claude.ai/install.sh | bash
      
      - name: Add Claude to PATH
        run: echo "$HOME/.local/bin" >> $GITHUB_PATH
      
      - name: Run ${{ needs.dispatch.outputs.agent }} agent
        env:
          GH_TOKEN: ${{ steps.app-token.outputs.token }}
          GITHUB_TOKEN: ${{ steps.app-token.outputs.token }}
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
          AGENT: ${{ needs.dispatch.outputs.agent }}
          ISSUE: ${{ needs.dispatch.outputs.issue }}
          PR: ${{ needs.dispatch.outputs.pr }}
          MODEL: ${{ needs.dispatch.outputs.model }}
          REPO: ${{ github.repository }}
          RUN_ID: ${{ github.run_id }}
        run: |
          echo "============================================="
          echo "  IDAD Agent Runner (Claude Code)"
          echo "============================================="
          echo ""
          echo "🤖 Agent: $AGENT"
          echo "📋 Issue: ${ISSUE:-none}"
          echo "🔀 PR: ${PR:-none}"
          echo "🧠 Model: $MODEL"
          echo ""
          
          AGENT_FILE=".claude/agents/${AGENT}.md"
          RULES_FILE=".claude/rules/system.md"
          
          if [[ ! -f "$AGENT_FILE" ]]; then
            echo "❌ Agent file not found: $AGENT_FILE"
            exit 1
          fi
          
          if [[ ! -f "$RULES_FILE" ]]; then
            echo "❌ Rules file not found: $RULES_FILE"
            exit 1
          fi
          
          PROMPT="You are the ${AGENT} agent for IDAD.

          CONTEXT:
          - Repository: ${REPO}
          - Issue: #${ISSUE:-N/A}
          - PR: #${PR:-N/A}
          - Workflow Run: ${RUN_ID}

          INSTRUCTIONS:
          Follow your agent definition exactly. Use 'gh' CLI for all GitHub operations.
          Use 'git' for all repository operations. Post a summary comment with agentlog
          block when done. Trigger the next appropriate agent via:
            gh workflow run idad.yml -f agent=<next> -f issue=<num> -f pr=<num>

          Execute your responsibilities now.
          
          --- AGENT DEFINITION ---
          $(cat $AGENT_FILE)"
          
          claude \
            ${MODEL:+--model "$MODEL"} \
            --system-prompt "$(cat $RULES_FILE)" \
            --print \
            --dangerously-skip-permissions \
            -p "$PROMPT"
```

---

## Timeline Estimate

| Phase | Effort |
|-------|--------|
| Phase 1: Structure | 1 hour |
| Phase 2: Claude Workflow | 1-2 hours |
| Phase 3: Installer | 2 hours |
| Phase 4: Documentation | 1 hour |

**Total**: ~5-6 hours

---

## Success Criteria

1. ✅ All installable files are in `src/`
2. ✅ Installer prompts for CLI choice
3. ✅ Cursor installs to `.cursor/` with correct workflow
4. ✅ Claude installs to `.claude/` with correct workflow
5. ✅ `install.sh` works from raw GitHub URL
6. ✅ Documentation reflects both CLI options

---

*Plan created: 2024-12-11*  
*Status: READY FOR IMPLEMENTATION*
