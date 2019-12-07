import Foundation
import SQLite3
import iTunesLibrary

let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

class Database {
    private var db: OpaquePointer?

    public init?(dbFileURL: URL) {

        if sqlite3_open(dbFileURL.path, &db) != SQLITE_OK {
            print("Error opening database")
            return nil
        }
        else {
            print("Opened Database " + dbFileURL.path)
        }
        
        CreateTables()
    }
    
    deinit {
        let rowCounts = Dictionary(uniqueKeysWithValues:
            ["Meta", "PlayCounts", "Ratings"].map { ($0, ExecuteScalarQuery(sql: "SELECT COUNT(*) FROM \($0)")!) } )
        
        let totalChanges = sqlite3_total_changes(db)
        
        if sqlite3_close(db) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("Error closing Database: \(errmsg)")
        }
        
        print("Closed Database, rows: \(rowCounts), writes: \(totalChanges)" )
    }
    
    private func CreateTables() {
        /*
         ITLibMediaEntityPropertyPersistentID == "PersistentID"
         ITLibMediaItemPropertyAlbumTitle == "AlbumTitle"
         ITLibMediaItemPropertyArtistName == "Artist"   (!)
         ITLibMediaItemPropertyBitRate == "BitRate"
         ...
         */
        ExecuteNonQuery(sql: """
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
        ExecuteNonQuery(sql: """
        CREATE TABLE IF NOT EXISTS PlayCounts (
            \(ITLibMediaEntityPropertyPersistentID) TEXT,
            Date INTEGER,
            \(ITLibMediaItemPropertyPlayCount) INTEGER,
            PRIMARY KEY (\(ITLibMediaEntityPropertyPersistentID),
                         \(ITLibMediaItemPropertyPlayCount)))
        """)
        ExecuteNonQuery(sql: """
        CREATE TABLE IF NOT EXISTS Ratings (
            \(ITLibMediaEntityPropertyPersistentID) TEXT,
            Date INTEGER,
            \(ITLibMediaItemPropertyRating) INTEGER)
        """)
    }
    
    @discardableResult
    private func ExecuteNonQuery(sql: String, params: [String] = []) -> Int {
        var statement: OpaquePointer?
        sqlite3_prepare_v2(db, sql, -1, &statement, nil)
        
        for (pos, param) in params.enumerated() {
            sqlite3_bind_text(statement, Int32(pos+1), param, -1, SQLITE_TRANSIENT)
        }
        
        if sqlite3_step(statement) != SQLITE_DONE {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("Failed to execute non query: \(errmsg)")
        }
        
        if sqlite3_finalize(statement) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db))
            print("Error finalizing statement: \(errmsg)")
        }
        
        return Int(sqlite3_changes(db))
    }
    
    private func ExecuteScalarQuery(sql: String, params: [String] = []) -> Any? {
        var statement: OpaquePointer?
        sqlite3_prepare_v2(db, sql, -1, &statement, nil)
        
        for (pos, param) in params.enumerated() {
            sqlite3_bind_text(statement, Int32(pos+1), param, -1, SQLITE_TRANSIENT)
        }
        
        var result: Any?

        if sqlite3_step(statement) != SQLITE_ROW {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            if errmsg != "no more rows available" {
                print("Error: Failed to execute scalar query: \(errmsg)")
            }
            result = nil
            
        } else {
            if sqlite3_column_count(statement) != 1 {
                print("Error: Scalar query provided more than one result column.")
                result = nil
                
            } else {
                switch sqlite3_column_type(statement, 0) {
                    case SQLITE_INTEGER:
                        result = Int(sqlite3_column_int64(statement, 0))
                    case SQLITE_TEXT:
                        result = String(cString: sqlite3_column_text(statement, 0)!)
                    default:
                        print("Error: Scalar query result is not INTEGER or TEXT.")
                        result = nil
                }
            }
        }
        
        if sqlite3_finalize(statement) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db))
            print("Error finalizing statement: \(errmsg)")
        }
        
        return result
    }
    
    private func GetLastRating(forTrack: Track) -> Int? {
        let queryResult = ExecuteScalarQuery(sql: """
            SELECT Rating FROM Ratings WHERE PersistentID = ? ORDER BY Date DESC LIMIT 1
            """, params: [forTrack.persistentID])
        
        if let result = queryResult as? NSNumber {
            return result.intValue
        } else { return nil }
    }
    
    private func GetLastPlayCount(forTrack: Track) -> Int? {
        let queryResult = ExecuteScalarQuery(sql: """
            SELECT PlayCount FROM PlayCounts WHERE PersistentID = ? ORDER BY Date DESC LIMIT 1
            """, params: [forTrack.persistentID])
        
        if let result = queryResult as? NSNumber {
            return result.intValue
        } else { return nil }
    }
    
    private func GetPropertyValue(forTrack: Track, forProperty: String) -> String {
        let val = ExecuteScalarQuery(sql: "SELECT \(forProperty) FROM Meta WHERE PersistentID = ?",
                                params: [forTrack.persistentID])
        if let val = val as? Int { return "\(val)" }
        else if let val = val as? String { return val }
        else { return "" }
    }
    
    @discardableResult
    private func SetPropertyValue(forTrack: Track, forProperty: String, value: String) -> Int {
        return ExecuteNonQuery(sql: "UPDATE Meta SET \(forProperty) = ? WHERE PersistentID = ?",
                               params: [value, forTrack.persistentID])
    }
    
    public func UpdateMeta(forTrack: Track) {
        if GetPropertyValue(forTrack: forTrack, forProperty: "PersistentID") == "" {
            let props: [String] = STATIC_PROPERTIES.map { forTrack.value(forProperty: $0) }
            ExecuteNonQuery(sql: "INSERT INTO Meta VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                            params: [forTrack.persistentID] + props)
            print("Title: \(forTrack) - Created Metadata")
        } else {
            for property in STATIC_PROPERTIES {
                let oldValue: String = GetPropertyValue(forTrack: forTrack, forProperty: property)
                let currentValue: String = forTrack.value(forProperty: property)

                if oldValue != currentValue {
                    SetPropertyValue(forTrack: forTrack, forProperty: property, value: currentValue)
                    print("Title: \(forTrack) - Updated \(property): \(oldValue == "" ? "NULL" : oldValue)"
                          + " -> \(currentValue == "" ? "NULL" : currentValue)")
                }
            }
        }
    }
    
    private func WritePlayCount(forTrack: Track) {
        let id: String = forTrack.persistentID
        let pc: String = String(forTrack.playCount)
        
        ExecuteNonQuery(sql: "INSERT OR REPLACE INTO PlayCounts VALUES (?, STRFTIME('%s', 'now'), ?)", params: [id, pc])
    }
    
    public func UpdatePlayCounts(forTrack: Track) {
        if GetLastPlayCount(forTrack: forTrack) == nil {
            print("Title: \(forTrack) - First PlayCount: \(forTrack.playCount)")
            WritePlayCount(forTrack: forTrack)
            return
        }
        
        else if GetLastPlayCount(forTrack: forTrack) != forTrack.playCount {
            print("Title: \(forTrack) - Updated PlayCount: \(GetLastPlayCount(forTrack: forTrack)!) -> \(forTrack.playCount)")
            WritePlayCount(forTrack: forTrack)
            return
        }
    }
    
    private func WriteRating(forTrack: Track) {
        let id: String = forTrack.persistentID
        let rating: String = String(forTrack.rating)

        ExecuteNonQuery(sql: "INSERT OR REPLACE INTO Ratings VALUES (?, STRFTIME('%s', 'now'), ?)",
                        params: [id, rating])
    }
    
    public func UpdateRatings(forTrack: Track) {
        if GetLastRating(forTrack: forTrack) == nil {
            print("Title: \(forTrack) - First Rating: \(forTrack.rating)")
            WriteRating(forTrack: forTrack)
            return
        }
        
        else if GetLastRating(forTrack: forTrack) != forTrack.rating {
            print("Title: \(forTrack) - Updated Rating: \(GetLastRating(forTrack: forTrack)!) -> \(forTrack.rating)")
            WriteRating(forTrack: forTrack)
            return
        }
    }
}
