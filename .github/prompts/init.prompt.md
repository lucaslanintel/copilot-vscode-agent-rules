---
description: Apply the engineering rules to the current project (AGENTS.md / hooks / prompts), no terminal needed
agent: agent
argument-hint: [optional: rules source repo path, e.g. C:\path\to\copilot-vscode-agent-rules]
---

You will install this VS Code + Copilot rules pack into the root of the "currently open project". Goal: give the project AGENTS.md, `/resume`, guardrail hooks, and an architecture doc.

> Language: **English** | 繁體中文:`/init.zh-TW`

## Steps

1. **Find the source repo** (containing `scripts/bootstrap.ps1`), in order:
   - If the user gave a path via `${input:extra}`, use it.
   - Otherwise look in common spots: `~/copilot-vscode-agent-rules`, `~/copilot-vscode-agent-rules-main`, current workspace.
   - None found → stop and ask the user where the source repo is; **do not** invent content.

2. **Install to the current project via the one-click script** (run in terminal, target = current workspace root):
   ```powershell
   pwsh -ExecutionPolicy Bypass -File <source-repo>\scripts\bootstrap.ps1 -Mode Project -TargetPath .
   ```
   - Existing files aren't overwritten by default; add `-Force` to overwrite (backs up first).

3. **Verify**: confirm all created → `AGENTS.md`, `.github/prompts/resume.prompt.md`, `.github/instructions/guardrails.instructions.md`, `.github/hooks/`, `docs/architecture.md`, `.handoffs/HANDOFF.md`. List results to the user.

4. **If the script can't run** (no PowerShell / no source repo): fall back to creating `AGENTS.md` at the project root directly, using the source repo's 18 ground rules + personal style; create the rest one by one likewise.

5. **Report**: list added / skipped files, and remind the user to offer options before major changes for sign-off (AGENTS.md Rule 16).
