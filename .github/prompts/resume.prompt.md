---
description: Resume unfinished work from the latest handoff file (maps to Rule 18)
agent: agent
argument-hint: [optional: extra instructions, e.g. "run tests first"]
---

You will take over from the handoff file left by the previous conversation / session and continue unfinished work. Strictly follow this project's `AGENTS.md` and `docs/architecture.md` architecture rules.

> Language: **English** | 繁體中文:`/resume.zh-TW`

## Steps

1. **Find the handoff file**, taking the first that exists:
   - `.handoffs/HANDOFF.md`
   - `.planning/HANDOFF.md`

   None found → **stop**, tell me "no handoff file found", and ask where to resume; **do not** invent a task and start.

2. **Read it fully**: current state, remaining plan, todos, blockers, related files and commands. If needed, read the key files it names to confirm the handoff matches reality (someone else wrote it — verify before trusting).

3. **Restate your understanding**: in a sentence or two, tell me "done up to here, next step is X" so I confirm you've picked up correctly. If the handoff conflicts with the repo's actual state (e.g. says committed but `git status` disagrees), **point out the conflict first** and ask me, don't just proceed.

4. **Continue execution**: start from the first unfinished step in "remaining plan". Before major changes, give me options + trade-offs to sign off on.

5. **Keep updating the handoff**: write progress back into the same `HANDOFF.md` so it always reflects the latest state (a new chat can resume from it alone).

Extra instructions (if any): ${input:extra}
