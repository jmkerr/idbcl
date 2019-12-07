import XCTest
import iTunesLibrary
import Foundation
@testable import libIdbcl

class idbcl_test: XCTestCase {
    
    class ITLibMediaItemMock: ITLibMediaItem {
        override var persistentID: NSNumber { return 10 }
        
        override func value(forProperty property: String) -> Any? {
            switch property {
            case ITLibMediaItemPropertyAlbumTitle:
                return "foo-albumtitle"
            case ITLibMediaItemPropertyTitle:
                return "foo-title"
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
        let item = ITLibMediaItemMock()
        let tr = Track(fromItem: item)
        
        XCTAssert(tr.persistentID.count == 16)
        XCTAssert(tr.persistentID == "000000000000000A")
        XCTAssert(tr.value(forProperty: "AlbumTitle") == "foo-albumtitle")
        XCTAssert(tr.value(forProperty: "Artist") == "")
        XCTAssert(tr.value(forProperty: "BitRate") == "20")
        XCTAssert(tr.playCount == DEFAULT_PLAY_COUNT)
        XCTAssert(tr.rating == DEFAULT_RATING)
        XCTAssert("\(tr)" == "foo-title")
    }
}
 
