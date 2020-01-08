import iTunesLibrary

let DEFAULT_RATING: Int = 50
let DEFAULT_PLAY_COUNT: Int = 0

public let PROPERTY_HEADERS = [
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

class Track : CustomStringConvertible {
    public let persistentID: String
    let item: ITLibMediaItem
    
    init(fromItem: ITLibMediaItem) {
        item = fromItem
        persistentID = String(format: "%016llX", fromItem.persistentID.uint64Value)
    }

    func value(forProperty: String) -> String { return String(describing: item.value(forProperty: forProperty) ?? "") }
    
    var description: String { return String(describing: item.value(forProperty: ITLibMediaItemPropertyTitle) ?? "Untitled Track") }
    
    var rating: Int {
        if item.isRatingComputed {
            return DEFAULT_RATING
        } else {
            return item.value(forProperty: ITLibMediaItemPropertyRating) as? Int ?? DEFAULT_RATING
        }
    }
    
    var playCount: Int { return item.value(forProperty: ITLibMediaItemPropertyPlayCount) as? Int ?? DEFAULT_PLAY_COUNT }
}
