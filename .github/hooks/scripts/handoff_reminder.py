#!/usr/bin/env python3
"""PreCompact 交接提醒 — Copilot / VS Code hooks 版。

為什麼用 PreCompact、而不是自己算 token:
Copilot 沒有「自動注入剩餘 token 數」的機制,
hook 也拿不到精確的 context 用量。但 PreCompact「只在 context 真的快滿、即將被壓縮時」
才觸發——這本身就是最可靠的『context 高』訊號,不需要(也不該)自己去猜 context 視窗大小。

行為:輸出 systemMessage,提醒把狀態 + 剩餘計畫寫進 .handoffs/HANDOFF.md,之後用 /resume 接續。
fail-open;留稽核 log。也可掛到 Stop 事件(收尾時提醒),行為相同。
"""
import datetime
import json
import sys
from pathlib import Path

LOG = Path(__file__).resolve().parent.parent / "handoff.log"  # .github/hooks/handoff.log


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        data = {}
    ev = data.get("hook_event_name", "?")
    try:
        LOG.parent.mkdir(parents=True, exist_ok=True)
        with LOG.open("a", encoding="utf-8") as f:
            f.write("%s\t%s\n" % (
                datetime.datetime.now().isoformat(timespec="seconds"), ev))
    except Exception:
        pass
    print(json.dumps({
        "systemMessage": "Context 即將壓縮(接近上限)。請把目前狀態 + 剩餘計畫寫進 "
                         ".handoffs/HANDOFF.md,之後開新對話用 /resume 接續(Rule 18)。"
    }))  # 純 ASCII 輸出
    sys.exit(0)


if __name__ == "__main__":
    main()
