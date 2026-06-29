---
description: Layered guardrails handbook (tool-agnostic essence) — high-risk operations should be machine-enforced, not just written as prose rules
---

# Guardrails (layered)

> Maps to `AGENTS.md` Rule 17. Core problem: **rules written in a doc still get ignored by AI at the critical moment.**
> Core answer: **put each rule at the right constraint layer by "cost of violation"; high-risk is always machine-enforced.**
> This is a methodology reference; the actual machine enforcement (hook / CI / guard) is a separate step.

## Three layers of enforcement

| Layer | Form | Strength | Use for |
|---|---|---|---|
| **1. Machine-enforced** | PreToolUse hook, permission deny/ask, in-code guard, tests, CI gate, `.gitignore` | **Holds** (no AI attention needed) | High / irreversible cost: wiping data, pushing remote, deleting files, leaking secrets, hitting external APIs |
| **2. Process / checklist** | multi-step workflow, TODO-ization, plan execution | Medium | TDD, plan execution, verification |
| **3. Prose rules** | AGENTS.md / instructions docs, verbal reminders | Weak (advisory) | Habits & style: language, commit format, directory conventions |

**One-line triage**: violation costs "redo at worst" → prose rule; violation costs "data gone / pushed remote / secret leaked" → don't trust the doc, write a hook / guard / test.

## Design principles
1. **Target real incident types**, don't try to cover everything (gate what has actually happened; too noisy gets disabled).
2. **Fail-open on faults, ask/deny on risk** (a hook's own error should silently allow, not block all commands).
3. **Block the bypass** (when blocking one path, consider alternate paths that run the same dangerous op).
4. **Leave an audit trail** (hook writes one log line; later you can machine-verify the guard runs).
5. **Before go-live, feed fake input offline to test the decision, then run a harmless live command and check the log.**
6. **Platform robustness** (output pure-ASCII JSON to avoid encoding traps; quote paths with spaces).
7. **Zero friction on routine paths** (silently allow safe high-frequency ops, or the guard gets removed for being annoying).

## Porting checklist to a new project
1. List this project's "high cost of violation" ops (wipe / overwrite real data, push remote, delete files, touch secrets, hit external services).
2. Make destructive tests opt-in in-code (module-level guard, only allowed via env var).
3. Add a PreToolUse hook to intercept dangerous commands ("Landing in Copilot / VS Code" below).
4. Require the AI to show independent verification for key changes (grep file contents, `git status`, `git show --stat`, run tests).
5. Keep rule docs habit-only and lean; for high-risk rules ask "can this be a hook / guard / test?" — if yes, write that.
6. Verify the guardrail itself: offline sample test → harmless live command → check audit log. Without this you only "believe" it runs.

## Landing in Copilot / VS Code (the machine-enforcement step)
- Hook config: `.github/hooks/*.json`.
- Events: `SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / PreCompact / SubagentStart / SubagentStop / Stop`.
- I/O: event JSON via stdin; JSON back on stdout; `exit 2` or `{"hookSpecificOutput":{"permissionDecision":"deny"}}` blocks a single tool call.
- Read `tool_name` / `tool_input` from stdin to judge dangerous commands.
