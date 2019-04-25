//
//  main.swift
//  idbcl
//
//  Created by Jonathan Kerr on 19.01.19.
//  Copyright © 2019 Jonathan Kerr. All rights reserved.
//

import Foundation
import iTunesLibrary
import SQLite3

var lib:ITLibrary? = nil
do {
    lib = try ITLibrary(apiVersion: "1.1")
    
    let iTunesVersion: String? = lib?.applicationVersion
    let apiMajorVersion: Int? = lib?.apiMajorVersion
    let apiMinorVersion: Int? = lib?.apiMinorVersion
    let musicFolderLocation: URL? = lib?.musicFolderLocation
        
    print("Writing iTunes Version " + iTunesVersion!)
    print("API Version " + String(apiMajorVersion!) + "." + String(apiMinorVersion!))
    print("In directory " + musicFolderLocation!.absoluteString)
    
} catch {
    print("Error Initializing ITLibrary.")
    exit(-5)
}

var media:[ITLibMediaItem]? = lib?.allMediaItems

for item in media! {
    if item.mediaKind == ITLibMediaItemMediaKind.kindSong {
        // unique property
        let persistentID = String(format: "%llX", item.persistentID.uint64Value)
        
        // untracked properties
        let untrackedProperties = [
              ITLibMediaItemPropertyAlbumTitle
            , ITLibMediaItemPropertyArtistName
            , ITLibMediaItemPropertyBitRate
            , ITLibMediaItemPropertyFileSize
            , ITLibMediaItemPropertyGenre
            , ITLibMediaItemPropertyKind
            , ITLibMediaItemPropertySampleRate
            , ITLibMediaItemPropertyTitle
            , ITLibMediaItemPropertyTotalTime
            , ITLibMediaItemPropertyYear
        ]
        
        let untrackedPropertyValues = untrackedProperties.map {
            item.value(forProperty: $0)!
        }
        
        print("persistent id: " + persistentID)
        print(untrackedPropertyValues)
        
        // tracked properties
        let rating = item.value(forProperty: ITLibMediaItemPropertyRating) ?? 50
        let playCount = item.value(forProperty: ITLibMediaItemPropertyPlayCount) ?? 0
        
        
        // Create 'meta' Table
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("db.sqlite3")
        
        var db: OpaquePointer?
        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            print("Error opening database")
        }
        
        var statement: OpaquePointer?
        
        sqlite3_prepare_v2(db
            , """
CREATE TABLE IF NOT EXISTS meta (
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
      
        let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        
        if sqlite3_step(statement) != SQLITE_DONE {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("Failed to conditionally create table meta: \(errmsg)")
        }
        
        if sqlite3_reset(statement) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("Failed to reset prepared statement: \(errmsg)")
        }
        
        
        sqlite3_prepare_v2(db, "INSERT INTO meta VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", -1, &statement, nil)
        sqlite3_bind_text(statement, 1, persistentID, -1, SQLITE_TRANSIENT)
        
        for (index, item) in untrackedPropertyValues.enumerated() {
            if let item = item as? NSNumber {
                sqlite3_bind_text(statement, Int32(index + 2), item.stringValue, -1, SQLITE_TRANSIENT)
                print("binding to index " + String(index + 2) + " the value " + item.stringValue)
            }
            else if let item = item as? String {
                sqlite3_bind_text(statement, Int32(index + 2), item, -1, SQLITE_TRANSIENT)
                print("binding to index " + String(index + 2) + " the value " + item)
            }
        }
        if sqlite3_step(statement) != SQLITE_DONE {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("Error on INSERT: \(errmsg)")
        }
        
        // !
        if sqlite3_close(db) != SQLITE_OK {
            print("Error closing Database")
        }
        db = nil
    }
}
