import XCTest
import iTunesLibrary
import Foundation

class idbcl_test: XCTestCase {
    
    class ITLibMediaItemMock: ITLibMediaItem {
        override var persistentID: NSNumber { return 10 }
        
        override func value(forProperty property: String) -> Any? {
            switch property {
            case ITLibMediaItemPropertyAlbumTitle:
                return "foo"
            case ITLibMediaItemPropertyBitRate:
                return 20
            default:
                return nil
            }
        }
    }
    
    let testDbURL: URL = URL(string: NSTemporaryDirectory())!.appendingPathComponent("idbcl-test.sqlite3")
    
    override func setUp() {
        XCTAssert(!FileManager.default.fileExists(atPath: testDbURL.path))
    }

    override func tearDown() {
        try? FileManager.default.removeItem(atPath: testDbURL.path)
    }
    
    func testTrack() {
        let item = ITLibMediaItemMock()
        let tr = Track(fromItem: item)
        
        XCTAssert(tr.persistentID.count == 16)
        XCTAssert(tr.staticProperties.count == STATIC_PROPERTIES.count)
        XCTAssert(tr.persistentID == "000000000000000A")
        XCTAssert(tr.staticProperties[0] == "foo")
        XCTAssert(tr.staticProperties[1] == "")
        XCTAssert(tr.staticProperties[2] == "20")
        XCTAssert(tr.playCount == DEFAULT_PLAY_COUNT)
        XCTAssert(tr.rating == DEFAULT_RATING)
    }
}
