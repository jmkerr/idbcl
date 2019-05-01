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
    private let untrackedPropertyValues: [String: Any]
    private let rating: Any
    private let playCount: Any
    
    public init(fromItem: ITLibMediaItem) {
        persistentID = String(format: "%llX", fromItem.persistentID.uint64Value)
        
        untrackedPropertyValues = Dictionary(uniqueKeysWithValues:
        untrackedProperties.map {
            ($0 as String, fromItem.value(forProperty: $0)!)
        })
        
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
    
    public func GetUntrackedPropertyValuesAsStrings() -> [String: String] {
        var result: [String: String] = [String: String]()
        
        for (key, val) in untrackedPropertyValues {
            if let val = val as? NSNumber {
                result.updateValue(val.stringValue, forKey: key)
            }
            else if let val = val as? String {
                result.updateValue(val, forKey: key)
            }
        }
        return result
    }
    
    
}
