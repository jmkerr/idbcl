import iTunesLibrary

/// Table level database abstraction used by Reporter and Updater.

class DbTables {
    let db: Database
    
    public init?(dbUrl: URL) {
        if let db = Database(dbFileURL: dbUrl) { self.db = db }
        else { return nil }
        createTables()
    }
    
    deinit {
        let rowCounts = Dictionary(uniqueKeysWithValues:
            ["Meta", "PlayCounts", "Ratings"].map { ($0, db.executeScalarQuery(sql: "SELECT COUNT(*) FROM \($0)")!) } )
       
        print("Closing Database, \(rowCounts), changed \(db.totalChanges)" )
    }
    
    private func createTables() {
        /*
         ITLibMediaEntityPropertyPersistentID == "PersistentID"
         ITLibMediaItemPropertyAlbumTitle == "AlbumTitle"
         ITLibMediaItemPropertyArtistName == "Artist"   (!)
         ITLibMediaItemPropertyBitRate == "BitRate"
         ...
         */
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
    }
    
    private func getTable(_ table: String) -> [[Any?]]? { return db.executeQuery(sql: "SELECT * FROM \(table)") }
    private func getThreeColumnTable(_ table: String) -> [(String, Int, Int)] {
            return getTable(table)!.map({ ($0[0] as! String, $0[1] as! Int, $0[2] as! Int) })
    }
    
    public func getMeta() -> [[Any?]] { getTable("Meta")! }
    public func getPlayCounts() -> [(String, Int, Int)] { return getThreeColumnTable("PlayCounts") }
    public func getRatings() -> [(String, Int, Int)] { return getThreeColumnTable("Ratings") }
    
    public func setMeta(id: String, property: String, value: String?) -> Int {
        return db.executeNonQuery(sql: "UPDATE Meta SET \(property) = ? WHERE PersistentID = ?", params: [value, id])
    }
    
    public func setMeta(values: [String?]) -> Int {
        return db.executeNonQuery(sql: "INSERT INTO Meta VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", params: values)
    }
    
    public func setPlayCount(id: String, value: Int) -> Int {
        return db.executeNonQuery(sql: "INSERT OR IGNORE INTO PlayCounts VALUES (?, ?, ?)",
                                  params: [id, String(Int(Date.current.timeIntervalSince1970)),String(value)])
    }
    
    public func setRating(id: String, value: Int) -> Int {
        return db.executeNonQuery(sql: "INSERT OR IGNORE INTO Ratings VALUES (?, ?, ?)",
                                  params: [id, String(Int(Date.current.timeIntervalSince1970)), String(value)])
    }
}
