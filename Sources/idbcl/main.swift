import Foundation
import libIdbcl

let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
print(dateFormatter.string(from: Date()))

if CommandLine.argc == 1 || CommandLine.arguments[1] == "update" {
    if let lib = MediaLibrary() {
        lib.UpdateDB()
    }
} else if CommandLine.arguments[1] == "emit-plist" {
    emitPlist()
}
