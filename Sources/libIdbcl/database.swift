import Foundation
import SQLite3

let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

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
    
    public var totalChanges: Int { return Int(sqlite3_total_changes(db)) }
    
    /// Execute SQL query to make changes to the database
    /// - parameter sql: SQL query
    /// - parameter params: Optional strings to bind to the parameter tokens in the query
    /// - returns: No of rows changed in INSERT, UPDATE, or DELETE statements
    
    @discardableResult
    public func ExecuteNonQuery(sql: String, params: [String] = []) -> Int {
        var statement: OpaquePointer?
        sqlite3_prepare_v2(db, sql, -1, &statement, nil)
        
        for (pos, param) in params.enumerated() {
            sqlite3_bind_text(statement, Int32(pos+1), param, -1, SQLITE_TRANSIENT)
        }
        
        if sqlite3_step(statement) != SQLITE_DONE {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("Failed to execute non query: \(errmsg)")
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
    
    public func ExecuteScalarQuery(sql: String, params: [String] = []) -> Any? {
        var statement: OpaquePointer?
        sqlite3_prepare_v2(db, sql, -1, &statement, nil)
        
        for (pos, param) in params.enumerated() {
            sqlite3_bind_text(statement, Int32(pos+1), param, -1, SQLITE_TRANSIENT)
        }
        
        var result: Any?

        if sqlite3_step(statement) != SQLITE_ROW {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            if errmsg != "no more rows available" {
                print("Error: Failed to execute scalar query: \(errmsg)")
            }
            result = nil
            
        } else {
            if sqlite3_column_count(statement) != 1 {
                print("Error: Scalar query provided more than one result column.")
                result = nil
                
            } else {
                switch sqlite3_column_type(statement, 0) {
                    case SQLITE_INTEGER:
                        result = Int(sqlite3_column_int64(statement, 0))
                    case SQLITE_TEXT:
                        result = String(cString: sqlite3_column_text(statement, 0)!)
                    default:
                        print("Error: Scalar query result is not INTEGER or TEXT.")
                        result = nil
                }
            }
        }
        
        if sqlite3_finalize(statement) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db))
            print("Error finalizing statement: \(errmsg)")
        }
        
        return result
    }
    

}
