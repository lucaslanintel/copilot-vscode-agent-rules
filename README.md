# VS Code + GitHub Copilot Rules — One-Click Installer

> Language: **English** | [繁體中文](README.zh-TW.md)

Packs a set of engineering ground rules, personal preferences, `/resume` handoff, and guardrail hooks into an **AGENTS.md universal-first** format for **VS Code + GitHub Copilot**. Clone on any machine and run the bootstrap script to apply everything in one click. Every schema is verified against the official docs (links at the end).

---

## One-Click Install

### Before you run install

1. Configure proxy first:

```cmd
set HTTPS_PROXY=http://proxy-dmz.intel.com:912
set HTTP_PROXY=http://proxy-dmz.intel.com:911
set NO_PROXY=intel.com,.intel.com,10.0.0.0/8,192.168.0.0/16,localhost,.local,127.0.0.0/8,172.16.0.0/12,134.134.0.0/16
```

2. Install Node.js and ensure `node`/`npm` are on PATH.

### Prerequisites

| Requirement | Version | Notes |
|---|---|---|
| **Windows** | 10 / 11 | Scripts are Windows-only (PowerShell) |
| **VS Code** | ≥ 1.90 | With GitHub Copilot extension enabled |
| **GitHub Copilot** | any | Chat mode required (`/init`, `/resume`) |
| **PowerShell** | 7+ (`pwsh`) recommended, 5.1 accepted | Pre-installed on Win 11; [install pwsh 7](https://github.com/PowerShell/PowerShell) |
| **Node.js** | ≥ 14 | For `npx` install only — VS Code ships Node but it may not be on PATH |
| **git** | any | Required for clone-based install (`gh` optional) |

> **Minimum for `npx` path**: Node.js on PATH + pwsh/powershell + VS Code with Copilot.
> **Minimum for PS1 path**: pwsh/powershell + VS Code with Copilot (no Node needed).

### Brand-new machine (zero-setup, one-liner)
After install you get global `/init`: type `/init` in any new project's Chat to apply the rules. Installer asks for consent (type `y`); add `-Force` for unattended install.

Quickest path (Node.js already on PATH):

```powershell
# requires Node.js (`npx` cannot auto-install Node by itself)
npx github:lucaslanintel/copilot-vscode-agent-rules
```

> **Why `npx` instead of `iex (iwr...).Content`?** Windows Defender / AMSI flags the `iex+iwr` pattern as malicious (common malware delivery technique) regardless of actual content. `npx` is not flagged.

No Node.js on PATH? Use clone + PowerShell installer (needs git, `gh` optional):

```powershell
$d="$HOME\copilot-vscode-agent-rules"; if (Get-Command gh -ErrorAction SilentlyContinue) { gh repo clone lucaslanintel/copilot-vscode-agent-rules $d } else { git clone https://github.com/lucaslanintel/copilot-vscode-agent-rules.git $d }; pwsh -ExecutionPolicy Bypass -File "$d\scripts\install.ps1"
```

### After clone (manual)

Clone this repo, then from the repo root run:

```powershell
# Global: install user-level preferences + enable VS Code Copilot settings
pwsh -ExecutionPolicy Bypass -File .\scripts\bootstrap.ps1 -Mode Global

# Apply to a project: create that project's AGENTS.md / prompts / hooks / instructions / docs
pwsh -ExecutionPolicy Bypass -File .\scripts\bootstrap.ps1 -Mode Project -TargetPath C:\path\to\new-project

# Both
pwsh -ExecutionPolicy Bypass -File .\scripts\bootstrap.ps1 -Mode All -TargetPath C:\path\to\new-project
```

Global install (`-Mode Global`/`All`) asks for consent before applying to your machine (type `y`); add `-Force` to skip the prompt and install unattended. Preview without changes: add `-WhatIf`. Overwrite existing files (auto-backup to `.bak-<timestamp>`): also add `-Force`.

---

## Files and Where They Go

| File | Location | Notes |
|---|---|---|
| `AGENTS.md` | **Each project root** | 18 engineering ground rules + personal style. VS Code Copilot auto-detects the root `AGENTS.md`. Subfolders can add more specific overrides (nearest wins). |
| `user-instructions.md` | **VS Code user layer** (global, set once) | Personal preferences across all repos. Install steps below. |
| `.github/prompts/resume.prompt.md` | **Each project's `.github/prompts/`** | Copilot's `/resume`. Trigger by typing `/resume` in Chat. |
| `.github/prompts/init.prompt.md` | **Each project's `.github/prompts/`** | Copilot's `/init`. Type `/init` in a new project's Chat to apply the rules (no terminal). |
| `.github/instructions/guardrails.instructions.md` | **Each project's `.github/instructions/`** | Layered-guardrails handbook essence. Methodology reference. |
| `.github/hooks/high-risk-guard.json` + `scripts/high_risk_guard.py` | **Each project's `.github/hooks/`** | **PreToolUse high-risk guard**: dangerous commands (git push / rm -rf / TRUNCATE / DROP…) are `deny`'d. |
| `.github/hooks/context-handoff.json` + `scripts/handoff_reminder.py` | **Each project's `.github/hooks/`** | **PreCompact handoff reminder**: when context is nearly full and about to compact, reminds you to write `HANDOFF` + `/resume`. |

### How global preferences install
`bootstrap.ps1 -Mode Global` copies [user-instructions.md](user-instructions.md) to `~/.copilot/instructions`, copies `/init` and `/resume` into the VS Code user prompts folder (global, **so any new project can call `/init`**), and updates VS Code settings. You can also do it manually: Command Palette → **Chat: New Instructions File** → choose **New Instructions (User)** and paste, enable **Settings Sync** with *Prompts and Instructions* checked to sync across machines.

---

## VS Code settings bootstrap enables (`settings.json`)

```jsonc
{
  // AGENTS.md support (usually on by default; confirm)
  "chat.useAgentsMdFile": true,
  // Nested AGENTS.md overrides in subfolders (experimental, monorepo only)
  "chat.useNestedAgentsMdFiles": true,
  // extra search location for prompt files (/resume); reads .github/prompts by default
  "chat.promptFilesLocations": { ".github/prompts": true },
  // extra search location for instructions
  "chat.instructionsFilesLocations": { ".github/instructions": true },
  // monorepo: also read customizations from the parent repo root
  "chat.useCustomizationsInParentRepositories": true
}
```

> For path-specific rules using an `applyTo` glob, put them in `.github/instructions/*.instructions.md` with frontmatter `applyTo: '**/*.py'`. This pack uses a single universal AGENTS.md, so it's not split.

---

## Contents at a Glance
- ✅ **18 ground rules + personal style** → `AGENTS.md` (Copilot always-on).
- ✅ **`/resume` handoff** → `.github/prompts/resume.prompt.md`.
- ✅ **Global personal preferences** → user-layer instructions.
- ✅ **Machine-enforced guardrails** → two hooks in `.github/hooks/`.

## Machine-enforced hooks

Two hooks live in `.github/hooks/`: JSON config + Python script. I/O is JSON via stdin/stdout; `permissionDecision:"deny"` blocks a single tool call, `exit 2` aborts.

**1. High-risk guard `high-risk-guard.json` (PreToolUse)**
- Matches dangerous patterns (`git push` / `rm -rf` / `--force` / `git reset --hard` / `TRUNCATE` / `DROP TABLE` / `mkfs` / `dd if=` …) → returns `permissionDecision:"deny"` to block, and writes `.github/hooks/guard.log` for audit.
- Patterns live in the `DANGEROUS` list at the top of `scripts/high_risk_guard.py` — **add/remove per each project's actual high-cost operations**.
- On error it fails open (allows), so it won't block routine commands.

**2. Context handoff reminder `context-handoff.json` (PreCompact)**
- Doesn't count tokens itself; hooks into `PreCompact` — which fires only when context is genuinely near full and about to compact, the most reliable "context high" signal.
- On trigger it emits a systemMessage reminding you to write `.handoffs/HANDOFF.md` + use `/resume`. Can also hook into `Stop` with the same script.

**Enable & notes**
- Hook config goes in `.github/hooks/*.json`; scripts are invoked via `python` (JSON covers Windows/osx/linux: `python` on Windows, `python3` on *nix), needs Python 3 on PATH.
- bootstrap already adds `.github/hooks/*.log` and `*.bak-*` to the project `.gitignore`.
- **Verification**: offline-tested (dangerous→deny, safe→allow, PreCompact→remind, JSON valid); run one harmless command in Copilot agent mode and check `guard.log` to confirm the harness actually calls it.
- Full event set: `SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / PreCompact / SubagentStart / SubagentStop / Stop`.

## Known limitations (honest)
- ⚠️ **Remaining-token countdown**: Copilot has **no** setting to auto-inject remaining token count. Replaced by `context-handoff.json` (PreCompact hook) — event-driven, no token math.
- ⚠️ **Compaction retention**: Copilot has a `PreCompact` hook, but whether it can steer summary content is uncertain; the AGENTS.md always-on part partly achieves the same.

## Priority
Personal (user layer) > Project (AGENTS.md / `.github/copilot-instructions.md`) > Org.

## Sources (official docs)
- VS Code — Custom instructions: https://code.visualstudio.com/docs/agent-customization/custom-instructions
- VS Code — Prompt files: https://code.visualstudio.com/docs/agent-customization/prompt-files
- VS Code — Hooks: https://code.visualstudio.com/docs/agent-customization/hooks
- VS Code — Copilot customization overview: https://code.visualstudio.com/docs/copilot/copilot-customization
- GitHub Docs — Repository custom instructions: https://docs.github.com/copilot/customizing-copilot/adding-custom-instructions-for-github-copilot
- GitHub Changelog — Coding agent supports AGENTS.md: https://github.blog/changelog/2025-08-28-copilot-coding-agent-now-supports-agents-md-custom-instructions/
