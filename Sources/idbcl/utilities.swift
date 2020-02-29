import Foundation

private struct launchAgentConfiguration: Encodable {
    var Label: String = "idbcl"
    var RunAtLoad: Bool = true
    var StartInterval: Int
    var ProgramArguments: [String]
    var StandardOutPath: String
    var StandardErrorPath: String
    
    init(bin: URL, dataDir: URL, startInterval: Int) {
        ProgramArguments = [bin.path, "update"]
        StandardOutPath = dataDir.appendingPathComponent("stdout").path
        StandardErrorPath = dataDir.appendingPathComponent("stderr").path
        StartInterval = startInterval
    }
}

public func createLaunchAgent(startInterval: Int) {
    guard let bin = Bundle.main.executableURL,
        let dataDirectory = Configuration.dataDir,
        let launchAgentDirectory = FileManager.default.urls(for: .libraryDirectory,
                                                            in: .userDomainMask).first?.appendingPathComponent("LaunchAgents")
        else {
            print("Error: Cannot get the relevant paths."); return
    }
    
    let config = launchAgentConfiguration(bin: bin, dataDir: dataDirectory, startInterval: startInterval)
    let target = launchAgentDirectory.appendingPathComponent("idbcl.plist")
    
    let encoder = PropertyListEncoder()
    encoder.outputFormat = .xml
    
    do {
        let data = try encoder.encode(config)
        try FileManager.default.createDirectory(at: launchAgentDirectory,
                                                withIntermediateDirectories: true,
                                                attributes: nil)
        try data.write(to: target)
        print("Created \(target.path)")
        
    } catch {
        print(error)
    }
}
