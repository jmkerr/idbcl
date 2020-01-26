import Foundation

/// Global configuration
struct Configuration {
    static let dataDir: URL? = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("idbcl")
    static let dbFilePath: URL? = dataDir!.appendingPathComponent("records.sqlite3")
}
