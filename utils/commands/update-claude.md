---
description: update CLAUDE.md based on conversation discoveries
---

# Update CLAUDE.md

Update CLAUDE.md with new facts, keeping it compact and high-signal.

## Core Actions
- Extract new/changed technical facts from conversation
- Prioritize P0 (architecture) → P5 (history)
- Remove obsolete/duplicate/low-value content with high conviction
- Target 80%+ info density per section
- Verify facts with file references

## Update Process
### 1) Extract
- New systems/patterns/APIs
- Corrections
- Redundant/conflicting content
- FAQs missing from CLAUDE.md

### 2) Place
- If topic exists: update section
- Else: add under best parent

### 3) Write
**New sections**
- Place under highest P0–P2 parent
- Use ## / ### hierarchy
- Lead with bullets/tables
- Examples only if non-obvious

**Updates**
- Keep structure if it fits
- Remove contradicted statements
- Compress prose to bullets/tables
- Add file path refs

**Removals (high conviction)**
- Contradicted by current facts
- Deprecated (verified)
- Duplicates better section
- >50 tokens for <P3