import Foundation

let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
print(dateFormatter.string(from: Date()))

if let lib = MediaLibrary() {
    lib.UpdateDB()
}
