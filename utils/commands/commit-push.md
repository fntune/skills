---
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*), Bash(git push:*), Bash(git branch:*), Bash(git diff:*)
argument-hint: [message]
description: Commit and push changes to the current branch
---

Commit all changes and push to the current branch.

Branch: !`git branch --show-current`
Status: !`git status --short`
Diff: !`git diff --stat`

Stage all changes and create a commit.

If message provided, use: $ARGUMENTS
If no message provided, generate a short one-liner summarizing the changes.

Then push to origin. No Claude attribution in commit message.
