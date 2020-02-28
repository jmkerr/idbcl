import XCTest
import iTunesLibrary
import Foundation
@testable import libIdbcl

/// Tests DbTables
class test_DbTables: idbcl_test {
    
    func testConstants() {
        XCTAssert(ITLibMediaEntityPropertyPersistentID == "PersistentID")
        XCTAssert(ITLibMediaItemPropertyAlbumTitle == "AlbumTitle")
        XCTAssert(ITLibMediaItemPropertyArtistName == "Artist")
        XCTAssert(ITLibMediaItemPropertyBitRate == "BitRate")
        XCTAssert(ITLibMediaItemPropertyFileSize == "FileSize")
        XCTAssert(ITLibMediaItemPropertyGenre == "Genre")
        XCTAssert(ITLibMediaItemPropertyKind == "Kind")
        XCTAssert(ITLibMediaItemPropertySampleRate == "SampleRate")
        XCTAssert(ITLibMediaItemPropertyTitle == "Title")
        XCTAssert(ITLibMediaItemPropertyTotalTime == "TotalTime")
        XCTAssert(ITLibMediaItemPropertyYear == "Year")
    }
    
    /// Test schema update on an empty database file
    
    func testDatabaseSchemaUpdate0() {
        // Empty database
        let dbFile = temporaryFile()
        
        
        // Update the database schema
        let _ = DbTables(dbUrl: dbFile)
        
        
        // Verify the changes
        var last: Any?
        if let db = Database(dbFileURL: dbFile) {
            last = db.executeScalarQuery(sql: "PRAGMA user_version")
        }

        XCTAssertEqual(last as? Int, 1)
        
    }
    
    
    /// Test schema update on a database without versioning
    
    func testDatabaseSchemaUpdate1() {
        let dbFile = temporaryFile()
        if let db = Database(dbFileURL: dbFile) {
            // Create the original schema
            db.executeNonQuery(sql: """
            CREATE TABLE IF NOT EXISTS Meta (
                \(ITLibMediaEntityPropertyPersistentID) TEXT PRIMARY KEY,
                \(ITLibMediaItemPropertyAlbumTitle) TEXT,
                \(ITLibMediaItemPropertyArtistName) TEXT,
                \(ITLibMediaItemPropertyBitRate) INTEGER,
                \(ITLibMediaItemPropertyFileSize) INTEGER,
                \(ITLibMediaItemPropertyGenre) TEXT,
                \(ITLibMediaItemPropertyKind) TEXT,
                \(ITLibMediaItemPropertySampleRate) INTEGER,
                \(ITLibMediaItemPropertyTitle) TEXT,
                \(ITLibMediaItemPropertyTotalTime) INTEGER,
                \(ITLibMediaItemPropertyYear) INTEGER)
            """)
            db.executeNonQuery(sql: """
            CREATE TABLE IF NOT EXISTS PlayCounts (
                \(ITLibMediaEntityPropertyPersistentID) TEXT,
                Date INTEGER,
                \(ITLibMediaItemPropertyPlayCount) INTEGER,
                PRIMARY KEY (\(ITLibMediaEntityPropertyPersistentID),
                             \(ITLibMediaItemPropertyPlayCount)))
            """)
            db.executeNonQuery(sql: """
            CREATE TABLE IF NOT EXISTS Ratings (
                \(ITLibMediaEntityPropertyPersistentID) TEXT,
                Date INTEGER,
                \(ITLibMediaItemPropertyRating) INTEGER)
            """)
    
        } else {
            XCTFail();
            return
            
        }
        
        
        // Update to the latest schema
        let _ = DbTables(dbUrl: dbFile)
        
        
        // Verify the changes
        var last: Any?
        if let db = Database(dbFileURL: dbFile) {
            last = db.executeScalarQuery(sql: "PRAGMA user_version")
        }

        XCTAssertEqual(last as? Int, 1)
    }
    
    
    func testMultipleDbs() {
        let dbFile = temporaryFile()
        
        let a = DbTables(dbUrl: dbFile, access: .readwrite)     // Writes schema, then opens read transaction
        let b = DbTables(dbUrl: dbFile, access: .dryrun)        // Opens read transaction

        XCTAssert(a != nil)
        XCTAssert(b != nil)


        let dbFile2 = temporaryFile()
        
        let d = DbTables(dbUrl: dbFile2, access: .dryrun)       // Opens write transaction
        let e = DbTables(dbUrl: dbFile2, access: .readwrite)    // Fails to open write transaction

        XCTAssert(d != nil)
        XCTAssert(e == nil)
    }
}
