//
//  mediaLibrary.swift
//  idbcl
//


import Foundation
import iTunesLibrary

class MediaLibrary {
    let lib: ITLibrary?
    let media:[ITLibMediaItem]?
    let db: Database
    
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
            
            media = lib?.allMediaItems
        } catch {
            print("Error Initializing ITLibrary-Object.")
            exit(-5)
        }
        
        db = Database(dbFileName: "records.sqlite3")
        db.createTables()
        
        scan()
    }
    
    private func scan() {
        for item in media! {
            if item.mediaKind == ITLibMediaItemMediaKind.kindSong {
                let tr = Track(fromItem: item)
                tr.updateTables(updateDB: db)
            }
        }
    }
}
