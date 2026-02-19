---
description: Gather decisions via structured questions with tradeoff analysis
argument-hint: [optional topic]
---

# Decision Gathering

## Context

Topic: $ARGUMENTS

If no topic provided, analyze the current conversation to identify what decisions need to be made based on:
- Recent discussion points
- Unresolved design questions
- Implementation choices mentioned
- Any ambiguities or multiple valid approaches discussed

This works in both **plan mode** (gathering requirements before implementation) and **execution mode** (making decisions during implementation).

## Process

For each decision point identified:

### Step 1: Analyze
- What is the decision that needs to be made?
- What are the constraints and requirements?
- What context from the conversation or codebase is relevant?

### Step 2: Present (before asking)
For each question, provide:

**Question Context:**
- Clear explanation of what we're deciding
- Why this decision matters
- Key assumptions being made

**Options Analysis:**
For each option:
- What it means in practice
- Pros and tradeoffs
- When you'd choose this option
- Any implications for other parts of the system

**Recommendation (if any):**
- Which option I'd suggest and why
- Mark it with "(Recommended)" in the options

### Step 3: Ask
Use the `AskUserQuestion` tool with:
- A concise header (max 12 chars)
- Clear question text
- 2-4 well-defined options with descriptions
- Set `multiSelect: true` only if choices aren't mutually exclusive

### Step 4: Record
After each answer, acknowledge the choice and note any implications.

## Output

After all questions are answered, provide:
1. **Summary of Decisions** - All choices made in a compact list
2. **Next Steps** - What to do with these decisions (update docs, implement, etc.)
3. **Dependencies** - Any decisions that affect or depend on each other
