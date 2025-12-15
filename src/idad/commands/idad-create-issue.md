---
description: Create a GitHub issue for the IDAD workflow with guided questions
allowed-tools: Bash(gh issue:*), Bash(git:*)
argument-hint: <feature or task description>
---

You are helping create a GitHub issue for the IDAD (Issue Driven Agentic Development) workflow.

## Context

Reference the IDAD documentation for workflow understanding:
@.idad/README.md

## User Request

The user wants to create an issue for: $ARGUMENTS

## Your Task

1. **Clarify the request** - Ask 2-3 focused questions to understand:
   - What exactly should be built or changed?
   - What are the acceptance criteria?
   - Are there any constraints or dependencies?

2. **Draft the issue** - Once you have enough information, draft:
   - A clear, concise title (under 60 characters)
   - A well-structured body with:
     - **Summary**: What and why
     - **Requirements**: Specific acceptance criteria
     - **Technical Notes**: Any implementation hints (optional)

3. **Create the issue** - When the user approves, run:
   ```bash
   gh issue create \
     --title "<title>" \
     --label "idad:issue-review" \
     --body "<body>"
   ```

4. **Confirm** - Provide the issue URL and explain that the IDAD workflow will now:
   - Review the issue (Issue Review Agent)
   - Create an implementation plan (Planner Agent)
   - Wait for human approval before implementing

## Guidelines

- Keep titles under 60 characters
- Use imperative mood ("Add feature" not "Adding feature")
- Be specific in requirements - vague issues lead to poor implementations
- The `idad:issue-review` label triggers the automation
