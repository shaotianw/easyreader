**English** | [简体中文](README.md)

# EasyReader - Invisible Reader

![macOS](https://img.shields.io/badge/platform-macOS-blue)
![License](https://img.shields.io/badge/license-MIT-green)

**EasyReader** is a macOS global stealth reading tool. Move your mouse to the top-right corner of the screen to pop up the reading window; move the mouse away and it auto-hides. Perfect for sneaking in some reading during work breaks.

## Features

- **Global Stealth** — Runs as a menu bar 📖 icon, no Dock icon, no distraction
- **Mouse Hot Zone** — Move to top-right corner to show, move away to hide
- **Page Navigation** — Left click/space for next page, right click for previous
- **Page Jump** — Type a page number at the bottom and press Enter
- **Recent Files** — Remembers the last 10 opened files
- **Highly Customizable** — Settings panel for:
  - Background / text color
  - Background transparency
  - Font size
  - Window width / height
- **Drag & Drop** — Drag a txt file onto the app icon to open it

## Installation

### Option 1: Download App Bundle

Download the latest `阅读隐身器.app` from [Releases](https://github.com/shaotianw/easyreader/releases) and move it to your `Applications` folder.

If macOS says the app is from an unidentified developer:
1. Open **System Settings → Privacy & Security**
2. Click **Open Anyway** in the Security section

### Option 2: Build from Source

```bash
git clone https://github.com/shaotianw/easyreader.git
cd easyreader/src
clang -o 阅读隐身器 main.m -framework Cocoa -fobjc-arc
```

## Usage

| Action | Effect |
|--------|--------|
| Move mouse to top-right corner | Show reading window |
| Move mouse away from window | Auto-hide after 0.3s |
| Left click on text | Next page |
| Right click on text | Previous page |
| Space key | Next page |
| Type number + Enter | Jump to page |
| Click menu bar 📖 | Open file / Settings |
| Cmd+O | Open file |
| Cmd+, | Open settings |
| Drag txt to app icon | Open file directly |

## Configuration

Config file: `~/.config/阅读隐身器/config.plist`. Can also be adjusted via the Settings panel.

## Tech Stack

- **Native macOS App** — Objective-C + AppKit
- **Python Fallback** — Pure Python/tkinter implementation

## Contributors

- [shaotianw](https://github.com/shaotianw) — Developer
- AI Tool: **DeepSeek V4** — Code generation and development assistance

## License

MIT License
