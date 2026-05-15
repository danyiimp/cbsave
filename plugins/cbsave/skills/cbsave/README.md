# cbsave

Skill that puts a **real file** on the macOS clipboard so Cmd+V in Finder/Telegram/Slack/Mail/iMessage pastes it as an **attachment**, not as plain text.

Uses built-in `osascript -l JavaScript` to call `NSPasteboard.writeObjects([NSURL])`. **Zero dependencies** — works on every macOS 10.10+ (no Xcode, no Swift, no Python, no Homebrew).

## When the skill triggers

Trigger phrases the description matches:

- "положи в буфер файлом" / "как вложение" / "чтобы упало вложением"
- "save as a file in clipboard" / "copy as attachment"
- `/cbsave <path>` — explicit invocation
- After generating CSV/JSON/MD in chat: "а можешь прям файлом?"

## Examples

**File already exists:**
> "положи `~/Downloads/report.pdf` в буфер"

→ skill runs `cbsave ~/Downloads/report.pdf` → Cmd+V attaches the PDF.

**Just generated content in chat:**
> "построй CSV с продажами за неделю и положи в буфер файлом"

→ skill writes `/tmp/sales_week.csv` → runs `cbsave /tmp/sales_week.csv` → Cmd+V attaches the CSV.

**Multiple files:**
> "положи все 3 этих скриншота в буфер"

→ skill runs `cbsave a.png b.png c.png` → Cmd+V attaches all three (works in Finder/Mail/Telegram; Slack/Discord take only the first).

**From stdin:**
> "сгрепай error'ы из лога и положи как .txt в буфер"

→ `grep ERROR app.log | cbsave - --name errors.txt`

## Layout

```
cbsave/
├── SKILL.md           # the skill itself (LLM-facing)
├── README.md          # this file
└── scripts/cbsave     # standalone bash; safe to copy to /usr/local/bin/
```

The `scripts/cbsave` script is self-contained and MIT-style — works as a standalone CLI tool outside the skill harness too.

## Exit codes (from scripts/cbsave)

| code | meaning |
|------|---------|
| `0` | success |
| `1` | filesystem error (missing file, non-macOS host) |
| `2` | bad arguments (`--name` with `..`/leading `/`, unknown flag) |
| `3` | pasteboard write failed (rare; sandbox/TCC issue) |

## Why not pbcopy / AppleScript

- `pbcopy` is text-only — binary input becomes garbage.
- `osascript -e 'set the clipboard to POSIX file …'` puts an alias-style reference that Telegram desktop often refuses to attach.
- `NSPasteboard.writeObjects([NSURL])` (what this skill uses) populates all the pasteboard types every app actually looks for.
