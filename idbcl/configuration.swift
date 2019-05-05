//
//  configuration.swift
//  idbcl
//

import Foundation

struct Configuration {
    static var executableURL: URL = URL(fileReferenceLiteralResourceName: CommandLine.arguments[0])
    static var dbFileURL: URL? = CommandLine.argc == 2 ? URL(string: CommandLine.arguments[1]) : nil
}
