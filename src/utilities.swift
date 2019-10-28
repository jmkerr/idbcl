import Foundation

func emitPlist() {
    let boilerplate = """
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0"><dict>
        <key>Label</key>                <string>idbcl</string>
        <key>RunAtLoad</key>            <true/>
        <key>StartInterval</key>        <integer>3456</integer>
        <key>StandardOutPath</key>      <string>/dev/null</string>
        <key>StandardErrorPath</key>    <string>/dev/null</string>
    </dict></plist>
    """
    
    let doc = try! XMLDocument(xmlString: boilerplate)
    
    let dict = doc.rootElement()!.elements(forName: "dict")[0]
    dict.addChild(XMLElement(name: "key", stringValue: "Program"))
    dict.addChild(XMLElement(name: "string", stringValue: Configuration.executableURL.path))
    
    let outfile = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("idbcl.plist")
    let xmlText = doc.xmlString(options: [XMLNode.Options.nodePrettyPrint, XMLNode.Options.nodeCompactEmptyElement])
   
    do {
        try xmlText.write(to: outfile, atomically: false, encoding: .utf8)
        print("Creating idbcl.plist")
    }
    catch { print("Unable to write to file.") }
}
