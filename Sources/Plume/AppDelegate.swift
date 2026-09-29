import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.mainMenu = makeMenu()
        DispatchQueue.main.async {
            if NSDocumentController.shared.documents.isEmpty {
                NSDocumentController.shared.openDocument(nil)
            }
        }
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool { false }
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { true }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { NSDocumentController.shared.openDocument(nil) }
        return false
    }

    private func item(_ title: String, _ action: Selector?, _ key: String = "",
                      _ mods: NSEvent.ModifierFlags = .command) -> NSMenuItem {
        let i = NSMenuItem(title: title, action: action, keyEquivalent: key)
        i.keyEquivalentModifierMask = mods
        return i
    }

    private func submenu(_ title: String, _ items: [NSMenuItem]) -> NSMenuItem {
        let m = NSMenu(title: title)
        items.forEach(m.addItem)
        let parent = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        parent.submenu = m
        return parent
    }

    private func makeMenu() -> NSMenu {
        let bar = NSMenu()
        let recent = submenu("Open Recent", [
            item("Clear Menu", #selector(NSDocumentController.clearRecentDocuments(_:)))
        ])
        let window = submenu("Window", [
            item("Minimize", #selector(NSWindow.performMiniaturize(_:)), "m"),
            item("Zoom", #selector(NSWindow.performZoom(_:))),
        ])
        NSApp.windowsMenu = window.submenu

        [
            submenu("Plume", [
                item("About Plume", #selector(NSApplication.orderFrontStandardAboutPanel(_:))),
                .separator(),
                item("Hide Plume", #selector(NSApplication.hide(_:)), "h"),
                item("Hide Others", #selector(NSApplication.hideOtherApplications(_:)), "h", [.command, .option]),
                item("Show All", #selector(NSApplication.unhideAllApplications(_:))),
                .separator(),
                item("Quit Plume", #selector(NSApplication.terminate(_:)), "q"),
            ]),
            submenu("File", [
                item("Open…", #selector(NSDocumentController.openDocument(_:)), "o"),
                recent,
                .separator(),
                item("Close", #selector(NSWindow.performClose(_:)), "w"),
                .separator(),
                item("Export as PDF…", #selector(MarkdownDocument.exportPDF(_:)), "e", [.command, .shift]),
                item("Export as HTML…", #selector(MarkdownDocument.exportHTML(_:))),
                item("Print…", #selector(MarkdownDocument.printDocument(_:)), "p"),
            ]),
            submenu("Edit", [
                item("Copy", #selector(NSText.copy(_:)), "c"),
                item("Select All", #selector(NSText.selectAll(_:)), "a"),
            ]),
            submenu("View", [
                item("Zoom In", #selector(MarkdownDocument.zoomIn(_:)), "+"),
                item("Zoom Out", #selector(MarkdownDocument.zoomOut(_:)), "-"),
                item("Actual Size", #selector(MarkdownDocument.zoomReset(_:)), "0"),
            ]),
            window,
        ].forEach(bar.addItem)
        return bar
    }
}
