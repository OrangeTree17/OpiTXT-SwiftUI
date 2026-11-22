// ============================================================
//  第 3 个文件：程序入口 / 窗口管理 / 启动画面 / 调试截图
//  ------------------------------------------------------------
//  AppDelegate 负责开各种窗口；WindowManager 是全局单例，
//  任何地方想开文档窗口就调用 WindowManager.shared.openDoc(doc)。
// ============================================================

import SwiftUI
import AppKit

// ============================================================
//  启动、窗口、原生菜单
// ============================================================

final class WindowManager {
    static let shared = WindowManager()

    private var main: NSWindow?
    private var splash: NSWindow?
    private var settingsWindow: NSWindow?
    private var onboardingWindow: NSWindow?
    private var docWindows: [String: NSWindow] = [:]
    private var folderWindows: [String: NSWindow] = [:]
    func window(forFolder id: String) -> NSWindow? { folderWindows[id] }
    func controller(for window: NSWindow?) -> EditorController? {
        guard let window else { return nil }
        return editors[ObjectIdentifier(window)]
    }
    private var editors: [ObjectIdentifier: EditorController] = [:]

    private func baseWindow(_ size: NSSize, showsTitle: Bool = false) -> NSWindow {
        let w = NSWindow(contentRect: NSRect(origin: .zero, size: NSSize(width: size.width, height: size.height + 22)),
                         styleMask: showsTitle
                            ? [.titled, .closable, .miniaturizable, .resizable]
                            : [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                         backing: .buffered, defer: false)
        w.titlebarAppearsTransparent = !showsTitle
        w.backgroundColor = Skin.p.bg
        w.isReleasedWhenClosed = false
        w.appearance = NSAppearance(named: Skin.isDark ? .darkAqua : .aqua)
        w.center()
        return w
    }

    func skinChanged() {
        for w in NSApp.windows {
            w.appearance = NSAppearance(named: Skin.isDark ? .darkAqua : .aqua)
            w.backgroundColor = Skin.p.bg
        }
    }

    // 启动浮层
    func showSplash(done: @escaping () -> Void) {
        let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 280),
                         styleMask: [.borderless], backing: .buffered, defer: false)
        w.isOpaque = false
        w.backgroundColor = .clear
        w.hasShadow = false
        w.level = .floating
        w.contentView = NSHostingView(rootView: SplashView())
        if let screen = NSScreen.main {
            w.setFrameOrigin(NSPoint(x: screen.frame.midX - 200, y: screen.frame.midY - 140))
        }
        w.orderFrontRegardless()
        splash = w

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.18
                w.animator().alphaValue = 0
            } completionHandler: {
                w.orderOut(nil)
                self.splash = nil
                done()
            }
        }
    }

    // 主页
    func showMain() {
        if let w = main {
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let w = baseWindow(NSSize(width: 1180, height: 780))
        w.title = "OπTXT"
        w.minSize = NSSize(width: 900, height: 560)
        w.contentView = NSHostingView(rootView: HomeView())
        HomeModel.shared.window = w
        HomeMarqueeMonitor.shared.install(on: w)
        w.makeKeyAndOrderFront(nil)
        w.alphaValue = 0
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.18
            w.animator().alphaValue = 1
        }
        main = w
        NSApp.activate(ignoringOtherApps: true)
    }

    // 文档窗口
    func openDoc(_ doc: DocItem) {
        if let w = docWindows[doc.id] {
            w.makeKeyAndOrderFront(nil)
            return
        }
        let w = baseWindow(NSSize(width: 940, height: 720))
        w.title = doc.title
        w.minSize = NSSize(width: 700, height: 480)

        let controller = EditorController()
        controller.docID = doc.id
        controller.docTitle = doc.title
        controller.isMarkdown = doc.isMarkdown
        controller.cachedText = Store.shared.content(doc.id)
        controller.window = w

        w.contentView = NSHostingView(rootView: EditorView(controller: controller))
        w.alphaValue = 0
        w.makeKeyAndOrderFront(nil)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.16
            w.animator().alphaValue = 1
        }
        docWindows[doc.id] = w
        editors[ObjectIdentifier(w)] = controller

        NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: w, queue: .main) { _ in
            controller.saveNow()
            WindowManager.shared.docWindows.removeValue(forKey: doc.id)
            WindowManager.shared.editors.removeValue(forKey: ObjectIdentifier(w))
        }
        Config.shared.set { $0.lastDocId = doc.id }
    }

    func editor(for window: NSWindow?) -> EditorController? {
        guard let w = window else { return nil }
        return editors[ObjectIdentifier(w)]
    }

    var keyEditor: EditorController? { editor(for: NSApp.keyWindow) }

    /// 双击文件夹：开一个真正的文件夹窗口
    func openFolder(_ f: FolderItem) {
        if let w = folderWindows[f.id] {
            w.makeKeyAndOrderFront(nil)
            return
        }
        let w = baseWindow(NSSize(width: 860, height: 620))
        w.title = f.name
        let model = FolderModel(folderID: f.id)
        let host = NSHostingView(rootView: FolderWindowView(model: model))
        w.contentView = host
        model.window = w
        w.setFrameAutosaveName("OpiFolder-\(f.id)")
        w.alphaValue = 0
        w.makeKeyAndOrderFront(nil)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.18
            w.animator().alphaValue = 1
        }
        folderWindows[f.id] = w
        NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: w, queue: .main) { _ in
            WindowManager.shared.forgetFolderWindow(f.id)
        }
    }

    func forgetFolderWindow(_ id: String) { folderWindows.removeValue(forKey: id) }

    /// 屏幕某点落在哪个文件夹窗口里（拖文件进来时用）
    func folderID(atScreen p: NSPoint) -> String? {
        for (id, w) in folderWindows where w.isVisible && w.frame.contains(p) { return id }
        return nil
    }
    /// 主页窗口（拖出文件夹时用来判断是不是放回首页）
    var homeWindow: NSWindow? { main }

    // 设置
    func showSettings() {
        if let w = settingsWindow {
            w.makeKeyAndOrderFront(nil)
            return
        }
        let w = baseWindow(NSSize(width: 780, height: 620), showsTitle: true)
        w.title = "OπTXT设置"
        w.contentView = NSHostingView(rootView: SettingsView())
        SettingsModel.shared.window = w
        w.alphaValue = 0
        w.makeKeyAndOrderFront(nil)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.16
            w.animator().alphaValue = 1
        }
        settingsWindow = w
        NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: w, queue: .main) { _ in
            WindowManager.shared.settingsWindow = nil
        }
    }

    // 首次启动
    func showOnboarding(done: @escaping () -> Void) {
        let model = OnboardingModel()
        model.finish = done
        let w = baseWindow(NSSize(width: 640, height: 500))
        w.title = "欢迎"
        w.contentView = NSHostingView(rootView: OnboardingView(model: model))
        model.window = w
        w.makeKeyAndOrderFront(nil)
        onboardingWindow = w
    }

    func renameDoc(_ id: String) {
        guard let doc = Store.shared.doc(id) else { return }
        let alert = NSAlert()
        alert.messageText = "重命名"
        alert.informativeText = "输入新的文档名称"
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 240, height: 24))
        field.stringValue = doc.title
        alert.accessoryView = field
        alert.addButton(withTitle: "好")
        alert.addButton(withTitle: "取消")
        if alert.runModal() == .alertFirstButtonReturn, !field.stringValue.isEmpty {
            Store.shared.renameDoc(id, field.stringValue)
            if let w = docWindows[id] { w.title = field.stringValue }
            NotificationCenter.default.post(name: .storeChanged, object: nil)
        }
    }
}

