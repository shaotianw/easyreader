# EasyReader - 隐身阅读器

![macOS](https://img.shields.io/badge/platform-macOS-blue)
![License](https://img.shields.io/badge/license-MIT-green)

**EasyReader** 是一款 macOS 全局隐身阅读工具。将鼠标移到屏幕右上角即可弹出阅读窗口，移出窗口自动隐藏，适合在工作间隙偷偷阅读。

## 功能特点

- **全局隐身** — 菜单栏 📖 图标运行，无 Dock 图标，不干扰工作
- **鼠标热区** — 移到屏幕右上角弹出，移出自动隐藏
- **翻页阅读** — 左键/空格下一页，右键上一页
- **页码跳转** — 底部输入页码直接跳转
- **最近打开** — 菜单栏记录最近打开的 10 个文件
- **高度可定制** — 设置面板可调整：
  - 背景色 / 字体色
  - 背景透明度
  - 字体大小
  - 窗口宽高
  - 行间距
- **拖拽打开** — 拖拽 txt 文件到 app 图标直接打开

## 安装

### 方法一：下载 App bundle

从 [Releases](https://github.com/shaotianw/easyreader/releases) 下载最新版 `阅读隐身器.app`，放入 `应用程序` 文件夹。

首次打开如提示"无法验证开发者"：
1. 打开 **系统设置 → 隐私与安全性**
2. 在"安全性"部分点击 **仍要打开**

### 方法二：源码编译

```bash
git clone https://github.com/shaotianw/easyreader.git
cd easyreader/src
clang -o 阅读隐身器 main.m -framework Cocoa -fobjc-arc
```

## 使用说明

| 操作 | 效果 |
|------|------|
| 鼠标移到屏幕右上角 | 弹出阅读窗口 |
| 鼠标移出窗口 | 0.3 秒后自动隐藏 |
| 左键单击阅读区 | 下一页 |
| 右键单击阅读区 | 上一页 |
| 空格键 | 下一页 |
| 输入数字 + 回车 | 跳转到指定页 |
| 点击菜单栏 📖 | 打开文件 / 设置 |
| Cmd+O | 打开文件 |
| Cmd+, | 打开设置 |
| 拖拽 txt 到 app 图标 | 直接打开 |

## 配置

配置文件保存在 `~/.config/阅读隐身器/config.plist`，也可通过设置面板调整。

## 技术栈

- **原生 macOS 应用** — Objective-C + AppKit
- **Python 备用版本** — 纯 Python/tkinter 实现

## 许可证

MIT License
