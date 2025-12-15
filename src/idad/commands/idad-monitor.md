---
description: Monitor IDAD workflow runs and check issue/PR status
allowed-tools: Bash(gh run:*), Bash(gh issue:*), Bash(gh pr:*)
argument-hint: [issue or PR number]
---

You are helping monitor IDAD workflow status.

## Context

@.idad/README.md

## User Request

Monitor status for: $ARGUMENTS

## Your Task

1. **Identify what to check**:
   - If a number is provided, determine if it's an issue or PR
   - If no number, show recent IDAD workflow runs

2. **Gather status information**:

   For recent runs:
   ```bash
   gh run list --workflow=idad.yml --limit 10
   ```

   For a specific issue:
   ```bash
   gh issue view <number> --json number,title,state,labels,comments
   ```

   For a specific PR:
   ```bash
   gh pr view <number> --json number,title,state,labels,headRefName,reviews,comments
   ```

   For workflow runs on an issue/PR:
   ```bash
   gh run list --workflow=idad.yml | grep -E "(issue|pr).*<number>"
   ```

3. **Interpret the status**:
   - Check the current `idad:*` label to understand workflow state
   - Identify if waiting for human action
   - Note any failed runs or errors

4. **Provide a summary**:
   - Current state in the workflow
   - What's happening or what's needed
   - Link to view details (workflow run URL, issue/PR URL)

## Status Labels Reference

| Label | State | Action Needed |
|-------|-------|---------------|
| `idad:issue-review` | Issue being analyzed | Wait |
| `idad:issue-needs-clarification` | Questions pending | Answer questions |
| `idad:planning` | Plan being created | Wait |
| `idad:human-plan-review` | Plan ready | Review and approve |
| `idad:implementing` | Code being written | Wait |
| `idad:security-scan` | Security check | Wait |
| `idad:code-review` | AI reviewing code | Wait |
| `idad:documenting` | Docs being updated | Wait |
| `idad:human-pr-review` | PR ready | Review and merge |
