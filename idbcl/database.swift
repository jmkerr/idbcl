//
//  database.swift
//  idbcl
//

import Foundation
import SQLite3

let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

class Database {
    private var db: OpaquePointer?
    private let sb: StatementBuilder
    
    public init(dbFileURL: URL) {

        if sqlite3_open(dbFileURL.path, &db) != SQLITE_OK {
            print("Error opening database")
        }
        else {
            print("Opened Database " + dbFileURL.absoluteString)
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

    private func executeNonQuery(statement: OpaquePointer?) {
        if sqlite3_step(statement) != SQLITE_DONE {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("Failed to execute non query: \(errmsg)")
        }
    }
    
    public func UpdateMeta(updateTrack: Track) {
        var statement: OpaquePointer?
        sqlite3_prepare_v2(db, "INSERT OR REPLACE INTO Meta VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", -1, &statement, nil)
        sqlite3_bind_text(statement, 1, updateTrack.GetPersistentID(), -1, SQLITE_TRANSIENT)
        
        var bindPosition: Int32 = 2
        for item in updateTrack.GetUntrackedPropertyValuesAsStrings() {
            sqlite3_bind_text(statement, bindPosition, item.value, -1, SQLITE_TRANSIENT)
            bindPosition += 1
        }
        
        executeNonQuery(statement: statement)
    }
    
    public func UpdatePlayCounts(updateTrack: Track) {
        var statement: OpaquePointer?
        sqlite3_prepare_v2(db
            , "INSERT OR REPLACE INTO PlayCounts VALUES (?, STRFTIME('%s', 'now'), ?)"
            , -1
            , &statement
            , nil)
        
        sqlite3_bind_text(statement, 1, updateTrack.GetPersistentID(), -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 2, updateTrack.GetPlayCount(), -1, SQLITE_TRANSIENT)
        
        executeNonQuery(statement: statement)
    }
}
