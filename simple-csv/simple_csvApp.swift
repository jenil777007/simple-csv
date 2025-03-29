//
//  simple_csvApp.swift
//  simple-csv
//
//  Created by Jenil Calcuttawala on 29/03/25.
//

import SwiftUI

@main
struct SimpleCSVApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandGroup(replacing: .saveItem) {
                Button("Save") {
                    NotificationCenter.default.post(name: .saveDocument, object: nil)
                }
                .keyboardShortcut("s", modifiers: .command)
                
                Button("Save As...") {
                    NotificationCenter.default.post(name: .saveAsDocument, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }
        }
    }
}

extension Notification.Name {
    static let saveDocument = Notification.Name("saveDocument")
    static let saveAsDocument = Notification.Name("saveAsDocument")
}
