//
//  mediaLibrary.swift
//  idbcl
//


import Foundation
import iTunesLibrary
import SQLite3

class MediaLibrary {
    let lib: ITLibrary?
    var db: Database
    let fileURL:URL
    
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
        
        fileURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Dropbox", isDirectory: true)
            .appendingPathComponent("idbcl", isDirectory: true)
            .appendingPathComponent("records-test.sqlite3")
        
        db = Database(dbFileURL: fileURL)
        db.createTables()
        
        scan()
    }
    
    private func scan() {
        let media = lib?.allMediaItems
        for item in media! {
            if item.mediaKind == ITLibMediaItemMediaKind.kindSong {
                let tr = Track(fromItem: item)
                db.UpdateMeta(updateTrack: tr)
                db.UpdatePlayCounts(updateTrack: tr)
            }
        }
    }
}
