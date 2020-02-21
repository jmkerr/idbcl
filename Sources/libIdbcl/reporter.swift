import Foundation

public struct DatabaseTrack {
    let meta: [Any?]
    let playCounts: [(String, Int, Int)]
    let ratings: [(String, Int, Int)]
    
    var id: String { String(describing: meta[0]!) }
    
    init(meta: [Any?], playCounts: [(String, Int, Int)], ratings: [(String, Int, Int)]) {
        self.playCounts = playCounts.sorted(by: { $0.1 > $1.1 })
        self.ratings = ratings.sorted(by: { $0.1 > $1.1 })
        self.meta = meta
    }
    
    func playCount(date: Int = Int(Date().timeIntervalSince1970)) -> Int? {
        let bestPc = playCounts.first(where: { $0.1 < date })
        if let pc = bestPc { return pc.2 } else { return nil }
    }
    
    func rating(date: Int = Int(Date().timeIntervalSince1970)) -> Int? {
        let bestRating = ratings.first(where: { $0.1 < date })
        if let r = bestRating { return r.2 } else { return nil }
    }
    
    func playTime(date: Int) -> Int {
        if let totalTime = value(forProperty: "TotalTime") {
            return (Int(totalTime) ?? 0) * (playCount(date: date) ?? DEFAULT_PLAY_COUNT)
        } else { return 0 }
    }
    
    func value(forProperty property: String) -> String? {
        if let index = PROPERTY_HEADERS.firstIndex(of: property) {
            if let value: Any = meta[index + 1] {
                return String(describing: value)
            }
        }
        return nil
    }
}

func group(track: DatabaseTrack, groups: [String]) -> String {
    return groups.reduce("", { ($0.count == 0 ? "" : "\($0) - ") + group(track: track, groupName: $1) })
}
    
func group(track: DatabaseTrack, groupName: String) -> String {
    let missing = "No Value"
    
    if PROPERTY_HEADERS.contains(groupName) {
        if let group = track.value(forProperty: groupName) { return String(describing: group) }
        return missing
    }
    else if groupName == "Decade" {
        if let year = track.value(forProperty: "Year") {
            if let nyear = Int(year) { return String(nyear / 10 * 10) }
        }
        return missing
        
    } else if groupName == "PlayCount" {
        if let pc = track.playCount() { return String(pc) }
        return missing
                
    } else if groupName == "Rating" {
        if let rating = track.rating() { return String(Double(rating)/20) }
        return missing
        
    } else if groupName == "PersistentID" {
        return track.id
    
    } else if groupName == "TotalMinutes" {
        if let tt = track.value(forProperty: "TotalTime") {
            if let ntt = Double(tt) {
                return String(Int(round(ntt / 1000 / 60)))
            }
        }
        return missing
        
    } else {
        print("Error: Grouping by \(groupName) not implemented.")
        return missing
    }
}

struct PlayList {
    let name: String
    let tracks: [DatabaseTrack]
    
    var count: Int { return tracks.count }
    
    func TotalPlayCount(date: Int) -> Int {
        return tracks.reduce(0, { $0 + ($1.playCount(date: date) ?? DEFAULT_PLAY_COUNT)})
    }
    
    func AvgRating(date: Int) -> Double {
        return Double(tracks.reduce(0, { $0 + ($1.rating(date: date) ?? DEFAULT_RATING)}))/20.0/Double(tracks.count)
    }
    
    func TotalPlayTime(date: Int) -> Double {
        return tracks.reduce(0.0, { $0 + Double($1.playTime(date: date))})/1000/60
    }
    
    func value(forProperty property: String, date: Int) -> Double {
        switch property {
        case "PlayCount":
            return Double(TotalPlayCount(date: date))
        case "Rating":
            return AvgRating(date: date)
        case "PlayTime":
            return Double(TotalPlayTime(date: date))
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
        guard let db = DbTables(dbUrl: dbUrl)
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
    
    public func getTrack(id: String) -> DatabaseTrack? {
        return tracks[id]
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
        let titles = Dictionary(uniqueKeysWithValues: tracks.values.map({
            (group(track: $0, groupName: "PersistentID"), group(track: $0, groupName: "Title"))
        }) )
        
        let tab = Array((playCountsLog + ratingsLog).sorted(by: { $0.0 > $1.0 }).prefix(limit))
        
        let tab2 = tab.map({ (Date(timeIntervalSince1970: Double($0.0)),
                              $0.1,
                              titles[$0.2] ?? "\($0.2): Missing Metadata",
                              $0.3) })
        
        return tab2
    }
}
