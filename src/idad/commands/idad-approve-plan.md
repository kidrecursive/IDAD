---
description: Review and approve an IDAD implementation plan
allowed-tools: Bash(gh issue:*), Bash(gh api:*)
argument-hint: <issue number>
---

You are helping review and approve an IDAD implementation plan.

## Context

@.idad/README.md

## User Request

Review plan for issue: $ARGUMENTS

## Your Task

1. **Fetch the issue and plan**:
   ```bash
   gh issue view $ARGUMENTS --json number,title,body,labels,comments
   ```

2. **Verify state**:
   - Confirm the issue has `idad:human-plan-review` label
   - If not, explain current state and what's needed

3. **Present the plan**:
   - Extract the implementation plan from the Planner agent's comment
   - Summarize key points:
     - What will be built
     - Files to be created/modified
     - Testing approach
     - Any risks or considerations

4. **Ask for decision**:
   - **Approve**: Proceed with implementation
   - **Request changes**: Specify what needs to change
   - **Reject**: Close or restart planning

5. **Execute the decision**:

   For approval:
   ```bash
   gh issue comment $ARGUMENTS --body "LGTM - approved for implementation"
   gh issue edit $ARGUMENTS --remove-label "idad:human-plan-review" --add-label "idad:implementing"
   ```

   For changes:
   ```bash
   gh issue comment $ARGUMENTS --body "<feedback>"
   # Label stays as idad:human-plan-review, planner will process comment
   ```

   For rejection:
   ```bash
   gh issue comment $ARGUMENTS --body "Rejecting this plan: <reason>"
   gh issue edit $ARGUMENTS --remove-label "idad:human-plan-review" --add-label "idad:planning"
   # Or close the issue if abandoning
   ```

6. **Confirm action**:
   - Explain what will happen next
   - Provide link to issue
