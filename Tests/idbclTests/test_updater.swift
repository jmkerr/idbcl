import XCTest
import iTunesLibrary
import Foundation
@testable import libIdbcl

/// Tests Updater, Reporter
class test_Updater: idbcl_test {
    
    func testUpdater() {
        let dbFile = temporaryFile()
        
        let mediaItem =  MockITLibMediaItem()
        let tr = LibraryTrack(fromItem: mediaItem)
        
        if let db = Updater(dbFileURL: dbFile) {
            XCTAssertEqual(db.updatePlayCounts(forTrack: tr), 0)
            XCTAssertEqual(db.updateRatings(forTrack: tr), 0)
        }
        
        
        if let db = Updater(dbFileURL: dbFile) {
            XCTAssertEqual(db.updateMeta(forTrack: tr), 1)
            XCTAssertEqual(db.updateRatings(forTrack: tr), 1)       // 1. log entry
            XCTAssertEqual(db.updatePlayCounts(forTrack: tr), 1)    // 2.
        }
        
        if let db = Updater(dbFileURL: dbFile) {
            XCTAssertEqual(db.updateMeta(forTrack: tr), 0)
            XCTAssertEqual(db.updateRatings(forTrack: tr), 0)
            XCTAssertEqual(db.updatePlayCounts(forTrack: tr), 0)
        }
        
        
        // change play count and rating
        mediaItem.props.updateValue(7, forKey: ITLibMediaItemPropertyPlayCount)
        mediaItem.props.updateValue(20, forKey: ITLibMediaItemPropertyRating)
        
        if let db = Updater(dbFileURL: dbFile) {
            XCTAssertEqual(db.updateMeta(forTrack: tr), 0)
            XCTAssertEqual(db.updatePlayCounts(forTrack: tr), 1)    // 3.
            XCTAssertEqual(db.updateRatings(forTrack: tr), 1)       // 4.
        }
        
        
        // change 'meta' data
        mediaItem.props.updateValue(8000, forKey: ITLibMediaItemPropertyYear)
        mediaItem.props.updateValue(9000, forKey: ITLibMediaItemPropertySampleRate)
        
        if let db = Updater(dbFileURL: dbFile) {
            XCTAssertEqual(db.updateMeta(forTrack: tr), 2)
            XCTAssertEqual(db.updateRatings(forTrack: tr), 0)
            XCTAssertEqual(db.updatePlayCounts(forTrack: tr), 0)
        }
        
        // Output of Reporter.log()
        if let reporter = Reporter(dbUrl: dbFile) {
            let log: [(Date, String, String, Int)] = reporter.log(limit: 10)
            
            XCTAssertEqual(log[0].3, 20)
            XCTAssertEqual(log[1].3, 7)
            XCTAssertEqual(log[2].3, 0)
            XCTAssertEqual(log[3].3, 50)
            
            XCTAssertEqual(log.count, 4)
        } else {
            XCTFail()
        }
    }
    
    func testInitialization() {
        let tmpFile = temporaryFile()
        let libCount = 11
        let lib: [ITLibMediaItem] = Array(0 ..< libCount).map { let _ = $0; return RandomITLibMediaItem() }
    
        var rows = 0
        if let upd = Updater(dbFileURL: tmpFile) {
            for item in lib {
                let tr = LibraryTrack(fromItem: item)
                rows += upd.updateMeta(forTrack: tr)
                rows += upd.updatePlayCounts(forTrack: tr)
                rows += upd.updateRatings(forTrack: tr)
            }
        }
        
        XCTAssertEqual(rows, 3 * libCount)
        
        if let upd = Updater(dbFileURL: tmpFile) {
            for item in lib {
                let tr = LibraryTrack(fromItem: item)
                rows += upd.updateMeta(forTrack: tr)
                rows += upd.updatePlayCounts(forTrack: tr)
                rows += upd.updateRatings(forTrack: tr)
            }
        }
        
        XCTAssertEqual(rows, 3 * libCount)
        
        
        if let reporter = Reporter(dbUrl: tmpFile) {
            let log = reporter.log(limit: 100)
            XCTAssertEqual(log.count, 2 * libCount)
            
        } else {
            XCTFail()
        }
    }
    
    /*
    func testPerformance_Initialization() {
        measure {
            let tmpFile = temporaryFile()
            let lib: [ITLibMediaItem] = Array(0 ..< 100).map { let _ = $0; return RandomITLibMediaItem() }
        
            if let upd = Updater(dbFileURL: tmpFile) {
                for item in lib {
                    let tr = LibraryTrack(fromItem: item)
                    upd.updateMeta(forTrack: tr)
                    upd.updatePlayCounts(forTrack: tr)
                    upd.updateRatings(forTrack: tr)
                }
            }
        }
    }
        
    func testPerformance_Update() {
        let tmpFile = temporaryFile()
        let lib: [ITLibMediaItem] = Array(0 ..< 1000).map { let _ = $0; return RandomITLibMediaItem() }
        
        if let upd = Updater(dbFileURL: tmpFile) {
            for item in lib {
                let tr = LibraryTrack(fromItem: item)
                upd.updateMeta(forTrack: tr)
                upd.updatePlayCounts(forTrack: tr)
                upd.updateRatings(forTrack: tr)
            }
        }
        
        measure {
            if let upd = Updater(dbFileURL: tmpFile) {
                for item in lib {
                    let tr = LibraryTrack(fromItem: item)
                    upd.updateMeta(forTrack: tr)
                    upd.updatePlayCounts(forTrack: tr)
                    upd.updateRatings(forTrack: tr)
                }
            }
        }
    }
     */
}
