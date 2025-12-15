---
description: Run an IDAD agent locally for testing or debugging
allowed-tools: Bash(*)
argument-hint: <agent-name> [issue-number] [pr-number]
---

You are helping run an IDAD agent locally for testing or debugging.

## Context

@.idad/README.md

## User Request

Run agent: $ARGUMENTS

## Available Agents

| Agent | Purpose |
|-------|---------|
| `issue-review` | Analyze and validate issues |
| `planner` | Create implementation plans |
| `implementer` | Write code and tests |
| `security-scanner` | Check for vulnerabilities |
| `reviewer` | Perform code review |
| `documenter` | Update documentation |
| `idad` | Create improvement issues |
| `repository-testing` | Verify IDAD installation |

## Your Task

1. **Parse the request**:
   - Agent name (required)
   - Issue number (optional)
   - PR number (optional)

2. **Validate**:
   - Check agent exists in `.idad/agents/`
   - Verify issue/PR exists if provided

3. **Confirm before running**:
   - Show which agent will run
   - Show the issue/PR context
   - Warn that this runs locally (not via GitHub Actions)
   - Ask for confirmation

4. **Run the agent**:

   Read the agent file and execute its instructions within this CLI session.
   Set up the environment first:

   ```bash
   export ISSUE=<issue> PR=<pr> REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
   ```

   Then read the agent file at `.idad/agents/<agent>.md` and follow its instructions.

5. **Important warnings**:
   - Local runs don't have GitHub App token (some operations may fail)
   - Changes made locally need to be pushed
   - This is for testing/debugging, not normal workflow
