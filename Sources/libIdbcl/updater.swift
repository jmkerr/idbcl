import Foundation
import iTunesLibrary

class Updater {
    private let dbTables: DbTables
    private var reporter: Reporter
    
    public init?(dbFileURL: URL) {
        if let dbTables = DbTables(dbUrl: dbFileURL) {
            self.dbTables = dbTables
        } else { return nil }
        
        self.reporter = Reporter(db: self.dbTables)
    }
       
    @discardableResult
    public func updateMeta(forTrack track: Track) -> Int {
        var rowsChanged = 0
        
        if let dbTrack = reporter.getTrack(id: track.persistentID) {
            for property in PROPERTY_HEADERS {
                let oldValue: String? = dbTrack.value(forProperty: property)
                let currentValue: String? = track.value(forProperty: property)

                if oldValue != currentValue {
                    rowsChanged += dbTables.setMeta(id: track.persistentID, property: property, value: currentValue)
                    
                    print("Title: \(track) - Updated \(property): \(oldValue ?? "NULL")"
                          + " -> \(currentValue ?? "NULL")")
                }
            }
        } else {
            let props: [String?] = PROPERTY_HEADERS.map { track.value(forProperty: $0) }
            rowsChanged = dbTables.setMeta(values: [track.persistentID] + props)
            print("Title: \(track) - Created Metadata")
            self.reporter = Reporter(db: self.dbTables)
        }
        
        return rowsChanged
    }
    
    private func printUpdate(forTrack: Track, forProperty: String, previous: Int?, current: Int) {
        print("Title: \(forTrack) - "
            + (previous == nil ? "First " : "Updated ")
            + "\(forProperty): "
            + (previous == nil ? "\(current)" : "\(previous!) -> \(current)"))
    }
    
    @discardableResult
    public func updatePlayCounts(forTrack track: Track) -> Int {
        if let dbTrack = reporter.getTrack(id: track.persistentID) {
            let last: Int? = dbTrack.playCount()
            let current = track.playCount
            
            if last != current {
                let res: Int = dbTables.setPlayCount(id: track.persistentID, value: current)
                if res == 1 { printUpdate(forTrack: track, forProperty: "PlayCount", previous: last, current: current) }
                return res
            }
        }
        
        return 0
    }
    
    @discardableResult
    public func updateRatings(forTrack track: Track) -> Int {
        if let dbTrack = reporter.getTrack(id: track.persistentID) {
            let last: Int? = dbTrack.rating()
            let current = track.rating
            
            if last != current {
                let res: Int = dbTables.setRating(id: track.persistentID, value: current)
                if res == 1 { printUpdate(forTrack: track, forProperty: "Rating", previous: last, current: current) }
                return res
            }
        }
        
        return 0
    }
}
