// ============================================================
//  01 核心代码（全部数据 + 全部界面，一个文件）
//  —— 给不会编程的你：改东西只要在这一个文件里搜索关键字就行
// ============================================================

// ============================================================
//  OπTXT · 纯 SwiftUI 版
//  第 1 个文件：数据与存储（文档 / 文件夹 / 设置 / Markdown）
//  ------------------------------------------------------------
//  说明：整个 App 只有 3 个源码文件，按「数据 → 界面 → 入口」排列。
//  想改行为时先看这里的 Store（文件都存在 ~/Library/Application Support/OπTXT）。
// ============================================================

import AppKit
import SwiftUI
import Observation

// ============================================================
//  Core：主题、设置、数据（和 .NET 版共用同一份
//  ~/Library/Application Support/OπTXT）
// ============================================================

let kAppName = "OπTXT"
let kSubFolder = "OπTXT"
let kLegacyFolder = "OxTXT"

extension Notification.Name {
    static let skinChanged = Notification.Name("skinChanged")
    static let storeChanged = Notification.Name("storeChanged")
    static let configChanged = Notification.Name("configChanged")
}

// MARK: - 调色板

struct Palette {
    var bg: NSColor
    var panel: NSColor
    var sheet: NSColor
    var border: NSColor
    var line: NSColor
    var text: NSColor
    var textDim: NSColor
    var accent: NSColor
    var accentSoft: NSColor
    var banner: NSColor
    var hover: NSColor
    var danger: NSColor

    static let light = Palette(
        bg: NSColor(hex: "#FFFFFF"),
        panel: NSColor(hex: "#FBFBFC"),
        sheet: NSColor(hex: "#FFFFFF"),
        border: NSColor(hex: "#E3E3E8"),
        line: NSColor(hex: "#EFEFF3"),
        text: NSColor(hex: "#1D1D1F"),
        textDim: NSColor(hex: "#6E6E73"),
        accent: NSColor(hex: "#FFD60A"),
        accentSoft: NSColor(hex: "#FFF4B8"),
        banner: NSColor(hex: "#FFF3C4"),
        hover: NSColor(hex: "#000000").withAlphaComponent(0.05),
        danger: NSColor(hex: "#C0392B")
    )

    static let dark = Palette(
        bg: NSColor(hex: "#1C1C1E"),
        panel: NSColor(hex: "#242426"),
        sheet: NSColor(hex: "#232326"),
        border: NSColor(hex: "#FFFFFF").withAlphaComponent(0.14),
        line: NSColor(hex: "#FFFFFF").withAlphaComponent(0.07),
        text: NSColor(hex: "#E8E8ED"),
        textDim: NSColor(hex: "#9A9AA0"),
        accent: NSColor(hex: "#FFD60A"),
        accentSoft: NSColor(hex: "#FFD60A").withAlphaComponent(0.22),
        banner: NSColor(hex: "#3A331C"),
        hover: NSColor(hex: "#FFFFFF").withAlphaComponent(0.08),
        danger: NSColor(hex: "#FF8A80")
    )

    // 稿纸底色
    func paper(_ tone: String) -> NSColor {
        let darkMode = Skin.isDark
        switch tone {
        case "cream": return darkMode ? NSColor(hex: "#2A2721") : NSColor(hex: "#FCF7EA")
        case "gray":  return darkMode ? NSColor(hex: "#232325") : NSColor(hex: "#F4F4F6")
        default:      return darkMode ? NSColor(hex: "#232326") : NSColor(hex: "#FFFFFF")
        }
    }
}

// 主题：真正的可观察状态，SwiftUI 会自动跟着重绘
@Observable
final class SkinState {
    static let shared = SkinState()
    var isDark: Bool = UserDefaults.standard.bool(forKey: "oxtxt.dark")
}

enum Skin {
    static var isDark: Bool { SkinState.shared.isDark }
    static var p: Palette { SkinState.shared.isDark ? .dark : .light }

    static func setDark(_ on: Bool) {
        SkinState.shared.isDark = on
        UserDefaults.standard.set(on, forKey: "oxtxt.dark")
        NotificationCenter.default.post(name: .skinChanged, object: nil)
    }
}

extension NSColor {
    convenience init(hex: String) {
        var s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        if s.count == 3 {
            s = s.map { "\($0)\($0)" }.joined()
        }
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        let r = CGFloat((v >> 16) & 0xFF) / 255
        let g = CGFloat((v >> 8) & 0xFF) / 255
        let b = CGFloat(v & 0xFF) / 255
        self.init(srgbRed: r, green: g, blue: b, alpha: 1)
    }

    var swiftUI: Color { Color(nsColor: self) }
}

// MARK: - 设置

struct ConfigData {
    var fontSize: Int = 15
    var fontName: String = "PingFang SC"
    /// 文档保存目录，默认放到桌面
    var saveDir: String = NSHomeDirectory() + "/Desktop"
    var lineHeight: Int = 30
    var paperWidth: Int = 760
    var paperTone: String = "white"      // white / cream / gray
    var startup: String = "home"          // home / newdoc / lastdoc
    var lastDocId: String = ""
    var autoSaveOnClose: Bool = false
    var autoSaveDir: String = ""
    var markdownDefault: Bool = false
    var focusMode: Bool = false
    var showSplash: Bool = true
    var viewList: Bool = false
    var toolbarVisible: Bool = true
    var animate: Bool = true
    var onboarded: Bool = false
}

@Observable
final class Config {
    static let shared = Config()
    private(set) var d = ConfigData()

    var filePath: String { Store.shared.appSupport + "/settings.json" }

    func load() {
        guard let obj = Config.readJSON(filePath) else { return }
        var c = ConfigData()
        if let v = obj["fontSize"] as? Int { c.fontSize = v }
        if let v = obj["lineHeight"] as? Int { c.lineHeight = v }
        if let v = obj["paperWidth"] as? Int { c.paperWidth = v }
        if let v = obj["fontName"] as? String { c.fontName = v }
        if let v = obj["saveDir"] as? String, !v.isEmpty { c.saveDir = v }
        if let v = obj["paperTone"] as? String { c.paperTone = v }
        if let v = obj["startup"] as? String { c.startup = v }
        if let v = obj["lastDocId"] as? String { c.lastDocId = v }
        if let v = obj["autoSaveOnClose"] as? Bool { c.autoSaveOnClose = v }
        if let v = obj["autoSaveDir"] as? String { c.autoSaveDir = v }
        if let v = obj["markdownDefault"] as? Bool { c.markdownDefault = v }
        if let v = obj["focusMode"] as? Bool { c.focusMode = v }
        if let v = obj["showSplash"] as? Bool { c.showSplash = v }
        if let v = obj["viewList"] as? Bool { c.viewList = v }
        if let v = obj["toolbarVisible"] as? Bool { c.toolbarVisible = v }
        if let v = obj["animate"] as? Bool { c.animate = v }
        if let v = obj["onboarded"] as? Bool { c.onboarded = v }
        d = c
    }

    func save() {
        let obj: [String: Any] = [
            "fontSize": d.fontSize, "fontName": d.fontName, "saveDir": d.saveDir,
            "lineHeight": d.lineHeight, "paperWidth": d.paperWidth,
            "paperTone": d.paperTone, "startup": d.startup, "lastDocId": d.lastDocId,
            "autoSaveOnClose": d.autoSaveOnClose, "autoSaveDir": d.autoSaveDir,
            "markdownDefault": d.markdownDefault, "focusMode": d.focusMode,
            "showSplash": d.showSplash, "viewList": d.viewList,
            "toolbarVisible": d.toolbarVisible, "animate": d.animate,
            "onboarded": d.onboarded,
        ]
        try? FileManager.default.createDirectory(atPath: Store.shared.appSupport, withIntermediateDirectories: true)
        if let data = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .withoutEscapingSlashes]) {
            try? data.write(to: URL(fileURLWithPath: filePath))
        }
        NotificationCenter.default.post(name: .configChanged, object: nil)
    }

    func set(_ change: (inout ConfigData) -> Void) {
        change(&d)
        save()
    }

    static func readJSON(_ path: String) -> [String: Any]? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        return obj
    }
}

// MARK: - 数据

struct DocItem: Codable, Identifiable, Hashable {
    var id: String
    var title: String
    var folder: String?
    var createdAt: String?
    var updatedAt: String?
    var kind: String?

    var isMarkdown: Bool { (kind ?? "").lowercased() == "md" }
}

struct FolderItem: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var createdAt: String?
}

@Observable
final class Store {
    static let shared = Store()

    let appSupport: String
    let dataDir: String
    let docsDir: String
    private let docsJson: String
    private let foldersJson: String
    private let exportsJson: String
    private let exportsDirsJson: String
    private let fm = FileManager.default

    private(set) var docs: [DocItem] = []
    private(set) var folders: [FolderItem] = []

    /// 导出记录：owner（"d:文档id" 或 "f:文件夹id"）→ 磁盘副本路径 → 当时写进去的正文
    /// 删除时只清理「内容完全一致」的副本，避免误删用户后来改过的文件
    var exportedFiles: [String: [String: String]] = [:]
    var exportedDirs: [String: [String]] = [:]

    private init() {
        let home = NSHomeDirectory()
        appSupport = home + "/Library/Application Support/" + kSubFolder
        let legacy = home + "/Library/Application Support/" + kLegacyFolder

        if !fm.fileExists(atPath: appSupport), fm.fileExists(atPath: legacy) {
            try? fm.moveItem(atPath: legacy, toPath: appSupport)
        }
        try? fm.createDirectory(atPath: appSupport, withIntermediateDirectories: true)
        try? fm.createDirectory(atPath: appSupport + "/docs", withIntermediateDirectories: true)

        let custom = ProcessInfo.processInfo.environment["OXTXT_DATA_DIR"]
        dataDir = (custom?.isEmpty == false) ? custom! : appSupport + "/data"
        docsDir = dataDir + "/docs"
        docsJson = dataDir + "/docs.json"
        foldersJson = dataDir + "/folders.json"
        exportsJson = dataDir + "/exports.json"
        exportsDirsJson = dataDir + "/exports-dirs.json"
        try? fm.createDirectory(atPath: dataDir, withIntermediateDirectories: true)
        try? fm.createDirectory(atPath: docsDir, withIntermediateDirectories: true)
        load()
    }

    func load() {
        docs = Store.readList(docsJson)
        folders = Store.readList(foldersJson)
        let dec = JSONDecoder()
        if let data = try? Data(contentsOf: URL(fileURLWithPath: exportsJson)) {
            exportedFiles = (try? dec.decode([String: [String: String]].self, from: data)) ?? [:]
        }
        if let data = try? Data(contentsOf: URL(fileURLWithPath: exportsDirsJson)) {
            exportedDirs = (try? dec.decode([String: [String]].self, from: data)) ?? [:]
        }
    }

    private func saveExports() {
        writeList(exportsJson, exportedFiles)
        writeList(exportsDirsJson, exportedDirs)
    }

    /// 记下「这一份副本是我写出去的」
    func noteExport(owner: String, path: String, text: String) {
        exportedFiles[owner, default: [:]][path] = text
        saveExports()
    }

    func noteExportDir(owner: String, dir: String) {
        var list = exportedDirs[owner] ?? []
        if !list.contains(dir) { list.append(dir); exportedDirs[owner] = list; saveExports() }
    }

    /// 在 App 里删除时，把记过的、没被改过的副本一起删掉
    func purgeExports(owner: String) {
        if let files = exportedFiles[owner] {
            for (path, text) in files {
                guard fm.fileExists(atPath: path) else { continue }
                let now = (try? String(contentsOfFile: path, encoding: .utf8)) ?? ""
                if now == text { try? fm.removeItem(atPath: path) }
            }
            exportedFiles[owner] = nil
        }
        if let dirs = exportedDirs[owner] {
            for dir in dirs {
                if let items = try? fm.contentsOfDirectory(atPath: dir), items.isEmpty {
                    try? fm.removeItem(atPath: dir)
                }
            }
            exportedDirs[owner] = nil
        }
        saveExports()
    }

    private static func readList<T: Decodable>(_ path: String) -> [T] {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return [] }
        return (try? JSONDecoder().decode([T].self, from: data)) ?? []
    }

    private func writeList<T: Encodable>(_ path: String, _ value: T) {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        guard let data = try? enc.encode(value) else { return }
        let tmp = path + ".tmp"
        try? data.write(to: URL(fileURLWithPath: tmp))
        try? fm.removeItem(atPath: path)
        try? fm.moveItem(atPath: tmp, toPath: path)
    }

    func save() {
        writeList(docsJson, docs)
        writeList(foldersJson, folders)
        NotificationCenter.default.post(name: .storeChanged, object: nil)
    }


    // 兜底：从任意「yyyy-MM-ddT…」里手动抠出年月日时分秒
    static func looseParse(_ raw: String) -> Date? {
        let parts = raw.split(separator: "T")
        guard parts.count == 2 else { return nil }
        let dp = parts[0].split(separator: "-")
        guard dp.count == 3,
              let y = Int(dp[0]), let mo = Int(dp[1]), let da = Int(dp[2]) else { return nil }
        let digits = parts[1].filter { $0.isNumber }
        guard digits.count >= 5,
              let sec = Int(digits.suffix(2)),
              let min = Int(digits.dropLast(2).suffix(2)),
              let hour = Int(digits.dropLast(4)) else { return nil }
        var c = DateComponents()
        c.year = y; c.month = mo; c.day = da; c.hour = hour; c.minute = min; c.second = sec
        return Calendar.current.date(from: c)
    }

    private static func now() -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return f.string(from: Date())
    }

    private static func newId() -> String {
        String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(8))
    }

    // 正文
    func contentPath(_ id: String) -> String { docsDir + "/" + id + ".txt" }

    func content(_ id: String) -> String {
        (try? String(contentsOfFile: contentPath(id), encoding: .utf8)) ?? ""
    }

    func saveContent(_ id: String, _ text: String, export: Bool = false) {
        try? text.write(toFile: contentPath(id), atomically: true, encoding: .utf8)
        if export { exportCopy(id, text) }
    }

    /// 把正文同步一份到「设置里指定的保存位置」（默认桌面）
    func exportCopy(_ id: String, _ text: String) {
        guard let d = doc(id) else { return }
        let dir = Config.shared.d.saveDir
        guard !dir.isEmpty else { return }
        try? fm.createDirectory(atPath: dir, withIntermediateDirectories: true)
        let title = d.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = title.isEmpty ? "未命名文档" : title
        let safe = base.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "-")
        let ext = d.isMarkdown ? "md" : "txt"
        var path = dir + "/" + safe + "." + ext
        var n = 2
        while fm.fileExists(atPath: path) && (try? String(contentsOfFile: path, encoding: .utf8)) != text {
            let existing = (try? String(contentsOfFile: path, encoding: .utf8)) ?? ""
            if existing == text { return }
            path = dir + "/" + safe + " " + String(n) + "." + ext
            n += 1
            if n > 99 { return }
        }
        try? text.write(toFile: path, atomically: true, encoding: .utf8)
        noteExport(owner: "d:" + id, path: path, text: text)
    }

    // 增删改
    @discardableResult
    func createDoc(folder: String? = nil, kind: String = "txt") -> DocItem {
        let isMd = kind.lowercased() == "md"
        let doc = DocItem(id: Store.newId(), title: isMd ? "未命名笔记" : "未命名文档",
                          folder: folder, createdAt: Store.now(), updatedAt: Store.now(),
                          kind: isMd ? "md" : "txt")
        docs.insert(doc, at: 0)
        saveContent(doc.id, "")
        save()
        return doc
    }

    @discardableResult
    func createFolder(name: String = "新建文件夹") -> FolderItem {
        let f = FolderItem(id: Store.newId(), name: name, createdAt: Store.now())
        folders.insert(f, at: 0)
        save()
        return f
    }

    func renameDoc(_ id: String, _ title: String) {
        guard let i = docs.firstIndex(where: { $0.id == id }) else { return }
        docs[i].title = title
        docs[i].updatedAt = Store.now()
        save()
    }

    func renameFolder(_ id: String, _ name: String) {
        guard let i = folders.firstIndex(where: { $0.id == id }) else { return }
        folders[i].name = name
        save()
    }

    func deleteDoc(_ id: String) {
        // 先把导出到桌面 / 保存位置上的副本清掉（只清内容没被改过的）
        purgeExports(owner: "d:" + id)
        docs.removeAll { $0.id == id }
        try? fm.removeItem(atPath: contentPath(id))
        save()
    }

    func dissolveFolder(_ id: String) {
        purgeExports(owner: "f:" + id)
        for i in docs.indices where docs[i].folder == id { docs[i].folder = nil }
        folders.removeAll { $0.id == id }
        save()
    }

    func moveDoc(_ id: String, folder: String?) {
        guard let i = docs.firstIndex(where: { $0.id == id }) else { return }
        docs[i].folder = folder
        docs[i].updatedAt = Store.now()
        save()
    }

    func touch(_ id: String) {
        guard let i = docs.firstIndex(where: { $0.id == id }) else { return }
        docs[i].updatedAt = Store.now()
        save()
    }

    func doc(_ id: String) -> DocItem? { docs.first { $0.id == id } }

    func docsIn(_ folder: String?) -> [DocItem] {
        docs.filter { $0.folder == folder }.sorted { ($0.updatedAt ?? "") > ($1.updatedAt ?? "") }
    }

    func countIn(_ folder: String?) -> Int { docs.filter { $0.folder == folder }.count }

    // 卡片展示
    func previewLines(_ id: String, count: Int = 5) -> [String] {
        let text = content(id).replacingOccurrences(of: "\r", with: "")
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return [] }
        return text.split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .prefix(count)
            .map { String($0) }
    }

    func metaLabel(_ id: String) -> String {
        let d = doc(id)
        let chars = content(id).replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: " ", with: "").count
        var when = d?.updatedAt ?? ""
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = TimeZone.current
        fmt.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        // 兼容早期写坏的本地化时间（如 2026-11-20T晚上7:38:31）
        let fmtCN = DateFormatter()
        fmtCN.locale = Locale(identifier: "zh_CN")
        fmtCN.timeZone = TimeZone.current
        fmtCN.dateFormat = "yyyy-MM-dd'T'ah:mm:ss"
        var parsed = fmt.date(from: String(when.prefix(19))) ?? fmtCN.date(from: when)
        if parsed == nil { parsed = Store.looseParse(when) }
        if let t = parsed {
            let cal = Calendar.current
            let day: String
            if cal.isDateInToday(t) { day = "今天" }
            else if cal.isDateInYesterday(t) { day = "昨天" }
            else {
                let f2 = DateFormatter(); f2.locale = Locale(identifier: "zh_CN"); f2.dateFormat = "M月d日"
                day = f2.string(from: t)
            }
            let f3 = DateFormatter()
            f3.locale = Locale(identifier: "en_US_POSIX"); f3.dateFormat = "HH:mm"
            when = day + " " + f3.string(from: t)
        }
        let tag = (d?.isMarkdown ?? false) ? "MD · " : ""
        return "\(tag)\(when) · \(chars) 字"
    }
}


