import Foundation
import SwiftUI
import libIdbcl

public class AppDelegate: NSObject, NSApplicationDelegate {
    
    let reporter: Reporter
    var window: NSWindow?
    
    init(reporter: Reporter) {
        self.reporter = reporter
    }
    
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    public func applicationWillFinishLaunching(_ notification: Notification) {
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 640, height: 480),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                              backing: .buffered,
                              defer: true)

        window?.center()
        window?.setFrameAutosaveName("idbcl")
        window?.title = "idbcl"
        window?.contentView = NSHostingView(rootView: RootView(reporter: reporter))
        window?.makeKeyAndOrderFront(nil)
    }
}

public func showGui(reporter: Reporter) {
    let app = NSApplication.shared
    let delegate = AppDelegate(reporter: reporter)
    app.delegate = delegate
    
    app.setActivationPolicy(.regular)
    app.activate(ignoringOtherApps: true)
    app.run()
}
