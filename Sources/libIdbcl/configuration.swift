import Foundation

struct Configuration {
    static let executablePath: URL = Bundle.main.executableURL!
    static let dataDir: URL? = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("idbcl")
    static let dbFilePath: URL? = dataDir!.appendingPathComponent("records.sqlite3")
}
