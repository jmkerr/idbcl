import Foundation

struct Configuration {
    static var executableURL: URL = URL(fileURLWithPath: CommandLine.arguments[0])
    static var dbFileURL: URL? = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("idbcl").appendingPathComponent("records.sqlite3")
}
