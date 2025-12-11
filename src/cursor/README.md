# Cursor Agent Configuration

This directory contains agent definitions and rules for the IDAD (Issue Driven Agentic Development) system.

## Structure

```
.cursor/
├── rules/               # Shared context rules
│   └── system.mdc       # Core IDAD system context
├── agents/              # Agent definition files
│   ├── issue-review.md  # Issue Review Agent
│   ├── planner.md       # Planner Agent
│   ├── implementer.md   # Implementer Agent
│   ├── security-scanner.md  # Security Scanner Agent (NEW)
│   ├── reviewer.md      # Reviewer Agent
│   ├── documenter.md    # Documenter Agent
│   ├── idad.md          # IDAD Self-Improvement Agent
│   └── reporting.md     # Reporting Agent
└── README.md            # This file
```

## Rules

The `rules/` directory contains shared context that's loaded for all agents:

- **system.mdc**: Core IDAD context including:
  - Agent chain and responsibilities
  - Git and GitHub CLI operations
  - Labels system
  - Agentlog format
  - Error handling patterns

## Agent Definition Files

Each agent has a dedicated markdown file in the `agents/` directory that defines:
- Agent purpose and responsibilities
- Trigger conditions
- Input/output specifications
- Decision logic
- Success criteria
- Error handling
- Examples

## Agent Chain

```
Issue (idad:auto) → Issue Review → Planner → Implementer → Security Scanner → [CI] → Reviewer → Documenter → Human
```

| Agent | Purpose | Triggers Next |
|-------|---------|---------------|
| Issue Review | Refine & classify issues | Planner |
| Planner | Create implementation plan | Implementer |
| Implementer | Write code & tests | Security Scanner |
| Security Scanner | Check for vulnerabilities | (CI runs automatically) |
| Reviewer | Code review | Documenter |
| Documenter | Update documentation | (end - human review) |
| IDAD | System self-improvement | (creates PR if needed) |
| Reporting | Generate metrics | (creates report issue) |

## Usage in Workflows

Agents are invoked via the unified `idad.yml` workflow:

```yaml
cursor-agent \
  --model "$MODEL" \
  -f ".cursor/rules/system.mdc" \
  -f ".cursor/agents/${AGENT}.md" \
  -p "Process according to agent definition..."
```

The workflow provides:
- Agent-specific definition file
- System context from rules/system.mdc
- Event context and environment variables
- GitHub API access (via GitHub App token)
- Cursor AI access (CURSOR_API_KEY)

## Model Configuration

Models can be configured per agent via repository variables:

```bash
gh variable set IDAD_MODEL_PLANNER --body "opus-4.5"
gh variable set IDAD_MODEL_IMPLEMENTER --body "sonnet-4.5"
```

| Variable | Default | Agent |
|----------|---------|-------|
| IDAD_MODEL_PLANNER | opus-4.5 | Planner |
| IDAD_MODEL_IMPLEMENTER | sonnet-4.5 | Implementer |
| IDAD_MODEL_REVIEWER | sonnet-4.5 | Reviewer |
| IDAD_MODEL_SECURITY | sonnet-4.5 | Security Scanner |
| IDAD_MODEL_DOCUMENTER | sonnet-4.5 | Documenter |
| IDAD_MODEL_ISSUE_REVIEW | sonnet-4.5 | Issue Review |
| IDAD_MODEL_IDAD | opus-4.5 | IDAD |
| IDAD_MODEL_DEFAULT | sonnet-4.5 | All others |

## Development

When creating or updating agent definitions:

1. Keep agent-specific logic in agent files
2. Reference common operations from rules/system.mdc
3. Test changes using feature branches
4. Document any special cases or exceptions
5. Update rules/system.mdc if new common patterns emerge

---

**Part of**: IDAD (Issue Driven Agentic Development)  
**Last Updated**: 2025-12-09
