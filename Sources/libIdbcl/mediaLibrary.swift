import iTunesLibrary

public class MediaLibrary {
    private let lib: ITLibrary?
    private let db: DatabaseUpdater?
    
    public init?(dbUrl: URL) {
        do {
            lib = try ITLibrary(apiVersion: "1.1")
        } catch {
            print("Error initializing ITLibrary: \(error)")
            return nil
        }
        
        if let applicationVersion: String = lib?.applicationVersion,
            let apiMajorVersion: Int = lib?.apiMajorVersion,
            let apiMinorVersion: Int = lib?.apiMinorVersion
        {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
            let msg: String = String(format: "%@: iTunesLibrary version %@, API %d.%d",
                                     df.string(from: Date()), applicationVersion, apiMajorVersion, apiMinorVersion)
            print(msg)
        }
        
        guard let _: URL = lib?.musicFolderLocation else {
            print("Error: No music folder.")
            return nil
        }
        
        do {
            let dbDirectory: URL = dbUrl.deletingLastPathComponent()
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
            
        db = DatabaseUpdater(dbFileURL: dbUrl)
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
