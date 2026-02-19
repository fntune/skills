---
description: Review issues against code, identify patterns, plan fixes with user decisions
argument-hint: <path-to-audit-file-or-issue-list>
---

# Issue Triage and Fix Planning

## Context

Audit/Issue Source: $ARGUMENTS

You are reviewing reported issues (from an audit, bug list, or tech debt backlog) to create a prioritized fix plan. The goal is NOT to blindly fix issues, but to:
1. Verify issues still exist in current code
2. Identify deeper patterns vs surface symptoms
3. Get user input on fix approach before implementation

## Phase 1: Verification

For each reported issue:

1. **Read the referenced code** - Never trust line numbers blindly; code changes
2. **Verify current state** - Check if issue was already fixed, partially addressed, or is a false positive
3. **Categorize**:
   - `CONFIRMED` - Issue exists as described
   - `FALSE_POSITIVE` - Code review shows this isn't actually a problem
   - `PARTIALLY_FIXED` - Issue exists but is less severe than reported
   - `OUTDATED` - Code has changed significantly, issue may not apply

Output a verification table:
| ID | Status | Finding |
|----|--------|---------|

## Phase 2: Pattern Analysis

For confirmed issues:

1. **Group by root cause** - Multiple issues may share the same underlying problem
2. **Identify architectural symptoms** - If 3+ issues point to same pattern, flag it
3. **Distinguish**:
   - **Quick fixes** - Isolated, low-risk, no design decisions needed
   - **Architectural decisions** - Affect multiple files, change contracts, need user input

Common patterns to look for:
- Polling where events would be better
- Fire-and-forget async without cleanup
- Unbounded queries/collections
- Missing error boundaries
- Duplicated logic across files

## Phase 3: Decision Gathering

For each confirmed issue or pattern group, use `/ask` to clarify approach:

**For architectural issues:**
- Bandage fix (stop bleeding) vs proper refactor
- Breaking changes acceptable?
- Shared utility vs individual fixes

**For scope decisions:**
- Fix now vs document for later
- Related issues to bundle together
- Dependencies that affect fix order

**Always present:**
- What the issue is (brief)
- Why it matters (impact)
- 2-4 options with tradeoffs
- Your recommendation

## Phase 4: Implementation Plan

After gathering decisions, output:

### Verified Issues
List only confirmed issues with their verification status.

### Pattern Groups
Group related issues that share root causes.

### Fix Order
Prioritized list considering:
1. Dependencies (foundations first)
2. Risk (high-impact issues first)
3. Efficiency (bundle related fixes)

### Work Items
For each fix:
- Files affected
- Approach decided
- Dependencies on other fixes

## Key Principles

- **Verify before fixing** - Audits can be outdated, code changes
- **Surface deeper problems** - If an issue is a symptom, say so
- **Get buy-in on approach** - Use `/ask` for any non-trivial decision
- **No bandage fixes without consent** - If user wants quick fix, confirm scope explicitly
- **Group related work** - Avoid fixing same pattern 5 times in 5 PRs
