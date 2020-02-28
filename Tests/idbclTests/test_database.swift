import XCTest
import iTunesLibrary
import Foundation
@testable import libIdbcl

import XCTest
import iTunesLibrary
import Foundation
@testable import libIdbcl

class test_Database: idbcl_test {
       
    /// Test basic CRUD operations
    
    func testDatabase() {
        let dbFile = temporaryFile()
        let db = Database(dbFileURL: dbFile)!
        var last: Any?
        
        db.executeNonQuery(sql: "CREATE TABLE foo (a INTEGER, b INTEGER, c INTEGER, d TEXT, e TEXT, f TEXT)")
        
        last = db.executeNonQuery(sql: "INSERT INTO foo VALUES (?, ?, ?, ?, ?, ?)",
                                  params: ["11", "twelve", nil, "fourteen", "", nil])
        XCTAssertEqual(last as? Int, 1)
        last = nil
        
        last = db.executeNonQuery(sql: "INSERT INTO foo VALUES (?, ?, ?, ?, ?, ?)",
                                  params: ["21", "22", nil, "twenty-four", "twenty-five", nil])
        XCTAssertEqual(last as? Int, 1)
        last = nil
        
        // General Query
        let lastArr = db.executeQuery(sql: "SELECT * FROM foo")
        XCTAssert(lastArr![0][0] as? Int == 11)
        XCTAssert(lastArr![0][1] as? Int == nil)
        XCTAssert(lastArr![0][1] as? String == "twelve")
        XCTAssert(lastArr![0][2] as? Int == nil)
        XCTAssert(lastArr![0][3] as? String == "fourteen")
        XCTAssert(lastArr![0][4] as? String == "")
        XCTAssert(lastArr![0][5] as? String == nil)
        
        
        // Scalar Query
        last = db.executeScalarQuery(sql: "SELECT * FROM foo")
        XCTAssert(last == nil)
        
        last = db.executeScalarQuery(sql: "SELECT * FROM foo WHERE a LIKE '2%'")
        XCTAssert(last == nil)
    
        last = db.executeScalarQuery(sql: "SELECT a FROM foo WHERE a LIKE '2%'")
        XCTAssert(last as? Int == 21)
        
        last = db.executeScalarQuery(sql: "SELECT d FROM foo WHERE a LIKE '2%'")
        XCTAssert(last as? String == "twenty-four")
    
        last = db.executeScalarQuery(sql: "SELECT d FROM foo WHERE a LIKE '3%'")
        XCTAssert(last as? String == nil)
        
        
        // Update
        last = db.executeNonQuery(sql: "UPDATE foo SET c=? WHERE a = ?", params: ["24", "21"])
        XCTAssertEqual(last as? Int, 1)
        
        last = db.executeScalarQuery(sql: "SELECT c FROM foo WHERE a = ?", params: ["21"])
        XCTAssertEqual(last as? Int, 24)
        
        last = db.executeNonQuery(sql: "UPDATE foo SET c=? WHERE a LIKE '%1'", params: ["", "21"])
        XCTAssertEqual(last as? Int, 2)
        
        
        // Empty Table
        db.executeNonQuery(sql: "CREATE TABLE bar (a INTEGER, b TEXT)")
        
        let foo2 = db.executeQuery(sql: "SELECT * FROM bar")
        XCTAssertNotNil(foo2)
        XCTAssertEqual(foo2!.count, 0)
        
        
        // test PRAGMA user_version
        if let version = db.executeScalarQuery(sql: "PRAGMA user_version") as? Int {
            XCTAssertEqual(version, 0)
        } else { XCTFail() }
        
        db.executeNonQuery(sql: "PRAGMA user_version=7")
        
        if let version = db.executeScalarQuery(sql: "PRAGMA user_version") as? Int {
            XCTAssertEqual(version, 7)
        } else { XCTFail() }
    }
    
    
    /// Database.exec
    
    func testExec() {
        let dbFile = temporaryFile()
        if let db = Database(dbFileURL: dbFile) {
            XCTAssertNoThrow(try db.exec("PRAGMA version_user"))
            
            XCTAssertThrowsError(try db.exec("PRAMGA user_version"))
            
            XCTAssertThrowsError(try db.exec("CREATE TABLE foo ("))
        }
    }
    
}
 
