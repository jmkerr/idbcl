import iTunesLibrary

public class MediaLibrary {
    private let lib: ITLibrary?
    private let db: DatabaseUpdater?
    
    public init?() {
        do {
            lib = try ITLibrary(apiVersion: "1.1")
        } catch {
            print("Error initializing ITLibrary: \(error)")
            return nil
        }
        
        if let applicationVersion: String = lib?.applicationVersion,
            let apiMajorVersion: Int = lib?.apiMajorVersion,
            let apiMinorVersion: Int = lib?.apiMinorVersion {
            let msg: String = String(format: "%@: iTunesLibrary version %@, API %d.%d",
                                     logDateString(), applicationVersion, apiMajorVersion, apiMinorVersion)
            print(msg)
        }
        
        guard let _: URL = lib?.musicFolderLocation else {
            print("Error: No music folder.")
            return nil
        }
        
        guard let dbPath = Configuration.dbFilePath else {
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
            
        db = DatabaseUpdater(dbFileURL: dbPath)
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
