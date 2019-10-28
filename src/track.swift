import iTunesLibrary

let DEFAULT_RATING: Int = 50
let DEFAULT_PLAY_COUNT: Int = 0

let UNTRACKED_PROPERTIES = [
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
    public let persistentID: String
    public let untrackedProperties: [String]
    public let rating: Int
    public let playCount: Int
    
    public init(fromItem: ITLibMediaItem) {
        persistentID = String(format: "%016llX", fromItem.persistentID.uint64Value)
        
        untrackedProperties = UNTRACKED_PROPERTIES.map {
            String(describing: fromItem.value(forProperty: $0) ?? "")
        }
        
        rating = fromItem.value(forProperty: ITLibMediaItemPropertyRating) as? Int ?? DEFAULT_RATING
        playCount = fromItem.value(forProperty: ITLibMediaItemPropertyPlayCount) as? Int ?? DEFAULT_PLAY_COUNT
    }
}
