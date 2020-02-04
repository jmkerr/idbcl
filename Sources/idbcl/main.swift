import Foundation
import libIdbcl
import SwiftCLI

class UpdateCmd: Command {
    
    let name = "update"
    let shortDescription = "Creates and updates the database"
    
    func execute() throws {
        if let lib = MediaLibrary(dbUrl: Configuration.dbFilePath!) {
            lib.UpdateDB()
        }
    }
}

class InstallCmd: Command {
    
    let name = "create-launchagent"
    let shortDescription = "Creates a launchd agent property list"
    
    func execute() throws { createLaunchAgent() }
}

class LogCmd: Command {
    
    let name = "log"
    let shortDescription: String = "Show changes to the database"
    
    @Key("-l", "--limit", description: "Limit the number of entries show (default: 10)")
    var candidatelimit: Int?
    let defaultLimit = 10
    
    func execute() throws {
        let limit = candidatelimit ?? defaultLimit
        
        if let stat = Reporter(dbUrl: Configuration.dbFilePath!) {
            let log = stat.log(limit: limit)
            
            let df = DateFormatter()
            df.dateStyle = .short
            df.timeStyle = .short
            df.locale = .current
            df.doesRelativeDateFormatting = true
            
            for (date, type, title, value) in log {
                print(df.string(from: date),
                      type.padding(toLength: 9, withPad: " ", startingAt: 0),
                      title.padding(toLength: 24, withPad: " ", startingAt: 0),
                      String(format: "%6d", value))
            }
        }
    }
}

class ReportCmd: Command {
    
    let name = "report"
    let shortDescription = "List song groups sorted by property delta."
    
    @Key("-t", "--timeframe", description: "Time frame in days (default: 30.0)")
    var timeframe: Double?
    let defaultTimeframe = 30.0
    
    @Key("-g", "--group-by", description: "Group tracks by common property, like 'AlbumTitle' (default: 'ArtistAndTitle'). 'Help' for options.")
    var candidateGroupingProperty: String?
    let defaultGroupingProperty = "ArtistAndTitle"
    
    @Key("-s", "--sort-by", description: "Sort groups by property (default: 'PlayCount')")
    var candidateSortingProperty: String?
    let defaultSortingProperty = "PlayCount"
    
    @Key("-l", "--limit", description: "Limit the number of entries displayed (default: 10)")
    var limit: Int?
    let defaultLimit = 10
    
    @Flag("-c", "--count", description: "Show the number of IDs in each group.")
    var count: Bool
    
    @Flag("-r", "--reverse", description: "Reverse list")
    var reverse: Bool
    
    func execute() throws {
        // Verify input
        let groupingProperty = candidateGroupingProperty ?? defaultGroupingProperty
        
        let groupingOptions = PROPERTY_HEADERS + ["ArtistAndTitle", "Decade", "CurrentPlayCount", "CurrentRating", "PersistentID", "PersistentIDAndTitle",  "TotalMinutes"]
        if !groupingOptions.contains(groupingProperty) {
            print("Error: Invalid grouping property. Expect one of \(groupingOptions)")
            return
        }
        
        let sortingProperty = candidateSortingProperty ?? defaultSortingProperty
        let sortingOptions = ["PlayCount", "Rating", "PlayTime"]
        if !sortingOptions.contains(sortingProperty) {
            print("Error: Invalid sorting property. Expect one of \(sortingOptions)")
            return
        }
        //
        
        if let stat = Reporter(dbUrl: Configuration.dbFilePath!) {
            let to: Int = Int(Date().timeIntervalSince1970)
            let from: Int = to - Int((timeframe ?? defaultTimeframe) * 24 * 3600)
            
            var top = stat.report(groupBy: groupingProperty,
                               sortBy: sortingProperty,
                               from: from,
                               to: to,
                               count: count)
            
            if reverse { top.reverse() }
            let groupCount = top.count
            top = Array(top.prefix(limit ?? defaultLimit))
            
            // Print header row
            let padLength = max(top.max(by: { $0.0.count < $1.0.count })?.0.count ?? 0, 32)
            let pad: (String) -> String = { $0.padding(toLength: padLength, withPad: " ", startingAt: 0) }
            let unit = sortingProperty == "PlayTime" ? " (m)" : "-Δ"
            print("   #", pad(groupingProperty + " (\(groupCount))"), sortingProperty + unit)
            
            // Print table, hiding decimals in play counts
            let valueFormatting = sortingProperty == "PlayCount" ? "%6.0f" : "%6.2f"
            for (index, (key, value)) in top.enumerated() {
                print(String(format: "%4d", index),
                      pad(key),
                      String(format: valueFormatting, value))
            }
        }
    }
}

let cli = CLI(name: "idbcl")
cli.commands = [UpdateCmd(), InstallCmd(), LogCmd(), ReportCmd()]
cli.goAndExit()