// 启动浮层：只有 logo，没有背景
// 启动浮层：只有图标，没有玻璃托底、没有文字
struct SplashView: View {
    var body: some View {
        LogoImage(size: 104)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear)
    }
}

// MARK: - AppDelegate

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Dock / 切换器 / 关于页 / 引导页都用系统按 icon.icon 渲染出来的原生 27 图标
        if let icon = LogoImage.appIcon { NSApp.applicationIconImage = icon }
        NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification,
                                               object: nil, queue: .main) { note in
            guard let w = note.object as? NSWindow else { return }
            if let c = WindowManager.shared.editor(for: w) { c.saveNow() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                let visible = NSApp.windows.contains { $0.isVisible && $0.level != .floating }
                if !visible {
                    // 留一小会儿「在后台运行」，让系统把保存完成，然后自己退出
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { NSApp.terminate(nil) }
                }
            }
        }
        Config.shared.load()
        EditorController.registerImportedFonts()
        // 老用户升级：保存位置默认落在桌面
        if Config.shared.d.saveDir.isEmpty {
            Config.shared.set { $0.saveDir = NSHomeDirectory() + "/Desktop" }
        }
        NSApp.setActivationPolicy(.regular)
        buildMenu()
        NSApp.appearance = NSAppearance(named: Skin.isDark ? .darkAqua : .aqua)

        if !Config.shared.d.onboarded {
            WindowManager.shared.showOnboarding { self.startFlow() }
        } else {
            startFlow()
        }
    }

    private func startFlow() {
        // 调试用：直接打开设置 / 编辑器，方便截图核对
        if CommandLine.arguments.contains("--open-settings") {
            WindowManager.shared.showSettings()
            return
        }
        if CommandLine.arguments.contains("--open-editor"), let d = Store.shared.docs.first {
            WindowManager.shared.openDoc(d)
            return
        }
        // 启动就直达编辑文档（新建 / 上次那篇）时不放启动浮层，直接把窗口给出来
        let cfg = Config.shared.d
        let willOpenEditor = cfg.startup == "newdoc"
            || (cfg.startup == "lastdoc" && Store.shared.doc(cfg.lastDocId) != nil)
        if willOpenEditor {
            afterStart()
            return
        }
        if cfg.showSplash {
            WindowManager.shared.showSplash {
                WindowManager.shared.showMain()
                self.afterStart()
            }
        } else {
            WindowManager.shared.showMain()
            afterStart()
        }
    }

    private func afterStart() {
        let cfg = Config.shared.d
        if cfg.startup == "newdoc" {
            let doc = Store.shared.createDoc(kind: cfg.markdownDefault ? "md" : "txt")
            NotificationCenter.default.post(name: .storeChanged, object: nil)
            WindowManager.shared.openDoc(doc)
        } else if cfg.startup == "lastdoc", let doc = Store.shared.doc(cfg.lastDocId) {
            WindowManager.shared.openDoc(doc)
        }
    }


    // ---------- 菜单 ----------

    private func buildMenu() {
        let mainMenu = NSMenu()

        let appItem = NSMenuItem()
        mainMenu.addItem(appItem)
        let appMenu = NSMenu()
        appItem.submenu = appMenu
        appMenu.addItem(item("关于 OπTXT", #selector(about), ""))
        appMenu.addItem(.separator())
        appMenu.addItem(item("设置…", #selector(openSettings), ","))
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "隐藏 OπTXT", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(withTitle: "退出 OπTXT", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        let fileItem = NSMenuItem()
        mainMenu.addItem(fileItem)
        fileItem.submenu = menu("文件", [
            item("新建文档", #selector(newDoc), "n"),
            item("新建 Markdown", #selector(newMarkdown), "N"),
            item("新建文件夹", #selector(newFolder), ""),
            .separator(),
            item("打开…", #selector(openFile), "o"),
            item("保存", #selector(saveDoc), "s"),
            item("导出…", #selector(exportDoc), "E"),
            .separator(),
            item("重命名…", #selector(renameCurrent), ""),
            item("删除", #selector(deleteCurrent), ""),
            .separator(),
            item("关闭窗口", #selector(NSWindow.performClose(_:)), "w"),
        ])

        let editItem = NSMenuItem()
        mainMenu.addItem(editItem)
        editItem.submenu = menu("编辑", [
            item("撤销", Selector(("undo:")), "z"),
            item("重做", Selector(("redo:")), "Z"),
            .separator(),
            item("剪切", #selector(NSText.cut(_:)), "x"),
            item("拷贝", #selector(NSText.copy(_:)), "c"),
            item("粘贴", #selector(NSText.paste(_:)), "v"),
            item("全选", #selector(NSText.selectAll(_:)), "a"),
            .separator(),
            item("插入日期时间", #selector(insertDate), "D"),
            .separator(),
            item("增加页面", #selector(addPage), ""),
        ])

        let fmtItem = NSMenuItem()
        mainMenu.addItem(fmtItem)
        fmtItem.submenu = menu("格式", [
            item("粗体", #selector(fmtBold), "b"),
            item("斜体", #selector(fmtItalic), "i"),
            item("下划线", #selector(fmtUnderline), "u"),
            item("高亮", #selector(fmtHighlight), "H"),
        ])

        let viewItem = NSMenuItem()
        mainMenu.addItem(viewItem)
        viewItem.submenu = menu("显示", [
            item("浅色 / 深色", #selector(toggleDark), ""),
            item("显示工具栏", #selector(toggleToolbar), ""),
        ])

        let winItem = NSMenuItem()
        mainMenu.addItem(winItem)
        let winMenu = NSMenu(title: "窗口")
        winItem.submenu = winMenu
        let closeItem = NSMenuItem(title: "关闭窗口并退出", action: #selector(closeWindowAndQuit), keyEquivalent: "w")
        closeItem.target = self
        winMenu.addItem(closeItem)
        winMenu.addItem(withTitle: "最小化", action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m")
        winMenu.addItem(withTitle: "前置全部窗口", action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: "")

        let helpItem = NSMenuItem()
        mainMenu.addItem(helpItem)
        helpItem.submenu = menu("帮助", [item("OπTXT 使用说明", #selector(helpDoc), "")])

        NSApp.mainMenu = mainMenu
    }

    private func menu(_ title: String, _ items: [NSMenuItem]) -> NSMenu {
        let m = NSMenu(title: title)
        for i in items { m.addItem(i) }
        return m
    }

    private func item(_ title: String, _ sel: Selector, _ key: String) -> NSMenuItem {
        let i = NSMenuItem(title: title, action: sel, keyEquivalent: key)
        i.target = self
        return i
    }

    // ---------- 动作 ----------

    @objc private func addPage() {
        if let w = NSApp.keyWindow, let c = WindowManager.shared.controller(for: w) {
            c.addPage()
        }
    }

    @objc private func openSettings() { WindowManager.shared.showSettings() }

    /// ⌘W：关掉窗口，并把整个应用退掉
    @objc private func closeWindowAndQuit() {
        WindowManager.shared.keyEditor?.saveNow()
        NSApp.keyWindow?.close()
        NSApp.terminate(nil)
    }

    @objc private func newDoc() {
        let doc = Store.shared.createDoc(kind: Config.shared.d.markdownDefault ? "md" : "txt")
        NotificationCenter.default.post(name: .storeChanged, object: nil)
        WindowManager.shared.openDoc(doc)
    }

    @objc private func newMarkdown() {
        let doc = Store.shared.createDoc(kind: "md")
        NotificationCenter.default.post(name: .storeChanged, object: nil)
        WindowManager.shared.openDoc(doc)
    }

    @objc private func newFolder() {
        Store.shared.createFolder()
        NotificationCenter.default.post(name: .storeChanged, object: nil)
    }

    @objc private func openFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let text = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
        let doc = Store.shared.createDoc(kind: url.pathExtension.lowercased() == "md" ? "md" : "txt")
        Store.shared.renameDoc(doc.id, url.deletingPathExtension().lastPathComponent)
        Store.shared.saveContent(doc.id, text)
        NotificationCenter.default.post(name: .storeChanged, object: nil)
        WindowManager.shared.openDoc(doc)
    }

    @objc private func saveDoc() {
        guard let c = WindowManager.shared.keyEditor else { return }
        c.saveNow()
        HomeModel.shared.say("已保存")
        NotificationCenter.default.post(name: .storeChanged, object: nil)
    }

    @objc private func exportDoc() {
        guard let c = WindowManager.shared.keyEditor else { return }
        let panel = NSSavePanel()
        panel.nameFieldStringValue = (c.docTitle.isEmpty ? "未命名文档" : c.docTitle) + (c.isMarkdown ? ".md" : ".txt")
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let text = c.plainText
        try? text.write(to: url, atomically: true, encoding: .utf8)
        Store.shared.noteExport(owner: "d:" + c.docID, path: url.path, text: text)
    }

    @objc private func renameCurrent() {
        guard let c = WindowManager.shared.keyEditor else { return }
        WindowManager.shared.renameDoc(c.docID)
    }

    @objc private func deleteCurrent() {
        guard let c = WindowManager.shared.keyEditor else { return }
        Store.shared.deleteDoc(c.docID)
        NotificationCenter.default.post(name: .storeChanged, object: nil)
        c.window?.performClose(nil)
    }

    @objc private func insertDate() { WindowManager.shared.keyEditor?.insertDate() }
    @objc private func fmtBold() { WindowManager.shared.keyEditor?.bold() }
    @objc private func fmtItalic() { WindowManager.shared.keyEditor?.italic() }
    @objc private func fmtUnderline() { WindowManager.shared.keyEditor?.underline() }
    @objc private func fmtHighlight() { WindowManager.shared.keyEditor?.highlight() }

    @objc private func toggleDark() {
        Skin.setDark(!Skin.isDark)
        WindowManager.shared.skinChanged()
    }

    @objc private func toggleToolbar() {
        Config.shared.set { $0.toolbarVisible.toggle() }
    }

    @objc private func about() {
        let alert = NSAlert()
        alert.messageText = "OπTXT"
        alert.informativeText = "新一代文本编辑工具\n开发者：orange tree 17\nSwiftUI 版本"
        alert.runModal()
    }

    @objc private func helpDoc() {
        let alert = NSAlert()
        alert.messageText = "怎么用"
        alert.informativeText = "主页双击文档卡片打开，⌘N 新建，⌘, 打开设置，⌘W 关闭窗口并退出。选中文字后再点格式按钮，只改选中的部分。"
        alert.runModal()
    }
}

// MARK: - main

let app = NSApplication.shared
if let i = CommandLine.arguments.firstIndex(of: "--snap") {
    Config.shared.load()
    let dir = i + 1 < CommandLine.arguments.count ? CommandLine.arguments[i + 1] : "/tmp/oxtxt-snap"
    Snap.run(dir: dir)
}
let delegate = AppDelegate()
app.delegate = delegate
app.run()


// ============================================================
//  首次启动引导（欢迎页）
// ============================================================

import SwiftUI
import AppKit
import Observation

// ============================================================
//  首次启动的三步向导
// ============================================================

@Observable
final class OnboardingModel {
    var step = 0
    var dark = false
    var paper = 0
    var fontSize = 1
    @ObservationIgnored var finish: (() -> Void)?
    @ObservationIgnored weak var window: NSWindow?

    func next() {
        if step == 2 {
            Config.shared.set {
                $0.onboarded = true
                $0.paperTone = ["white", "cream", "gray"][paper]
                $0.fontSize = [14, 15, 17][fontSize]
            }
            Skin.setDark(dark)
            window?.performClose(nil)
            finish?()
        } else {
            step += 1
        }
    }

    func back() {
        step = max(0, step - 1)
    }
}

struct OnboardingView: View {
    let model: OnboardingModel
    private var m: OnboardingModel { model }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            switch m.step {
            case 0: welcome
            case 1: appearance
            default: writing
            }
            Spacer(minLength: 0)

            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(i == m.step ? Color(nsColor: Skin.p.text) : Color(nsColor: Skin.p.border))
                        .frame(width: 6, height: 6)
                }
                Spacer()
                if m.step > 0 {
                    Button("上一步") { m.back() }
                        .buttonStyle(.plain)
                        .font(.system(size: 12))
                        .foregroundStyle(Color(nsColor: Skin.p.textDim))
                }
                Button(m.step == 2 ? "开始使用" : "继续") { m.next() }
                    .keyboardShortcut(.defaultAction)
                    .controlSize(.large)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 28)
        }
        .background(Color(nsColor: Skin.p.bg))
        .frame(minWidth: 560, minHeight: 460)
    }

    private var welcome: some View {
        VStack(spacing: 18) {
            LogoImage(size: 84)
            VStack(spacing: 6) {
                Text("OπTXT")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Color(nsColor: Skin.p.text))
                Text("新一代文本编辑工具")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(nsColor: Skin.p.textDim))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("你的数据会存在这里")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color(nsColor: Skin.p.text))
                Text(Store.shared.appSupport)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color(nsColor: Skin.p.textDim))
                    .lineLimit(2)
            }
            .padding(12)
            .frame(maxWidth: 420, alignment: .leading)
            .card(radius: 11)
        }
        .padding(.horizontal, 40)
    }

    private var appearance: some View {
        VStack(spacing: 20) {
            titleBlock("先选个外观", "以后随时能在设置里改。")
            VStack(spacing: 14) {
                HStack {
                    Text("深浅色").font(.system(size: 12)).foregroundStyle(Color(nsColor: Skin.p.text))
                    Spacer()
                    Pills(options: ["浅色", "深色"], index: m.dark ? 1 : 0) { i in
                        m.dark = i == 1
                        Skin.setDark(m.dark)
                    }
                }
                HStack {
                    Text("纸张颜色").font(.system(size: 12)).foregroundStyle(Color(nsColor: Skin.p.text))
                    Spacer()
                    Pills(options: ["白", "米黄", "浅灰"], index: m.paper) { i in
                        m.paper = i
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: 460)
            .card()
        }
        .padding(.horizontal, 40)
    }

    private var writing: some View {
        VStack(spacing: 20) {
            titleBlock("字大一点还是小一点", "编辑区正文大小，选个顺眼的。")
            VStack(spacing: 14) {
                HStack {
                    Text("字号").font(.system(size: 12)).foregroundStyle(Color(nsColor: Skin.p.text))
                    Spacer()
                    Pills(options: ["小", "标准", "大"], index: m.fontSize) { i in
                        m.fontSize = i
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: 460)
            .card()
        }
        .padding(.horizontal, 40)
    }

    private func titleBlock(_ main: String, _ sub: String) -> some View {
        VStack(spacing: 6) {
            Text(main)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(Color(nsColor: Skin.p.text))
            Text(sub)
                .font(.system(size: 12))
                .foregroundStyle(Color(nsColor: Skin.p.textDim))
        }
    }
}


// ============================================================
//  离屏截图（调试用，不影响正常使用）
//  命令行加 --snap 目录 就会把各个界面渲染成 png
// ============================================================

import SwiftUI
import AppKit

// 离屏截图（调试用）：./OpiTXT --snap /tmp/shots
enum Snap {
    static func render<V: View>(_ view: V, size: NSSize, to path: String, dark: Bool = false) {
        let host = NSHostingView(rootView: view)
        host.frame = NSRect(origin: .zero, size: size)
        host.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
        host.layoutSubtreeIfNeeded()
        guard let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { return }
        host.cacheDisplay(in: host.bounds, to: rep)
        if let data = rep.representation(using: .png, properties: [:]) {
            try? data.write(to: URL(fileURLWithPath: path))
        }
    }

    static func run(dir: String) {
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)

        // 调试用：OXTXT_FONT=13/15/18/24 可以在截图时改字号，方便逐个字号核对横线对齐
        if let fs = ProcessInfo.processInfo.environment["OXTXT_FONT"].flatMap({ Int($0) }) {
            Config.shared.set { $0.fontSize = fs; $0.lineHeight = Int(Double(fs) * 1.55) + 6 }
        }

        render(HomeView(), size: NSSize(width: 1180, height: 780), to: dir + "/home.png")
        render(HomeView(), size: NSSize(width: 1180, height: 780), to: dir + "/home-dark.png", dark: true)

        if let d0 = Store.shared.docs.first, Store.shared.docs.count >= 2 {
            HomeModel.shared.selection = ["d:" + d0.id, "d:" + Store.shared.docs[1].id]
            render(HomeView(), size: NSSize(width: 1180, height: 780), to: dir + "/home-selection.png")
            HomeModel.shared.clearSelection()
        }
        if let f0 = Store.shared.folders.first {
            render(FolderWindowView(model: FolderModel(folderID: f0.id)),
                   size: NSSize(width: 860, height: 620), to: dir + "/folder.png")
        }

        let c = EditorController()
        if let first = Store.shared.docs.first {
            c.docID = first.id
            c.docTitle = first.title
            c.isMarkdown = first.isMarkdown
            c.cachedText = Store.shared.content(first.id)
        } else {
            c.docTitle = "未命名文档"
            c.cachedText = "# 标题\n\n这是一段示例文字，用来检查稿纸、行高和工具栏。\n\n- 第一项\n- 第二项"
        }
        render(EditorView(controller: c), size: NSSize(width: 940, height: 720), to: dir + "/editor.png")

        // 调试：在页底按回车，应该整页翻过去；再把那行删掉，应该退回上一页
        if ProcessInfo.processInfo.environment["OXTXT_ENTER_TEST"] != nil,
           let tv = c.textView as? RuledTextView, let sv = tv.enclosingScrollView {
            RunLoop.current.run(until: Date().addingTimeInterval(0.5))
            let idx = tv.characterIndex(atPageTop: 1)
            tv.setSelectedRange(NSRange(location: max(0, idx - 1), length: 0))
            tv.insertNewline(nil)
            fflush(stdout)
            RunLoop.current.run(until: Date().addingTimeInterval(0.7))
            print("enter-test after-return page=\(c.currentPage) total=\(c.totalPages) y=\(sv.contentView.bounds.origin.y)")
            fflush(stdout)
            tv.deleteBackward(nil)
            RunLoop.current.run(until: Date().addingTimeInterval(0.7))
            print("enter-test after-delete page=\(c.currentPage) total=\(c.totalPages) y=\(sv.contentView.bounds.origin.y)")
            fflush(stdout)
            exit(0)
        }

        // 调试：只测截图
        if ProcessInfo.processInfo.environment["OXTXT_IMG_TEST"] != nil,
           let tv = c.textView as? RuledTextView {
            RunLoop.current.run(until: Date().addingTimeInterval(0.4))
            print("img-test visible=\(tv.visibleRect) bounds=\(tv.bounds)", terminator: "\n")
            fflush(stdout)
            let img = tv.pageImage(of: tv.visibleRect)
            print("img-test image=\(String(describing: img?.size))")
            fflush(stdout)
            exit(0)
        }

        // 调试：验证翻页后的滚动位置与光标位置（OXTXT_PAGE_TEST=1）
        if ProcessInfo.processInfo.environment["OXTXT_PAGE_TEST"] != nil,
           let tv = c.textView, let sv = tv.enclosingScrollView {
            RunLoop.current.run(until: Date().addingTimeInterval(0.4))
            print("page-test totalPages=\(c.totalPages) pageLines=\((tv as? RuledTextView)?.pageLines ?? -1) pageH=\((tv as? RuledTextView)?.pageHeight ?? -1) frame=\(tv.frame.height) clip=\(sv.contentSize.height)")
            fflush(stdout)
            c.flipToPage(2, direction: 1, moveCaretToTop: true)
            RunLoop.current.run(until: Date().addingTimeInterval(1.0))
            print("page-test after flip page=\(c.currentPage) boundsY=\(sv.contentView.bounds.origin.y) caret=\(tv.selectedRange().location)")
            fflush(stdout)
            render(EditorView(controller: c), size: NSSize(width: 940, height: 720), to: dir + "/editor-page2.png")
        }

        // 调试：验证「选中加粗」在自动重排之后仍然生效（OXTXT_BOLD_TEST=1）
        if ProcessInfo.processInfo.environment["OXTXT_BOLD_TEST"] != nil,
           let tv = c.textView, (tv.string as NSString).length > 4 {
            tv.setSelectedRange(NSRange(location: 0, length: 4))
            c.bold()
            if let f = tv.textStorage?.attribute(.font, at: 0, effectiveRange: nil) as? NSFont {
                print("bold-right-after font ->", f.fontName, "bold:", f.fontDescriptor.symbolicTraits.contains(.bold))
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.9))
            if let f = tv.textStorage?.attribute(.font, at: 0, effectiveRange: nil) as? NSFont {
                print("bold-test font ->", f.fontName, "bold:", f.fontDescriptor.symbolicTraits.contains(.bold))
            }
            render(EditorView(controller: c), size: NSSize(width: 940, height: 720), to: dir + "/editor-bold.png")
        }

        render(SettingsView(), size: NSSize(width: 780, height: 620), to: dir + "/settings-appearance.png")
        SettingsModel.shared.page = "about"
        render(SettingsView(), size: NSSize(width: 780, height: 620), to: dir + "/settings-about.png")
        SettingsModel.shared.page = "appearance"

        let model = OnboardingModel()
        render(OnboardingView(model: model), size: NSSize(width: 640, height: 500), to: dir + "/oobe.png")
        model.step = 1
        render(OnboardingView(model: model), size: NSSize(width: 640, height: 500), to: dir + "/oobe-2.png")

        render(SplashView(), size: NSSize(width: 400, height: 280), to: dir + "/splash.png")
        print("snapshots -> \(dir)")
        exit(0)
    }
}

// ============================================================
//  主页「框选」：窗口级鼠标监听
//  为什么不用 SwiftUI 手势：手势挂在背景上，会被横幅、按钮、滚动区域吃掉，
//  导致只有空白处能框选。这里直接监听窗口的三种鼠标事件，判断起点是否落在卡片上，
//  没落在卡片上就等于“在空白处按下”，于是任何位置都能拉框。
// ============================================================

final class HomeMarqueeMonitor {
    static let shared = HomeMarqueeMonitor()

    private var monitor: Any?
    private weak var window: NSWindow?
    private var start: CGPoint?          // 按下点（SwiftUI 坐标，左上原点）

    func install(on win: NSWindow) {
        window = win
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .leftMouseDragged, .leftMouseUp]) { [weak self] event in
            guard let self, let w = self.window, event.window === w else { return event }
            return self.handle(event)
        }
    }

    /// 把窗口坐标（左下原点）换成 SwiftUI 坐标（左上原点）
    private func point(_ e: NSEvent) -> CGPoint? {
        guard let w = window, let cv = w.contentView else { return nil }
        let p = e.locationInWindow
        return CGPoint(x: p.x, y: cv.bounds.height - p.y)
    }

    private func handle(_ e: NSEvent) -> NSEvent? {
        guard let p = point(e) else { return e }
        let m = HomeModel.shared

        switch e.type {
        case .leftMouseDown:
            // 按在卡片上 → 交给卡片自己的手势（拖拽已选中的卡片）
            let onCard = m.frames.values.contains { $0.contains(p) }
            start = onCard ? nil : p
            return e

        case .leftMouseDragged:
            guard let s = start, hypot(p.x - s.x, p.y - s.y) > 3 else { return e }
            m.marqueeStart = s
            m.marqueePoint = p
            let r = CGRect(x: min(s.x, p.x), y: min(s.y, p.y),
                           width: abs(p.x - s.x), height: abs(p.y - s.y))
            let hit = Set(m.frames.filter { $0.value.intersects(r) }.keys)
            if hit != m.selection { m.selection = hit }
            return nil        // 吞掉拖动，避免同时滚动列表

        case .leftMouseUp:
            guard start != nil else { return e }
            let wasActive = m.marqueeStart != nil
            start = nil
            m.marqueeStart = nil
            m.marqueePoint = nil
            return wasActive ? nil : e

        default:
            return e
        }
    }
}
