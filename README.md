# OπTXT

一个用纯 SwiftUI + AppKit 写的 macOS 稿纸文本编辑器。打开就是一张方格稿纸，一行一行写字，写满一页就左右翻页——不滚动、不花哨。

> 名字读作「O-pai-TXT」，写作「OπTXT」；工程名和可执行文件仍用`OpiTXT`，避免路径和脚本出问题。

---

## 功能

- **稿纸式排版**：固定行高与格线，字踩在线上，一页行数按窗口高度自动算
- **整页左右翻页**：左页向左滑出、右页同时从右侧进入，翻页后光标落在新页第一行
- **自动接续**：打满最后一行或按回车，自动翻到下一页；把新页写空再退格，自动退回上一页
- **富文本**：粗体、斜体、下划线、高亮，四种对齐，字体与字号可换
- **纯文本存储**：文档保存在 `~/Library/Application Support/OπTXT/docs/`，一个文档一个 `.txt`
- **Markdown 预览**：`.md` 文档可切换预览
- **原生观感**：Liquid Glass 面板、深浅色适配、系统图标体系
- **无第三方依赖**，一个 `swiftc` 就能编

## 环境要求

- macOS 26 或更高（开发与测试环境为 macOS 27 + Xcode 27）
- 构建需要 Xcode（含命令行工具）

## 构建与运行

**方式一：Xcode**

```bash
open OpiTXT.xcodeproj
```

选中 `OpiTXT` scheme，⌘R 运行。

**方式二：命令行打包成 .app**

```bash
./打包.sh
```

脚本会编译 `Sources/*.swift`，在 `dist/` 下组装 `OπTXT.app`（含图标、Info.plist、ad-hoc 签名），然后刷新图标缓存。

只想快速编一个可执行文件：

```bash
swiftc -O -o build/OpiTXT Sources/*.swift
```

## 目录结构

```
OpiTXT-Swift/
├── Sources/                 # 源码（两个文件，全部逻辑在这里）
│   ├── 01_全部代码.swift      # 皮肤、配置、存储、编辑器、首页、设置页
│   └── main.swift            # 窗口管理、菜单、AppDelegate、离屏截图调试
├── Previews/Preview.swift    # SwiftUI 预览
├── Packaging/                # AppIcon.png（图标母版）、icon.icns、Info.plist
├── OpiTXT.xcodeproj/         # Xcode 工程
├── 打包.sh                   # 命令行打包脚本
├── 使用指南.md                # 面向使用者的功能说明
└── 图标接入教程.md            # 图标从母版到 icns 的流程
```

## 数据与隐私

- 所有文档只存在本机 `~/Library/Application Support/OπTXT/`，不上传、不联网。
- 删除文档/文件夹时，会连带清理曾经导出到桌面或自定义保存位置的副本（只删内容与登记文本完全一致的文件）。

## 已知限制
- 富文本只支持粗体 / 斜体 / 下划线 / 高亮 / 对齐，没有表格编辑（仅能插入分隔线与简单表格）。
- 未做 iCloud 同步。

## 参与贡献

欢迎提 Issue 和 PR。提交前请确认：

1. `swiftc -O -o build/OpiTXT Sources/*.swift` 能编译通过；
2. 不引入第三方依赖；
3. 改动涉及翻页/排版时，说明在哪种窗口尺寸下验证过。

## 许可

MIT License

字体使用系统自带的苹方（PingFang SC）等，随 macOS 分发，不随本仓库再分发字体文件。
