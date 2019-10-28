import Foundation
import SQLite3

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
        if sqlite3_close(db) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("Error closing Database: \(errmsg)")
        }
    }
    
    private func CreateTables() {
        ExecuteNonQuery(sql: """
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
        """)
        ExecuteNonQuery(sql: """
        CREATE TABLE IF NOT EXISTS PlayCounts (
            PersistentID TEXT,
            Date INTEGER,
            PlayCount INTEGER,
            PRIMARY KEY (PersistentID, PlayCount))
        """)
        ExecuteNonQuery(sql: """
        CREATE TABLE IF NOT EXISTS Ratings (
            PersistentID TEXT,
            Date INTEGER,
            Rating INTEGER)
        """)
    }
    
    private func ExecuteNonQuery(sql: String, params: [String] = []) {
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
                print("Failed to execute scalar query: \(errmsg)")
            }
            result = nil
            
        } else {
            if sqlite3_column_count(statement) != 1 {
                print("Query provided more than one result column.")
                result = nil
                
            } else {
                switch sqlite3_column_type(statement, 0) {
                    case SQLITE_INTEGER:
                        result = sqlite3_column_int64(statement, 0)
                    case SQLITE_TEXT:
                        result = sqlite3_column_text(statement, 0)
                    default:
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
    
    public func UpdateMeta(forTrack: Track) {
        ExecuteNonQuery(sql: "INSERT OR REPLACE INTO Meta VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                        params: [forTrack.persistentID] + forTrack.untrackedProperties)
    }
    
    private func WritePlayCount(forTrack: Track) {
        let id: String = forTrack.persistentID
        let pc: String = String(forTrack.playCount)
        
        ExecuteNonQuery(sql: "INSERT OR REPLACE INTO PlayCounts VALUES (?, STRFTIME('%s', 'now'), ?)", params: [id, pc])
    }
    
    public func UpdatePlayCounts(forTrack: Track) {
        if GetLastPlayCount(forTrack: forTrack) == nil {
            print("Title: \(forTrack.untrackedProperties[7]) - First PlayCount: \(forTrack.playCount)")
            WritePlayCount(forTrack: forTrack)
            return
        }
        
        if GetLastPlayCount(forTrack: forTrack) != forTrack.playCount {
            print("Title: \(forTrack.untrackedProperties[7]) - Updated PlayCount: \(GetLastPlayCount(forTrack: forTrack)!) -> \(forTrack.playCount)")
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
            print("Title: \(forTrack.untrackedProperties[7]) - First Rating: \(forTrack.rating)")
            WriteRating(forTrack: forTrack)
            return
        }
        
        if GetLastRating(forTrack: forTrack) != forTrack.rating {
            print("Title: \(forTrack.untrackedProperties[7]) - Updated Rating: \(GetLastRating(forTrack: forTrack)!) -> \(forTrack.rating)")
            WriteRating(forTrack: forTrack)
            return
        }
    }
}
