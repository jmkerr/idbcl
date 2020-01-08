import Foundation
import iTunesLibrary

class DatabaseUpdater {
    private let db: Database
    
    public init?(dbFileURL: URL) {
        if let db = Database(dbFileURL: dbFileURL) {
            self.db = db
            CreateTables()
        } else { return nil }
    }
    
    deinit {
        let rowCounts = Dictionary(uniqueKeysWithValues:
            ["Meta", "PlayCounts", "Ratings"].map { ($0, db.ExecuteScalarQuery(sql: "SELECT COUNT(*) FROM \($0)")!) } )
       
        print("Closing Database, \(rowCounts), changed \(db.totalChanges)" )
    }
    
    private func CreateTables() {
        /*
         ITLibMediaEntityPropertyPersistentID == "PersistentID"
         ITLibMediaItemPropertyAlbumTitle == "AlbumTitle"
         ITLibMediaItemPropertyArtistName == "Artist"   (!)
         ITLibMediaItemPropertyBitRate == "BitRate"
         ...
         */
        db.ExecuteNonQuery(sql: """
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
        db.ExecuteNonQuery(sql: """
        CREATE TABLE IF NOT EXISTS PlayCounts (
            \(ITLibMediaEntityPropertyPersistentID) TEXT,
            Date INTEGER,
            \(ITLibMediaItemPropertyPlayCount) INTEGER,
            PRIMARY KEY (\(ITLibMediaEntityPropertyPersistentID),
                         \(ITLibMediaItemPropertyPlayCount)))
        """)
        db.ExecuteNonQuery(sql: """
        CREATE TABLE IF NOT EXISTS Ratings (
            \(ITLibMediaEntityPropertyPersistentID) TEXT,
            Date INTEGER,
            \(ITLibMediaItemPropertyRating) INTEGER)
        """)
    }
    
    private func GetMetaPropertyValue(forTrack: Track, forProperty: String) -> String {
        let val = db.ExecuteScalarQuery(sql: "SELECT \(forProperty) FROM Meta WHERE PersistentID = ?",
                                params: [forTrack.persistentID])
        if let val = val as? Int { return "\(val)" }
        else if let val = val as? String { return val }
        else { return "" }
    }
    
    @discardableResult
    private func UpdateMetaPropertyValue(forTrack: Track, forProperty: String, value: String) -> Int {
        return db.ExecuteNonQuery(sql: "UPDATE Meta SET \(forProperty) = ? WHERE PersistentID = ?",
                               params: [value, forTrack.persistentID])
    }
    
    @discardableResult
    public func UpdateMeta(forTrack: Track) -> Int {
        var rowsChanged = 0

        if GetMetaPropertyValue(forTrack: forTrack, forProperty: "PersistentID") == "" {
            let props: [String] = PROPERTY_HEADERS.map { forTrack.value(forProperty: $0) }
            rowsChanged = db.ExecuteNonQuery(sql: "INSERT INTO Meta VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                                         params: [forTrack.persistentID] + props)
            print("Title: \(forTrack) - Created Metadata")
            
        } else {
            for property in PROPERTY_HEADERS {
                let oldValue: String = GetMetaPropertyValue(forTrack: forTrack, forProperty: property)
                let currentValue: String = forTrack.value(forProperty: property)

                if oldValue != currentValue {
                    rowsChanged += UpdateMetaPropertyValue(forTrack: forTrack, forProperty: property, value: currentValue)
                    print("Title: \(forTrack) - Updated \(property): \(oldValue == "" ? "NULL" : oldValue)"
                          + " -> \(currentValue == "" ? "NULL" : currentValue)")
                }
            }
        }
        
        return rowsChanged
    }
    
    private func GetLastPropertyValue(forTrack: Track, forProperty: String) -> Int? {
        if !["PlayCount", "Rating"].contains(forProperty) { return nil }
        
        let queryResult = db.ExecuteScalarQuery(sql: """
            SELECT \(forProperty) FROM \(forProperty)s WHERE PersistentID = ? ORDER BY Date DESC LIMIT 1
            """, params: [forTrack.persistentID])
        
        if let result = queryResult as? NSNumber {
            return result.intValue
        } else { return nil }
    }
    
    private func WritePropertyValue(forTrack: Track, forProperty: String, value: Int) -> Int {
        if !["PlayCount", "Rating"].contains(forProperty) { return 0 }
        
        let id: String = forTrack.persistentID
        let dbValue: String = String(value)
        
        return db.ExecuteNonQuery(sql: "INSERT OR IGNORE INTO \(forProperty)s VALUES (?, STRFTIME('%s', 'now'), ?)", params: [id, dbValue])
    }
    
    private func UpdatePropertyValue(forTrack: Track, forProperty: String, value: Int) -> Int {
        if !["PlayCount", "Rating"].contains(forProperty) { return 0 }
        let last: Int? = GetLastPropertyValue(forTrack: forTrack, forProperty: forProperty)
        if last != value {
            let res: Int = WritePropertyValue(forTrack: forTrack, forProperty: forProperty, value: value)
            if res == 1 {
                print("Title: \(forTrack) - "
                    + (last == nil ? "First " : "Updated ")
                    + "\(forProperty): "
                    + (last == nil ? "\(value)" : "\(last!) -> \(value)"))
            }
            return res
        } else { return 0 }
    }
    
    @discardableResult
    public func UpdatePlayCounts(forTrack: Track) -> Int {
        return UpdatePropertyValue(forTrack: forTrack, forProperty: "PlayCount", value: forTrack.playCount)
    }
    
    @discardableResult
    public func UpdateRatings(forTrack: Track) -> Int {
        return UpdatePropertyValue(forTrack: forTrack, forProperty: "Rating", value: forTrack.rating)
    }
}
