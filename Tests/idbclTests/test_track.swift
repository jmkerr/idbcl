import XCTest
import iTunesLibrary
import Foundation
@testable import libIdbcl

/// Tests Track
class test_Track: idbcl_test {
    func testTrack() {
        let item = MockITLibMediaItem(persistentID: 10, props: [
            "AlbumTitle" : "foo-albumtitle",
            "PersistentID" : 10,
            "BitRate" : 20,
            "Title" : "foo-title"])
        let tr = LibraryTrack(fromItem: item)
        
        XCTAssert(tr.persistentID.count == 16)
        XCTAssert(tr.persistentID == "000000000000000A")
        
        XCTAssert(tr.stringValue(forProperty: "AlbumTitle") == "foo-albumtitle")
        XCTAssert(tr.stringValue(forProperty: "Artist") == nil)
        XCTAssert(tr.stringValue(forProperty: "BitRate") == "20")
        XCTAssert(tr.stringValue(forProperty: "SampleRate") == nil)
        XCTAssertEqual("\(tr)", "Title: foo-title")
        
        XCTAssert(tr.playCount == nil)
        XCTAssert(tr.rating == nil)

    }
}
