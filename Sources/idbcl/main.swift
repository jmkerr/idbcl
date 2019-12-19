import Foundation
import libIdbcl
import SwiftCLI

class UpdateCmd: Command {
    
    let name = "update"
    let shortDescription = "Creates and updates the database"
    
    func execute() throws {
        if let lib = MediaLibrary() {
            lib.UpdateDB()
        }
    }
}

class InstallCmd: Command {
    
    let name = "create-launchagent"
    let shortDescription = "Creates a launchd agent property list"
    
    func execute() throws {
        createLaunchAgent()
    }
}

let cli = CLI(name: "idbcl")
cli.commands = [UpdateCmd(), InstallCmd()]
cli.goAndExit()
