# AGENTS.md

> Universal AI agent rules. VS Code's GitHub Copilot auto-detects a root `AGENTS.md`, and other tools that support `AGENTS.md` read this file too.
> Place at the **project root**. One per project; subfolders can hold more specific `AGENTS.md` overrides (nearest wins).
> If it conflicts with the project's existing `docs/architecture.md`, the architecture doc wins.

> Language: **English** | [繁體中文](AGENTS.zh-TW.md)

---

## Personal working style (cross-tool)

- Always reply and write commit messages in **Traditional Chinese**.
- Before deciding, give me **options + trade-offs** to sign off on; don't silently pick one.
- Confirm with me before major changes / writing files.
- Comments / docstrings follow each project's existing language convention (most local projects: Traditional Chinese).
- Large changes: commit in batches, reversible; after changes run the project's tests / smoke and report results.
- Secrets (token / key / `.env`) never go into version control; proactively check for leaks.
- **Look up official docs before writing environment / config / schema knowledge** — don't rely on memory (config mistakes often fail silently, harder to catch than code errors).
- Strictly follow the project's established architecture throughout (directory split, module responsibilities, naming, prohibitions); don't deviate.

---

## Engineering ground rules (apply to every task unless explicitly overridden)

Preference: on non-trivial work, "caution over speed"; use judgment for trivial tasks.

1. **Think Before Coding** — State assumptions; if unsure, ask, don't guess. List multiple readings when ambiguous. Propose simpler approaches. If confused, stop and say what's unclear.
2. **Simplicity First** — Minimal code to solve the problem, no speculative features. No abstractions for one-off code. If a senior engineer would call it over-engineered, simplify.
3. **Surgical Changes** — Touch only what's necessary; clean up only your own mess. No "drive-by improvements" to nearby code / comments / formatting. Don't refactor what isn't broken. Match existing style.
4. **Goal-Driven Execution** — Define success criteria first, loop until verification passes. Don't just follow steps; use strong criteria so you can iterate independently.
5. **Use the model only for judgment work** — Classify, draft, summarize, extract with the model; routing, retries, deterministic transforms shouldn't. If code can solve it, use code.
6. **Token budget is not a suggestion** — Near budget, summarize and restart. Surface overruns; don't blow up silently.
7. **Surface conflicts, don't average** — When two patterns conflict, pick one (newer / better-tested), explain why, flag the other for cleanup. Don't blend conflicting patterns.
8. **Read before you write** — Before adding code, read exports, direct callers, shared utilities. "Seems unrelated" is dangerous; if you don't get why a structure is the way it is, ask.
9. **Tests verify intent, not just behavior** — Tests should encode "why this matters", not just "what it does". A test that doesn't fail when business logic changes is wrong.
10. **Set a checkpoint after each important step** — Summarize what was done, verified, what's left. Don't continue from a state you can't describe. If lost, stop and restate.
11. **Match codebase conventions even when you disagree** — In-repo consistency > personal taste. If a convention is genuinely harmful, raise it; don't fork on your own.
12. **Fail loud** — If anything is silently skipped, "done" is wrong; if any test is skipped, "tests pass" is wrong. Surface uncertainty by default, don't hide it.
13. **Dependencies Are Commitments** — Every new dependency is code you don't control and may maintain forever. Before adding a package, check whether the project / framework / stdlib already solves it. No trivial / one-off convenience / speculative-future deps. To add one, explain why, what alternatives were rejected, and the runtime/security/size/license/deploy impact. List all manifest / lockfile changes in the final report.
14. **Debug Before Changing** — When broken, investigate before changing. Read the full error, stack trace, logs, related call paths. Reproduce first if feasible. Change one hypothesis at a time, then verify. Don't mask unknown causes with defensive checks / broad catches / retries / null guards. If a value is unexpectedly null/invalid, explain how it got that way first.
15. **Bug Fixes Start With a Failing Test** — Pin the bug with a failing test / repro script / fixture / documented manual repro. Confirm it fails for the right reason, then change implementation, then confirm the same test passes. If not automatable, say why and give the strongest repro + verification path. Proving only the happy path doesn't count as fixed.
16. **Stop Signs (common failure modes)** — Stop, summarize risk, propose the minimal safe path, and wait for confirmation if any appear: Kitchen Sink (diff starts doing unrelated cleanup / formatting / refactors), Wrong Abstraction (abstracting before the pattern appears twice), Optimistic Path (handling only success, ignoring failure / empty / perms / timeout / bad input), Runaway Refactor (a local fix sprawls into unrelated files / architecture boundaries), Silent Assumption (relying on unconfirmed assumptions).
17. **High-Risk Rules Must Become Guardrails** — If breaking a rule could delete data, push remote, delete files, leak secrets, call external services, or change prod-like state, **don't rely on this doc alone**. Turn the risk into machine-enforced guardrails: hooks, permission ask/deny, in-code guards, tests, CI gates, `.gitignore`. Docs can point the way but can't be the guardrail. Before a new project, identify high-cost operations and say which layer enforces each.
18. **Hand Off Before Context Runs Out** — When context usage is high, don't start unrelated new work. Bring the current task to a clean stop, then write a handoff: current state (done / verified / committed), remaining plan (next steps, in order), blockers and questions, files / commands needed for a cold start. Save the handoff durably (a file in the repo, e.g. `.handoffs/HANDOFF.md`), not just in chat. Then open a new chat / session and resume strictly from the handoff. If a new session can't continue from the handoff alone, the handoff failed.

---

## Context handoff (maps to Rule 18)

- Near the limit: write state + remaining plan into `.handoffs/HANDOFF.md` (create if absent).
- After opening a new chat, resume from that file via `/resume` (Copilot prompt).
- Note: VS Code Copilot has no mechanism to auto-inject remaining token count; rely on the tool's context-usage display or your judgment. For machine-enforced handoff, use `.github/hooks` `Stop` / `PreCompact` hooks (see README).
