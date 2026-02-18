---
name: design-exploration
description: Generate multiple visual design variants of a page using parallel agents. Use when the user wants to explore design directions, create design variants, or says "generate N designs." Triggers on "design exploration", "design variants", "parallel designs", "design sprint".
argument-hint: <source-page-path> [count]
---

# Design Exploration

Generate N distinct visual design variants of a page by spawning parallel opus agents. Each variant is a **single self-contained page.tsx file** with a unique aesthetic direction, preserving the source page's copy.

**Arguments:** `$ARGUMENTS`

Parse arguments to extract:
- `sourcePath` — path to the source page file (required)
- `count` — number of designs to generate (optional, will ask if not provided)

---

## Phase 1 — Context

Read the source page file and understand:

1. **Copy** — All text content (headings, body, CTAs, labels). This MUST be preserved exactly in every variant.
2. **Sections** — The logical structure (hero, features, testimonials, CTA, footer, etc.)
3. **Dependencies** — What packages the file imports (framer-motion, lucide-react, next/image, etc.). Variants should use the same dependencies — do not introduce new npm packages.
4. **Framework** — Confirm it's a Next.js App Router page (or adapt if not).

Determine the output directory:
- Default: sibling `designs/` folder next to the source file (e.g., `app/designs/` for `app/page.tsx`)
- If a `designs/` directory already exists with numbered variants, continue numbering from the highest existing number + 1

Check what design variants already exist (if any) and report them to the user.

---

## Phase 2 — Directions

Ask the user how they want to direct the designs:

**Option A — User provides directions:**
If the user specifies aesthetic directions (e.g., "minimalist", "brutalist", "dark luxury"), use those.

**Option B — User provides just a count:**
Ask: "Want to define each direction, or should I generate diverse ones?"
- If "generate" / "surprise me": produce N distinct directions spanning different design schools
- If they want to define: collect their directions

**Option C — No count provided:**
Ask how many variants they want (suggest 5-10 as a sweet spot for exploration).

**Generating diverse directions:**
When generating directions automatically, ensure maximum variety. No two directions should converge on similar choices. Vary across ALL of these axes simultaneously:

- **Layout**: single-column vs multi-column vs asymmetric vs grid-based vs horizontal scroll vs diagonal flow vs overlapping sections
- **Typography**: serif-heavy vs geometric sans vs mono vs mixed vs display fonts vs hand-drawn — NEVER default to generic fonts (Inter, Roboto, Arial, system fonts). Choose distinctive, characterful fonts. Pair a display font with a refined body font.
- **Color**: monochrome vs bold accent vs gradient-heavy vs earth tones vs neon vs muted pastels vs high-contrast duotone — dominant colors with sharp accents outperform timid, evenly-distributed palettes
- **Theme**: light vs dark vs mixed — vary between them across directions
- **Density**: airy/minimal vs dense/editorial vs balanced
- **Era/Movement**: Swiss/International vs Art Deco vs Y2K vs Brutalist vs Contemporary minimal vs Japanese vs Bauhaus vs Mid-century vs Psychedelic vs Cyberpunk vs Organic/Natural vs Industrial
- **Animation**: static vs subtle micro-interactions vs dramatic staggered reveals vs parallax vs scroll-triggered vs hover surprises
- **Spatial composition**: unexpected layouts, asymmetry, overlap, grid-breaking elements, generous negative space OR controlled density
- **Atmosphere**: gradient meshes, noise textures, geometric patterns, layered transparencies, dramatic shadows, grain overlays, decorative borders

Each direction should be a 2-3 sentence brief that commits to a BOLD aesthetic, e.g.:
> "**Swiss Modernism** — Rigid 12-column grid with strong vertical rhythm. Neue Haas Grotesk headings, crisp geometric hierarchy. Pure black + white + signal red accent. Zero gradients, zero shadows, maximum whitespace."

> "**Dark Maximalist** — Deep charcoal canvas with layered translucent panels and neon accent bleeds. Dramatic staggered entrance animations on scroll. Space Mono headers, tight letter-spacing, overwhelming density that rewards exploration."

---

## Phase 3 — Generation

Each variant is a **single self-contained `page.tsx` file**. No additional files, no external stylesheets, no shared components. Everything lives in one file.

Spawn N parallel Task agents to create the variants.

**For each variant, launch:**

```
Task tool:
  subagent_type: task-executor
  model: opus
  run_in_background: true
  description: "Design variant {NN}"
  prompt: [see agent prompt template below]
```

**IMPORTANT:** Launch ALL agents in a single message to maximize parallelism.

### Agent Prompt Template

For each agent, provide this prompt (fill in the bracketed values):

````
You are creating a design variant for a Next.js page. Your goal is to produce a distinctive, production-grade page that avoids generic "AI slop" aesthetics.

## Source Page
Read this file first: {sourcePath}

## Design Direction
{directionBrief}

## Output
Write a single file: {outputDir}/design-{NN}/page.tsx

This file must be COMPLETELY SELF-CONTAINED. Everything goes in this one file:
- All components (define them in the same file, above the default export)
- All styles (Tailwind classes or inline styles — no external CSS)
- All animations (CSS keyframes via inline style tags, or framer-motion)
- All constants, data arrays, configuration

