**English** | [简体中文](README_CN.md)

# EasyReader - 隐身阅读器

![macOS](https://img.shields.io/badge/platform-macOS-blue)
![License](https://img.shields.io/badge/license-MIT-green)

**EasyReader** 是一款 macOS 全局隐身阅读工具。鼠标移到屏幕右上角弹出阅读窗口，移出自动隐藏。

## 功能

- **全局隐身** — 菜单栏 📖 图标运行，无 Dock 图标
- **鼠标热区** — 移到右上角弹出，移出自动隐藏
- **翻页阅读** — 左键/空格下一页，右键上一页
- **页码跳转** — 输入页码直接跳转
- **最近打开** — 记录最近 10 个文件
- **自定义设置** — 背景色/字体色、透明度、字体大小、窗口大小
- **拖拽打开** — 拖拽 txt 到图标打开

## 安装

### 下载 App

从 [Releases](https://github.com/shaotianw/easyreader/releases) 下载，放入应用程序文件夹。

### 源码编译

```bash
git clone https://github.com/shaotianw/easyreader.git
cd easyreader/src
clang -o 隐身阅读器 main.m -framework Cocoa -fobjc-arc
```

## 使用

| 操作 | 效果 |
|------|------|
| 鼠标移到屏幕右上角 | 弹出阅读窗口 |
| 鼠标移出窗口 | 0.3 秒后自动隐藏 |
| 左键单击 | 下一页 |
| 右键单击 | 上一页 |
| 空格键 | 下一页 |
| 输入数字 + 回车 | 跳转到指定页 |
| 点击菜单栏 📖 | 打开文件 / 设置 |
| Cmd+O | 打开文件 |
| Cmd+, | 打开设置 |
| 拖拽 txt 到图标 | 直接打开 |

## 技术栈

- **原生 macOS** — Objective-C + AppKit
- **Python 备用** — Python/tkinter

## 贡献者

- [shaotianw](https://github.com/shaotianw) — 开发者
- AI 工具: **DeepSeek V4** — 代码生成与辅助开发

## 许可证

MIT License