// ============================================================
//  下面开始：Markdown（预览、导出用）
// ============================================================

import SwiftUI
import AppKit

// ============================================================
//  简版 Markdown 渲染：标题 / 列表 / 引用 / 代码块 / 分隔线
//  加粗 / 斜体 / 删除线 / 高亮 / 下划线 / span 字号颜色字体
//  <div align="center">…</div> 段落对齐
// ============================================================

enum MarkdownRenderer {
    static func render(_ source: String) -> NSAttributedString {
        let cfg = Config.shared.d
        let base = NSFont(name: "PingFang SC", size: CGFloat(cfg.fontSize)) ?? NSFont.systemFont(ofSize: CGFloat(cfg.fontSize))
        let out = NSMutableAttributedString()

        func attrs(size: CGFloat, weight: NSFont.Weight = .regular, align: NSTextAlignment = .left,
                   color: NSColor = Skin.p.text, mono: Bool = false) -> [NSAttributedString.Key: Any] {
            let f = mono ? NSFont.monospacedSystemFont(ofSize: size, weight: weight)
                         : (weight == .regular ? NSFont(name: base.fontName, size: size) ?? NSFont.systemFont(ofSize: size)
                                               : NSFont.systemFont(ofSize: size, weight: weight))
            let p = NSMutableParagraphStyle()
            p.alignment = align
            p.minimumLineHeight = CGFloat(cfg.lineHeight)
            p.maximumLineHeight = CGFloat(cfg.lineHeight)
            return [.font: f, .foregroundColor: color, .paragraphStyle: p]
        }

        let lines = source.replacingOccurrences(of: "\r", with: "").components(separatedBy: "\n")
        var i = 0
        var currentAlign: NSTextAlignment = .left

        while i < lines.count {
            let raw = lines[i]
            let t = raw.trimmingCharacters(in: .whitespaces)

            // <div align="…">
            if t.hasPrefix("<div"), t.contains("align=") {
                if t.contains("center") { currentAlign = .center }
                else if t.contains("right") { currentAlign = .right }
                else if t.contains("justify") { currentAlign = .justified }
                else { currentAlign = .left }
                i += 1
                continue
            }
            if t.hasPrefix("</div") {
                currentAlign = .left
                i += 1
                continue
            }

            // 代码块
            if t.hasPrefix("```") {
                i += 1
                var code: [String] = []
                while i < lines.count, !lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                    code.append(lines[i])
                    i += 1
                }
                i += 1
                let body = code.joined(separator: "\n") + "\n"
                out.append(NSAttributedString(string: body, attributes: attrs(size: CGFloat(cfg.fontSize) - 1, mono: true)))
                continue
            }

            if t.isEmpty {
                out.append(NSAttributedString(string: "\n", attributes: attrs(size: CGFloat(cfg.fontSize), align: currentAlign)))
                i += 1
                continue
            }

            // 分隔线
            if t.hasPrefix("---") || t.hasPrefix("***") || t == "———" {
                let p = NSMutableParagraphStyle()
                p.alignment = currentAlign
                out.append(NSAttributedString(string: "────────────────\n",
                                               attributes: [.font: base, .foregroundColor: Skin.p.line, .paragraphStyle: p]))
                i += 1
                continue
            }

            // 标题
            if t.hasPrefix("#") {
                let level = t.prefix(while: { $0 == "#" }).count
                let text = t.drop(while: { $0 == "#" }).trimmingCharacters(in: .whitespaces)
                let sizes: [CGFloat] = [26, 21, 17, 15, 14, 13]
                let s = sizes[min(level, 6) - 1]
                out.append(line(text, attrs(size: s, weight: .semibold, align: currentAlign)))
                i += 1
                continue
            }

            // 引用
            if t.hasPrefix("> ") {
                var quote: [String] = []
                while i < lines.count, lines[i].trimmingCharacters(in: .whitespaces).hasPrefix(">") {
                    quote.append(lines[i].trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "> ", with: ""))
                    i += 1
                }
                let p = NSMutableParagraphStyle()
                p.alignment = currentAlign
                p.firstLineHeadIndent = 12
                p.headIndent = 12
                p.minimumLineHeight = CGFloat(cfg.lineHeight)
                p.maximumLineHeight = CGFloat(cfg.lineHeight)
                let f = NSFont(name: base.fontName, size: CGFloat(cfg.fontSize)) ?? base
                out.append(NSAttributedString(string: quote.joined(separator: "\n") + "\n",
                                               attributes: [.font: f, .foregroundColor: Skin.p.textDim, .paragraphStyle: p]))
                continue
            }

            // 列表
            if t.hasPrefix("- ") || t.hasPrefix("* ") || t.hasPrefix("+ ") || t.range(of: "^\\d+\\. ", options: .regularExpression) != nil {
                let bullet: String
                if t.range(of: "^\\d+\\. ", options: .regularExpression) != nil {
                    bullet = String(t.prefix(while: { $0.isNumber || $0 == "." })) + " "
                } else {
                    bullet = "• "
                }
                var itemText = t
                if t.hasPrefix("- ") || t.hasPrefix("* ") || t.hasPrefix("+ ") {
                    itemText = String(t.dropFirst(2))
                } else if let r = t.range(of: "^\\d+\\. ", options: .regularExpression) {
                    itemText = String(t[r.upperBound...])
                }
                let p = NSMutableParagraphStyle()
                p.alignment = currentAlign
                p.firstLineHeadIndent = 8
                p.headIndent = 22
                p.minimumLineHeight = CGFloat(cfg.lineHeight)
                p.maximumLineHeight = CGFloat(cfg.lineHeight)
                let f = NSFont(name: base.fontName, size: CGFloat(cfg.fontSize)) ?? base
                out.append(NSAttributedString(string: bullet,
                                               attributes: [.font: f, .foregroundColor: Skin.p.textDim, .paragraphStyle: p]))
                out.append(inline(itemText, base: f, color: Skin.p.text))
                out.append(NSAttributedString(string: "\n", attributes: [.font: f, .paragraphStyle: p]))
                i += 1
                continue
            }

            let f = NSFont(name: base.fontName, size: CGFloat(cfg.fontSize)) ?? base
            let p = NSMutableParagraphStyle()
            p.alignment = currentAlign
            p.minimumLineHeight = CGFloat(cfg.lineHeight)
            p.maximumLineHeight = CGFloat(cfg.lineHeight)
            out.append(NSAttributedString(string: "", attributes: [.font: f, .paragraphStyle: p]))
            out.append(inline(raw, base: f, color: Skin.p.text))
            out.append(NSAttributedString(string: "\n", attributes: [.font: f, .paragraphStyle: p]))
            i += 1
        }
        return out
    }

    private static func line(_ s: String, _ attrs: [NSAttributedString.Key: Any]) -> NSAttributedString {
        NSAttributedString(string: s + "\n", attributes: attrs)
    }

    // 行内语法
    private static func inline(_ s: String, base: NSFont, color: NSColor) -> NSAttributedString {
        let out = NSMutableAttributedString()
        var i = s.startIndex
        var buf = ""

        func flush() {
            if !buf.isEmpty {
                out.append(NSAttributedString(string: buf, attributes: [.font: base, .foregroundColor: color]))
                buf = ""
            }
        }

        while i < s.endIndex {
            let rest = s[i...]

            if rest.hasPrefix("**"), let r = rest.dropFirst(2).range(of: "**") {
                flush()
                let inner = String(rest.dropFirst(2)[..<r.lowerBound])
                let f = NSFont(descriptor: base.fontDescriptor.withSymbolicTraits(.bold), size: base.pointSize) ?? base
                out.append(NSAttributedString(string: inner, attributes: [.font: f, .foregroundColor: color]))
                i = r.upperBound
                continue
            }
            if rest.hasPrefix("~~"), let r = rest.dropFirst(2).range(of: "~~") {
                flush()
                let inner = String(rest.dropFirst(2)[..<r.lowerBound])
                out.append(NSAttributedString(string: inner, attributes: [
                    .font: base, .foregroundColor: color, .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                ]))
                i = r.upperBound
                continue
            }
            if rest.hasPrefix("=="), let r = rest.dropFirst(2).range(of: "==") {
                flush()
                let inner = String(rest.dropFirst(2)[..<r.lowerBound])
                out.append(NSAttributedString(string: inner, attributes: [
                    .font: base, .foregroundColor: color, .backgroundColor: NSColor(hex: "#FFE97A"),
                ]))
                i = r.upperBound
                continue
            }
            if rest.hasPrefix("<u>"), let r = rest.dropFirst(3).range(of: "</u>") {
                flush()
                let inner = String(rest.dropFirst(3)[..<r.lowerBound])
                out.append(NSAttributedString(string: inner, attributes: [
                    .font: base, .foregroundColor: color, .underlineStyle: NSUnderlineStyle.single.rawValue,
                ]))
                i = r.upperBound
                continue
            }
            if rest.hasPrefix("*"), !rest.hasPrefix("**"), let r = rest.dropFirst(1).range(of: "*") {
                flush()
                let inner = String(rest.dropFirst(1)[..<r.lowerBound])
                let f = NSFont(descriptor: base.fontDescriptor.withSymbolicTraits(.italic), size: base.pointSize) ?? base
                out.append(NSAttributedString(string: inner, attributes: [.font: f, .foregroundColor: color]))
                i = r.upperBound
                continue
            }
            if rest.hasPrefix("`"), let r = rest.dropFirst(1).range(of: "`") {
                flush()
                let inner = String(rest.dropFirst(1)[..<r.lowerBound])
                out.append(NSAttributedString(string: inner, attributes: [
                    .font: NSFont.monospacedSystemFont(ofSize: base.pointSize - 1, weight: .regular),
                    .foregroundColor: color,
                ]))
                i = r.upperBound
                continue
            }
            if rest.hasPrefix("<span"), let end = rest.range(of: ">") {
                // <span style="...">文字</span>
                let style = String(rest[..<end.lowerBound])
                if let close = rest.range(of: "</span>") {
                    flush()
                    var f = base
                    var c = color
                    if let r = style.range(of: "font-size:\\s*([0-9.]+)", options: .regularExpression) {
                        let v = style[r].components(separatedBy: CharacterSet(charactersIn: ": ")).last ?? ""
                        if let size = Double(v) { f = NSFont(name: base.fontName, size: CGFloat(size)) ?? base }
                    }
                    if let r = style.range(of: "#[0-9a-fA-F]{3,8}", options: .regularExpression) {
                        c = NSColor(hex: String(style[r]))
                    }
                    if let r = style.range(of: "font-family:\\s*[^;\"]+", options: .regularExpression) {
                        let fam = String(style[r]).replacingOccurrences(of: "font-family:", with: "")
                            .trimmingCharacters(in: CharacterSet(charactersIn: " ;\"'"))
                        f = NSFont(name: fam, size: f.pointSize) ?? f
                    }
                    let inner = String(rest[end.upperBound..<close.lowerBound])
                    out.append(NSAttributedString(string: inner, attributes: [.font: f, .foregroundColor: c]))
                    i = close.upperBound
                    continue
                }
            }

            buf.append(s[i])
            i = s.index(after: i)
        }
        flush()
        return out
    }
}

struct MarkdownPreview: View {
    var text: String
    var body: some View {
        ScrollView {
            Text(AttributedString(MarkdownRenderer.render(text)))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineSpacing(max(0, CGFloat(Config.shared.d.lineHeight) - CGFloat(Config.shared.d.fontSize) - 3))
                .padding(.horizontal, 22)
                .padding(.top, 10)
                .padding(.bottom, 14)
        }
    }
}

// ============================================================
//  02 界面部分（接在上面同一个文件里，方便你一次看完）
// ============================================================

// ============================================================
//  第 2 个文件：所有界面
//  ------------------------------------------------------------
//  顺序：
//   1. 视觉零件（颜色、玻璃、稿纸横线、胶囊、卡片）
//   2. 首页（多选、框选框、拖拽预览、底部胶囊）
//   3. 文件夹窗口
//   4. 设置页
//   5. 编辑器（工具栏、正文、稿纸对齐）
//  所有界面文字都是中文，配色统一在 Skin 里改。
// ============================================================

import SwiftUI
import AppKit

// ============================================================
//  通用视觉组件（标准 SwiftUI + 官方 Liquid Glass）
// ============================================================

let kRadius: CGFloat = 13

// ---------- 官方液态玻璃 ----------

extension View {
    /// SwiftUI 自带的 Liquid Glass 材质（macOS 26+ 的系统级玻璃）
    @ViewBuilder
    func glassPanel(radius: CGFloat = kRadius,
                    tint: Color? = nil,
                    interactive: Bool = false,
                    lit: Bool = true) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        self
            .glassEffect(glassMaterial(tint: tint ?? Color.white.opacity(Skin.isDark ? 0.05 : 0.55),
                                       interactive: interactive),
                         in: .rect(cornerRadius: radius))
            .overlay {
                if lit {
                    shape.strokeBorder(Color.white.opacity(Skin.isDark ? 0.14 : 0.42), lineWidth: 0.6)
                }
            }
            .shadow(color: .black.opacity(Skin.isDark ? 0.30 : 0.05), radius: 7, y: 2)
    }

    /// 玻璃材质本身（可供 GlassEffectContainer 里组合使用）
    func glassMaterial(tint: Color? = nil, interactive: Bool = false) -> Glass {
        var glass: Glass = .regular
        if let tint { glass = glass.tint(tint) }
        if interactive { glass = glass.interactive() }
        return glass
    }
}

