import Foundation

class DatabaseReader {
    let db: Database
    
    public init?(dbUrl: URL) {
        if let db = Database(dbFileURL: dbUrl) { self.db = db }
        else { return nil }
    }
    
    private func GetTable(_ table: String) -> [[Any?]]? {
        return db.ExecuteQuery(sql: "SELECT * FROM \(table)")
    }
    
    private func GetThreeColumnTable(_ table: String) -> [(String, Int, Int)] {
        return GetTable(table)!.map({
            ($0[0] as! String, $0[1] as! Int, $0[2] as! Int)
        })
    }
    
    public func GetMeta() -> [[Any?]] {
        if let table = GetTable("Meta") { return table }
        else {
            print("Error: Cannot find table 'Meta'")
            return []
        }
    }
    
    public func GetPlayCounts() -> [(String, Int, Int)] {
        return GetThreeColumnTable("PlayCounts")
    }
    
    public func GetRatings() -> [(String, Int, Int)] {
        return GetThreeColumnTable("Ratings")
    }
}
