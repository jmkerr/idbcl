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
    public func updateMeta(forTrack: Track) -> Int {
        var rowsChanged = 0
        
        if let dbTrack = reporter.getTrack(id: forTrack.persistentID) {
            for property in PROPERTY_HEADERS {
                let oldValue: String? = dbTrack.value(forProperty: property)
                let currentValue: String? = forTrack.value(forProperty: property)

                if oldValue != currentValue {
                    rowsChanged += dbTables.setMeta(id: forTrack.persistentID, property: property, value: currentValue)
                    
                    print("Title: \(forTrack) - Updated \(property): \(oldValue ?? "NULL")"
                          + " -> \(currentValue ?? "NULL")")
                }
            }
        } else {
            let props: [String?] = PROPERTY_HEADERS.map { forTrack.value(forProperty: $0) }
            rowsChanged = dbTables.setMeta(values: [forTrack.persistentID] + props)
            print("Title: \(forTrack) - Created Metadata")
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
    public func updatePlayCounts(forTrack: Track) -> Int {
        if let dbTrack = reporter.getTrack(id: forTrack.persistentID) {
            let last: Int? = dbTrack.PlayCount()
            let current = forTrack.playCount
            
            if last != current {
                let res: Int = dbTables.setPlayCount(id: forTrack.persistentID, value: current)
                if res == 1 { printUpdate(forTrack: forTrack, forProperty: "PlayCount", previous: last, current: current) }
                return res
            }
        }
        
        return 0
    }
    
    @discardableResult
    public func updateRatings(forTrack: Track) -> Int {
        if let dbTrack = reporter.getTrack(id: forTrack.persistentID) {
            let last: Int? = dbTrack.Rating()
            let current = forTrack.rating
            
            if last != current {
                let res: Int = dbTables.setRating(id: forTrack.persistentID, value: current)
                if res == 1 { printUpdate(forTrack: forTrack, forProperty: "Rating", previous: last, current: current) }
                return res
            }
        }
        
        return 0
    }
}