// 一张普通卡片（纸面 / 面板）
struct RoundedCard: ViewModifier {
    var radius: CGFloat = kRadius
    var fill: NSColor? = nil
    var stroke: NSColor? = nil
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Color(nsColor: fill ?? Skin.p.panel))
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Color(nsColor: stroke ?? Skin.p.border), lineWidth: 1)
            )
    }
}

extension View {
    func card(radius: CGFloat = kRadius, fill: NSColor? = nil, stroke: NSColor? = nil) -> some View {
        modifier(RoundedCard(radius: radius, fill: fill, stroke: stroke))
    }
}

// 稿纸横线
struct RuledPaper: View {
    var lineHeight: CGFloat = 20
    var color: NSColor = Skin.p.line
    var topInset: CGFloat = 8
    var body: some View {
        Canvas { ctx, size in
            var y = topInset
            while y < size.height {
                var p = Path()
                p.move(to: CGPoint(x: 0, y: y))
                p.addLine(to: CGPoint(x: size.width, y: y))
                ctx.stroke(p, with: .color(Color(nsColor: color)), lineWidth: 1)
                y += lineHeight
            }
        }
        .allowsHitTesting(false)
    }
}

// 稿纸输入框：横线是「固定格线」，不管有没有字都画满整张纸。
// 行高被锁死在 linePitch 上，横线画在每行的基线上，所以光标底边、字脚正好落在线上。
/// 稿纸容器：像真正的书页一样，只能翻页，不能拿滚轮上下滑
final class PagedScrollView: NSScrollView {
    override func scrollWheel(with event: NSEvent) {
        // 不允许自由滚动：页面切换只走左右翻页
    }
}

final class RuledTextView: NSTextView {
    /// 翻页模式：纸只能整页翻，绝不让 NSTextView 自己上下滚
    override func scrollRangeToVisible(_ range: NSRange) {
        // 故意留空：换页由 EditorController.followCaretToNewPage / flipToPage 负责
    }
    var ruleColor: NSColor = .clear
    var showsRules: Bool = true
    /// 画线用的字体（只用来取 descent，不往正文套）
    var ruleFont: NSFont?
    /// 行距（= 每个字行的高度），由 Controller 按设置里的行高同步
    var linePitch: CGFloat = 26
    /// 稿纸上方留白
    let topInset: CGFloat = 10
    /// 每页多少行（按可视高度算，窗口大小变了会重算）
    var pageLines: Int = 24

    var pageHeight: CGFloat { CGFloat(max(1, pageLines)) * max(8, linePitch) }

    override func draw(_ dirtyRect: NSRect) {
        if showsRules { drawRuledGrid(in: dirtyRect) }
        super.draw(dirtyRect)
    }

    /// 固定格线：从纸顶一直画到可视区域底部，空纸也有线
    private func drawRuledGrid(in dirty: NSRect) {
        let pitch = max(8, linePitch)
        let width = bounds.width
        let descent = abs((ruleFont ?? font ?? NSFont.systemFont(ofSize: 15)).descender)
        let firstRow = max(0, Int(floor((dirty.minY - topInset) / pitch)) - 1)
        let lastRow = Int(ceil((dirty.maxY - topInset) / pitch)) + 1
        if lastRow < firstRow { return }
        for row in firstRow...lastRow {
            // 线压在光标的下边缘：字照样踩线，光标也不再往下冒头
            let y = topInset + CGFloat(row + 1) * pitch - descent + 1.0
            ruleColor.setFill()
            NSBezierPath(rect: NSRect(x: 0, y: y, width: width, height: 1)).fill()
        }
    }

    /// 内容变长 / 窗口变高时，把纸的高度补齐到整数页，空页也能显示格线
    func refreshPaperExtent() {
        guard let lm = layoutManager, let tc = textContainer else { return }
        lm.ensureLayout(for: tc)
        let used = lm.usedRect(for: tc).height
        let pages = max(1, Int(ceil(max(used, 1) / max(1, pageHeight))))
        let target = CGFloat(pages) * pageHeight + topInset * 2
        if abs(frame.height - target) > 0.5 {
            setFrameSize(NSSize(width: frame.width, height: target))
        }
    }

    /// 某个字符在第几行（0 开始）
    func lineIndex(atCharacter index: Int) -> Int {
        guard let lm = layoutManager, lm.numberOfGlyphs > 0 else { return 0 }
        let len = (string as NSString).length
        let ch = min(max(0, index), max(0, len))
        let glyph = min(lm.glyphIndexForCharacter(at: ch), lm.numberOfGlyphs - 1)
        let rect = lm.lineFragmentRect(forGlyphAt: glyph, effectiveRange: nil)
        return max(0, Int(floor(rect.minY / max(8, linePitch) + 0.02)))
    }

    func pageIndex(atCharacter index: Int) -> Int {
        max(0, lineIndex(atCharacter: index) / max(1, pageLines))
    }

    /// 把输入框的一块区域拍成图（翻页动画用）
    func pageImage(of rect: NSRect) -> NSImage? {
        let r = rect.intersection(bounds)
        guard !r.isEmpty else { return nil }
        let data = dataWithPDF(inside: r)
        guard let pdfImg = NSImage(data: data) else { return nil }
        let scale: CGFloat = 2
        guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                        pixelsWide: Int(r.width * scale),
                                        pixelsHigh: Int(r.height * scale),
                                        bitsPerSample: 8, samplesPerPixel: 4,
                                        hasAlpha: true, isPlanar: false,
                                        colorSpaceName: .deviceRGB,
                                        bytesPerRow: 0, bitsPerPixel: 0) else { return nil }
        rep.size = r.size
        NSGraphicsContext.saveGraphicsState()
        if let ctx = NSGraphicsContext(bitmapImageRep: rep) {
            NSGraphicsContext.current = ctx
            pdfImg.draw(in: NSRect(origin: .zero, size: r.size))
        }
        NSGraphicsContext.restoreGraphicsState()
        let img = NSImage(size: r.size)
        img.addRepresentation(rep)
        return img
    }

    /// 某一页第一行行首的字符位置（翻页后把光标放上去）
    func characterIndex(atPageTop page: Int) -> Int {
        guard let lm = layoutManager, let tc = textContainer, lm.numberOfGlyphs > 0 else { return 0 }
        let y = max(0, CGFloat(page) * pageHeight) + 1
        let glyph = lm.glyphIndex(for: NSPoint(x: 0, y: y), in: tc)
        let idx = lm.characterIndexForGlyph(at: min(glyph, lm.numberOfGlyphs - 1))
        return min(idx, (string as NSString).length)
    }

    override func didChangeText() {
        super.didChangeText()
        refreshPaperExtent()
    }
}

// ---------- 三个点：真正的菜单 ----------

struct DotsItem: Identifiable {
    let id = UUID()
    var title: String
    var danger: Bool = false
    var action: () -> Void
}

struct DotsButton: View {
    var items: [DotsItem]

    var body: some View {
        Menu {
            ForEach(items) { it in
                Button(role: it.danger ? .destructive : nil) { it.action() } label: { Text(it.title) }
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(nsColor: Skin.p.textDim))
                .frame(width: 26, height: 22)
                .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }
}

// ---------- 胶囊选择器 ----------

struct Pills: View {
    var options: [String]
    var index: Int
    var onPick: (Int) -> Void

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<options.count, id: \.self) { i in
                let on = i == index
                Button {
                    withAnimation(.easeInOut(duration: 0.16)) { onPick(i) }
                } label: {
                    Text(options[i])
                        .font(.system(size: 12, weight: on ? .semibold : .regular))
                        .foregroundStyle(Color(nsColor: on ? Skin.p.text : Skin.p.textDim))
                        .padding(.horizontal, 12)
                        .frame(height: 26)
                        .background {
                            if on {
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(Color(nsColor: Skin.p.sheet))
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .glassPanel(radius: 11, interactive: true)
        .fixedSize()
    }
}

// ---------- 开关 ----------

struct Lever: View {
    var on: Bool
    var onChange: (Bool) -> Void
    var body: some View {
        Toggle(isOn: Binding(get: { on }, set: { onChange($0) })) { EmptyView() }
            .toggleStyle(.switch)
            .labelsHidden()
            .controlSize(.mini)
    }
}

// ---------- Logo ----------

struct LogoImage: View {
    /// App 里所有位置（关于页 / 引导页 / 启动浮层）都读这一份 icon.icns，保证和访达、Dock 完全一致
    static let appIcon: NSImage? = {
        // 优先用访达那张图标的 1024 快照（AppIcon.png），它在任何进程里都稳定
        if let img = Bundle.main.image(forResource: "AppIcon") { return img }
        // 兜底：系统渲染图 → icns
        let src = NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath)
        if src.representations.contains(where: { $0.pixelsWide >= 256 }) { return src }
        guard let path = Bundle.main.path(forResource: "icon", ofType: "icns") else { return nil }
        return NSImage(contentsOfFile: path)
    }()

    var size: CGFloat = 96
    var body: some View {
        Group {
            if let img = LogoImage.appIcon {
                Image(nsImage: img)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
            } else if let appIcon = NSApp.applicationIconImage, appIcon.size.width > 32 {
                Image(nsImage: appIcon)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                        .fill(LinearGradient(
                            colors: [Color(red: 1.0, green: 0.63, blue: 0.04),
                                     Color(red: 0.97, green: 0.93, blue: 0.54)],
                            startPoint: .top, endPoint: .bottom))
                    Text("π")
                        .font(.system(size: size * 0.58, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
        .frame(width: size, height: size)
    }
}


// ---------- 鼠标形态 ----------

extension View {
    /// 悬停变「手指」，离开还原
    func hoverHand() -> some View {
        onHover { inside in
            if inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
        }
    }

    /// 悬停变「文本输入」光标
    func hoverIBeam() -> some View {
        onHover { inside in
            if inside { NSCursor.iBeam.push() } else { NSCursor.pop() }
        }
    }
}

// ---------- 卡片坐标收集 ----------

struct CardFrameKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}


// ============================================================
//  首页
// ============================================================

import SwiftUI
import AppKit
import Observation

// 主页状态：标准的可观察模型，界面自动刷新
@Observable
final class HomeModel {
    static var shared = HomeModel()
    var selectedDoc: String?
    var selectedFolder: String?
    var toast: String?
    var selection: Set<String> = []
    var draggingSelection = false
    var dragPoint: CGPoint?
    var frames: [String: CGRect] = [:]
    var order: [String] = []
    var marqueeStart: CGPoint?
    /// 框选进行中的鼠标位置（由窗口级鼠标监听写入；nil 表示没在框选）
    var marqueePoint: CGPoint?

    func clearSelection() { selection.removeAll() }
    var hasFolderSelected: Bool { selection.contains { $0.hasPrefix("f:") } }
    private var lastKey: String?
    private var lastAt: Date = .distantPast
    /// 单击 / ⌘ 单击 / ⇧ 单击 / 双击，全部在这一处判断
    /// 说明：SwiftUI 的 onTapGesture 拿不到修饰键，所以直接读当前事件的修饰键
    func click(_ key: String, onDouble: @escaping () -> Void) {
        let flags = NSEvent.modifierFlags
        if flags.contains(.command) {
            lastKey = key
            lastAt = .distantPast
            if selection.contains(key) { selection.remove(key) } else { selection.insert(key) }
            return
        }
        if flags.contains(.shift), let anchor = lastKey, let a = order.firstIndex(of: anchor),
           let b = order.firstIndex(of: key) {
            let r = a < b ? a...b : b...a
            selection = Set(order[r])
            lastAt = Date()
            return
        }
        let now = Date()
        if lastKey == key, now.timeIntervalSince(lastAt) < 0.5 {
            // 同一个位置 0.5 秒内点第二下 = 双击打开
            lastKey = nil
            lastAt = .distantPast
            onDouble()
        } else {
            lastKey = key
            lastAt = now
            // 普通单击：只选中这一个（想多选必须按 ⌘ 或 ⇧）
            selection = [key]
        }
    }

    /// 列表视图专用：永远只选一个。⌘ / ⇧ 都不生效（列表里不允许多选）
    func clickSingle(_ key: String, onDouble: @escaping () -> Void) {
        let now = Date()
        if lastKey == key, now.timeIntervalSince(lastAt) < 0.5 {
            lastKey = nil
            lastAt = .distantPast
            selection = [key]
            onDouble()
        } else {
            lastKey = key
            lastAt = now
            selection = [key]
        }
    }

    func toggle(_ key: String) {
        if selection.contains(key) { selection.remove(key) } else { selection.insert(key) }
    }
    @ObservationIgnored weak var window: NSWindow?

    func selectDoc(_ id: String?) {
        selectedDoc = id
        selectedFolder = nil
        if let id { selection = ["d:" + id] } else { selection.removeAll() }
    }

    func selectFolder(_ id: String?) {
        selectedFolder = id
        selectedDoc = nil
        if let id { selection = ["f:" + id] } else { selection.removeAll() }
    }

    func say(_ text: String) {
        toast = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in
            guard let self, self.toast == text else { return }
            self.toast = nil
        }
    }
}

struct HomeView: View {
    private var folders: [FolderItem] { Store.shared.folders }
    private var rootDocs: [DocItem] { Store.shared.docsIn(nil) }
    private let m = HomeModel.shared

    var body: some View {
        VStack(spacing: 0) {
            banner
            HStack(spacing: 12) {
                NewDocBar(onNew: { md in newDoc(markdown: md, folder: nil) })
                NewFolderBar { newFolder() }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 54)
            .offset(y: -27)
            .zIndex(2)

            ScrollView {
                if Config.shared.d.viewList {
                    listView
                } else {
                    gridView
                }
            }
            .contextMenu {
                Button("新建文档") { newDoc(markdown: false, folder: nil) }
                Button("新建 Markdown") { newDoc(markdown: true, folder: nil) }
                Divider()
                Button("新建文件夹") { newFolder() }
                Divider()
                Button(Config.shared.d.viewList ? "切换网格视图" : "切换列表视图") {
                    Config.shared.set { $0.viewList.toggle() }
                }
            }
        }
        .padding(.bottom, 40)
        .background(Color(nsColor: Skin.p.bg))
        .coordinateSpace(name: "root")
        .onPreferenceChange(CardFrameKey.self) {
            m.frames = $0
            m.order = $0.keys.sorted()
        }
        .overlay(alignment: .topLeading) { marqueeLayer }
        // 拖动时跟着鼠标的小卡片
        .overlay(alignment: .topLeading) { dragPreview }
        .overlay(alignment: .bottom) {
            if let t = m.toast {
                Text(t)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(nsColor: Skin.p.text))
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .glassPanel(radius: 13)
                    .padding(.bottom, 22)
            }
        }
    }

    // ---------- 欢迎条 ----------

    private var banner: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("欢迎使用 OπTXT")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(nsColor: Skin.p.text))
            Text("新一代文本编辑工具")
                .font(.system(size: 12))
                .foregroundStyle(Color(nsColor: Skin.p.textDim))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 36)
        .glassPanel(radius: kRadius, tint: Color(nsColor: Skin.p.accent).opacity(Skin.isDark ? 0.10 : 0.28))
        .padding(.horizontal, 40)
        .padding(.top, 20)
    }

    // ---------- 网格 ----------