No other files. No shared components. No external stylesheets. One file, one page.

## Hard Constraints
1. **Preserve ALL copy exactly** — every heading, paragraph, label, CTA, and piece of text from the source must appear in your variant. Do not rewrite, shorten, or omit any text.
2. **Same dependencies only** — Only import packages the source file uses: {dependencyList}. Do not add new npm packages.
3. **TypeScript strict** — Must compile with strict TypeScript (`noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`). Use proper types, no `any`.
4. **App Router conventions** — Default export. Add `"use client"` directive if using hooks or interactivity.
5. **Mobile responsive** — Must work well on mobile, tablet, and desktop.

## Design Principles

### Think Before Coding
Before writing code, commit to a BOLD aesthetic:
- What makes this design UNFORGETTABLE? What's the one thing someone will remember?
- The design direction should be unmistakable from the first viewport — not a subtle variation, a genuinely different visual experience.

### Typography
Choose fonts that are beautiful, unique, and interesting. NEVER use generic fonts like Arial, Inter, Roboto, or system fonts. Pick distinctive, characterful choices that elevate the page. Pair a display font with a refined body font. Use Google Fonts via `@import` in an inline `<style>` tag, or `next/font/google`.

### Color & Theme
Commit to a cohesive palette. Use CSS variables for consistency. Dominant colors with sharp accents outperform timid, evenly-distributed palettes. Make color choices that reinforce the aesthetic — not safe defaults.

### Motion & Animation
Focus on high-impact moments: one well-orchestrated page load with staggered reveals (`animation-delay`) creates more delight than scattered micro-interactions. Use scroll-triggering and hover states that surprise. For CSS animations, embed `@keyframes` in an inline `<style>` tag. For complex motion, use framer-motion (if available in source deps).

### Spatial Composition
Unexpected layouts. Asymmetry. Overlap. Diagonal flow. Grid-breaking elements. Generous negative space OR controlled density — match the aesthetic direction.

### Backgrounds & Atmosphere
Create depth rather than defaulting to flat solid colors. Use gradient meshes, noise textures, geometric patterns, layered transparencies, dramatic shadows, grain overlays — whatever fits the direction.

### Match Complexity to Vision
Maximalist designs need elaborate code with extensive animations and effects. Minimalist designs need restraint, precision, and careful attention to spacing, typography, and subtle details. Elegance comes from executing the vision fully.

## Process
1. Read the source file completely
2. Extract all text content — you will preserve every word
3. Commit to a strong visual concept for the direction
4. Build the complete page: layout, typography system, color palette, spacing, animations
5. Write everything into a single page.tsx file
6. Verify all source text is present in your output
````

### Monitoring

After launching all agents, inform the user:
- "Spawned {N} design agents in background. Working on: {list of directions}"
- Read the output files as agents complete
- Report completion status

---

## Phase 4 — Navigation

Check if a navigator component already exists:

1. Look for `{outputDir}/nav.tsx` — if it exists and uses the `DesignNav` pattern (Cmd+J/K), skip this phase entirely
2. Look for a provider component that auto-discovers `design-*/page.tsx` directories — if it exists, skip

If no navigator exists, create these two files (the ONLY non-page.tsx files this skill creates):

### `{outputDir}/nav.tsx` — Client component
A floating pill with Cmd+J (next) / Cmd+K (previous) keyboard navigation:
- Fixed bottom-right position
- Shows current design label and arrow buttons
- Wraps around at both ends
- Dark semi-transparent background with backdrop blur
- Accepts `routes: { path: string; label: string }[]` prop

### Provider component (sibling to output dir or in nearest layout)
A server component that:
- Reads the `{outputDir}` directory at build time
- Finds all `design-*/page.tsx` directories
- Sorts numerically
- Includes the home page as first route
- Passes routes to `DesignNav`

### Wire into layout
- Import the provider in the nearest `layout.tsx`
- Render it inside `<body>` after `{children}`

**If the project already has this pattern (check for existing DesignNav imports in layout files), adapt to the existing structure rather than creating duplicate components.**

---

## Phase 5 — Verify

Run the project's build command to verify all variants compile:

```bash
pnpm build
```

**If build fails:**
1. Parse errors to identify which design files have issues
2. Report: "Designs {X, Y} have build errors. Designs {A, B, C, ...} compiled successfully."
3. Offer to fix the broken ones (launch quick-refactor agents for each)

**If build succeeds:**
Report: "All {N} designs compiled successfully. Navigate with Cmd+J/K or visit /designs/design-{NN}"

---

## Error Handling

- If an agent fails to produce output, note it and continue with others
- If the source file can't be read, stop and ask the user
- If the output directory has permission issues, report and ask
- If more than half the agents produce build errors, offer to regenerate with adjusted constraints

---

## Tips

- For best results, 5-10 designs gives enough variety without overwhelming
- The skill works best with landing pages, marketing pages, and content-heavy pages
- Each agent runs independently — no coordination between designs (maximum diversity)
- Re-running the skill adds more designs (numbering continues from the last existing one)
- Every design is one file — easy to delete, copy, or share individually
