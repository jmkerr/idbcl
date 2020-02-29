import iTunesLibrary

enum Access {
    /// Can open and commit write transactions
    case readwrite
    
    /// Can open write transactions
    case dryrun
}

/// Table level database abstraction used by Reporter and Updater.

class DbTables {
    let db: Database
    let access: Access
    
    public init?(dbUrl: URL, access: Access = .readwrite) {
        if let db = Database(dbFileURL: dbUrl ) {
            self.db = db
            self.access = access
            
            guard let userVersion = db.executeScalarQuery(sql: "PRAGMA user_version") as? Int else {
                print("Unable to detect database schema version.")
                return nil
            }
            
            print("Opened DB, v\(userVersion), \(dbUrl.path)")

            do {
                try beginTransaction()
                try setSchema(userVersion: userVersion)
                try commitTransaction()
                
            } catch {
                print(error)
                return nil
            }
        
        }
        else { return nil }
    }
    
    deinit {
        let nrows = db.executeQuery(sql:"""
            SELECT (SELECT COUNT(*) FROM Meta),
                (SELECT COUNT(*) FROM PlayCounts),
                (SELECT COUNT(*) FROM Ratings)
            """)![0].map { String(describing: $0!) }
        
        do { try commitTransaction() }
        catch { print(error) }
        
        print("Closing Database, M: \(nrows[0]), P: \(nrows[1]), R: \(nrows[2]), Changed \(db.totalChanges)")
    }
    
    private func beginTransaction() throws {
        try db.exec("BEGIN TRANSACTION")
    }
    
    private func commitTransaction() throws {
        if access == .dryrun {
            /* Implicit rollback */
            
        } else if access == .readwrite {
            try db.exec("COMMIT")
            try beginTransaction()
        }
    }
    
    private func setSchema(userVersion: Int) throws {
        if userVersion == 0 {
            print("Updating tables to schema version 1...", terminator: "")
            /*
             ITLibMediaEntityPropertyPersistentID == "PersistentID"
             ITLibMediaItemPropertyAlbumTitle == "AlbumTitle"
             ITLibMediaItemPropertyArtistName == "Artist"   (!)
             ITLibMediaItemPropertyBitRate == "BitRate"
             ...
             */
            let sql = ["""
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
            """,
            """
            CREATE TABLE IF NOT EXISTS PlayCounts (
                \(ITLibMediaEntityPropertyPersistentID) TEXT,
                Date INTEGER,
                \(ITLibMediaItemPropertyPlayCount) INTEGER,
                PRIMARY KEY (\(ITLibMediaEntityPropertyPersistentID),
                             \(ITLibMediaItemPropertyPlayCount)))
            """,
            """
            CREATE TABLE IF NOT EXISTS Ratings (
                \(ITLibMediaEntityPropertyPersistentID) TEXT,
                Date INTEGER,
                \(ITLibMediaItemPropertyRating) INTEGER)
            """,
            "PRAGMA user_version=1"]
            
            for query in sql { try db.exec(query) }
            print("OK")
        }
    }
    
    private func getTable(_ table: String) -> [[Any?]]? { return db.executeQuery(sql: "SELECT * FROM \(table)") }
    private func getTypedTable(_ table: String) -> [(String, Int, Int)] {
            return getTable(table)!.map({ ($0[0] as! String, $0[1] as! Int, $0[2] as! Int) })
    }
    
    public func getMeta() -> [[Any?]] { getTable("Meta")! }
    public func getPlayCounts() -> [(String, Int, Int)] { return getTypedTable("PlayCounts") }
    public func getRatings() -> [(String, Int, Int)] { return getTypedTable("Ratings") }
    
    @discardableResult
    public func setMeta(id: String, property: String, value: String?) -> Int {
        return db.executeNonQuery(sql: "UPDATE Meta SET \(property) = ? WHERE PersistentID = ?", params: [value, id])
    }
    
    @discardableResult
    public func setMeta(values: [String?]) -> Int {
        return db.executeNonQuery(sql: "INSERT INTO Meta VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", params: values)
    }
    
    @discardableResult
    public func setPlayCount(id: String, value: Int) -> Int {
        return db.executeNonQuery(sql: "INSERT OR IGNORE INTO PlayCounts VALUES (?, ?, ?)",
                                  params: [id, String(Int(Date.current.timeIntervalSince1970)),String(value)])
    }
    
    @discardableResult
    public func setRating(id: String, value: Int) -> Int {
        return db.executeNonQuery(sql: "INSERT OR IGNORE INTO Ratings VALUES (?, ?, ?)",
                                  params: [id, String(Int(Date.current.timeIntervalSince1970)), String(value)])
    }
}
