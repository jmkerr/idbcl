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
    
    func PlayCount(date: Int = Int(Date().timeIntervalSince1970)) -> Int? {
        let bestPc = playCounts.first(where: { $0.1 < date })
        if let pc = bestPc { return pc.2 } else { return nil }
    }
    
    func Rating(date: Int = Int(Date().timeIntervalSince1970)) -> Int? {
        let bestRating = ratings.first(where: { $0.1 < date })
        if let r = bestRating { return r.2 } else { return nil }
    }
    
    func PlayTime(date: Int) -> Int {
        let totalTime = Int(group(groupName: "TotalTime")) ?? 0
        return totalTime * (PlayCount(date: date) ?? DEFAULT_PLAY_COUNT)
    }
    
    func value(forProperty: String) -> String? {
        if PROPERTY_HEADERS.contains(forProperty) {
            let index = PROPERTY_HEADERS.firstIndex(of: forProperty)! + 1
            
            if let value: Any = meta[index] { return String(describing: value) }
        }
        return nil
    }
    
    func group(groupName: String) -> String {
        let missing = "No Value"
        
        if PROPERTY_HEADERS.contains(groupName) {
            if let group = value(forProperty: groupName) { return String(describing: group) }
            else { return missing }
        }
            
        else if groupName == "ArtistAndTitle" {
            return "\(group(groupName: "Artist")) - \(group(groupName: "Title"))"
        
        } else if groupName == "Decade" {
            if let year = Int(group(groupName: "Year")) {
                return String(year/10*10)
            } else { return missing }
            
        } else if groupName == "CurrentPlayCount" {
            return String(PlayCount() ?? DEFAULT_PLAY_COUNT)
                    
        } else if groupName == "CurrentRating" {
            return String(Double(Rating() ?? DEFAULT_RATING)/20)
            
        } else if groupName == "PersistentID" {
            return id
        
        } else if groupName == "PersistentIDAndTitle" {
            return "\(group(groupName: "PersistentID")) (\(group(groupName: "Title")))"
        
        } else if groupName == "TotalMinutes" {
            if let pt = Double(group(groupName: "TotalTime")) {
                return String(Int(round(pt/1000/60)))
            } else { return missing }
            
        } else {
            print("Error: Grouping by \(groupName) not implemented.")
            return "Error"
        }
    }
}

struct PlayList {
    let name: String
    let tracks: [DatabaseTrack]
    
    var count: Int { return tracks.count }
    
    func TotalPlayCount(date: Int) -> Int {
        return tracks.reduce(0, { $0 + ($1.PlayCount(date: date) ?? DEFAULT_PLAY_COUNT)})
    }
    
    func AvgRating(date: Int) -> Double {
        return Double(tracks.reduce(0, { $0 + ($1.Rating(date: date) ?? DEFAULT_RATING)}))/20.0/Double(tracks.count)
    }
    
    func TotalPlayTime(date: Int) -> Double {
        return tracks.reduce(0.0, { $0 + Double($1.PlayTime(date: date))})/1000/60
    }
    
    func value(forProperty: String, date: Int) -> Double {
        switch forProperty {
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
    let tracks: [DatabaseTrack]
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
    
        tracks = meta.map({
            let pid = $0[0] as! String // TODO: Nil & Sanity check
            return DatabaseTrack(meta: $0,
                                 playCounts: playCountsById[pid] ?? [],
                                 ratings: ratingsById[pid] ?? [])
        })
    }
    
    public func getTrack(id: String) -> DatabaseTrack? {
        return tracks.first(where: { $0.id == id })
    }

    public func report(groupBy: String, sortBy: String, from: Int, to: Int, count: Bool = true) -> [(String, Double)] {
        
        var lists: [String : [DatabaseTrack]] = [:]
        
        for track in tracks {
            let prop = track.group(groupName: groupBy)
            lists.updateValue((lists[prop] ?? []) + [track], forKey: prop)
        }
        
        let plists: [PlayList] = lists.map({ PlayList(name: $0, tracks: $1) })
    
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
        let titles = Dictionary(uniqueKeysWithValues: tracks.map({
            ($0.group(groupName: "PersistentID"), $0.group(groupName: "Title"))
        }) )
        
        let tab = Array((playCountsLog + ratingsLog).sorted(by: { $0.0 > $1.0 }).prefix(limit))
        
        let tab2 = tab.map({ (Date(timeIntervalSince1970: Double($0.0)),
                              $0.1,
                              titles[$0.2] ?? "\($0.2): Missing Metadata",
                              $0.3) })
        
        return tab2
    }
}
