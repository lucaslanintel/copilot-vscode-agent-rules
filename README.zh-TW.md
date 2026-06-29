# VS Code + GitHub Copilot 規範一鍵安裝包

> 語言:[English](README.md) | **繁體中文**

把一套工程鐵則、個人偏好、`/resume` 交接、護欄 hook 打包成 **AGENTS.md 通用優先** 格式,給 **VS Code + GitHub Copilot** 用。在任何一台電腦 clone 後執行 bootstrap 腳本即可一鍵套用。所有 schema 依官方文件查證(連結見最後)。

---

## 一鍵安裝

### 全新電腦(零前置一行指令)
裝完即擁有全域 `/init`,新專案 Chat 直接喊 `/init` 就套規範,不必再手動跑任何東西。安裝過程會先問你是否套用到本機(輸入 `y` 同意);要全自動免互動就加 `-Force`。

```powershell
# 純遠端安裝(先下載再執行,避免 AMSI 誤判)
$f="$env:TEMP\cvar-install.ps1"
iwr https://raw.githubusercontent.com/lucaslanintel/copilot-vscode-agent-rules/master/scripts/install.ps1 -UseBasicParsing -OutFile $f
pwsh -ExecutionPolicy Bypass -File $f
Remove-Item $f -Force
```

> **為什麼不用 `iex (iwr...).Content`?** Windows Defender / AMSI 會把這個模式判定為惡意(不管內容),先存檔再執行可避免誤判。

想先 clone 再裝(需 git + gh):

```powershell
$d="$HOME\copilot-vscode-agent-rules"; gh repo clone lucaslanintel/copilot-vscode-agent-rules $d; pwsh -ExecutionPolicy Bypass -File "$d\scripts\install.ps1"
```

### 已 clone 後手動

clone 這個 repo 後,在 repo 根目錄執行:

```powershell
# 全域:安裝使用者層偏好 + 開啟 VS Code Copilot 設定
pwsh -ExecutionPolicy Bypass -File .\scripts\bootstrap.ps1 -Mode Global

# 套到某個專案:建立該專案的 AGENTS.md / prompts / hooks / instructions / docs
pwsh -ExecutionPolicy Bypass -File .\scripts\bootstrap.ps1 -Mode Project -TargetPath C:\path\to\new-project

# 兩者都做
pwsh -ExecutionPolicy Bypass -File .\scripts\bootstrap.ps1 -Mode All -TargetPath C:\path\to\new-project
```

全域安裝(`-Mode Global`/`All`)會先詢問是否套用到本機(輸入 `y` 確認);加 `-Force` 可略過詢問全自動安裝。先預覽不動手:加 `-WhatIf`。覆寫既有檔(會自動備份 `.bak-時間戳`):同樣加 `-Force`。

---

## 檔案與放置位置

| 檔案 | 放哪 | 說明 |
|---|---|---|
| `AGENTS.md` | **每個專案根目錄** | 18 條工程鐵則 + 個人工作風格。VS Code Copilot 自動偵測根目錄 `AGENTS.md`。子目錄可放更專屬的覆寫(就近者優先)。 |
| `user-instructions.md` | **VS Code 使用者層**(全域,一次設定) | 跨所有 repo 的個人偏好。安裝方式見下。 |
| `.github/prompts/resume.prompt.md` | **每個專案的 `.github/prompts/`** | Copilot 的 `/resume`。在 Chat 輸入 `/resume` 觸發。 |
| `.github/prompts/init.prompt.md` | **每個專案的 `.github/prompts/`** | Copilot 的 `/init`。在新專案 Chat 輸入 `/init` 把規範套進來(免開終端機)。 |
| `.github/instructions/guardrails.instructions.md` | **每個專案的 `.github/instructions/`** | 護欄分層手冊精華。方法論參考。 |
| `.github/hooks/high-risk-guard.json` + `scripts/high_risk_guard.py` | **每個專案的 `.github/hooks/`** | **PreToolUse 高風險護欄**:危險指令(git push / rm -rf / TRUNCATE / DROP…)直接 `deny`。 |
| `.github/hooks/context-handoff.json` + `scripts/handoff_reminder.py` | **每個專案的 `.github/hooks/`** | **PreCompact 交接提醒**:context 快滿要被壓縮時,提醒寫 `HANDOFF` + `/resume`。 |

### 全域偏好怎麼安裝
`bootstrap.ps1 -Mode Global` 會把 [user-instructions.zh-TW.md](user-instructions.zh-TW.md) 複製到 `~/.copilot/instructions`、把 `/init` 與 `/resume` 複製到 VS Code 使用者 prompts 目錄(全域生效,**任何新專案都能直接喊 `/init`**),並更新 VS Code 設定。也可手動:Command Palette → **Chat: New Instructions File** → 選 **New Instructions (User)** 貼上,開 **Settings Sync** 勾 *Prompts and Instructions* 跨機同步。

