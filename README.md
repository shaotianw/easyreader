[简体中文](README_CN.md) | **English**

# EasyReader - Invisible Reader

![macOS](https://img.shields.io/badge/platform-macOS-blue)
![License](https://img.shields.io/badge/license-MIT-green)

**EasyReader** is a macOS global stealth reading tool. Move your mouse to the top-right corner of the screen to pop up the reading window; move the mouse away and it auto-hides.

## Features

- **Global Stealth** — Runs as a menu bar 📖 icon, no Dock icon
- **Mouse Hot Zone** — Top-right corner to show, move away to hide
- **Page Navigation** — Left click / space for next, right click for previous
- **Page Jump** — Type page number and press Enter
- **Recent Files** — Remembers last 10 opened files
- **Customizable** — Background/text color, transparency, font size, window size
- **Drag & Drop** — Drag txt file onto the app icon to open

## Installation

### Option 1: Download App Bundle

Download from [Releases](https://github.com/shaotianw/easyreader/releases) and move to Applications.

### Option 2: Build from Source

```bash
git clone https://github.com/shaotianw/easyreader.git
cd easyreader/src
clang -o 隐身阅读器 main.m -framework Cocoa -fobjc-arc
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

## Tech Stack

- **Native macOS App** — Objective-C + AppKit
- **Python Fallback** — Python/tkinter

## Contributors

- [shaotianw](https://github.com/shaotianw) — Developer
- AI Tool: **DeepSeek V4** — Code generation and development assistance (Co-authored)

## License

MIT License
