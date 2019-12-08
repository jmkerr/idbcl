import XCTest
import iTunesLibrary
import Foundation
@testable import libIdbcl

class idbcl_test: XCTestCase {
    
    class ITLibMediaItemMock: ITLibMediaItem {
        var mockid: NSNumber = 0
        var props: [String : Any] = [:]
        
        convenience init(persistentID: NSNumber = 0, props: [String : Any] = [:]) {
            self.init()
            self.props = props
            self.mockid = persistentID
        }
        
        override var persistentID: NSNumber { return mockid }
        
        override func value(forProperty: String) -> Any? { return props[forProperty] }
        
    }
       
    var testDbURL: URL = URL(string: NSTemporaryDirectory())!.appendingPathComponent("idbcl-test.sqlite3")
    
    override func setUp() {
        XCTAssert(!FileManager.default.fileExists(atPath: testDbURL.path))
    }

    override func tearDown() {
        try? FileManager.default.removeItem(atPath: testDbURL.path)
    }
       
    func testConstants() {
        XCTAssert(ITLibMediaEntityPropertyPersistentID == "PersistentID")
        XCTAssert(ITLibMediaItemPropertyAlbumTitle == "AlbumTitle")
        XCTAssert(ITLibMediaItemPropertyArtistName == "Artist")
        XCTAssert(ITLibMediaItemPropertyBitRate == "BitRate")
        XCTAssert(ITLibMediaItemPropertyFileSize == "FileSize")
        XCTAssert(ITLibMediaItemPropertyGenre == "Genre")
        XCTAssert(ITLibMediaItemPropertyKind == "Kind")
        XCTAssert(ITLibMediaItemPropertySampleRate == "SampleRate")
        XCTAssert(ITLibMediaItemPropertyTitle == "Title")
        XCTAssert(ITLibMediaItemPropertyTotalTime == "TotalTime")
        XCTAssert(ITLibMediaItemPropertyYear == "Year")
    }
    
    func testTrack() {
        let item = ITLibMediaItemMock(persistentID: 10, props: [
            "AlbumTitle" : "foo-albumtitle",
            "PersistentID" : 10,
            "BitRate" : 20,
            "Title" : "foo-title"])
        let tr = Track(fromItem: item)
        
        XCTAssert(tr.persistentID.count == 16)
        XCTAssert(tr.persistentID == "000000000000000A")
        
        XCTAssert(tr.value(forProperty: "AlbumTitle") == "foo-albumtitle")
        XCTAssert(tr.value(forProperty: "Artist") == "")
        XCTAssert(tr.value(forProperty: "BitRate") == "20")
        XCTAssert(tr.value(forProperty: "SampleRate") == "")
        XCTAssert("\(tr)" == "foo-title")
        
        XCTAssert(tr.playCount == DEFAULT_PLAY_COUNT)
        XCTAssert(tr.rating == DEFAULT_RATING)

    }
    
    func testDatabaseUpdate() {
        let tr = Track(fromItem: ITLibMediaItemMock(props: ["PlayCount" : 0]))
        let db = DatabaseUpdater(dbFileURL: testDbURL)
        
        XCTAssert(db?.UpdateMeta(forTrack: tr) == 1)
        XCTAssert(db?.UpdateMeta(forTrack: tr) == 0)
        
        XCTAssert(db?.UpdateRatings(forTrack: tr) == 1)
        XCTAssert(db?.UpdateRatings(forTrack: tr) == 0)
        
        XCTAssert(db?.UpdatePlayCounts(forTrack: tr) == 1)
        XCTAssert(db?.UpdatePlayCounts(forTrack: tr) == 0)
        
        sleep(1) // Currently requires entries to have different timestamps
        
        let tr_2 = Track(fromItem: ITLibMediaItemMock(props: ["PlayCount" : 1]))
        
        XCTAssert(db?.UpdatePlayCounts(forTrack: tr_2) == 1)
        XCTAssert(db?.UpdatePlayCounts(forTrack: tr_2) == 0)
        
        
        let tr_3 = Track(fromItem: ITLibMediaItemMock(props: ["Rating" : 20]))
        
        XCTAssert(db?.UpdateRatings(forTrack: tr_3) == 1)
        XCTAssert(db?.UpdateRatings(forTrack: tr_3) == 0)
    }
    
    
}
 