    private var gridView: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 206), spacing: 18)],
                  alignment: .leading, spacing: 28) {
            ForEach(folders) { f in
                let key = "f:" + f.id
                FolderCard(name: f.name, count: Store.shared.countIn(f.id),
                           selected: m.selection.contains(key), menu: [
                    DotsItem(title: "打开") { openFolder(f) },
                    DotsItem(title: "重命名…") { renameFolder(f) },
                    DotsItem(title: "解散文件夹", danger: true) {
                        Store.shared.dissolveFolder(f.id)
                    },
                ])
                    .hoverHand()
                    .background(frameReader(key))
                    .onTapGesture { m.click(key) { openFolder(f) } }
                    .contextMenu {
                        Button("打开") { openFolder(f) }
                        Button("重命名…") { renameFolder(f) }
                        Button(m.selection.count > 1 && m.selection.contains(key) ? "解散选中的 \(m.selection.count) 项" : "解散文件夹",
                               role: .destructive) {
                            if m.selection.count > 1 && m.selection.contains(key) {
                                deleteSelection()
                            } else {
                                Store.shared.dissolveFolder(f.id)
                                refresh()
                            }
                        }
                    }
            }
            ForEach(rootDocs) { d in
                let key = "d:" + d.id
                DocCard(doc: d, selected: m.selection.contains(key), menu: [
                    DotsItem(title: "打开") { open(d) },
                    DotsItem(title: "重命名…") { WindowManager.shared.renameDoc(d.id) },
                    DotsItem(title: "移动到文件夹…") { move(d) },
                    DotsItem(title: "删除", danger: true) { delete(d) },
                ])
                .hoverHand()
                .background(frameReader(key))
                .onTapGesture { m.click(key) { open(d) } }
                .contextMenu {
                    if m.selection.count > 1 && m.selection.contains(key) {
                        Button("删除选中的 \(m.selection.count) 项", role: .destructive) { deleteSelection() }
                        Button("移到文件夹…") { moveSelection() }
                        Button("导出…") { exportSelection() }
                    } else {
                        Button("打开") { open(d) }
                        Button("重命名…") { WindowManager.shared.renameDoc(d.id) }
                        Button("移动到…") { move(d) }
                        Divider()
                        Button("删除", role: .destructive) { delete(d) }
                    }
                }
                .simultaneousGesture(selectionDrag(key))
            }
        }
        .padding(.horizontal, 40)
        .padding(.top, 26)
        .padding(.bottom, 70)
    }

    // 记录每张卡片的坐标，供框选命中判断用
    private func frameReader(_ key: String) -> some View {
        GeometryReader { p in
            Color.clear.preference(key: CardFrameKey.self,
                                   value: [key: p.frame(in: .named("root"))])
        }
    }

    // ---------- 框选 ----------

    @ViewBuilder
    private var marqueeLayer: some View {
        if let s0 = m.marqueeStart, s0.x > -9000, let p = m.marqueePoint {
            let r = CGRect(x: min(s0.x, p.x), y: min(s0.y, p.y),
                           width: abs(p.x - s0.x), height: abs(p.y - s0.y))
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color(nsColor: Skin.p.accent).opacity(0.16))
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(Color(nsColor: Skin.p.accent).opacity(0.85), lineWidth: 1)
                )
                .frame(width: max(r.width, 1), height: max(r.height, 1))
                .offset(x: r.minX, y: r.minY)
                .allowsHitTesting(false)
        }
    }

    // 拖动已选中的卡片：松手时看落点 —— 文件夹卡片 → 移进去；窗口外 → 放到桌面
    private func selectionDrag(_ key: String) -> some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .named("root"))
            .onChanged { v in
                guard m.selection.contains(key) else { return }
                if !m.draggingSelection {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                        m.draggingSelection = true
                    }
                }
                m.dragPoint = v.location
            }
            .onEnded { v in
                guard m.selection.contains(key) else { return }
                let point = v.location
                withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                    m.draggingSelection = false
                    m.dragPoint = nil
                }
                handleDrop(at: point, sourceKey: key)
            }
    }

    private func handleDrop(at p: CGPoint, sourceKey: String) {
        let docs = selectedDocIDs
        guard !docs.isEmpty else { return }
        // 1) 拖到某个已经打开的文件夹窗口里
        if let sp = screenPoint(p), let fid = WindowManager.shared.folderID(atScreen: sp) {
            for id in docs { Store.shared.moveDoc(id, folder: fid) }
            m.say("已移入「\(Store.shared.folders.first { $0.id == fid }?.name ?? "文件夹")」")
            withAnimation(.easeOut(duration: 0.18)) { m.clearSelection() }
            refresh()
            return
        }
        // 2) 落在首页的文件夹卡片上（不能是正在拖的那个文件夹自己）
        if let target = m.frames.first(where: {
            $0.key.hasPrefix("f:") && $0.value.contains(p) && $0.key != sourceKey
        })?.key {
            let fid = String(target.dropFirst(2))
            for id in docs { Store.shared.moveDoc(id, folder: fid) }
            m.say("已移入「\(Store.shared.folders.first { $0.id == fid }?.name ?? "文件夹")」")
            withAnimation(.easeOut(duration: 0.18)) { m.clearSelection() }
            refresh()
            return
        }
        // 3) 拖到窗口外面 → 放到桌面
        if isOutsideWindow(p) {
            exportToDesktop(docs)
            m.say("已放到桌面")
            withAnimation(.easeOut(duration: 0.18)) { m.clearSelection() }
        }
    }

    private func screenPoint(_ p: CGPoint) -> NSPoint? {
        guard let w = m.window, let content = w.contentView else { return nil }
        return w.convertPoint(toScreen: NSPoint(x: p.x, y: content.bounds.height - p.y))
    }

    private func isOutsideWindow(_ p: CGPoint) -> Bool {
        guard let w = m.window, let sp = screenPoint(p) else { return false }
        return !w.frame.contains(sp)
    }

    /// 把文档写成文件放到桌面（重名自动加序号）
    private func exportToDesktop(_ ids: [String]) {
        guard !ids.isEmpty else { return }
        let dir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
        let fm = FileManager.default
        for id in ids {
            guard let doc = Store.shared.docs.first(where: { $0.id == id }) else { continue }
            let ext = doc.isMarkdown ? "md" : "txt"
            let base = doc.title.replacingOccurrences(of: "/", with: "-")
            var url = dir.appendingPathComponent("\(base).\(ext)")
            var n = 2
            while fm.fileExists(atPath: url.path) {
                url = dir.appendingPathComponent("\(base) \(n).\(ext)")
                n += 1
            }
            let text = Store.shared.content(id)
            try? text.write(to: url, atomically: true, encoding: .utf8)
            Store.shared.noteExport(owner: "d:" + id, path: url.path, text: text)
        }
    }

    /// 拖动时跟着鼠标的小卡片（缩小、半透明，像系统拖拽预览）
    @ViewBuilder
    private var dragPreview: some View {
        if m.draggingSelection, let p = m.dragPoint {
            HStack(spacing: 8) {
                Image(systemName: m.hasFolderSelected ? "folder" : "doc.text")
                    .font(.system(size: 12))
                Text("\(m.selection.count) 项")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(Color(nsColor: Skin.p.text))
            .padding(.horizontal, 12)
            .frame(height: 34)
            .glassPanel(radius: 10, tint: Color.white.opacity(0.8))
            .scaleEffect(0.96)
            .shadow(color: .black.opacity(0.18), radius: 10, y: 5)
            .position(x: p.x + 18, y: p.y + 14)
            .allowsHitTesting(false)
            .transition(.opacity)
        }
    }

    // ---------- 批量动作 ----------

    private var selectedDocIDs: [String] { m.selection.filter { $0.hasPrefix("d:") }.map { String($0.dropFirst(2)) } }
    private var selectedFolderIDs: [String] { m.selection.filter { $0.hasPrefix("f:") }.map { String($0.dropFirst(2)) } }

    private func deleteSelection() {
        guard !m.selection.isEmpty else { return }
        let a = NSAlert()
        a.messageText = "删除选中的 \(m.selection.count) 项？"
        a.informativeText = "删除后无法恢复。导出到桌面 / 保存位置上的同名副本也会一起删掉（你在外面改过的不动）。"
        a.addButton(withTitle: "删除")
        a.addButton(withTitle: "取消")
        guard a.runModal() == .alertFirstButtonReturn else { return }
        for id in selectedDocIDs { Store.shared.deleteDoc(id) }
        for id in selectedFolderIDs { Store.shared.dissolveFolder(id) }
        withAnimation(.easeOut(duration: 0.18)) { m.clearSelection() }
        refresh()
    }

    private func moveSelection() {
        guard !selectedDocIDs.isEmpty else { return }
        let alert = NSAlert()
        alert.messageText = "把选中的 \(selectedDocIDs.count) 篇文档移到…"
        let popup = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 240, height: 26))
        popup.addItem(withTitle: "（首页根目录）")
        for f in Store.shared.folders { popup.addItem(withTitle: f.name) }
        alert.accessoryView = popup
        alert.addButton(withTitle: "移动")
        alert.addButton(withTitle: "取消")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let idx = popup.indexOfSelectedItem
        let target = idx <= 0 ? nil : Store.shared.folders[idx - 1].id
        for id in selectedDocIDs { Store.shared.moveDoc(id, folder: target) }
        withAnimation(.easeOut(duration: 0.18)) { m.clearSelection() }
        refresh()
    }

    private func exportSelection() {
        guard !m.selection.isEmpty else { return }
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.prompt = "导出到这里"
        guard panel.runModal() == .OK, let dir = panel.url else { return }
        let fm = FileManager.default
        for id in selectedDocIDs {
            guard let doc = Store.shared.docs.first(where: { $0.id == id }) else { continue }
            let name = doc.title.replacingOccurrences(of: "/", with: "-")
            let ext = doc.isMarkdown ? "md" : "txt"
            let url = dir.appendingPathComponent("\(name).\(ext)")
            let text = Store.shared.content(id)
            try? text.write(to: url, atomically: true, encoding: .utf8)
            Store.shared.noteExport(owner: "d:" + id, path: url.path, text: text)
        }
        for id in selectedFolderIDs {
            guard let f = Store.shared.folders.first(where: { $0.id == id }) else { continue }
            let sub = dir.appendingPathComponent(f.name)
            try? fm.createDirectory(at: sub, withIntermediateDirectories: true)
            Store.shared.noteExportDir(owner: "f:" + id, dir: sub.path)
            for doc in Store.shared.docsIn(id) {
                let ext = doc.isMarkdown ? "md" : "txt"
                let url = sub.appendingPathComponent("\(doc.title).\(ext)")
                let text = Store.shared.content(doc.id)
                try? text.write(to: url, atomically: true, encoding: .utf8)
                Store.shared.noteExport(owner: "f:" + id, path: url.path, text: text)
            }
        }
        m.say("已导出 \(m.selection.count) 项")
        withAnimation(.easeOut(duration: 0.18)) { m.clearSelection() }
    }

    // ---------- 列表 ----------

    private var listView: some View {
        VStack(spacing: 0) {
            ForEach(folders) { f in
                let key = "f:" + f.id
                listRow(key: key,
                        icon: "folder",
                        title: f.name,
                        meta: "\(Store.shared.countIn(f.id)) 个文档",
                        onOpen: { openFolder(f) },
                        menu: [
                            DotsItem(title: "打开") { openFolder(f) },
                            DotsItem(title: "重命名…") { renameFolder(f) },
                            DotsItem(title: "解散文件夹", danger: true) {
                                Store.shared.dissolveFolder(f.id); refresh()
                            },
                        ])
                Divider().overlay(Color(nsColor: Skin.p.line))
            }
            ForEach(rootDocs) { d in
                let key = "d:" + d.id
                listRow(key: key,
                        icon: d.isMarkdown ? "doc.text" : "doc",
                        title: d.title,
                        meta: Store.shared.metaLabel(d.id),
                        onOpen: { open(d) },
                        menu: [
                            DotsItem(title: "打开") { open(d) },
                            DotsItem(title: "重命名…") { WindowManager.shared.renameDoc(d.id) },
                            DotsItem(title: "移动到文件夹…") { move(d) },
                            DotsItem(title: "删除", danger: true) { delete(d) },
                        ])
                Divider().overlay(Color(nsColor: Skin.p.line))
            }
        }
        .padding(.horizontal, 40)
        .padding(.top, 20)
        .padding(.bottom, 60)
    }

    /// 列表的一行：单击只选中这一行（列表不允许多选）、双击打开、右边三个点出菜单
    private func listRow(key: String, icon: String, title: String, meta: String,
                         onOpen: @escaping () -> Void, menu: [DotsItem]) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(Color(nsColor: Skin.p.textDim))
                .frame(width: 18)
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(Color(nsColor: Skin.p.text))
                .lineLimit(1)
            Spacer(minLength: 8)
            Text(meta)
                .font(.system(size: 11))
                .foregroundStyle(Color(nsColor: Skin.p.textDim))
            DotsButton(items: menu)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(m.selection.contains(key)
                      ? Color(nsColor: Skin.p.accent).opacity(Skin.isDark ? 0.25 : 0.35)
                      : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture { m.clickSingle(key) { onOpen() } }
        .contextMenu {
            ForEach(Array(menu.enumerated()), id: \.offset) { _, it in
                Button(role: it.danger ? .destructive : nil) { it.action() } label: { Text(it.title) }
            }
        }
        .hoverHand()
    }

    // ---------- 动作 ----------

    private func refresh() {
        NotificationCenter.default.post(name: .storeChanged, object: nil)
    }

    private func newDoc(markdown: Bool, folder: String?) {
        let md = markdown || Config.shared.d.markdownDefault
        let doc = Store.shared.createDoc(folder: folder, kind: md ? "md" : "txt")
        refresh()
        WindowManager.shared.openDoc(doc)
    }

    private func newFolder() {
        Store.shared.createFolder()
        refresh()
        m.say("已新建文件夹")
    }

    private func open(_ d: DocItem) {
        Store.shared.touch(d.id)
        refresh()
        WindowManager.shared.openDoc(d)
    }

    private func openFolder(_ f: FolderItem) {
        WindowManager.shared.openFolder(f)
    }

    private func renameFolder(_ f: FolderItem) {
        let alert = NSAlert()
        alert.messageText = "重命名文件夹"
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 240, height: 24))
        field.stringValue = f.name
        alert.accessoryView = field
        alert.addButton(withTitle: "好")
        alert.addButton(withTitle: "取消")
        if alert.runModal() == .alertFirstButtonReturn, !field.stringValue.isEmpty {
            Store.shared.renameFolder(f.id, field.stringValue)
            refresh()
        }
    }

    private func move(_ d: DocItem) {
        let alert = NSAlert()
        alert.messageText = "移动到文件夹"
        let popup = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 240, height: 26))
        popup.addItem(withTitle: "（首页根目录）")
        for f in Store.shared.folders { popup.addItem(withTitle: f.name) }
        alert.accessoryView = popup
        alert.addButton(withTitle: "移动")
        alert.addButton(withTitle: "取消")
        if alert.runModal() == .alertFirstButtonReturn {
            let idx = popup.indexOfSelectedItem
            Store.shared.moveDoc(d.id, folder: idx <= 0 ? nil : Store.shared.folders[idx - 1].id)
            refresh()
        }
    }

    private func delete(_ d: DocItem) {
        let a = NSAlert()
        a.messageText = "删除这篇文档？"
        a.informativeText = "删除后无法恢复。导出到桌面 / 保存位置上的同名副本也会一起删掉（你在外面改过的不动）。"
        a.addButton(withTitle: "删除")
        a.addButton(withTitle: "取消")
        if a.runModal() == .alertFirstButtonReturn {
            Store.shared.deleteDoc(d.id)
            refresh()
        }
    }
}

// 半嵌在欢迎条下面的「新建文档」
struct NewDocBar: View {
    var onNew: (Bool) -> Void

    var body: some View {
        Button {
            onNew(Config.shared.d.markdownDefault)
        } label: {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(nsColor: Skin.p.accent))
                    .frame(width: 30, height: 30)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color(nsColor: NSColor(hex: "#1D1D1F")))
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text("新建文档")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(nsColor: Skin.p.text))
                    Text("从一张空白稿纸开始")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(nsColor: Skin.p.textDim))
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .frame(width: 300, height: 52)
            .glassPanel(radius: kRadius, interactive: true)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .focusEffectDisabled()
        .contextMenu {
            Button("新建文档") { onNew(false) }
            Button("新建 Markdown") { onNew(true) }
        }
        .frame(width: 300, alignment: .leading)
    }
}

