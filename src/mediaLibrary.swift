//
//  mediaLibrary.swift
//  idbcl
//

import Foundation
import iTunesLibrary
import SQLite3

class MediaLibrary {
    let lib: ITLibrary?
    var db: Database?
    
    init() {
        do {
            lib = try ITLibrary(apiVersion: "1.1")
            
            let iTunesVersion: String? = lib?.applicationVersion
            let apiMajorVersion: Int? = lib?.apiMajorVersion
            let apiMinorVersion: Int? = lib?.apiMinorVersion
            let musicFolderLocation: URL? = lib?.musicFolderLocation
            
            print("iTunes Library Version " + iTunesVersion!)
            print("API Version " + String(apiMajorVersion!) + "." + String(apiMinorVersion!))
            print("In directory " + musicFolderLocation!.absoluteString)
        } catch {
            print("Error Initializing ITLibrary-Object.")
            exit(-5)
        }
        
        if Configuration.dbFileURL != nil {
            let dbDirectory: URL = Configuration.dbFileURL!.deletingLastPathComponent()
            do {
                try FileManager.default.createDirectory(at: dbDirectory, withIntermediateDirectories: false, attributes: nil)
            } catch CocoaError.fileWriteFileExists {
                // Not an error
            } catch {
                print("\(error)")
            }
                
            db = Database(dbFileURL: Configuration.dbFileURL!)
            db!.CreateTables()
            UpdateDB()
        } else {
            print("""
Usage:
    idbcl <database>
""")
        }
    }
    
    private func UpdateDB() {
        let media = lib?.allMediaItems
        for item in media! {
            if item.mediaKind == ITLibMediaItemMediaKind.kindSong {
                let tr = Track(fromItem: item)
                db!.UpdateMeta(forTrack: tr)
                db!.UpdatePlayCounts(forTrack: tr)
                db!.UpdateRatings(forTrack: tr)
            }
        }
    }
}
