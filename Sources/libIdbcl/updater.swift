import Foundation
import iTunesLibrary

class Updater {
    private let dbTables: DbTables
    private var dbTracksById: [String : DatabaseTrack]
    
    public init?(dbFileURL: URL, dryRun: Bool = false) {
        guard let dbTables = DbTables(dbUrl: dbFileURL, access: dryRun ? .dryrun : .readwrite)  else { return nil }
        self.dbTables = dbTables
        self.dbTracksById = Reporter(db: self.dbTables).tracks
    }
       
    @discardableResult
    public func updateMeta(forTrack track: LibraryTrack) -> Int {
        var rowsChanged = 0
        
        if let dbTrack = dbTracksById[track.persistentID] {
            for property in DatabaseTrack.metadataLayout {
                let oldValue: String? = dbTrack.stringValue(forProperty: property)
                let currentValue: String? = track.stringValue(forProperty: property)

                if oldValue != currentValue {
                    rowsChanged += dbTables.setMeta(id: track.persistentID, property: property, value: currentValue)
                    
                    print("\(track) - Updated \(property): \(oldValue ?? "NULL")"
                          + " -> \(currentValue ?? "NULL")")
                }
            }
        } else {
            let props: [String?] = DatabaseTrack.metadataLayout.map { track.stringValue(forProperty: $0) }
            rowsChanged = dbTables.setMeta(values: [track.persistentID] + props)
            print("\(track) - Created Metadata")
            dbTracksById.updateValue(DatabaseTrack(meta: [track.persistentID] + props), forKey: track.persistentID)
        }
        
        return rowsChanged
    }
    
    private func printUpdate(track: LibraryTrack, property: String, previous: Int?, current: Int) {
        print("\(track) - "
            + (previous == nil ? "First " : "Updated ")
            + "\(property): "
            + (previous == nil ? "\(current)" : "\(previous!) -> \(current)"))
    }
    
    @discardableResult
    public func updatePlayCounts(forTrack track: LibraryTrack) -> Int {
        if let dbTrack = dbTracksById[track.persistentID] {
            let last: Int? = dbTrack.playCount
            let current: Int = track.playCount ?? DEFAULT_PLAY_COUNT
            
            if last != current {
                let res: Int = dbTables.setPlayCount(id: track.persistentID, value: current)
                if res == 1 { printUpdate(track: track, property: "PlayCount", previous: last, current: current) }
                return res
            }
        }
        
        return 0
    }
    
    @discardableResult
    public func updateRatings(forTrack track: LibraryTrack) -> Int {
        if let dbTrack = dbTracksById[track.persistentID] {
            let last: Int? = dbTrack.rating
            let current: Int = track.rating ?? DEFAULT_RATING

            if last != current {
                let res: Int = dbTables.setRating(id: track.persistentID, value: current)
                if res == 1 { printUpdate(track: track, property: "Rating", previous: last, current: current) }
                return res
            }
        }
        
        return 0
    }
}