// 新建文件夹小条
struct NewFolderBar: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(nsColor: Skin.p.text))
                    .frame(width: 30, height: 30)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(nsColor: Skin.p.accentSoft))
                    )
                Text("新建文件夹")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(nsColor: Skin.p.text))
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .frame(width: 176, height: 52)
            .glassPanel(radius: kRadius, interactive: true)
            .contentShape(Rectangle())
            .hoverHand()
        }
        .buttonStyle(.plain)
        .focusEffectDisabled()
    }
}

// 文档卡片
struct DocCard: View {
    var doc: DocItem
    var selected: Bool
    var menu: [DotsItem] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: kRadius, style: .continuous)
                    .fill(Color(nsColor: Skin.p.paper(Config.shared.d.paperTone)))
                    .frame(height: 158)
                    .overlay(
                        RuledPaper(lineHeight: 20, color: Skin.p.line, topInset: 10)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 12)
                            .clipShape(RoundedRectangle(cornerRadius: kRadius, style: .continuous))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: kRadius, style: .continuous)
                            .stroke(Color(nsColor: selected ? Skin.p.accent : Skin.p.border),
                                    lineWidth: selected ? 1.5 : 1)
                    )

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(preview.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.system(size: 10))
                            .foregroundStyle(Color(nsColor: Skin.p.textDim).opacity(0.85))
                            .lineLimit(1)
                            .frame(height: 20, alignment: .leading)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 14)
                .padding(.trailing, 34)

                HStack {
                    Spacer()
                    DotsButton(items: menu)
                        .padding(.trailing, 6)
                        .padding(.top, 6)
                }
            }
            .frame(height: 158)
            .shadow(color: .black.opacity(0.04), radius: 6, y: 1)

            VStack(alignment: .leading, spacing: 3) {
                Text(doc.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(nsColor: Skin.p.text))
                    .lineLimit(1)
                Text(Store.shared.metaLabel(doc.id))
                    .font(.system(size: 11))
                    .foregroundStyle(Color(nsColor: Skin.p.textDim))
                    .lineLimit(1)
            }
            .padding(.horizontal, 2)
        }
        .contentShape(Rectangle())
    }

    private var preview: [String] {
        Store.shared.previewLines(doc.id, count: 5)
    }
}

// 文件夹卡片
struct FolderCard: View {
    var name: String
    var count: Int
    var selected: Bool
    var menu: [DotsItem] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: kRadius, style: .continuous)
                    .fill(Color(nsColor: Skin.p.panel))
                    .frame(height: 158)
                    .overlay(
                        RoundedRectangle(cornerRadius: kRadius, style: .continuous)
                            .stroke(Color(nsColor: selected ? Skin.p.accent : Skin.p.border),
                                    lineWidth: selected ? 1.5 : 1)
                    )
                HStack {
                    Spacer()
                    DotsButton(items: menu)
                        .padding(.trailing, 6)
                        .padding(.top, 6)
                }
                VStack(spacing: 8) {
                    Image(systemName: "folder")
                        .font(.system(size: 30, weight: .regular))
                        .foregroundStyle(Color(nsColor: Skin.p.textDim))
                    Text("\(count) 个文档")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(nsColor: Skin.p.textDim))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(nsColor: Skin.p.text))
                Text("文件夹")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(nsColor: Skin.p.textDim))
            }
            .padding(.horizontal, 2)
        }
        .contentShape(Rectangle())
    }
}


// ============================================================
//  文件夹窗口
// ============================================================

import SwiftUI
import AppKit
import Observation

// ============================================================
//  文件夹窗口
//  双击首页的文件夹卡片就会打开它；关窗用系统红绿灯，没有返回键
// ============================================================

@Observable
final class FolderModel {
    var folderID: String
    init(folderID: String) { self.folderID = folderID }
    @ObservationIgnored weak var window: NSWindow?
    var folder: FolderItem? { Store.shared.folders.first { $0.id == folderID } }
    var docs: [DocItem] { Store.shared.docsIn(folderID) }
}

struct FolderWindowView: View {
    var model: FolderModel
    @GestureState private var marqPoint: CGPoint?

    // 窗口内的多选状态（和首页互不影响）
    @State private var selection: Set<String> = []
    @State private var frames: [String: CGRect] = [:]
    @State private var order: [String] = []
    @State private var marqueeStart: CGPoint?
    @State private var lastKey: String?
    @State private var lastAt: Date = .distantPast

    private var folderName: String { model.folder?.name ?? "文件夹" }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.35)
            if model.docs.isEmpty {
                empty
            } else {
                ScrollView { grid.padding(20) }
            }
        }
        .background {
            Color(nsColor: Skin.p.bg)
            Color.clear.contentShape(Rectangle()).gesture(marqueeGesture)
        }
        .coordinateSpace(name: "folder")
        .onPreferenceChange(CardFrameKey.self) {
            frames = $0
            order = $0.keys.sorted()
        }
        .overlay(alignment: .topLeading) {
            if let s0 = marqueeStart, s0.x > -9000, let p = marqPoint {
                let r = CGRect(x: min(s0.x, p.x), y: min(s0.y, p.y),
                               width: abs(p.x - s0.x), height: abs(p.y - s0.y))
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color(nsColor: Skin.p.accent).opacity(0.16))
                    .overlay(RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(Color(nsColor: Skin.p.accent).opacity(0.85), lineWidth: 1))
                    .frame(width: max(r.width, 1), height: max(r.height, 1))
                    .offset(x: r.minX, y: r.minY)
                    .allowsHitTesting(false)
            }
        }

    }

    // ---------- 顶栏 ----------

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "folder.fill")
                .font(.system(size: 12))
                .foregroundStyle(Color(nsColor: Skin.p.accent))
            Text(folderName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(nsColor: Skin.p.text))
            Text("\(model.docs.count) 个文档")
                .font(.system(size: 11))
                .foregroundStyle(Color(nsColor: Skin.p.textDim))
            Spacer()
            Button {
                let d = Store.shared.createDoc(folder: model.folderID)
                NotificationCenter.default.post(name: .storeChanged, object: nil)
                WindowManager.shared.openDoc(d)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus").font(.system(size: 10, weight: .bold))
                    Text("新建到此处").font(.system(size: 11))
                }
                .foregroundStyle(Color(nsColor: Skin.p.text))
                .padding(.horizontal, 10)
                .frame(height: 24)
                .glassPanel(radius: 12, interactive: true)
            }
            .buttonStyle(.plain)
            .hoverHand()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var empty: some View {
        VStack(spacing: 10) {
            Image(systemName: "doc.text")
                .font(.system(size: 30))
                .foregroundStyle(Color(nsColor: Skin.p.textDim))
            Text("这个文件夹还是空的")
                .font(.system(size: 12))
                .foregroundStyle(Color(nsColor: Skin.p.textDim))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // ---------- 网格 ----------

    private var grid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 206), spacing: 18)],
                  alignment: .leading, spacing: 24) {
            ForEach(model.docs) { d in
                let key = "d:" + d.id
                DocCard(doc: d, selected: selection.contains(key), menu: cardMenu(d))
                    .hoverHand()
                    .background(
                        GeometryReader { p in
                            Color.clear.preference(key: CardFrameKey.self,
                                                   value: [key: p.frame(in: .named("folder"))])
                        }
                    )
                    .onTapGesture { click(key) { WindowManager.shared.openDoc(d) } }
                    .simultaneousGesture(dragOut(key))
                    .contextMenu { contextMenu(d) }
            }
        }
    }

    private func cardMenu(_ d: DocItem) -> [DotsItem] {
        [
            DotsItem(title: "打开") { WindowManager.shared.openDoc(d) },
            DotsItem(title: "重命名…") { WindowManager.shared.renameDoc(d.id) },
            DotsItem(title: "移出文件夹") { moveOut([d.id]) },
            DotsItem(title: "删除", danger: true) { deleteDocs([d.id]) },
        ]
    }

    @ViewBuilder
    private func contextMenu(_ d: DocItem) -> some View {
        Button("打开") { WindowManager.shared.openDoc(d) }
        Button("重命名…") { WindowManager.shared.renameDoc(d.id) }
        Button("移出文件夹") { moveOut([d.id]) }
        Divider()
        Button("删除", role: .destructive) { deleteDocs([d.id]) }
    }

    // ---------- 点击 / 框选 ----------

    private func click(_ key: String, onDouble: @escaping () -> Void) {
        let flags = NSEvent.modifierFlags
        if flags.contains(.command) {
            if selection.contains(key) { selection.remove(key) } else { selection.insert(key) }
            lastKey = key; lastAt = .distantPast
            return
        }
        if flags.contains(.shift), let anchor = lastKey,
           let a = order.firstIndex(of: anchor), let b = order.firstIndex(of: key) {
            selection = Set(order[a < b ? a...b : b...a])
            return
        }
        let now = Date()
        if lastKey == key, now.timeIntervalSince(lastAt) < 0.5 {
            lastKey = nil
            onDouble()
        } else {
            lastKey = key; lastAt = now
            selection = selection.contains(key) ? [] : [key]
        }
    }

    private var marqueeGesture: some Gesture {
        DragGesture(minimumDistance: 3, coordinateSpace: .named("folder"))
            .onChanged { v in
                if marqueeStart == nil {
                    let onCard = frames.values.contains { $0.contains(v.startLocation) }
                    marqueeStart = onCard ? CGPoint(x: -9999, y: -9999) : v.startLocation
                }
                guard let s0 = marqueeStart, s0.x > -9000 else { return }
                let r = CGRect(x: min(s0.x, v.location.x), y: min(s0.y, v.location.y),
                               width: abs(v.location.x - s0.x), height: abs(v.location.y - s0.y))
                _ = r
                selection = Set(frames.filter { $0.value.intersects(r) }.keys)
            }
            .updating($marqPoint) { v, state, _ in state = v.location }
            .onEnded { _ in marqueeStart = nil }
    }

    /// 拖动文件夹里的文档：拖到首页窗口 → 移出文件夹；拖到窗口外面 → 放到桌面
    private func dragOut(_ key: String) -> some Gesture {
        DragGesture(minimumDistance: 5, coordinateSpace: .named("folder"))
            .onChanged { _ in
                if !selection.contains(key) { selection = [key] }
            }
            .onEnded { v in
                let ids = selectionIDs
                guard !ids.isEmpty, let w = model.window, let content = w.contentView else { return }
                let screen = w.convertPoint(toScreen: NSPoint(x: v.location.x,
                                                              y: content.bounds.height - v.location.y))
                if let home = WindowManager.shared.homeWindow, home.isVisible, home.frame.contains(screen) {
                    moveOut(ids)
                    return
                }
                if !w.frame.contains(screen) {
                    let dir = FileManager.default.homeDirectoryForCurrentUser
                        .appendingPathComponent("Desktop")
                    let fm = FileManager.default
                    for id in ids {
                        guard let d = Store.shared.docs.first(where: { $0.id == id }) else { continue }
                        let ext = d.isMarkdown ? "md" : "txt"
                        var url = dir.appendingPathComponent("\(d.title).\(ext)")
                        var n = 2
                        while fm.fileExists(atPath: url.path) {
                            url = dir.appendingPathComponent("\(d.title) \(n).\(ext)")
                            n += 1
                        }
                        let text = Store.shared.content(id)
                        try? text.write(to: url, atomically: true, encoding: .utf8)
                        Store.shared.noteExport(owner: "d:" + id, path: url.path, text: text)
                    }
                    selection.removeAll()
                }
            }
    }

    private var selectionIDs: [String] { selection.map { String($0.dropFirst(2)) } }

    private func deleteDocs(_ ids: [String]) {
        guard !ids.isEmpty else { return }
        let a = NSAlert()
        a.messageText = "删除选中的 \(ids.count) 篇文档？"
        a.informativeText = "删除后无法恢复。导出到桌面 / 保存位置上的同名副本也会一起删掉（你在外面改过的不动）。"
        a.addButton(withTitle: "删除")
        a.addButton(withTitle: "取消")
        guard a.runModal() == .alertFirstButtonReturn else { return }
        for id in ids { Store.shared.deleteDoc(id) }
        selection.removeAll()
        NotificationCenter.default.post(name: .storeChanged, object: nil)
    }

    private func moveOut(_ ids: [String]) {
        for id in ids { Store.shared.moveDoc(id, folder: nil) }
        selection.removeAll()
        NotificationCenter.default.post(name: .storeChanged, object: nil)
    }

    private func export(_ ids: [String]) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.prompt = "导出到这里"
        guard panel.runModal() == .OK, let dir = panel.url else { return }
        for id in ids {
            guard let d = Store.shared.docs.first(where: { $0.id == id }) else { continue }
            let ext = d.isMarkdown ? "md" : "txt"
            let url = dir.appendingPathComponent("\(d.title).\(ext)")
            let text = Store.shared.content(id)
            try? text.write(to: url, atomically: true, encoding: .utf8)
            Store.shared.noteExport(owner: "d:" + id, path: url.path, text: text)
        }
        selection.removeAll()
    }
}


// ============================================================
//  设置页
// ============================================================

import SwiftUI
import AppKit
import Observation

// ============================================================
//  设置：左栏六分类 + 右侧内容（换页靠重建）
// ============================================================

@Observable
final class SettingsModel {
    static var shared = SettingsModel()
    var page = "appearance"
    /// 换页时右侧内容先错开一点，再滑回原位（第一次打开设置时是 0，没有动画）
    var slide: CGFloat = 0
    @ObservationIgnored weak var window: NSWindow?

    private let pageOrder = ["appearance", "editing", "saving", "startup", "shortcuts", "about"]

    func pick(_ key: String) {
        guard key != page else { return }
        let oldIdx = pageOrder.firstIndex(of: page) ?? 0
        let newIdx = pageOrder.firstIndex(of: key) ?? 0
        let dir: CGFloat = newIdx > oldIdx ? 1 : -1
        // 先无动画地把新页放好位置，但整体错开 26pt，再滑回来 → 像翻到下一页
        page = key
        slide = dir * 26
        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                SettingsModel.shared.slide = 0
            }
        }
    }
}

struct SettingsView: View {
    private let m = SettingsModel.shared
    private var cfg: ConfigData { Config.shared.d }

