import Foundation

struct DatabaseTrack {
    let meta: [Any?]
    let playCounts: [(String, Int, Int)]
    let ratings: [(String, Int, Int)]
    
    init(meta: [Any?], playCounts: [(String, Int, Int)], ratings: [(String, Int, Int)]) {
        self.playCounts = playCounts.sorted(by: { $0.1 > $1.1 })
        self.ratings = ratings.sorted(by: { $0.1 > $1.1 })
        self.meta = meta
    }
    
    func PlayCount(date: Int = Int(Date().timeIntervalSince1970)) -> Int {
        let bestPc = playCounts.first(where: { $0.1 < date })
        if let pc = bestPc { return pc.2 } else { return DEFAULT_PLAY_COUNT }
    }
    
    func Rating(date: Int = Int(Date().timeIntervalSince1970)) -> Int {
        let bestRating = ratings.first(where: { $0.1 < date })
        if let r = bestRating { return r.2 } else { return DEFAULT_RATING }
    }
    
    func PlayTime(date: Int) -> Int {
        let totalTime = Int(value(forProperty: "TotalTime")) ?? 0
        return totalTime * PlayCount(date: date)
    }
    
    func value(forProperty: String) -> String {
        
        if PROPERTY_HEADERS.contains(forProperty) {
            let index = PROPERTY_HEADERS.firstIndex(of: forProperty)! + 1
            return String(describing: meta[index] ?? "No Value")
            
        } else if forProperty == "PersistentID" {
            return String(describing: meta[0]!)
        
        } else if forProperty == "PersistentIDAndTitle" {
            return "\(value(forProperty: "PersistentID")) (\(value(forProperty: "Title")))"
            
        } else if forProperty == "CurrentRating" {
            return String(Double(Rating())/20)
            
        } else if forProperty == "CurrentPlayCount" {
            return String(PlayCount())
                        
        } else if forProperty == "Decade" {
            if let year = Int(value(forProperty: "Year")) {
                return String(year/10*10)
            } else { return "No Value" }
        
        } else if forProperty == "TotalMinutes" {
            if let pt = Double(value(forProperty: "TotalTime")) {
                return String(Int(round(pt/1000/60)))
            } else { return "No Value" }
            
        } else {
            print("Error: DatabaseTrack.value() for this property not implemented.")
            return ""
        }
    }
}

struct PlayList {
    let name: String
    let tracks: [DatabaseTrack]
    
    func TotalPlayCount(date: Int) -> Int {
        return tracks.reduce(0, { $0 + $1.PlayCount(date: date) })
    }
    
    func AvgRating(date: Int) -> Double {
        return Double(tracks.reduce(0, { $0 + $1.Rating(date: date)}))/20.0/Double(tracks.count)
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
    private let db: DatabaseReader
    let tracks: [DatabaseTrack]
    
    public init?(dbUrl: URL) {
        if let db = DatabaseReader(dbUrl: dbUrl) { self.db = db }
        else { return nil }
        
        let meta = self.db.GetMeta()
        let playCounts = Dictionary(grouping: self.db.GetPlayCounts(), by: { $0.0 })
        let ratings = Dictionary(grouping: self.db.GetRatings(), by: { $0.0 })
    
        tracks = meta.map({
            let pid = $0[0] as! String // TODO: Nil & Sanity check
            return DatabaseTrack(meta: $0,
                                 playCounts: playCounts[pid] ?? [],
                                 ratings: ratings[pid] ?? [])
        })
    }
    
    public func report(groupBy: String, sortBy: String, from: Int, to: Int) -> [(String, Double)] {
        
        var lists: [String : [DatabaseTrack]] = [:]
        
        for track in tracks {
            let prop = track.value(forProperty: groupBy)
            lists.updateValue((lists[prop] ?? []) + [track], forKey: prop)
        }
        
        let plists: [PlayList] = lists.map({ PlayList(name: $0, tracks: $1) })
    
        var top: [(String, Double)] = plists.map {
            ($0.name, $0.value(forProperty: sortBy, date: to) - $0.value(forProperty: sortBy, date: from))
        }
        
        top.sort(by: { $0.1 > $1.1 })
        
        return top
    }
      
    public func log(limit: Int) -> [(Date, String, String, Int)] {
        let playCounts = db.GetPlayCounts().map({ ($0.1, "PlayCount", $0.0, $0.2) })
        let ratings = db.GetRatings().map({ ($0.1, "Rating", $0.0, $0.2) })
        let titles = Dictionary(uniqueKeysWithValues: tracks.map({
            ($0.value(forProperty: "PersistentID"), $0.value(forProperty: "Title"))
        }) )
        
        let tab = Array((playCounts + ratings).sorted(by: { $0.0 > $1.0 }).prefix(limit))
        
        let tab2 = tab.map({ (Date(timeIntervalSince1970: Double($0.0)),
                              $0.1,
                              titles[$0.2] ?? "\($0.2): Missing Metadata",
                              $0.3) })
        
        return tab2
    }
}
