import Foundation

struct Configuration {
    static let executablePath: URL = URL(fileURLWithPath: CommandLine.arguments[0])
    static let dataDir: URL? = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("idbcl")
    static let dbFilePath: URL? = dataDir!.appendingPathComponent("records.sqlite3")
}
