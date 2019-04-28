//
//  statementBuilder.swift
//  idbcl
//


import Foundation
import SQLite3

let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

class StatementBuilder {
    private let db: OpaquePointer?
    
    init(targetDb: OpaquePointer?) {
        db = targetDb
    }
    
    public func initializeMeta() -> OpaquePointer? {
        var statement: OpaquePointer?
        sqlite3_prepare_v2(db
            , """
CREATE TABLE IF NOT EXISTS Meta (
    PersistentID TEXT PRIMARY KEY,
    AlbumTitle TEXT,
    ArtistName TEXT,
    BitRate INTEGER,
    FileSize INTEGER,
    Genre TEXT,
    Kind TEXT,
    SampleRate INTEGER,
    Title TEXT,
    TotalTime INTEGER,
    Year INTEGER)
"""
            , -1
            , &statement
            , nil)
        
        return statement
    }
    
    public func initializePlayCounts() -> OpaquePointer? {
        var statement: OpaquePointer?
        sqlite3_prepare_v2(db
            , """
CREATE TABLE IF NOT EXISTS PlayCounts (
    PersistentID TEXT,
    Date INTEGER,
    PlayCount INTEGER,
    PRIMARY KEY (PersistentID, PlayCount))
"""
            , -1
            , &statement
            , nil)
        return statement
    }
    
    public func initializeRatings() -> OpaquePointer? {
        var statement: OpaquePointer?
        sqlite3_prepare_v2(db
            , """
CREATE TABLE IF NOT EXISTS Ratings (
    PersistentID TEXT,
    Date INTEGER,
    Rating INTEGER,
    PRIMARY KEY(PersistentID, Rating))
"""
            , -1
            , &statement
            , nil)
        return statement
    }
    
    public func updateMeta(persistentID: String, untrackedPropertyValues: [Any]) -> OpaquePointer? {
        var statement: OpaquePointer?
        sqlite3_prepare_v2(db
            , "INSERT OR REPLACE INTO Meta VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
            , -1
            , &statement
            , nil)
        
        sqlite3_bind_text(statement, 1, persistentID, -1, SQLITE_TRANSIENT)
        
        for (index, item) in untrackedPropertyValues.enumerated() {
            if let item = item as? NSNumber {
                sqlite3_bind_text(statement, Int32(index + 2), item.stringValue, -1, SQLITE_TRANSIENT)
                print(persistentID + ": binding to index " + String(index + 2) + " the value " + item.stringValue)
            }
            else if let item = item as? String {
                sqlite3_bind_text(statement, Int32(index + 2), item, -1, SQLITE_TRANSIENT)
                print(persistentID + ": binding to index " + String(index + 2) + " the value " + item)
            }
        }
        
        return statement
    }
    
    public func updateTable(tableName: String, persistentID: String, value: Any) -> OpaquePointer? {
        var statement: OpaquePointer?
        sqlite3_prepare_v2(db
            , "INSERT OR REPLACE INTO \(tableName) VALUES (?, STRFTIME('%s', 'now'), ?)"
            , -1
            , &statement
            , nil)
        
        sqlite3_bind_text(statement, 1, persistentID, -1, SQLITE_TRANSIENT)
        
        if let value = value as? NSNumber {
            sqlite3_bind_text(statement, 2, value.stringValue, -1, SQLITE_TRANSIENT)
        }
        
        return statement
    }
}
