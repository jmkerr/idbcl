//
//  statementBuilder.swift
//  idbcl
//

import Foundation
import SQLite3

class Statements {
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
    Rating INTEGER)
"""
            , -1
            , &statement
            , nil)
        return statement
    }
}
