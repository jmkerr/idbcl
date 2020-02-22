import Foundation
import SQLite3

let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

/// Provides methods to execute SQL-Queries
class Database {
    private var db: OpaquePointer?

    public init?(dbFileURL: URL) {

        if sqlite3_open(dbFileURL.path, &db) != SQLITE_OK {
            print("Error opening database")
            return nil
        }
        else { print("Opened Database " + dbFileURL.path) }
    }
    
    deinit {
        if sqlite3_close(db) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("Error closing Database: \(errmsg)")
        }
    }
    
    /// General SQL query
    /// - parameter sql: SQL query
    /// - parameter params: Optional strings to bind to the parameter tokens in the query
    /// - returns: nil if the table does not exist, or result table, represented by [] if empty
    
    public func executeQuery(sql: String, params: [String?] = []) -> [[Any?]]? {
        
        var statement: OpaquePointer?
        sqlite3_prepare_v2(db, sql, -1, &statement, nil)
        
        for (pos, param) in params.enumerated() {
            sqlite3_bind_text(statement, Int32(pos+1), param, -1, SQLITE_TRANSIENT)
        }
        
        var result: [[Any?]]? = []

        getRows: while sqlite3_step(statement) == SQLITE_ROW {
            
            let cols = sqlite3_column_count(statement)
            var row: [Any?] = []
            row.reserveCapacity(Int(cols))
            
            for col in 0...cols-1 {
                switch sqlite3_column_type(statement, col) {
                    case SQLITE_NULL:
                        row.append(nil)
                    case SQLITE_INTEGER:
                        row.append(Int(sqlite3_column_int64(statement, col)))
                    case SQLITE_TEXT:
                        row.append(String(cString: sqlite3_column_text(statement, col)!))
                    default:
                        print("Error: Database field type is not INTEGER or TEXT.")
                        result = nil
                        break getRows
                }
            }
            
            result?.append(row)
        }
        
        if sqlite3_finalize(statement) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db))
            print("Error finalizing statement: \(errmsg)")
        }
        
        return result
    }
    
    public var totalChanges: Int { return Int(sqlite3_total_changes(db)) }
    
    /// Execute SQL query to make changes to the database
    /// - parameter sql: SQL query
    /// - parameter params: Optional strings to bind to the parameter tokens in the query
    /// - returns: No of rows changed in INSERT, UPDATE, or DELETE statements
    
    @discardableResult
    public func executeNonQuery(sql: String, params: [String?] = []) -> Int {
        var statement: OpaquePointer?
        sqlite3_prepare_v2(db, sql, -1, &statement, nil)
        
        for (pos, param) in params.enumerated() {
            sqlite3_bind_text(statement, Int32(pos+1), param, -1, SQLITE_TRANSIENT)
        }
        
        if sqlite3_step(statement) != SQLITE_DONE {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("Error: Failed to execute non query: \(errmsg)")
        }
        
        if sqlite3_finalize(statement) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db))
            print("Error finalizing statement: \(errmsg)")
        }
        
        return Int(sqlite3_changes(db))
    }
    
    /// Execute SQL query for a single Int or String
    /// - parameter sql: SQL query
    /// - parameter params: Optional strings to bind to the parameter tokens in the query
    /// - returns: Any errors result in nil
    
    public func executeScalarQuery(sql: String, params: [String?] = []) -> Any? {
       
        guard let table = executeQuery(sql: sql, params: params) else { return nil }
        
        if table.count == 0 { return nil }
        else if table.count > 1 {
            print("Error: Scalar query provided more than one result row.")
            return nil
        }
        
        let row = table[0]
        
        if row.count == 0 { return nil }
        else if row.count > 1 {
            print("Error: Scalar query provided more than one result column.")
            return nil
        }
        
        return row[0]
    }
    

}