    private let pages: [(key: String, title: String, hint: String)] = [
        ("appearance", "外观", "主题、界面动画、纸色与主页视图"),
        ("editing", "编辑", "字号、行高、稿纸宽度与专注模式"),
        ("saving", "保存", "自动保存与导出位置"),
        ("startup", "启动", "启动时显示哪一页"),
        ("shortcuts", "快捷键", "常用的键盘操作"),
        ("about", "关于", "开发者、数据位置与公告"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            nav
            Divider().overlay(Color(nsColor: Skin.p.line))
            VStack(alignment: .leading, spacing: 0) {
                let meta = pages.first { $0.key == m.page }!
                VStack(alignment: .leading, spacing: 3) {
                    Text(meta.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color(nsColor: Skin.p.text))
                    Text(meta.hint)
                        .font(.system(size: 11))
                        .foregroundStyle(Color(nsColor: Skin.p.textDim))
                }
                .padding(.horizontal, 26)
                .padding(.top, 22)
                .padding(.bottom, 14)

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) { content }
                        .id(m.page)
                        .padding(.horizontal, 26)
                        .padding(.bottom, 30)
                }
            }
            // 换栏目时整块内容从上下错开一点滑回原位；单纯在右边滚动不会触发
            .offset(y: m.slide)
            .opacity(1 - min(abs(m.slide) / 60, 0.55))
            .clipped()

        }
        .background(Color(nsColor: Skin.p.bg))
    }

    private var nav: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(pages, id: \.key) { item in
                let on = item.key == m.page
                Button { m.pick(item.key) } label: {
                    Text(item.title)
                        .font(.system(size: 12, weight: on ? .semibold : .regular))
                        .foregroundStyle(Color(nsColor: Skin.p.text))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .frame(height: 30)
                        .background {
                            if on { RoundedRectangle(cornerRadius: 8, style: .continuous).glassPanel(radius: 8, interactive: true) }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.top, 56)
        .frame(width: 168)
        .background(Color(nsColor: Skin.p.panel))
    }

    @ViewBuilder private var content: some View {
        switch m.page {
        case "appearance": appearance
        case "editing": editing
        case "saving": saving
        case "startup": startup
        case "shortcuts": shortcuts
        default: about
        }
    }

    // ---------- 外观 ----------

    private var appearance: some View {
        VStack(alignment: .leading, spacing: 18) {
            SettingSection(title: "主题") {
                SettingRow(title: "深浅色", hint: "夜猫子专属。") {
                    Pills(options: ["浅色", "深色"], index: Skin.isDark ? 1 : 0) { i in
                        Skin.setDark(i == 1)
                        WindowManager.shared.skinChanged()
                    }
                }
            }
            SettingSection(title: "交互") {
                SettingRow(title: "界面动画", hint: "利落！") {
                    Lever(on: cfg.animate) { v in
                        Config.shared.set { $0.animate = v }
                    }
                }
            }
            SettingSection(title: "稿纸") {
                SettingRow(title: "纸张颜色", hint: "纯白 / 米黄 / 浅灰。") {
                    Pills(options: ["白", "米黄", "浅灰"],
                          index: cfg.paperTone == "cream" ? 1 : cfg.paperTone == "gray" ? 2 : 0) { i in
                        Config.shared.set { $0.paperTone = i == 0 ? "white" : i == 1 ? "cream" : "gray" }
                    }
                }
                RowSeparator()
                SettingRow(title: "主页视图", hint: "网格是卡片；列表排得更密。") {
                    Pills(options: ["网格", "列表"], index: cfg.viewList ? 1 : 0) { i in
                        Config.shared.set { $0.viewList = i == 1 }
                        NotificationCenter.default.post(name: .storeChanged, object: nil)
                    }
                }
            }
        }
    }

    // ---------- 编辑 ----------

    private var editing: some View {
        VStack(alignment: .leading, spacing: 18) {
            SettingSection(title: "文字") {
                SettingRow(title: "字号", hint: "正文大小，稿纸横线的间距会跟着一起变。") {
                    HStack(spacing: 8) {
                        Pills(options: ["小", "标准", "大"],
                              index: cfg.fontSize <= 14 ? 0 : cfg.fontSize >= 18 ? 2 : 1) { i in
                            let v = i == 0 ? 13 : i == 2 ? 19 : 15
                            Config.shared.set {
                                $0.fontSize = v
                                $0.lineHeight = Int(Double(v) * 1.55) + 6
                            }
                        }
                        Button("自定义…") { promptFontSize() }.controlSize(.small)
                    }
                }
                RowSeparator()
                SettingRow(title: "行高", hint: "稿纸每一行的高度，横线会跟着走。") {
                    Pills(options: ["紧凑", "标准", "宽松"],
                          index: cfg.lineHeight <= 26 ? 0 : cfg.lineHeight >= 34 ? 2 : 1) { i in
                        Config.shared.set { $0.lineHeight = i == 0 ? 26 : i == 2 ? 34 : 30 }
                    }
                }
                RowSeparator()
                SettingRow(title: "纸张宽度", hint: "窄一点读长文更舒服，宽一点适合写表格。") {
                    Pills(options: ["窄", "标准", "宽"],
                          index: cfg.paperWidth <= 690 ? 0 : cfg.paperWidth >= 860 ? 2 : 1) { i in
                        Config.shared.set { $0.paperWidth = i == 0 ? 660 : i == 2 ? 900 : 760 }
                    }
                }
                RowSeparator()
                SettingRow(title: "专注模式", hint: "把稿纸上的横线藏起来，只看字。") {
                    Lever(on: cfg.focusMode) { v in
                        Config.shared.set { $0.focusMode = v }
                    }
                }
            }
            SettingSection(title: "新建文档") {
                SettingRow(title: "默认新建 Markdown", hint: "以后点「新建文档」直接建 .md，适合写笔记。") {
                    Lever(on: cfg.markdownDefault) { v in
                        Config.shared.set { $0.markdownDefault = v }
                    }
                }
            }
        }
    }

    // ---------- 保存 ----------

    private var saving: some View {
        VStack(alignment: .leading, spacing: 18) {
            SettingSection(title: "保存") {
                SettingRow(title: "关窗时自动保存", hint: "关掉编辑窗口时先把正文写进保存位置，再让 App 退回后台、随后自动退出。") {
                    Lever(on: cfg.autoSaveOnClose) { v in
                        Config.shared.set { $0.autoSaveOnClose = v }
                    }
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("保存位置")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(nsColor: Skin.p.text))
                Text(savePath)
                    .font(.system(size: 11))
                    .foregroundStyle(Color(nsColor: Skin.p.textDim))
                    .lineLimit(2)
                Button("选择文件夹…") { pickFolder() }.controlSize(.small)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassPanel(radius: kRadius)

            Text("新建文档不会立刻落盘，只有点「保存」或关掉窗口时才写到上面的位置；正文同时留一份内部副本。")
                .font(.system(size: 11))
                .foregroundStyle(Color(nsColor: Skin.p.textDim))
        }
    }

    private var savePath: String {
        cfg.saveDir.isEmpty ? NSHomeDirectory() + "/Desktop" : cfg.saveDir
    }

    private func promptFontSize() {
        let alert = NSAlert()
        alert.messageText = "自定义字号"
        alert.informativeText = "9 – 72 之间，横线间距自动重排。"
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 160, height: 24))
        field.stringValue = String(cfg.fontSize)
        alert.accessoryView = field
        alert.addButton(withTitle: "确定")
        alert.addButton(withTitle: "取消")
        if alert.runModal() == .alertFirstButtonReturn, let v = Double(field.stringValue) {
            let px = max(9, min(72, v))
            Config.shared.set {
                $0.fontSize = Int(px)
                $0.lineHeight = Int(px * 1.55) + 6
            }
        }
    }

    private func pickFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            Config.shared.set { $0.saveDir = url.path }
        }
    }

    // ---------- 启动 ----------

    private var startup: some View {
        SettingSection(title: "启动") {
            SettingRow(title: "启动显示", hint: "决定打开 App 后先看到什么。") {
                Pills(options: ["主页", "新建文档", "上次的文档"],
                      index: cfg.startup == "newdoc" ? 1 : cfg.startup == "lastdoc" ? 2 : 0) { i in
                    Config.shared.set { $0.startup = i == 0 ? "home" : i == 1 ? "newdoc" : "lastdoc" }
                }
            }
            SettingRow(title: "显示启动画面", hint: "那个只有 logo 的浮层，关掉就直接进主页。") {
                Lever(on: cfg.showSplash) { v in
                    Config.shared.set { $0.showSplash = v }
                }
            }
        }
    }

    // ---------- 快捷键 ----------

    private var shortcuts: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(shortcutList.enumerated()), id: \.offset) { i, item in
                HStack {
                    Text(item.0).font(.system(size: 12)).foregroundStyle(Color(nsColor: Skin.p.text))
                    Spacer()
                    Text(item.1)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color(nsColor: Skin.p.textDim))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                if i < shortcutList.count - 1 {
                    Divider().overlay(Color(nsColor: Skin.p.line)).padding(.horizontal, 14)
                }
            }
        }
        .glassPanel(radius: kRadius)
    }

    private let shortcutList: [(String, String)] = [
        ("新建文档", "⌘N"),
        ("新建 Markdown", "⇧⌘N"),
        ("保存", "⌘S"),
        ("打开…", "⌘O"),
        ("导出…", "⇧⌘E"),
        ("设置…", "⌘'"),
        ("撤销 / 重做", "⌘Z / ⇧⌘Z"),
        ("粗体 / 斜体 / 下划线", "⌘B / ⌘I / ⌘U"),
        ("高亮", "⇧⌘H"),
        ("插入日期时间", "⇧⌘D"),
        ("关闭窗口", "⌘W"),
    ]

    // ---------- 关于 ----------

    private var about: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 16) {
                LogoImage(size: 64)
                VStack(alignment: .leading, spacing: 4) {
                    Text("OπTXT")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(nsColor: Skin.p.text))
                    Text("新一代文本编辑工具")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(nsColor: Skin.p.textDim))
                    Text("开发者：Orange_tree_17")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(nsColor: Skin.p.textDim))
                    Text("SwiftUI 版本 · \(appVersion)")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(nsColor: Skin.p.textDim))
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("数据位置")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(nsColor: Skin.p.text))
                Text(Store.shared.appSupport)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color(nsColor: Skin.p.textDim))
                    .textSelection(.enabled)
                Button("在 Finder 里打开") {
                    NSWorkspace.shared.open(URL(fileURLWithPath: Store.shared.appSupport))
                }
                .controlSize(.small)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassPanel(radius: kRadius)

            VStack(alignment: .leading, spacing: 8) {
                Text("告示")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(nsColor: Skin.p.text))
                Text("OπTXT是一款开源软件，它的目标是取代macOS自带的文本编辑，让macOS体验更舒适！")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(nsColor: Skin.p.textDim))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassPanel(radius: kRadius)
        }
    }

    private var appVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0"
    }
}

struct SettingSection<Content: View>: View {
    var title: String
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(nsColor: Skin.p.textDim))
                .padding(.leading, 2)
            VStack(spacing: 0) { content }
                .glassPanel(radius: kRadius)
        }
    }
}

struct SettingRow<Control: View>: View {
    var title: String
    var hint: String
    @ViewBuilder var control: Control
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(nsColor: Skin.p.text))
                Text(hint)
                    .font(.system(size: 11))
                    .foregroundStyle(Color(nsColor: Skin.p.textDim))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 12)
            control
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }
}

// 设置分区内部的细分隔线
struct RowSeparator: View {
    var body: some View {
        Rectangle()
            .fill(Color(nsColor: Skin.p.border).opacity(0.7))
            .frame(height: 1)
            .padding(.horizontal, 14)
    }
}


// ============================================================
//  编辑器
// ============================================================

import SwiftUI
import AppKit
import Observation

// ============================================================
//  编辑器：NSTextView 富文本 + 稿纸背景 + 工具栏
// ============================================================

@Observable
final class EditorController {
    @ObservationIgnored weak var textView: NSTextView?
    var docID: String = ""
    var docTitle: String = "未命名文档"
    var isMarkdown: Bool = false
    var preview = false

    // 工具栏当前状态（跟着光标走，不是跟着「上次点了哪个按钮」走）
    var alignmentIndex = 0
    var boldOn = false
    var italicOn = false
    var underlineOn = false
    var highlightOn = false
    var currentFontName = "PingFang SC"
    /// 一页显示几行（给界面算纸张高度用）
    var paperLines: Int = 18
    var currentSize: CGFloat = 15

    @ObservationIgnored weak var window: NSWindow?

    var plainText: String { textView?.string ?? cachedText }
    var cachedText: String = ""

    /// 根据光标/选区回读当前格式，让工具栏正确高亮
    static func friendlyName(of f: NSFont) -> String {
        let name = f.fontName
        let fam = (f.familyName ?? name)
        let cleanFam = fam.hasPrefix(".") ? String(fam.dropFirst()) : fam
        let bold = f.fontDescriptor.symbolicTraits.contains(.bold)
        if cleanFam.contains("PingFang") { return bold ? "苹方 粗体" : "苹方" }
        if cleanFam.contains("HelveticaNeue") || cleanFam.contains("SF Pro") {
            return bold ? "系统 粗体" : "系统"
        }
        return cleanFam
    }

    func refreshFormatState() {
        guard let tv = textView, let storage = tv.textStorage else { return }
        let sel = tv.selectedRange()
        let loc = min(sel.location, max(0, storage.length - 1))
        if storage.length == 0 {
            alignmentIndex = 0
            boldOn = false; italicOn = false; underlineOn = false; highlightOn = false
            return
        }
        if let para = storage.attribute(.paragraphStyle, at: loc, effectiveRange: nil) as? NSParagraphStyle {
            switch para.alignment {
            case .center: alignmentIndex = 1
            case .right: alignmentIndex = 2
            case .justified: alignmentIndex = 3
            default: alignmentIndex = 0
            }
        }
        if let f = storage.attribute(.font, at: loc, effectiveRange: nil) as? NSFont {
            let traits = f.fontDescriptor.symbolicTraits
            boldOn = traits.contains(.bold)
            let slant = (storage.attribute(.obliqueness, at: loc, effectiveRange: nil) as? Double) ?? 0
            italicOn = traits.contains(.italic) || slant > 0.05
            currentSize = f.pointSize
            currentFontName = EditorController.friendlyName(of: f)
        }
        underlineOn = ((storage.attribute(.underlineStyle, at: loc, effectiveRange: nil) as? Int) ?? 0) != 0
        highlightOn = storage.attribute(.backgroundColor, at: loc, effectiveRange: nil) != nil
    }

    func load(_ text: String) {
        cachedText = text
        guard let tv = textView else { return }
        tv.string = text
        restyleAll()
        refreshFormatState()
    }

    func saveNow() {
        guard !docID.isEmpty else { return }
        let text = plainText
        cachedText = text
        Store.shared.saveContent(docID, text, export: true)
        Store.shared.touch(docID)
    }

    /// 把稿纸样式（横线颜色 / 行距 / 字号）重新套到输入框上
    /// 编辑 → 增加页面：光标跳到下一页稿纸的第一行（这一页没写完也可以加）
    func addPage() {
        guard let tv = textView else { return }
        let pageLines = (tv as? RuledTextView)?.pageLines ?? 24
        let s = tv.string as NSString
        let lineCount = s.length == 0 ? 1 : s.components(separatedBy: "\n").count
        let target = ((lineCount - 1) / pageLines + 1) * pageLines + 1
        let need = max(1, target - lineCount)
        tv.insertText(String(repeating: "\n", count: need),
                      replacementRange: NSRange(location: s.length, length: 0))
        tv.setSelectedRange(NSRange(location: (tv.string as NSString).length, length: 0))
        tv.scrollRangeToVisible(tv.selectedRange())
        updatePageState()
        followCaretPage()
        saveNow()
    }

    private var pageWork: DispatchWorkItem?

