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
        
        let fileURL: URL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Dropbox", isDirectory: true)
            .appendingPathComponent("idbcl", isDirectory: true)
            .appendingPathComponent("records-test.sqlite3")
        
        db = Database(dbFileURL: fileURL)
        db.CreateTables()
        
        UpdateDB()
    }
    
    private func UpdateDB() {
        let media = lib?.allMediaItems
        for item in media! {
            if item.mediaKind == ITLibMediaItemMediaKind.kindSong {
                let tr = Track(fromItem: item)
                db.UpdateMeta(forTrack: tr)
                db.UpdatePlayCounts(forTrack: tr)
                db.UpdateRatings(forTrack: tr)
            }
        }
    }
}
