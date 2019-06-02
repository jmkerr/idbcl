//
//  track.swift
//  idbcl
//

import Foundation
import iTunesLibrary

let untrackedProperties = [
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
] 

class Track {
    private let persistentID: String
    private let untrackedPropertyValues: [Any]
    private let rating: Any
    private let playCount: Any
    
    public init(fromItem: ITLibMediaItem) {
        var tmpPersistentID = String(format: "%llX", fromItem.persistentID.uint64Value)
        
        while tmpPersistentID.count != 16 {
            tmpPersistentID = "0" + tmpPersistentID
        }
        persistentID = tmpPersistentID
        
        untrackedPropertyValues =
        untrackedProperties.map {
            fromItem.value(forProperty: $0)!
        }
        
        rating = fromItem.value(forProperty: ITLibMediaItemPropertyRating) ?? 50
        playCount = fromItem.value(forProperty: ITLibMediaItemPropertyPlayCount) ?? 0
    }
    
    public func GetPersistentID() -> String {
        return persistentID
    }
    
    public func GetRating() -> String {
        if let result = rating as? NSNumber {
            return result.stringValue
        } else {
            return "NULL"
        }
    }
    
    public func GetPlayCount() -> String {
        if let result = playCount as? NSNumber {
            return result.stringValue
        } else {
            return "NULL"
        }
    }
    
    public func GetUntrackedPropertyValuesAsStrings() -> [String] {
        var result: [String] = [String]()
        
        for element in untrackedPropertyValues {
            if let val = element as? NSNumber {
                result.append(val.stringValue)
            }
            else if let val = element as? String {
                result.append(val)
            }
        }
        return result
    }
}
