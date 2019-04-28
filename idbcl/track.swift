//
//  track.swift
//  idbcl
//

import Foundation
import iTunesLibrary

class Track {
    private let persistentID: String
    private let untrackedPropertyValues:[Any]
    private let rating: Any
    private let playCount: Any
    
    public init(fromItem: ITLibMediaItem) {
        persistentID = String(format: "%llX", fromItem.persistentID.uint64Value)
        
        untrackedPropertyValues = [
            ITLibMediaItemPropertyAlbumTitle
            , ITLibMediaItemPropertyArtistName
            , ITLibMediaItemPropertyBitRate
            , ITLibMediaItemPropertyFileSize
            , ITLibMediaItemPropertyGenre
            , ITLibMediaItemPropertyKind
            , ITLibMediaItemPropertySampleRate
            , ITLibMediaItemPropertyTitle
            , ITLibMediaItemPropertyTotalTime
            , ITLibMediaItemPropertyYear
        ].map {
            fromItem.value(forProperty: $0)!
        }
        
        rating = fromItem.value(forProperty: ITLibMediaItemPropertyRating) ?? 50
        playCount = fromItem.value(forProperty: ITLibMediaItemPropertyPlayCount) ?? 0
    }
    
    public func updateTables(updateDB: Database) {
        updateDB.updateMeta(persistentID: persistentID, untrackedPropertyValues: untrackedPropertyValues)
        updateDB.updateTable(tableName: "PlayCounts", persistentID: persistentID, trackedPropertyValue: playCount)
        updateDB.updateTable(tableName: "Ratings", persistentID: persistentID, trackedPropertyValue: rating)
    }
}
