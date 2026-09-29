import AppKit
import WebKit

@objc(MarkdownDocument)
final class MarkdownDocument: NSDocument, WKNavigationDelegate {
    private let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
    private var markdown = ""
    private var loaded = false

    private static let exportCSS = """
    html{color-scheme:light;background:#fff}body{margin:0}
    .markdown-body{box-sizing:border-box;max-width:980px;margin:0 auto;padding:32px 45px}
    .mermaid{text-align:center;margin:16px 0}svg{max-width:100%;height:auto}
    """

    override init() {
        super.init()
        webView.navigationDelegate = self
        if let page = Bundle.main.url(forResource: "index", withExtension: "html") {
            webView.loadFileURL(page, allowingReadAccessTo: URL(fileURLWithPath: "/"))
        }
    }

    override class var autosavesInPlace: Bool { false }

    override func makeWindowControllers() {
        let win = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 900, height: 1000),
                           styleMask: [.titled, .closable, .miniaturizable, .resizable],
                           backing: .buffered, defer: false)
        win.contentView = webView
        win.center()
        addWindowController(NSWindowController(window: win))
    }

    override func read(from data: Data, ofType typeName: String) throws {
        markdown = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) ?? ""
        render()
    }

    override func presentedItemDidChange() {
        super.presentedItemDidChange()
        DispatchQueue.main.async {
            guard let url = self.fileURL, let data = try? Data(contentsOf: url) else { return }
            try? self.read(from: data, ofType: "")
        }
    }

    // MARK: Rendering

    private var baseHref: String { fileURL?.deletingLastPathComponent().absoluteString ?? "" }

    private func render() {
        guard loaded else { return }
        webView.callAsyncJavaScript("await render(md, base)", arguments: ["md": markdown, "base": baseHref],
                                    in: nil, in: .page) { _ in self.headlessExport() }
    }

    /// `PLUME_EXPORT=/path/prefix` writes prefix.html and prefix.pdf once rendered, then quits.
    private var exported = false
    private func headlessExport() {
        guard !exported, !markdown.isEmpty, let prefix = ProcessInfo.processInfo.environment["PLUME_EXPORT"] else { return }
        exported = true
        saveHTML(to: URL(fileURLWithPath: prefix + ".html")) {
            self.afterPrint = { NSApp.terminate(nil) }
            self.savePDF(to: URL(fileURLWithPath: prefix + ".pdf"))
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loaded = true
        render()
    }

    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard action.navigationType == .linkActivated, let url = action.request.url else {
            return decisionHandler(.allow)
        }
        decisionHandler(.cancel)
        if url.isFileURL, ["md", "markdown", "mdown"].contains(url.pathExtension.lowercased()) {
            NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { _, _, _ in }
        } else {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: Light theme for output (dark UI would print light text on white paper)

    private func withLight(_ body: @escaping () -> Void) {
        webView.appearance = NSAppearance(named: .aqua)
        webView.callAsyncJavaScript("await settle(false)", arguments: [:], in: nil, in: .page) { _ in body() }
    }

    private func restoreTheme() { webView.appearance = nil }

    // MARK: Zoom

    @objc func zoomIn(_ sender: Any?) { webView.pageZoom *= 1.1 }
    @objc func zoomOut(_ sender: Any?) { webView.pageZoom /= 1.1 }
    @objc func zoomReset(_ sender: Any?) { webView.pageZoom = 1 }

    // MARK: Print and PDF

    private var window: NSWindow? { windowControllers.first?.window }

    private func pageInfo() -> NSPrintInfo {
        let info = printInfo.copy() as! NSPrintInfo
        info.topMargin = 36; info.bottomMargin = 36; info.leftMargin = 36; info.rightMargin = 36
        info.isHorizontallyCentered = false
        info.isVerticallyCentered = false
        return info
    }

    private func run(_ info: NSPrintInfo, panel: Bool) {
        let op = webView.printOperation(with: info)
        op.showsPrintPanel = panel
        op.showsProgressPanel = panel
        op.view?.frame = NSRect(origin: .zero, size: info.paperSize)
        if let window = window {
            op.runModal(for: window, delegate: self, didRun: #selector(printDidRun(_:success:contextInfo:)),
                        contextInfo: nil)
        } else {
            restoreTheme()
        }
    }

    private var afterPrint: (() -> Void)?

    @objc func printDidRun(_ op: NSPrintOperation, success: Bool, contextInfo: UnsafeMutableRawPointer?) {
        restoreTheme()
        afterPrint?()
        afterPrint = nil
    }

    override func printDocument(_ sender: Any?) {
        withLight { self.run(self.pageInfo(), panel: true) }
    }

    @objc func exportPDF(_ sender: Any?) {
        guard let window = window else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = baseName + ".pdf"
        panel.beginSheetModal(for: window) { result in
            guard result == .OK, let url = panel.url else { return }
            self.savePDF(to: url)
        }
    }

    private func savePDF(to url: URL) {
        withLight {
            let info = self.pageInfo()
            info.jobDisposition = .save
            info.dictionary()[NSPrintInfo.AttributeKey.jobSavingURL] = url
            self.run(info, panel: false)
        }
    }

    // MARK: HTML export

    @objc func exportHTML(_ sender: Any?) {
        guard let window = window else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.html]
        panel.nameFieldStringValue = baseName + ".html"
        panel.beginSheetModal(for: window) { result in
            guard result == .OK, let url = panel.url else { return }
            self.saveHTML(to: url)
        }
    }

    private func saveHTML(to url: URL, done: (() -> Void)? = nil) {
        withLight {
            self.webView.callAsyncJavaScript("return document.getElementById('content').innerHTML",
                                             arguments: [:], in: nil, in: .page) { r in
                self.restoreTheme()
                if case .success(let body as String) = r {
                    do { try self.page(body: body).write(to: url, atomically: true, encoding: .utf8) }
                    catch { if let w = self.window { NSAlert(error: error).beginSheetModal(for: w) } }
                }
                done?()
            }
        }
    }

    private var baseName: String { fileURL?.deletingPathExtension().lastPathComponent ?? "Untitled" }

    private func page(body: String) -> String {
        // Keep only the light palette so the exported page matches the light-themed diagrams.
        let css = (Bundle.main.url(forResource: "github-markdown", withExtension: "css")
            .flatMap { try? String(contentsOf: $0) } ?? "")
            .replacingOccurrences(of: "(prefers-color-scheme: dark)", with: "not all")
            .replacingOccurrences(of: "(prefers-color-scheme: light)", with: "all")
        return """
        <!doctype html><html><head><meta charset="utf-8">
        <meta name="viewport" content="width=device-width,initial-scale=1">
        <title>\(baseName)</title><base href="\(baseHref)">
        <style>\(css)\n\(Self.exportCSS)</style></head>
        <body><article class="markdown-body">\(body)</article></body></html>
        """
    }
}