    /// 输入后延迟重排版分页，避免每敲一个字就重算
    func schedulePageRestyle() {
        pageWork?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.applyPageStyle() }
        pageWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: work)
    }

    func applyPageStyle() {
        let cfg = Config.shared.d
        if let tv = textView as? RuledTextView {
            tv.ruleColor = Skin.p.line
            tv.showsRules = !cfg.focusMode
            tv.linePitch = CGFloat(cfg.lineHeight)
            tv.textContainerInset = NSSize(width: 0, height: tv.topInset)
            if let sv = tv.enclosingScrollView {
                // 刚建视图时 contentSize 还可能是 0，这时别把页行数算崩（否则纸张高度会被越算越矮）
                let clipH = sv.contentSize.height
                if clipH > 120 {
                    let usable = clipH - tv.topInset
                    let lines = max(8, Int(floor(usable / CGFloat(cfg.lineHeight))))
                    tv.pageLines = lines
                    paperLines = lines
                }
            }
            tv.refreshPaperExtent()
            tv.needsDisplay = true
        }
        restyleAll()
        updatePageState()
    }

    /// 窗口大小变了只重算分页，不重排整篇文字
    func refreshPagination() {
        guard let tv = textView as? RuledTextView, let sv = tv.enclosingScrollView else { return }
        let clipH = sv.contentSize.height
        guard clipH > 120 else { return }
        let usable = clipH - tv.topInset
        let lines = max(8, Int(floor(usable / max(8, tv.linePitch))))
        if lines != tv.pageLines {
            tv.pageLines = lines
            tv.refreshPaperExtent()
            tv.needsDisplay = true
        }
        updatePageState()
    }

    // MARK: - 分页/翻页
    var currentPage: Int = 1
    var totalPages: Int = 1

    func updatePageState() {
        guard let tv = textView as? RuledTextView, let sv = tv.enclosingScrollView else { return }
        let ph = max(1, tv.pageHeight)
        let total = max(1, Int(round((tv.frame.height - tv.topInset * 2) / ph)))
        let y = sv.contentView.bounds.origin.y - tv.topInset
        let page = max(1, min(total, Int(round(max(0, y) / ph)) + 1))
        if page != currentPage { currentPage = page }
        if total != totalPages { totalPages = total }
    }

    /// 左右翻页时的横向位移（SwiftUI 用 offset 播放滑动动画）
    var slideOffset: CGFloat = 0
    private var flipping = false

    func pageTopY(_ p: Int, _ tv: RuledTextView) -> CGFloat {
        let ph = max(1, tv.pageHeight)
        let base = CGFloat(max(0, p - 1)) * ph
        return max(0, p <= 1 ? base : base + tv.topInset)
    }

    func scrollToPage(_ p: Int) {
        guard let tv = textView as? RuledTextView, let sv = tv.enclosingScrollView else { return }
        let maxY = max(0, tv.frame.height - sv.contentSize.height)
        let y = min(maxY, max(0, pageTopY(p, tv)))
        sv.contentView.scroll(to: NSPoint(x: 0, y: y))
        sv.reflectScrolledClipView(sv.contentView)
        currentPage = max(1, min(totalPages, p))
    }

    /// 左右翻页：整页横向滑走，滑出去之后再换内容（看不到竖向跳动）
    func flipToPage(_ p: Int, direction: Int, moveCaretToTop: Bool) {
        guard p >= 1, p <= totalPages, !flipping else { return }
        guard let tv = textView as? RuledTextView,
              let sv = tv.enclosingScrollView else {
            scrollToPage(p); return
        }
        let fromPage = currentPage
        guard p != fromPage else {
            if moveCaretToTop { putCaretAtPageTop(p) }
            return
        }
        flipping = true
        let size = sv.contentSize
        let savedY = sv.contentView.bounds.origin.y

        // 两页各拍一张图，然后整条横向平移：左边那页左移出画面，右边新页同步从右侧进来
        let shotA = tv.pageImage(of: tv.visibleRect)
        scrollToPage(p)
        let shotB = tv.pageImage(of: tv.visibleRect)
        sv.contentView.scroll(to: NSPoint(x: 0, y: savedY))
        sv.reflectScrolledClipView(sv.contentView)
        currentPage = fromPage

        guard let a = shotA, let b = shotB else {
            finishFlip(p, moveCaretToTop: moveCaretToTop)
            return
        }

        let paper = tv.backgroundColor
        let overlay = NSView(frame: NSRect(origin: .zero, size: size))
        overlay.wantsLayer = true
        overlay.layer?.backgroundColor = paper.cgColor
        overlay.layer?.masksToBounds = true
        overlay.autoresizingMask = [.width, .height]
        sv.addSubview(overlay)

        func cg(_ img: NSImage) -> CGImage? {
            var r = NSRect(origin: .zero, size: img.size)
            return img.cgImage(forProposedRect: &r, context: nil, hints: nil)
        }
        let w = size.width, h = size.height
        var firstX: CGFloat = 0
        var secondX: CGFloat = direction > 0 ? w : -w
        if direction > 0 { firstX = 0; secondX = w }
        let shift: CGFloat = direction > 0 ? -w : w

        let l0 = CALayer()
        l0.contentsScale = 2
        l0.frame = CGRect(x: firstX, y: 0, width: w, height: h)
        l0.contents = cg(a)
        l0.contentsGravity = .resize
        let l1 = CALayer()
        l1.contentsScale = 2
        l1.frame = CGRect(x: secondX, y: 0, width: w, height: h)
        l1.contents = cg(b)
        l1.contentsGravity = .resize

        overlay.layer?.addSublayer(l0)
        overlay.layer?.addSublayer(l1)

        let anim = CABasicAnimation(keyPath: "transform.translation.x")
        anim.fromValue = 0
        anim.toValue = shift
        anim.duration = 0.26
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        anim.fillMode = .forwards
        anim.isRemovedOnCompletion = false

        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self, weak overlay] in
            overlay?.removeFromSuperview()
            self?.finishFlip(p, moveCaretToTop: moveCaretToTop)
        }
        l0.add(anim, forKey: "slide")
        l1.add(anim, forKey: "slide")
        CATransaction.commit()

        // 兜底：动画没跑完（比如窗口不可见）也要收尾
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self, weak overlay] in
            guard let self, self.flipping else { return }
            overlay?.removeFromSuperview()
            self.finishFlip(p, moveCaretToTop: moveCaretToTop)
        }
    }

    private func finishFlip(_ p: Int, moveCaretToTop: Bool) {
        guard flipping else { return }
        flipping = false
        scrollToPage(p)
        if moveCaretToTop { putCaretAtPageTop(p) }
    }

    /// 光标一越过页边界就整页翻过去；把新页上唯一的字删掉时退回上一页
    func followCaretToNewPage() {
        guard let tv = textView as? RuledTextView, !tv.hasMarkedText() else { return }
        guard let sv = tv.enclosingScrollView else { return }
        // 内容变短了，页数可能缩回去：先按真实行数补齐/收缩纸高
        tv.refreshPaperExtent()
        updatePageState()
        if currentPage > totalPages, !flipping {
            flipToPage(totalPages, direction: -1, moveCaretToTop: false)
            return
        }
        guard !flipping else { return }
        let len = (tv.string as NSString).length
        let loc = min(max(0, tv.selectedRange().location), len)
        let page = min(totalPages, tv.pageIndex(atCharacter: loc) + 1)
        guard page != currentPage else {
            // 停在同一页时，纸必须停在这一页顶上，不能留半截滚动
            let maxY = max(0, tv.frame.height - sv.contentSize.height)
            let want = min(maxY, max(0, pageTopY(currentPage, tv)))
            if abs(sv.contentView.bounds.origin.y - want) > 1 {
                sv.contentView.scroll(to: NSPoint(x: 0, y: want))
                sv.reflectScrolledClipView(sv.contentView)
            }
            return
        }
        // 拍图前先把纸拉回当前页，否则拍到的是被自动滚下去的那半页
        scrollToPage(currentPage)
        flipToPage(page, direction: page > currentPage ? 1 : -1, moveCaretToTop: false)
    }

    func nextPage() { flipToPage(currentPage + 1, direction: 1, moveCaretToTop: true) }
    func prevPage() { flipToPage(currentPage - 1, direction: -1, moveCaretToTop: true) }

    /// 翻到某页后，光标落在那一页的第一行行首
    func putCaretAtPageTop(_ p: Int) {
        guard let tv = textView as? RuledTextView else { return }
        var idx = tv.characterIndex(atPageTop: p - 1)
        let ns = tv.string as NSString
        // 页边界常常落在一个换行符上，往后挪到真正的新页第一行行首
        while idx < ns.length, ns.character(at: idx) == 10 || ns.character(at: idx) == 13 { idx += 1 }
        // 翻到哪页，光标就落在哪页第一行：否则 NSTextView 会把纸自动滚回光标原来那一页
        tv.setSelectedRange(NSRange(location: idx, length: 0))
    }

    /// 一页写满、光标跑到下一页时，自动把纸翻到那一页（光标本来就在新页第一行）
    func followCaretPage() {
        guard let tv = textView as? RuledTextView, !flipping else { return }
        let page = tv.pageIndex(atCharacter: tv.selectedRange().location) + 1
        if page > currentPage { flipToPage(page, direction: 1, moveCaretToTop: false) }
    }

    func restyleAll() {
        guard let tv = textView, let storage = tv.textStorage else { return }
        let cfg = Config.shared.d
        let size = CGFloat(cfg.fontSize)
        let base = NSFont(name: cfg.fontName, size: size)
            ?? NSFont(name: "PingFang SC", size: size)
            ?? NSFont.systemFont(ofSize: size)
        let para = NSMutableParagraphStyle()
        para.minimumLineHeight = CGFloat(cfg.lineHeight)
        para.maximumLineHeight = CGFloat(cfg.lineHeight)
        para.lineSpacing = 0
        para.paragraphSpacing = 0
        para.lineBreakMode = .byCharWrapping        // 一行写满整行宽才换行，不提前断
        para.hyphenationFactor = 0
        let whole = NSRange(location: 0, length: storage.length)
        if storage.length > 0 {
            storage.addAttribute(.foregroundColor, value: Skin.p.text, range: whole)
            // 对齐方式是段落级的，重排必须原样保留，否则点完对齐一秒就被打回左边
            var paraFixes: [(NSRange, NSParagraphStyle)] = []
            storage.enumerateAttribute(.paragraphStyle, in: whole) { value, range, _ in
                let align = (value as? NSParagraphStyle)?.alignment ?? .left
                let p = para.mutableCopy() as! NSMutableParagraphStyle
                p.alignment = align
                paraFixes.append((range, p))
            }
            for (r, p) in paraFixes { storage.addAttribute(.paragraphStyle, value: p, range: r) }
            // 重排只换「基础字体」，粗体 / 斜体这些字符级样式必须保留
            var fixes: [(NSRange, NSFont)] = []
            storage.enumerateAttribute(.font, in: whole) { value, range, _ in
                let old = value as? NSFont
                let keep = old?.fontDescriptor.symbolicTraits.intersection([.bold, .italic]) ?? []
                if ProcessInfo.processInfo.environment["OXTXT_BOLD_TEST"] != nil, range.location < 6 {
                    print("restyle run <\(old?.fontName ?? "nil")> keep:\(keep.rawValue)")
                }
                fixes.append((range, fontMatching(base: base, size: size, traits: keep)))
            }
            for (r, f) in fixes { storage.addAttribute(.font, value: f, range: r) }
        }
        // 注意：不能写 tv.font = base —— NSTextView 的 font 是「整篇套字体」，
        // 会把这 0.35 秒前刚加的粗体/斜体全部冲掉，粗体只粗一秒就是这么来的。
        (tv as? RuledTextView)?.ruleFont = base
        tv.defaultParagraphStyle = para
        tv.typingAttributes = [.font: base, .foregroundColor: Skin.p.text, .paragraphStyle: para]
        tv.textColor = Skin.p.text
        tv.insertionPointColor = Skin.p.text
        tv.needsDisplay = true
    }

    /// 按「字体名 + 字号 + 粗斜体」造字体；重排时靠它把粗体 / 斜体原样还原
    private func fontMatching(base: NSFont, size: CGFloat, traits: NSFontDescriptor.SymbolicTraits) -> NSFont {
        var f = NSFont(name: base.fontName, size: size) ?? base
        if traits.contains(.bold) { f = fontFrom(f, trait: .bold, on: true) }
        if traits.contains(.italic) { f = fontFrom(f, trait: .italic, on: true) }
        if ProcessInfo.processInfo.environment["OXTXT_BOLD_TEST"] != nil, !traits.isEmpty {
            print("fontMatching traits:\(traits.rawValue) -> \(f.fontName)")
        }
        return f
    }

    private var selection: NSRange { textView?.selectedRange() ?? NSRange(location: 0, length: 0) }

    /// 只对选中的文字生效；没选中就什么都不改
    private func mutateSelection(_ change: (NSMutableAttributedString, NSRange) -> Void) {
        guard let tv = textView, let storage = tv.textStorage else { return }
        let sel = selection
        guard sel.length > 0 else { return }
        storage.beginEditing()
        change(storage, sel)
        storage.endEditing()
        tv.didChangeText()
        refreshFormatState()
    }

    func toggleTrait(_ trait: NSFontDescriptor.SymbolicTraits) {
        guard let tv = textView, let storage = tv.textStorage else { return }
        let sel = selection
        guard sel.length > 0 else { return }
        // 整段都已经是这个样式 → 这次是取消；否则统一加上
        var allOn = true
        storage.enumerateAttribute(.font, in: sel) { value, _, _ in
            guard let f = value as? NSFont,
                  f.fontDescriptor.symbolicTraits.contains(trait) else { allOn = false; return }
        }
        var fixes: [(NSRange, NSFont)] = []
        storage.enumerateAttribute(.font, in: sel) { value, range, _ in
            let base = (value as? NSFont) ?? NSFont.systemFont(ofSize: CGFloat(Config.shared.d.fontSize))
            fixes.append((range, fontFrom(base, trait: trait, on: !allOn)))
        }
        storage.beginEditing()
        for (r, f) in fixes { storage.addAttribute(.font, value: f, range: r) }
        storage.endEditing()
        tv.didChangeText()
        refreshFormatState()
    }

    /// 加/去粗体、斜体：用 NSFontManager 找同字族的真字形，找不到才退回系统字重
    private func fontFrom(_ base: NSFont, trait: NSFontDescriptor.SymbolicTraits, on: Bool) -> NSFont {
        let mask: NSFontTraitMask = trait == .bold
            ? (on ? .boldFontMask : .unboldFontMask)
            : (on ? .italicFontMask : .unitalicFontMask)
        let converted = NSFontManager.shared.convert(base, toHaveTrait: mask)
        let has = converted.fontDescriptor.symbolicTraits.contains(trait)
        if on {
            if has { return converted }
            if trait == .bold { return NSFont.systemFont(ofSize: base.pointSize, weight: .bold) }
            let d = NSFont.systemFont(ofSize: base.pointSize).fontDescriptor.withSymbolicTraits(.italic)
            if let f = NSFont(descriptor: d, size: base.pointSize) { return f }
            return converted
        } else {
            if !has { return converted }
            // 字族压根没有粗体/斜体字形时，取消后回到常规体
            return NSFont(name: base.familyName ?? "", size: base.pointSize)
                ?? NSFont.systemFont(ofSize: base.pointSize)
        }
    }

    func bold() { toggleTrait(.bold) }

    /// 斜体：字族本身没有斜体字形（PingFang / SF 都没有），所以用 obliqueness 倾斜 + 尽量换真斜体字体
    func italic() {
        guard let tv = textView else { return }
        let sel = selection
        let slant: CGFloat = 0.28

        if sel.length == 0 {
            var attrs = tv.typingAttributes
            let on = ((attrs[.obliqueness] as? Double) ?? 0) > 0.05
            attrs[.obliqueness] = on ? 0 : Double(slant)
            if let f = attrs[.font] as? NSFont {
                attrs[.font] = italicized(f, on: !on)
            }
            tv.typingAttributes = attrs
            italicOn = !on
            return
        }

        mutateSelection { storage, range in
            var anyItalic = false
            storage.enumerateAttribute(.obliqueness, in: range) { v, _, _ in
                if ((v as? Double) ?? 0) > 0.05 { anyItalic = true }
            }
            storage.enumerateAttribute(.font, in: range) { v, _, _ in
                if let f = v as? NSFont, f.fontDescriptor.symbolicTraits.contains(.italic) { anyItalic = true }
            }
            storage.addAttribute(.obliqueness, value: anyItalic ? 0 : Double(slant), range: range)
            storage.enumerateAttribute(.font, in: range) { v, sub, _ in
                guard let f = v as? NSFont else { return }
                storage.addAttribute(.font, value: italicized(f, on: !anyItalic), range: sub)
            }
        }
    }

    private func italicized(_ font: NSFont, on: Bool) -> NSFont {
        fontFrom(font, trait: .italic, on: on)
    }

    func underline() {
        mutateSelection { storage, sel in
            var has = false
            storage.enumerateAttribute(.underlineStyle, in: sel) { v, _, _ in
                if (v as? Int ?? 0) != 0 { has = true }
            }
            storage.addAttribute(.underlineStyle, value: has ? 0 : NSUnderlineStyle.single.rawValue, range: sel)
        }
    }

    func highlight() {
        mutateSelection { storage, sel in
            var has = false
            storage.enumerateAttribute(.backgroundColor, in: sel) { v, _, _ in
                if v != nil { has = true }
            }
            if has { storage.removeAttribute(.backgroundColor, range: sel) }
            else { storage.addAttribute(.backgroundColor, value: NSColor(hex: "#FFE97A"), range: sel) }
        }
    }

    func align(_ index: Int) {
        // 只对选中的文字生效；没选中就什么都不改
        guard let tv = textView, let storage = tv.textStorage else { return }
        let sel = selection
        guard sel.length > 0 else { return }
        let range = (tv.string as NSString).paragraphRange(for: sel)
        guard range.length > 0 else { return }
        guard let existing = storage.attribute(.paragraphStyle, at: range.location, effectiveRange: nil) as? NSParagraphStyle,
              let copy = existing.mutableCopy() as? NSMutableParagraphStyle else { return }
        copy.alignment = [.left, .center, .right, .justified][max(0, min(3, index))]
        storage.addAttribute(.paragraphStyle, value: copy, range: range)
        tv.didChangeText()
        alignmentIndex = max(0, min(3, index))
    }

    func setFont(_ name: String) {
        Config.shared.set { $0.fontName = name }
        currentFontName = name
        if selection.length > 0 {
            mutateSelection { storage, sel in
                storage.enumerateAttribute(.font, in: sel) { value, range, _ in
                    let size = (value as? NSFont)?.pointSize ?? CGFloat(Config.shared.d.fontSize)
                    let f = NSFont(name: name, size: size)
                        ?? NSFont(name: Config.shared.d.fontName, size: size)
                        ?? NSFont.systemFont(ofSize: size)
                    storage.addAttribute(.font, value: f, range: range)
                }
            }
        } else {
            restyleAll()
        }
    }

    /// 字号：整篇跟着变，稿纸横线间距按字号重新排（没选中时）
    func setSize(_ size: CGFloat) {
        let px = max(9, min(72, size))
        Config.shared.set {
            $0.fontSize = Int(px)
            $0.lineHeight = max(Int(px * 1.55) + 6, Int(px) + 10)
        }
        currentSize = px
        if selection.length > 0 {
            mutateSelection { storage, sel in
                storage.enumerateAttribute(.font, in: sel) { value, range, _ in
                    let desc = (value as? NSFont)?.fontDescriptor
                        ?? NSFont(name: Config.shared.d.fontName, size: px)?.fontDescriptor
                        ?? NSFont.systemFont(ofSize: px).fontDescriptor
                    storage.addAttribute(.font, value: NSFont(descriptor: desc, size: px) ?? NSFont.systemFont(ofSize: px), range: range)
                }
            }
            adjustLineHeight(ofSelection: px)
        } else {
            restyleAll()
        }
    }

    private func adjustLineHeight(ofSelection px: CGFloat) {
        guard let tv = textView, let storage = tv.textStorage else { return }
        let sel = selection
        guard sel.length > 0 else { return }
        let range = (tv.string as NSString).paragraphRange(for: sel)
        let para = NSMutableParagraphStyle()
        para.minimumLineHeight = px * 1.55 + 6
        para.maximumLineHeight = px * 1.55 + 6
        storage.addAttribute(.paragraphStyle, value: para, range: range)
        tv.didChangeText()
    }

    // 可选字体：系统里所有字族 + 用户导入的
    static func availableFamilies() -> [String] {
        let all = NSFontManager.shared.availableFontFamilies
        let skip = ["Apple Symbols", "LastResort", "Zapf Dingbats"]
        return all.filter { !skip.contains($0) }.sorted()
    }

    /// 手动导入字体（.ttf / .otf / .ttc），注册到用户字体库
    func importFont() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.font, .data]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let dir = Store.shared.appSupport + "/Fonts"
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        let dest = URL(fileURLWithPath: dir).appendingPathComponent(url.lastPathComponent)
        try? FileManager.default.removeItem(at: dest)
        try? FileManager.default.copyItem(at: url, to: dest)
        var err: Unmanaged<CFError>?
        CTFontManagerRegisterFontsForURL(dest as CFURL, .user, &err)
        if let base = url.deletingPathExtension().lastPathComponent.components(separatedBy: "-").first {
            setFont(base)
        }
    }

    /// 启动时把以前导入过的字体重新注册
    static func registerImportedFonts() {
        let dir = Store.shared.appSupport + "/Fonts"
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: dir) else { return }
        for f in files {
            let url = URL(fileURLWithPath: dir).appendingPathComponent(f)
            var err: Unmanaged<CFError>?
            CTFontManagerRegisterFontsForURL(url as CFURL, .user, &err)
        }
    }

    func promptSize() {
        let alert = NSAlert()
        alert.messageText = "自定义字号"
        alert.informativeText = "输入 9 – 72 之间的数字，稿纸横线会自动跟着新字号重排。"
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 160, height: 24))
        field.stringValue = String(Int(currentSize))
        alert.accessoryView = field
        alert.addButton(withTitle: "确定")
        alert.addButton(withTitle: "取消")
        if alert.runModal() == .alertFirstButtonReturn, let v = Double(field.stringValue) {
            setSize(CGFloat(v))
        }
    }

    func insertDate() { textView?.insertText(dateString(), replacementRange: selection) }
    func insertDivider() { textView?.insertText("\n———\n", replacementRange: selection) }
    func insertTable() { textView?.insertText("\n| 列 1 | 列 2 |\n| --- | --- |\n|  |  |\n", replacementRange: selection) }

    private func dateString() -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "yyyy年M月d日 HH:mm"
        return f.string(from: Date())
    }

    func togglePreview() {
        saveNow()
        preview.toggle()
    }
}

