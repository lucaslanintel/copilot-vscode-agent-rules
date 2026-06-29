# Personal global preferences (user layer / cross-project)

> This is personal, cross-project preferences (user layer).
> Install as **VS Code user-layer instructions** (see README) so it applies globally without copying into every repo.
> Project-specific rules go in each repo's `AGENTS.md`; this file holds only cross-project personal style.

> Language: **English** | [繁體中文](user-instructions.zh-TW.md)

## Communication
- Always reply and write commit messages in **Traditional Chinese**.
- Before deciding, give me **options + trade-offs** to sign off on; don't silently pick one.
- Confirm with me before major changes / writing files.

## Code
- Comments / docstrings follow each project's existing language convention (most local projects: Traditional Chinese).
- Match the codebase's existing style and conventions even if you disagree; raise it only if genuinely harmful, don't fork on your own.

## Workflow (general)
- At the start of a new session, first read the project's `AGENTS.md` and `docs/architecture.md`,
  and strictly follow the established architecture throughout (directory split, module responsibilities, naming, prohibitions); no deviation.
- Large changes: commit in batches, reversible; after changes run the project's tests / smoke and report.
- Secrets (token / key / `.env`) never go into version control; proactively check for leaks.
- Look up official docs before writing environment / config / schema knowledge — don't rely on memory (config mistakes often fail silently).
- **High-risk operations** (deleting data, pushing remote, deleting files, touching secrets, hitting external services) shouldn't rely on text rules alone;
  if it can be machine-enforced, use hook / permission / in-code guard / tests / CI / `.gitignore` (maps to Rule 17).

## Context handoff (maps to Rule 18)
- Near the limit, bring the current task to a clean stop, write state + remaining plan into `.handoffs/HANDOFF.md`,
  then open a new chat and resume via `/resume`. Write the handoff well enough that a new chat can take over from it alone.
