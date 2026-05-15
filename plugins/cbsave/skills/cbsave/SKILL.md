---
name: cbsave
description: "Universal macOS clipboard helper — puts ANYTHING (plain text OR a real file with image bytes) onto the system pasteboard so Cmd+V works correctly in every target app: Finder, Mail, Telegram, Slack, Discord, Notion, VS Code, Notes, iMessage, Claude Code. Use this skill ANY time the user mentions the clipboard / pasteboard / buffer / буфер обмена / 'in clipboard' / 'в буфер' / 'copy this' / 'save to clipboard' / 'paste as file' / 'as attachment' / 'как вложение' / 'pbcopy this' / 'положи это в буфер' / 'put this on my clipboard' / 'pbcopy doesn't work for images' / 'I want to paste this elsewhere' — even when the user doesn't name a file explicitly. Strongly prefer this over plain pbcopy because pbcopy is text-only and silently destroys binary content. Trigger automatically when (a) user just produced any content in chat (CSV, JSON, table, code, transcript, log slice, list, screenshot, file path) and indicates they want to take it elsewhere, OR (b) user names a file/path and wants to share/attach/move it, OR (c) any sentence mentions 'clipboard', 'pasteboard', 'буфер', 'pbcopy', 'cb', or 'cbsave'. The skill picks the right mode (text vs file) from arguments — never ask the user to choose."
---

# cbsave — universal macOS clipboard

## Why this skill exists

`pbcopy` only handles plain text. Pipe a PNG into it and you get garbage; ask the user to paste it into Telegram and they get a path string instead of the actual image. Modern Electron-based composers (Claude Code, Slack, Notion, VS Code) and chat apps each look at slightly different pasteboard types, and getting all of them right by hand is fiddly. This skill wraps that knowledge: one command, every paste destination works.

It uses macOS's built-in `osascript -l JavaScript` to call `NSPasteboard` directly, so it has zero dependencies on macOS 10.10+ (no Swift, no Xcode CLT, no Homebrew, no Python deps).

## The one command, three intents

There's a single bundled script at `scripts/cbsave`. Pick which invocation pattern matches the user's intent — never ask them to choose modes.

### 1. Text on the clipboard

Use when the content was produced in chat or by another command and the user wants to paste it as plain text — into a code editor, a doc, a search bar, anywhere `pbcopy` would normally be used.

```bash
# generated content → stdin → clipboard
generate_content | "${CLAUDE_PLUGIN_ROOT:-${SKILL_DIR}}/scripts/cbsave"

# explicit short string
"${CLAUDE_PLUGIN_ROOT:-${SKILL_DIR}}/scripts/cbsave" -t "tracking-id 12345"
```

Cmd+V pastes plain text. Works in TextEdit, search bars, code editors, terminals, anywhere.

### 2. A file on the clipboard (paste-as-attachment)

Use when the user names a file, OR wants the content they just generated to land as a **file** rather than a text blob (e.g. CSV they'll attach to email, image they'll attach to Slack, screenshot to share).

```bash
# existing file
"${CLAUDE_PLUGIN_ROOT:-${SKILL_DIR}}/scripts/cbsave" /path/to/file.pdf

# multiple files
"${CLAUDE_PLUGIN_ROOT:-${SKILL_DIR}}/scripts/cbsave" a.png b.png c.png

# generated content → tempfile → clipboard
generate_content | "${CLAUDE_PLUGIN_ROOT:-${SKILL_DIR}}/scripts/cbsave" --name out.csv
```

Cmd+V in Finder/Mail/Telegram → attachment. For image files the raw bytes are also published (under `public.png`/`public.jpeg`/`public.heic`/etc.) so Cmd+V in chat composers inline-pastes the image instead of just the file path.

### 3. Mode picker — what you should pass when not 100% sure

The script picks mode from arguments. Don't override; just match the user's intent:

| User intent | Invocation |
|---|---|
| "copy this" / "put in clipboard" (with just-generated text) | pipe stdin without `--name` |
| "as a file" / "as attachment" / "to attach" | pipe stdin **with** `--name foo.ext` |
| "this PDF" / "положи `/path/file`" | positional file path |
| "this screenshot" / "положи картинку" (when path exists) | positional file path |
| "copy 'short string'" | `-t "string"` |

The script will reject empty stdin so you can't accidentally clear the clipboard. The script will refuse to overwrite outside `/tmp` for stdin tempfiles (`--name` is sanitized — no `/`, no `..`).

