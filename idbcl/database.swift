//
//  database.swift
//  idbcl
//

import Foundation
import SQLite3

class Database {
    private let fileURL: URL
    private var db: OpaquePointer?
    private let sb: StatementBuilder
    
    public init(dbFileName: String) {
        fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(dbFileName)

        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            print("Error opening database")
        }
        else {
            print("Opened Database " + fileURL.absoluteString)
        }
        
        sb = StatementBuilder(targetDb: db)
    }
    
    deinit {
        if sqlite3_close(db) != SQLITE_OK {
            print("Error closing Database")
        }
        db = nil
    }
    
    public func createTables() {
        executeNonQuery(statement: sb.initializeMeta())
        executeNonQuery(statement: sb.initializePlayCounts())
        executeNonQuery(statement: sb.initializeRatings())
    }
    
    public func updateMeta(persistentID: String, untrackedPropertyValues: [Any]) {
        executeNonQuery(statement: sb.updateMeta(persistentID: persistentID, untrackedPropertyValues: untrackedPropertyValues))
    }
    
    public func updateTable(tableName: String, persistentID: String, trackedPropertyValue: Any) {
        executeNonQuery(statement: sb.updateTable(tableName: tableName, persistentID: persistentID, value: trackedPropertyValue))
    }
    
    private func executeNonQuery(statement: OpaquePointer?) {
        if sqlite3_step(statement) != SQLITE_DONE {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("Failed to execute non query: \(errmsg)")
        }
    }
}
