---
description: 在目前專案套用工程規範(AGENTS.md / hooks / prompts),免開終端機
agent: agent
argument-hint: [可選:規範來源 repo 路徑,例如 C:\path\to\copilot-vscode-agent-rules]
---

你要把這套 VS Code + Copilot 規範安裝到「目前開啟的專案」根目錄。目標:讓專案具備 AGENTS.md、`/resume`、護欄 hook 與架構文件。

## 步驟

1. **找規範來源 repo**(含 `scripts/bootstrap.ps1`),依序:
   - 若使用者用 `${input:額外指示}` 指定了路徑,用它。
   - 否則找常見位置:`~/copilot-vscode-agent-rules`、`~/copilot-vscode-agent-rules-main`、目前工作區。
   - 都找不到 → 停下,問使用者來源 repo 在哪,**不要**自己亂猜內容。

2. **以一鍵腳本安裝到目前專案**(在終端機跑,目標為目前工作區根):
   ```powershell
   pwsh -ExecutionPolicy Bypass -File <來源repo>\scripts\bootstrap.ps1 -Mode Project -TargetPath .
   ```
   - 既有檔預設不覆寫;要覆寫才加 `-Force`(會先備份)。

3. **驗證**:確認下列都已建立 → `AGENTS.md`、`.github/prompts/resume.prompt.md`、`.github/instructions/guardrails.instructions.md`、`.github/hooks/`、`docs/architecture.md`、`.handoffs/HANDOFF.md`。列出結果給使用者。

4. **若無法執行腳本**(無 PowerShell / 無來源 repo):退而求其次,直接在專案根建立 `AGENTS.md`,內容沿用來源 repo 的 18 條鐵則 + 個人風格;其餘檔案逐一比照建立。

5. **回報**:列出新增 / 跳過的檔案,並提醒重大改動前先給選項讓使用者拍板(AGENTS.md Rule 16)。
