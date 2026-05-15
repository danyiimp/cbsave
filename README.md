# cbsave

> A Claude Code skill that makes _"put this on my clipboard"_ actually work — for files, text, and inline images. Not just text.

[![macOS](https://img.shields.io/badge/macOS-10.10%2B-black?logo=apple)](https://github.com/danyiimp/cbsave)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![CI](https://github.com/danyiimp/cbsave/actions/workflows/test.yml/badge.svg)](https://github.com/danyiimp/cbsave/actions)

**Tiny.** One bash script. ~290 lines. Zero dependencies — no Swift, no Homebrew, no Python. macOS 10.10+.

## Install

```
/plugin marketplace add danyiimp/cbsave
/plugin install cbsave@cbsave
```

Auto-triggers on clipboard intent in your next session — no slash command, no flags.

## What it does

You say it in plain English (or any language). The skill picks the right mode and puts the result on your macOS clipboard, ready for Cmd+V anywhere.

> **You:** _"copy this CSV to my clipboard so I can attach it in Gmail"_<br>
> **Claude:** writes `/tmp/data.csv`, puts it on the pasteboard as a file. Cmd+V into Gmail → attachment.

> **You:** _"I want to paste this screenshot into Slack"_ (pointing at `~/Desktop/screenshot.png`)<br>
> **Claude:** puts the file URL **and** the raw PNG bytes on the clipboard. Cmd+V in Slack → image inline.

> **You:** _"copy these 14 screenshots so I can drop them in Notion"_<br>
> **Claude:** all 14 on the clipboard at once. Cmd+V → all 14 pasted. (No limit.)

> **You:** _"put `~/Downloads/contract.pdf` on my clipboard"_<br>
> **Claude:** Cmd+V into Mail → PDF attached. Cmd+V into Finder → file copied.

> **You:** _"pbcopy this output for me"_ (after a `kubectl get pods`)<br>
> **Claude:** plain text on the clipboard, just like `pbcopy` but unicode-safe.

## What's on the pasteboard

| You wanted | What lands | Cmd+V result |
|---|---|---|
| any file | `public.file-url` + `NSFilenamesPboardType` | attaches/copies in Finder, Mail, Telegram, Finder |
| an image file | also `public.png` / `public.jpeg` / `public.heic` raw bytes | inline image in Slack, Notion, Notes, iMessage, Claude Code |
| any number of files | per-item entries, no upper bound | multi-paste where the receiving app supports it (Finder, Mail, Telegram) |
| plain text | `public.utf8-plain-text` | normal text paste, unicode-safe |

## Why this exists

`pbcopy` is text-only. Pipe a PNG into it and you get garbage. Drop a CSV onto Cmd+V into Mail and you get a wall of text, not an attached file. Every chat composer (Slack, Discord, Notion, iMessage, Claude Code) looks at slightly different pasteboard types — getting all of them right by hand is fiddly. This skill wraps that knowledge so you stop thinking about it.

## How

Uses macOS's built-in `osascript -l JavaScript` to talk to `NSPasteboard` directly — the Cocoa bridge that ships with every system since 10.10 Yosemite. For files, the legacy `NSFilenamesPboardType` + `setPropertyList` pattern Finder itself uses on Cmd+C. For image files, additionally publishes the raw bytes under their native UTI so modern Electron-based composers paste the image inline instead of just a file reference.

The bundled `scripts/cbsave` is also a standalone bash CLI — drop it on your `PATH` if you want `pbcopy`'s rich cousin without Claude Code.

## License

MIT — use it however.
