#!/usr/bin/env python3
"""PreToolUse 高風險護欄(Copilot / VS Code hooks 版)。

讀 stdin 的 event JSON,取出工具要跑的指令;命中危險樣式就回 permissionDecision:"deny"
擋下「單一工具呼叫」(不結束整個 session)。其餘一律 fail-open(exit 0、無輸出)。

對應 guardrails-playbook 原則:對準真實事故類型、fail-open、堵繞道、留稽核 log、輸出純 ASCII。
DANGEROUS 樣式請依各專案實際的「違反代價高」操作增刪——這份是通用起點,不是萬用清單。
"""
import datetime
import json
import re
import sys
from pathlib import Path

LOG = Path(__file__).resolve().parent.parent / "guard.log"  # .github/hooks/guard.log

# (regex, 說明) — 命中即 deny。大小寫不敏感。依專案增刪。
DANGEROUS = [
    (r"\brm\s+-[a-z]*[rf]", "rm -rf 刪檔"),
    (r"\bgit\s+push\b", "git push 推遠端"),
    (r"--force\b|\bpush\s+.*\s-f\b", "git 強制推送 / --force"),
    (r"\bgit\s+reset\s+--hard\b", "git reset --hard 丟棄變更"),
    (r"\bgit\s+clean\s+-[a-z]*f", "git clean -f 刪未追蹤檔"),
    (r"\bTRUNCATE\b", "TRUNCATE 清表"),
    (r"\bDROP\s+(TABLE|DATABASE|SCHEMA)\b", "DROP 刪除資料庫物件"),
    (r"\b(mkfs|shutdown|reboot)\b", "破壞性系統指令"),
    (r"\bdd\s+if=", "dd 直寫裝置"),
]


def deny(reason):
    print(json.dumps({
        "hookSpecificOutput": {"permissionDecision": "deny"},
        "systemMessage": "高風險指令已被護欄擋下:%s。確定要執行請自行手動操作。" % reason,
    }))  # 預設 ensure_ascii=True → 純 ASCII,免 Windows 編碼雷
    sys.exit(0)


def extract_command(tool_input):
    """從 tool_input 取出指令字串(欄位名因工具而異,盡量寬鬆)。"""
    if isinstance(tool_input, dict):
        for k in ("command", "commandLine", "cmd", "script", "input"):
            v = tool_input.get(k)
            if isinstance(v, str):
                return v
        return ""
    if isinstance(tool_input, str):
        return tool_input
    return ""


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)  # fail-open
    cmd = extract_command(data.get("tool_input"))
    if not cmd:
        sys.exit(0)
    for rx, label in DANGEROUS:
        if re.search(rx, cmd, re.IGNORECASE):
            try:
                LOG.parent.mkdir(parents=True, exist_ok=True)
                with LOG.open("a", encoding="utf-8") as f:
                    f.write("%s\tDENY\t%s\t%s\n" % (
                        datetime.datetime.now().isoformat(timespec="seconds"),
                        label, cmd[:200]))
            except Exception:
                pass
            deny(label)
    sys.exit(0)


if __name__ == "__main__":
    main()