---

## bootstrap 會開的 VS Code 設定(`settings.json`)

```jsonc
{
  // AGENTS.md 支援(通常預設開;確認一下)
  "chat.useAgentsMdFile": true,
  // 子目錄的 AGENTS.md 覆寫(實驗性,monorepo 才需要)
  "chat.useNestedAgentsMdFiles": true,
  // prompt files(/resume)額外搜尋位置;預設讀 .github/prompts
  "chat.promptFilesLocations": { ".github/prompts": true },
  // instructions 額外搜尋位置
  "chat.instructionsFilesLocations": { ".github/instructions": true },
  // monorepo:從父 repo 根目錄一併讀客製
  "chat.useCustomizationsInParentRepositories": true
}
```

> 路徑專屬規則若要用 `applyTo` glob,放 `.github/instructions/*.instructions.md`,前置 frontmatter `applyTo: '**/*.py'`。本套採 AGENTS.md 單檔通用,故未拆。

---

## 內容一覽
- ✅ **18 條工程鐵則 + 個人風格** → `AGENTS.md`(Copilot always-on)。
- ✅ **`/resume` 交接** → `.github/prompts/resume.prompt.md`。
- ✅ **全域個人偏好** → 使用者層 instructions。
- ✅ **機器強制護欄** → `.github/hooks/` 兩支 hook。

## 機器強制 hooks

兩支 hook 放在 `.github/hooks/`,JSON 設定 + Python 腳本。stdin/stdout 走 JSON,`permissionDecision:"deny"` 擋單一工具呼叫,`exit 2` 阻斷。

**1. 高風險護欄 `high-risk-guard.json`(PreToolUse)**
- 命中危險樣式(`git push` / `rm -rf` / `--force` / `git reset --hard` / `TRUNCATE` / `DROP TABLE` / `mkfs` / `dd if=` …)→ 回 `permissionDecision:"deny"` 擋下該指令,並寫 `.github/hooks/guard.log` 稽核。
- 危險樣式在 `scripts/high_risk_guard.py` 頂部的 `DANGEROUS` 清單,**請依各專案實際的高代價操作增刪**。
- 出錯一律 fail-open(放行),不會卡住日常指令。

**2. context 交接提醒 `context-handoff.json`(PreCompact)**
- 不自己算 token;改掛 `PreCompact`——它只在 context 真的快滿、即將壓縮時觸發,本身就是最可靠的「context 高」訊號。
- 觸發時輸出 systemMessage,提醒寫 `.handoffs/HANDOFF.md` + 用 `/resume`。也可改掛 `Stop`,腳本同一支。

**啟用與注意**
- Hooks 設定放 `.github/hooks/*.json`;腳本用 `python` 呼叫(JSON 含 Windows/osx/linux 三平台:Windows 用 `python`,*nix 用 `python3`),需 Python 3 在 PATH。
- bootstrap 已把 `.github/hooks/*.log` 與 `*.bak-*` 加進專案 `.gitignore`。
- **驗收**:離線已測(危險→deny、安全→放行、PreCompact→提醒、JSON 合法);實際在 Copilot agent mode 跑一個無害指令、查 `guard.log` 確認 harness 真的呼叫。
- 事件全集:`SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / PreCompact / SubagentStart / SubagentStop / Stop`。

## 已知限制(誠實標註)
- ⚠️ **剩餘 token 倒數**:Copilot **沒有**「自動注入剩餘 token 數」的設定。已用 `context-handoff.json`(PreCompact hook)替代,事件驅動、不必算 token。
- ⚠️ **壓縮保留**:Copilot 有 `PreCompact` hook,但能否左右摘要內容不確定;AGENTS.md always-on 部分達成同效。

## 優先序
個人(使用者層)> 專案(AGENTS.md / `.github/copilot-instructions.md`)> 組織。

## 來源(官方文件)
- VS Code — Custom instructions: https://code.visualstudio.com/docs/agent-customization/custom-instructions
- VS Code — Prompt files: https://code.visualstudio.com/docs/agent-customization/prompt-files
- VS Code — Hooks: https://code.visualstudio.com/docs/agent-customization/hooks
- VS Code — Copilot customization 總覽: https://code.visualstudio.com/docs/copilot/copilot-customization
- GitHub Docs — Repository custom instructions: https://docs.github.com/copilot/customizing-copilot/adding-custom-instructions-for-github-copilot
- GitHub Changelog — Coding agent 支援 AGENTS.md: https://github.blog/changelog/2025-08-28-copilot-coding-agent-now-supports-agents-md-custom-instructions/
