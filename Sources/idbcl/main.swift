import Foundation
import libIdbcl

if CommandLine.argc == 1 || CommandLine.arguments[1] == "update" {
    if let lib = MediaLibrary() {
        lib.UpdateDB()
    }
} else if CommandLine.arguments[1] == "create-launchagent" {
    createLaunchAgent()
}
