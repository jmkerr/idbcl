import XCTest
import iTunesLibrary
import Foundation
@testable import libIdbcl

/// Test base class
class idbcl_test: XCTestCase {
    
    class MockITLibMediaItem: ITLibMediaItem {
        public var mockid: NSNumber = 0
        public var props: [String : Any?] = [:]
        
        init(persistentID: NSNumber = 0, props: [String : Any] = [:]) {
            self.props = props
            self.mockid = persistentID
        }
        
        override var persistentID: NSNumber { return mockid }
        
        override func value(forProperty property: String) -> Any? {
            if props.contains(where: { $0.key == property }) {
              return props[property]!
            } else {
                return nil
            }
        }
    }
    
    class RandomITLibMediaItem: MockITLibMediaItem {
        
        let stringValuedProperties = [
            ITLibMediaEntityPropertyPersistentID,
            ITLibMediaItemPropertyAlbumTitle,
            ITLibMediaItemPropertyArtistName,
            ITLibMediaItemPropertyGenre,
            ITLibMediaItemPropertyKind,
            ITLibMediaItemPropertyTitle
        ]
        
        init() {
            let randomNumber = Int.random(in: 0 ..< LONG_MAX)
            super.init(persistentID: randomNumber as NSNumber, props: [:])
        }
    
        
        override func value(forProperty property: String) -> Any? {
            if let val: Any? = props[property] {
              return val
                
            } else {
                let random = UUID()
                
                if random.uuidString.starts(with: "0") {
                    props.updateValue(nil, forKey: property)
                    
                } else if stringValuedProperties.contains(property) {
                    props.updateValue(random.uuidString, forKey: property)
                    
                } else {
                    props.updateValue(random.hashValue, forKey: property)
                }
                
                return value(forProperty: property)
            }
        }
    }

    func temporaryFile() -> URL {
        let dir = NSTemporaryDirectory()
        let filename = UUID().uuidString
        let fileURL = URL(fileURLWithPath: dir).appendingPathComponent(filename)
        
        addTeardownBlock {
            do {
                let fm = FileManager.default
                if fm.fileExists(atPath: fileURL.path) {
                    try fm.removeItem(at: fileURL)
                    XCTAssertFalse(fm.fileExists(atPath: fileURL.path))
                }
            } catch {
                XCTFail("Error deleting temporary file \(error)")
            }
        }
            
        return fileURL
    }

    override func setUp() { libIdbcl.MOCK_DATE = true }
    override func tearDown() {}
}
