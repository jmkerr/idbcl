import iTunesLibrary

class MediaLibrary {
    private let lib: ITLibrary?
    private let db: Database?
    
    init?() {
        do {
            lib = try ITLibrary(apiVersion: "1.1")
        } catch {
            print("Error initializing ITLibrary: \(error)")
            return nil
        }
        
        if let applicationVersion: String = lib?.applicationVersion,
            let apiMajorVersion: Int = lib?.apiMajorVersion,
            let apiMinorVersion: Int = lib?.apiMinorVersion,
            let musicFolderLocation: URL = lib?.musicFolderLocation {
                print("iTunes Library Version " + applicationVersion
                    + ", API Version " + String(apiMajorVersion) + "." + String(apiMinorVersion))
                print("In directory " + musicFolderLocation.path)
        }
        
        guard let dbPath = Configuration.dbFileURL else {
            print("Configuration error.")
            return nil
        }
        
        do {
            let dbDirectory: URL = dbPath.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: dbDirectory,
                                                        withIntermediateDirectories: false,
                                                        attributes: nil)
            print("Creating " + dbDirectory.path)
        } catch CocoaError.fileWriteFileExists {
            // Ignore error
        } catch {
            print("Error creating directory: \(error)")
            return nil
        }
            
        db = Database(dbFileURL: dbPath)
    }

    public func UpdateDB() {
        if let mediaItems = lib?.allMediaItems,
            let db = db {
            let songItems = mediaItems.filter { $0.mediaKind == ITLibMediaItemMediaKind.kindSong }
            if songItems.count > 0 {
                for item in songItems {
                    let tr = Track(fromItem: item)
                    db.UpdateMeta(forTrack: tr)
                    db.UpdatePlayCounts(forTrack: tr)
                    db.UpdateRatings(forTrack: tr)
                }
            } else {
                print("The iTunes-Library appears to be empty.")
            }
        } else {
            print("Invalid operation")
        }
    }
}
