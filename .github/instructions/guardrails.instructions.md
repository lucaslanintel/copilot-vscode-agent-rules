---
description: 護欄分層手冊(工具無關精華)— 高風險操作該用機器強制,不要只寫成散文規則
---

# 護欄分層(Guardrails)

> 對應 `AGENTS.md` 的 Rule 17。核心問題:**寫在規則文件裡的規定,AI 讀了仍會在關鍵時刻無視**。
> 核心答案:**按「違反的代價」把規則放到對的約束層;高風險一律機器強制**。
> 這份是方法論參考;實際的機器強制(hook / CI / guard)是另一步。

## 三層約束力

| 層 | 形式 | 約束力 | 適用 |
|---|---|---|---|
| **1. 機器強制** | PreToolUse hook、permission deny/ask、程式內 guard、測試、CI gate、`.gitignore` | **擋得住**(不靠 AI 注意力) | 違反代價高 / 不可逆:清資料、推遠端、刪檔、洩漏機密、打外部 API |
| **2. 流程 / 檢查表** | 多步驟工作流、TODO 待辦化、計劃執行 | 中 | TDD、計劃執行、驗收 |
| **3. 散文規則** | AGENTS.md / instructions 文件、口頭叮嚀 | 弱(建議性) | 習慣與風格:語言、commit 格式、目錄慣例 |

**分流一句話**:違反了「頂多重做一下」→ 放散文規則;違反了「資料沒了 / 推上遠端 / 機密外洩」→ 不要靠文件,寫成 hook / guard / 測試。

## 設計原則
1. **對準真實事故類型**,不求包山包海(發生過那類才蓋護欄;太吵會被關掉)。
2. **故障 fail-open、風險 ask/deny**(hook 自身出錯應靜默放行,別卡死所有指令)。
3. **堵繞道**(攔了一條路徑要想到替代路徑能跑同一危險操作)。
4. **留稽核痕跡**(hook 寫一行 log;之後能機器驗證護欄真的在跑)。
5. **上線前先離線餵假輸入測判定,再實彈跑無害指令查 log**。
6. **平台健壯性**(輸出純 ASCII JSON 免編碼雷;路徑含空白加引號)。
7. **日常路徑零摩擦**(安全的高頻操作靜默放行,否則護欄因煩人被拆)。

## 移植到新專案的 checklist
1. 列出本專案「違反代價高」的操作(清 / 覆寫真實資料、推遠端、刪檔、碰機密、打外部服務)。
2. 破壞性測試一律程式內 opt-in(module-level guard,環境變數才放行)。
3. 掛 PreToolUse hook 攔危險指令(下方「在 Copilot / VS Code 落地」)。
4. 要求 AI 對關鍵改動出示獨立驗證(grep 檔案內容、`git status`、`git show --stat`、跑測試)。
5. 規則文件只放習慣類,並保持精簡;高風險規則問自己「能不能寫成 hook / guard / 測試?」能就寫成那個。
6. 驗收護欄本身:離線樣本測 → 實彈跑無害指令 → 查稽核 log。沒這步,你只是「相信」它在跑。

## 在 Copilot / VS Code 落地(機器強制這一步)
- Hooks 設定:`.github/hooks/*.json`。
- 事件:`SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / PreCompact / SubagentStart / SubagentStop / Stop`。
- I/O:event JSON 走 stdin;stdout 回 JSON;`exit 2` 或 `{"hookSpecificOutput":{"permissionDecision":"deny"}}` 可擋下單一工具呼叫。
- stdin 取 `tool_name` / `tool_input` 來判斷危險指令。