// NSTextView 包装
struct RichTextView: NSViewRepresentable {
    var controller: EditorController
    var onChange: (String) -> Void

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = PagedScrollView()
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = false
        scroll.borderType = .noBorder
        scroll.autohidesScrollers = true

        let tv = RuledTextView(frame: NSRect(x: 0, y: 0, width: 600, height: 800))
        tv.isRichText = true
        tv.allowsUndo = true
        _ = tv.layoutManager   // 强制 TextKit 1：斜体用的 obliqueness 只有 TK1 会渲染
        tv.drawsBackground = false
        tv.textContainerInset = NSSize(width: 0, height: tv.topInset)
        tv.textContainer?.lineFragmentPadding = 0
        tv.textContainer?.widthTracksTextView = true   // 一行写满整行宽才换行
        tv.textContainer?.heightTracksTextView = false   // 高度自己算整数页，不能让容器高度跟着框走（否则量不出真实行数）
        tv.textContainer?.size.height = 100000
        tv.isHorizontallyResizable = false
        tv.isVerticallyResizable = false               // 纸张高度由「整数页」算出来，不让系统自己缩
        tv.autoresizingMask = [.width]
        tv.minSize = NSSize(width: 0, height: 0)
        tv.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        tv.isAutomaticQuoteSubstitutionEnabled = false
        tv.isAutomaticDashSubstitutionEnabled = false
        tv.delegate = context.coordinator
        scroll.documentView = tv
        controller.textView = tv
        controller.load(controller.cachedText)
        controller.applyPageStyle()

        // 翻页箭头要知道「现在在第几页」：滚动 / 窗口大小变化时回读
        scroll.contentView.postsBoundsChangedNotifications = true
        scroll.postsFrameChangedNotifications = true
        let c = controller
        NotificationCenter.default.addObserver(forName: NSView.boundsDidChangeNotification,
                                               object: scroll.contentView, queue: .main) { _ in c.updatePageState() }
        NotificationCenter.default.addObserver(forName: NSView.frameDidChangeNotification,
                                               object: scroll, queue: .main) { _ in c.refreshPagination() }
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
        // 文本由 NSTextView 自己管理，不在这里同步
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: RichTextView
        private var pending: DispatchWorkItem?

        init(_ parent: RichTextView) { self.parent = parent }

        func textViewDidChangeSelection(_ notification: Notification) {
            parent.controller.refreshFormatState()
        }

        func textDidChange(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            parent.controller.refreshFormatState()
            let text = tv.string
            pending?.cancel()
            let work = DispatchWorkItem { [weak self] in
                self?.parent.controller.cachedText = text
                Store.shared.saveContent(self?.parent.controller.docID ?? "", text)
            }
            pending = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: work)

            // 行数变了 → 页边界跟着重排（延迟一点，别打断输入）
            self.parent.controller.schedulePageRestyle()
            self.parent.controller.updatePageState()
            self.parent.controller.followCaretToNewPage()
        }
    }
}

// 编辑器页面
struct EditorView: View {
    var controller: EditorController

    private var cfg: ConfigData { Config.shared.d }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                header
                if cfg.toolbarVisible { toolbar }
            }
            .background {
                Rectangle()
                    .fill(.clear)
                    .glassEffect(.regular, in: .rect(cornerRadius: 0))
            }
            ZStack {
                Color(nsColor: Skin.p.bg)
                Group {
                    if controller.preview {
                        paperBackground(showLines: false)
                        MarkdownPreview(text: controller.cachedText)
                            .padding(.horizontal, 120)
                    } else {
                        paperBackground(showLines: !cfg.focusMode)
                        VStack(spacing: 0) {
                            RichTextView(controller: controller) { _ in }
                                .frame(height: CGFloat(controller.paperLines) * CGFloat(cfg.lineHeight) + 10)
                            HStack(spacing: 0) {
                                Spacer(minLength: 0)
                                Text("第 \(controller.currentPage) 页")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Color(nsColor: Skin.p.textDim))
                                    .padding(.trailing, 2)
                            }
                            .padding(.top, 6)
                        }
                        .frame(width: CGFloat(min(cfg.paperWidth, 1000)) - 44)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 22)
                    }
                }
                .offset(x: controller.slideOffset)
                if !controller.preview {
                    pageArrows
                }
            }
            .clipped()
        }
        .background(Color(nsColor: Skin.p.bg))
        .onChange(of: cfg.fontSize) { _, _ in controller.applyPageStyle() }
        .onChange(of: cfg.lineHeight) { _, _ in controller.applyPageStyle() }
        .onChange(of: cfg.focusMode) { _, _ in controller.applyPageStyle() }
    }

    private func paperBackground(showLines: Bool) -> some View {        HStack {
            Spacer(minLength: 0)
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: kRadius, style: .continuous)
                    .fill(Color(nsColor: Skin.p.paper(cfg.paperTone)))
                    .shadow(color: .black.opacity(0.05), radius: 10, y: 2)

            }
            .frame(width: CGFloat(min(cfg.paperWidth, 1000)))
            .padding(.vertical, 18)
            Spacer(minLength: 0)
        }
    }

    /// 左右翻页：左边一个、右边一个，各管一边，不会再变成同一个按钮
    private var pageArrows: some View {
        HStack(spacing: 0) {
            if controller.currentPage > 1 {
                pageArrow("chevron.left") { controller.prevPage() }
            }
            Spacer(minLength: 0)
            if controller.currentPage < controller.totalPages {
                pageArrow("chevron.right") { controller.nextPage() }
            }
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .animation(.easeInOut(duration: 0.16), value: controller.currentPage)
        .animation(.easeInOut(duration: 0.16), value: controller.totalPages)
    }

    private func pageArrow(_ icon: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(nsColor: Skin.p.text))
                .frame(width: 32, height: 32)
                .glassEffect(.regular, in: .circle)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .help(icon == "chevron.right" ? "下一页" : "上一页")
    }

    private var header: some View {
        HStack(spacing: 10) {
            // 没有「返回」按钮：关窗用它自己的红绿灯，关闭即保存
            Text(controller.docTitle)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(nsColor: Skin.p.text))
                .lineLimit(1)

            if controller.isMarkdown {
                Text("MD")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color(nsColor: Skin.p.textDim))
                    .padding(.horizontal, 5).padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color(nsColor: Skin.p.hover)))
            }

            Spacer()

            Text(Store.shared.metaLabel(controller.docID))
                .font(.system(size: 11))
                .foregroundStyle(Color(nsColor: Skin.p.textDim))

            if controller.isMarkdown {
                Button(action: { controller.togglePreview() }) {
                    Text(controller.preview ? "编辑" : "预览")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color(nsColor: Skin.p.text))
                        .padding(.horizontal, 10).frame(height: 22)
                        .background(RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(Color(nsColor: Skin.p.accentSoft)))
                }
                .buttonStyle(.plain)
            }

            Menu {
                Button("重命名…") { WindowManager.shared.renameDoc(controller.docID) }
                Button("显示属性") { HomeModel.shared.say(Store.shared.metaLabel(controller.docID)) }
                Divider()
                Button("删除") {
                    Store.shared.deleteDoc(controller.docID)
                    NotificationCenter.default.post(name: .storeChanged, object: nil)
                    controller.window?.performClose(nil)
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(nsColor: Skin.p.textDim))
                    .frame(width: 26, height: 22)
                    .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
    }

    private var toolbar: some View {
        HStack(spacing: 6) {
            ToolButton(icon: "bold", on: controller.boldOn) { controller.bold() }
            ToolButton(icon: "italic", on: controller.italicOn) { controller.italic() }
            ToolButton(icon: "underline", on: controller.underlineOn) { controller.underline() }
            ToolButton(icon: "highlighter", on: controller.highlightOn) { controller.highlight() }

            sep

            ToolButton(icon: "text.alignleft", on: controller.alignmentIndex == 0) { controller.align(0) }
            ToolButton(icon: "text.aligncenter", on: controller.alignmentIndex == 1) { controller.align(1) }
            ToolButton(icon: "text.alignright", on: controller.alignmentIndex == 2) { controller.align(2) }
            ToolButton(icon: "text.justify", on: controller.alignmentIndex == 3) { controller.align(3) }

            sep

            Menu {
                Section("常用") {
                    Button("苹方 PingFang") { controller.setFont("PingFang SC") }
                    Button("宋体 Songti") { controller.setFont("Songti SC") }
                    Button("黑体 Heiti") { controller.setFont("Heiti SC") }
                    Button("楷体 Kaiti") { controller.setFont("Kaiti SC") }
                    Button("圆体 Yuanti") { controller.setFont("Yuanti SC") }
                    Button("等宽 Menlo") { controller.setFont("Menlo") }
                }
                Divider()
                Button("导入字体文件…") { controller.importFont() }
                Divider()
                Menu("全部字体") {
                    ForEach(EditorController.availableFamilies(), id: \.self) { fam in
                        Button(fam) { controller.setFont(fam) }
                    }
                }
            } label: {
                Text(controller.currentFontName)
                    .font(.system(size: 11))
                    .foregroundStyle(Color(nsColor: Skin.p.text))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .padding(.horizontal, 9)
            .frame(height: 26)
            .glassPanel(radius: 13, tint: Color.white.opacity(Skin.isDark ? 0.10 : 0.85), interactive: true)
            .frame(width: 92, alignment: .leading)
            .padding(.trailing, 14)

            Menu {
                Button("12") { controller.setSize(12) }
                Button("15") { controller.setSize(15) }
                Button("18") { controller.setSize(18) }
                Button("21") { controller.setSize(21) }
                Button("24") { controller.setSize(24) }
                Button("30") { controller.setSize(30) }
                Button("36") { controller.setSize(36) }
                Button("48") { controller.setSize(48) }
                Divider()
                Button("自定义字号…") { controller.promptSize() }
            } label: {
                Text("Aa \(Int(controller.currentSize))")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(nsColor: Skin.p.text))
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .padding(.horizontal, 9)
            .frame(height: 26)
            .glassPanel(radius: 13, tint: Color.white.opacity(Skin.isDark ? 0.10 : 0.85), interactive: true)
            .frame(width: 62)

            Spacer()

            Menu {
                Button("插入当前时间") { controller.insertDate() }
                Button("插入表格") { controller.insertTable() }
                Button("插入分隔线") { controller.insertDivider() }
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(nsColor: Skin.p.textDim))
            }
            .menuStyle(.borderlessButton).fixedSize().frame(width: 28)
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 10)
    }

    private var sep: some View {
        Rectangle().fill(Color(nsColor: Skin.p.line)).frame(width: 1, height: 16).padding(.horizontal, 4)
    }
}

struct ToolButton: View {
    var icon: String
    var on: Bool = false
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color(nsColor: on ? Skin.p.text : Skin.p.textDim))
                .frame(width: 26, height: 24)
                .background {
                    if on {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color(nsColor: Skin.p.accent))
                    }
                }
                .contentShape(Rectangle())
                .hoverHand()
        }
        .buttonStyle(.plain)
    }
}
