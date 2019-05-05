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
    
    public func CreateTables() {
        ExecuteNonQuery(statement: sb.initializeMeta())
        ExecuteNonQuery(statement: sb.initializePlayCounts())
        ExecuteNonQuery(statement: sb.initializeRatings())
    }

    private func ExecuteNonQuery(statement: OpaquePointer?) {
        if sqlite3_step(statement) != SQLITE_DONE {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("Failed to execute non query: \(errmsg)")
        }
    }
    
    private func ExecuteScalarQuery(statement: OpaquePointer?) -> Any? {
        if sqlite3_step(statement) != SQLITE_ROW {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            if errmsg != "no more rows available" {
                print("Failed to execute scalar query: \(errmsg)")
            }
            return nil
        }
            
        if sqlite3_column_count(statement) != 1 {
            print("Query provided more than one result column.")
            return nil
        }
        
        switch sqlite3_column_type(statement, 0) {
            case SQLITE_INTEGER:
                return sqlite3_column_int64(statement, 0)
            case SQLITE_TEXT:
                return sqlite3_column_text(statement, 0)
            default:
                return nil
        }
    }
    
    public func GetLastRating(forTrack: Track) -> Int? {
        var statement: OpaquePointer?
        sqlite3_prepare_v2(db, "SELECT Rating FROM Ratings WHERE PersistentID = ? ORDER BY Date DESC LIMIT 1", -1, &statement, nil)
        sqlite3_bind_text(statement, 1, forTrack.GetPersistentID(), -1, SQLITE_TRANSIENT)
        let queryResult = ExecuteScalarQuery(statement: statement)
        
        if let result = queryResult as? NSNumber {
            return result.intValue
        } else { return nil }
    }
    
    public func GetLastPlayCount(forTrack: Track) -> Int? {
        var statement: OpaquePointer?
        sqlite3_prepare_v2(db, "SELECT PlayCount FROM PlayCounts WHERE PersistentID = ? ORDER BY Date DESC LIMIT 1", -1, &statement, nil)
        sqlite3_bind_text(statement, 1, forTrack.GetPersistentID(), -1, SQLITE_TRANSIENT)
        let queryResult = ExecuteScalarQuery(statement: statement)
        
        if let result = queryResult as? NSNumber {
            return result.intValue
        } else { return nil }
    }
    
    public func UpdateMeta(forTrack: Track) {
        var statement: OpaquePointer?
        sqlite3_prepare_v2(db, "INSERT OR REPLACE INTO Meta VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", -1, &statement, nil)
        sqlite3_bind_text(statement, 1, forTrack.GetPersistentID(), -1, SQLITE_TRANSIENT)
        
        var bindPosition: Int32 = 2
        for item in forTrack.GetUntrackedPropertyValuesAsStrings() {
            sqlite3_bind_text(statement, bindPosition, item, -1, SQLITE_TRANSIENT)
            bindPosition += 1
        }
        
        ExecuteNonQuery(statement: statement)
    }
    
    public func WritePlayCount(forTrack: Track) {
        var statement: OpaquePointer?
        sqlite3_prepare_v2(db
            , "INSERT OR REPLACE INTO PlayCounts VALUES (?, STRFTIME('%s', 'now'), ?)"
            , -1
            , &statement
            , nil)
        
        sqlite3_bind_text(statement, 1, forTrack.GetPersistentID(), -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 2, forTrack.GetPlayCount(), -1, SQLITE_TRANSIENT)
        
        ExecuteNonQuery(statement: statement)
    }
    
    public func UpdatePlayCounts(forTrack: Track) {
        if GetLastPlayCount(forTrack: forTrack) == nil {
            print("Title: \(forTrack.GetUntrackedPropertyValuesAsStrings()[7]) - First PlayCount: \(forTrack.GetPlayCount())")
            WritePlayCount(forTrack: forTrack)
            return
        }
        
        if String(GetLastPlayCount(forTrack: forTrack)!) != forTrack.GetPlayCount() {
            print("Title: \(forTrack.GetUntrackedPropertyValuesAsStrings()[7]) - Updated PlayCount: \(GetLastPlayCount(forTrack: forTrack)!) -> \(forTrack.GetPlayCount())")
            WritePlayCount(forTrack: forTrack)
            return
        }
    }
    
    private func WriteRating(forTrack: Track) {
        var statement: OpaquePointer?
        sqlite3_prepare_v2(db
            , "INSERT OR REPLACE INTO Ratings VALUES (?, STRFTIME('%s', 'now'), ?)"
            , -1
            , &statement
            , nil)
        
        sqlite3_bind_text(statement, 1, forTrack.GetPersistentID(), -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 2, forTrack.GetRating(), -1, SQLITE_TRANSIENT)
        
        ExecuteNonQuery(statement: statement)
    }
    
    public func UpdateRatings(forTrack: Track) {
        if GetLastRating(forTrack: forTrack) == nil {
            print("Title: \(forTrack.GetUntrackedPropertyValuesAsStrings()[7]) - First Rating: \(forTrack.GetRating())")
            WriteRating(forTrack: forTrack)
            return
        }
        
        if String(GetLastRating(forTrack: forTrack)!) != forTrack.GetRating() {
            print("Title: \(forTrack.GetUntrackedPropertyValuesAsStrings()[7]) - Updated Rating: \(GetLastRating(forTrack: forTrack)!) -> \(forTrack.GetRating())")
            WriteRating(forTrack: forTrack)
            return
        }
    }
}
