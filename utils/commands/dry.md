---
description: Find DRY violations - duplicated logic, repeated patterns, refactoring opportunities
---

# DRY Audit

Scan codebase for DRY (Don't Repeat Yourself) violations. Works with any language.

## Process

1. **Scan** the codebase (or `$ARGUMENTS` path if provided)
2. **Identify** duplication patterns by severity
3. **Report** findings with file locations and line numbers
4. **Recommend** concrete refactoring with effort estimates

## Detection Categories

### 🔴 HIGH - Identical Logic
- Copy-pasted blocks (>10 lines)
- Identical functions with different names
- Repeated query/SQL construction
- Duplicate error handling blocks
- Same validation logic in multiple places

### 🟠 MEDIUM - Similar Patterns
- Functions with >60% overlapping logic
- Repeated parameter extraction/validation
- Similar data transformation flows
- Duplicate handler/endpoint patterns
- Repeated filter/builder patterns

### 🟡 LOW - Minor Repetition
- Magic numbers/strings that should be constants
- Similar logging patterns
- Repeated type conversions
- Duplicate import groupings

## What to Look For

### Function-Level
- Same logic with different function names
- Functions that differ only in 1-2 lines
- Helper functions that could be generalized

### Pattern-Level
- Repeated try-except structures
- Similar list comprehensions
- Duplicate dict/object construction
- Repeated conditional chains

### Data-Level
- Same SQL/query patterns
- Repeated JSON parsing with error handling
- Similar API response building
- Duplicate validation rules

## Output Format

```markdown
## Summary
- HIGH: X findings (~Y lines reducible)
- MEDIUM: X findings
- LOW: X findings

## Findings

### [SEVERITY] Description
**Files:** path/file.py:L10-25, path/other.py:L30-45
**Pattern:** [brief description]
**Code:**
```python
# duplicated snippet
```
**Refactor:** Extract to `helper_name()` in `utils/`
**Effort:** LOW/MEDIUM/HIGH

## Priority Tiers

### Tier 1 - Quick Wins (1-2h each)
- [finding with highest impact/effort ratio]

### Tier 2 - Medium Impact
- [findings worth doing]

### Tier 3 - Nice to Have
- [low priority items]
```

## Arguments

`$ARGUMENTS` - Optional: directory path to scope scan (e.g., `src/` or `handlers/`)