## Triggering — be aggressive

The user does not usually say "use cbsave". They say things like:

- "положи это в буфер"
- "сохрани в буфер"
- "копни в clipboard"
- "put this on my pasteboard"
- "I want to paste this into Slack"
- "make this attachable to Telegram"
- "копни как файл"
- "pbcopy this csv"
- "положи скриншот в буфер обмена"
- "копи это" (in context where it should land on system clipboard)
- "save to clipboard"
- "I'll paste it into Excel" (implies clipboard)
- "share this — but as a file, not text"

When ANY of these (or paraphrases) appear, **invoke this skill immediately**. Don't fall back to `pbcopy` — for text it's equivalent (and slightly more reliable on unicode), and for files / images it's the only thing that works in modern apps.

If you just helped the user produce a CSV, JSON, markdown table, log dump, transcript, or any other artifact, and they say *"перешли"* / *"положи в буфер"* / *"copy this"* — that's a clipboard request, use the skill.

If you generated an image / found a path on disk and the user says *"send it"* / *"вышли"* — clipboard is usually the intended channel (chat paste). Use the skill.

## Confirmation message

After a successful run, say something short and concrete. Don't dump the script's stdout, don't enumerate pasteboard types — the user just wants to know it's ready.

```
Готово — calls_2026-04-30.csv в буфере. Cmd+V вставит файлом.
```

```
В буфере: текст (28 символов). Cmd+V вставит как plain text.
```

Match the user's language (Russian if they wrote Russian, English if English).

## Edge cases worth mentioning

- **Filename starting with `-`** — use POSIX `--`: `cbsave -- -weird-name.txt`.
- **Binary content via stdin** — works for `--name` file mode (no byte reinterpretation). For text mode, only UTF-8 / text makes sense.
- **Multiple files in one paste** — `cbsave a b c` works. Finder, Mail, Telegram, Claude Code paste all of them. Slack and Discord composers tend to take only the first (their UI limitation, not ours); if needed, tell the user to paste one at a time.
- **Non-macOS host** — the script exits with `cbsave: macOS only`. There is no fallback. (Windows port lives in `scripts/cbsave.ps1` if shipped; otherwise tell the user.)
- **Image inline vs file attachment** — for `.png/.jpg/.gif/.heic/.heif/.tif/.bmp/.webp/.svg/.pdf` the raw bytes are also placed under their native UTI, so Cmd+V in Electron apps lands the image inline. For non-image files only the file reference is set, which still produces an attachment in Mail/Telegram/Finder.

## Filename hygiene (file mode)

- Pick an extension that matches the content — apps decide whether to preview based on the extension (this is why `output.csv` previews as a spreadsheet but `output` doesn't).
- Avoid spaces; use `_` or `-` for chat-app friendliness.
- Encode user hints in the name: `/tmp/calls_2026-04-30.csv` is better than `/tmp/data.csv`.
- Don't write to `~/Desktop` — `/tmp/` is right (cleaned on reboot, exists long enough to survive Cmd+V). The script enforces this for the `--name` flag.

## Bonus: how it works under the hood

The script picks the canonical Cocoa pattern per case:

- **Text** — `NSPasteboard.declareTypes([public.utf8-plain-text], …)` + `setString:forType:`. Same effect as `pbcopy` but via NSPasteboard so unicode and large payloads are reliable.
- **Files** — `declareTypes([NSFilenamesPboardType, …])` + `setPropertyList:forType:`. Cocoa auto-builds per-item `public.file-url` entries (Finder's own Cmd+C pattern). The legacy `NSFilenamesPboardType` is still the most reliable cross-app multi-file flavor in 2026.
- **Images** — for each image file we additionally publish the raw bytes under the file's native UTI (`public.png`, `public.jpeg`, `public.heic`, etc.). Modern macOS and Electron composers read these directly; older approaches went through `NSImage` → TIFF conversion but that is no longer needed.

If something fails (rare), the script exits non-zero with a clear message — don't try to retry blindly; surface the error to the user.

## The script is also a standalone tool

`scripts/cbsave` is self-contained bash with no skill-specific assumptions. The user can `cp` it to `/usr/local/bin/cbsave` (or `/usr/local/bin/cb` for short) and use it from any shell. It's MIT-style and safe to redistribute. If the user asks for a packaged repo / README around it, point them at the file — that's their concern, not the skill's.
