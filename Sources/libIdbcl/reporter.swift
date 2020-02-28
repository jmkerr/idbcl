import Foundation

func group(track: DatabaseTrack, groups: [String]) -> String {
    return groups.reduce("", { ($0.count == 0 ? "" : "\($0) - ") + group(track: track, groupName: $1) })
}
    
func group(track: DatabaseTrack, groupName: String) -> String {
    let missing = "No Value"
    
    if DatabaseTrack.metadataLayout.contains(groupName) {
        if let group = track.stringValue(forProperty: groupName) { return group }
        return missing
    }
    
    switch groupName {
    case "Decade":
        if let year = track.value(forProperty: "Year") as? Int { return String(year / 10 * 10) }
        
    case "PlayCount":
        if let pc = track.playCount { return pc.description }
                
    case "Rating":
        if let rating = track.rating { return String(Double(rating) / 20) }
        
    case "PersistentID":
        return track.persistentID
    
    case "TotalMinutes":
        if let tt = track.value(forProperty: "TotalTime") as? Int {
            return String(Int(round(Double(tt) / 1000 / 60)))
        }
    
    default:
        print("Error: Grouping by \(groupName) not implemented.")
    }
    
    return missing
}

struct PlayList {
    let name: String
    let tracks: [DatabaseTrack]
    
    var count: Int { return tracks.count }
    
    func totalPlayCount(date: Int) -> Int {
        return tracks.reduce(0, { $0 + ($1.playCount(date: date) ?? DEFAULT_PLAY_COUNT)})
    }
    
    func avgRating(date: Int) -> Double {
        return Double(tracks.reduce(0, { $0 + ($1.rating(date: date) ?? DEFAULT_RATING)}))
            / 20.0 / Double(tracks.count)
    }
    
    func totalPlayTime(date: Int) -> Double {
        return tracks.reduce(0.0, {
            if let playCount = $1.playCount(date: date),
                let totalTime = $1.value(forProperty: "TotalTime") as? Int {
                return $0 + Double(playCount) * Double(totalTime)
            } else {
                return 0
            }
        }) / 1000 / 60
    }
    
    func value(forProperty property: String, date: Int) -> Double {
        switch property {
        case "PlayCount":
            return Double(totalPlayCount(date: date))
        case "Rating":
            return avgRating(date: date)
        case "PlayTime":
            return Double(totalPlayTime(date: date))
        default:
            print("Error")
            return 0.0
        }
    }
}

public class Reporter {
    let tracks: [String : DatabaseTrack]
    let playCounts: [(String, Int, Int)]
    let ratings: [(String, Int, Int)]
    
    public convenience init?(dbUrl: URL) {
        guard let db = DbTables(dbUrl: dbUrl, access: .dryrun)
        else { return nil }
        
        self.init(db: db)
    }
    
    init(db: DbTables) {
        let meta = db.getMeta()
        playCounts = db.getPlayCounts()
        ratings = db.getRatings()
        
        let playCountsById = Dictionary(grouping: playCounts, by: { $0.0 })
        let ratingsById = Dictionary(grouping: ratings, by: { $0.0 })
          
        tracks = Dictionary(uniqueKeysWithValues: meta.map {
            let pid = $0[0] as! String
            return (pid, DatabaseTrack(meta: $0,
                                       playCounts: playCountsById[pid] ?? [],
                                       ratings: ratingsById[pid] ?? []))
        })
    }

    public func report(groupBy: [String], sortBy: String, from: Int, to: Int, count: Bool = true) -> [(String, Double)] {
        
        let groupedTracks = Dictionary(grouping: tracks.values, by: { group(track: $0, groups: groupBy) })
        let plists: [PlayList] = groupedTracks.map({ PlayList(name: $0, tracks: $1) })
    
        var top: [(String, Double)] = plists.map {
            ($0.name + (count ? " (\($0.count))" : ""),
             $0.value(forProperty: sortBy, date: to) - $0.value(forProperty: sortBy, date: from))
        }
        
        top.sort(by: { $0.1 > $1.1 })
        
        return top
    }
      
    public func log(limit: Int) -> [(Date, String, String, Int)] {
        let playCountsLog = playCounts.map({ ($0.1, "PlayCount", $0.0, $0.2) })
        let ratingsLog = ratings.map({ ($0.1, "Rating", $0.0, $0.2) })
        let tab = Array((playCountsLog + ratingsLog).sorted(by: { $0.0 > $1.0 }).prefix(limit))
        
        return tab.map {
            (Date(timeIntervalSince1970: Double($0.0)),
             $0.1,
             tracks[$0.2]?.value(forProperty: "Title") as? String ?? "Missing Metadata",
             $0.3)
        }
    }
}
