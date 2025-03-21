//
//  MyCalcApp.swift
//  MyCalc
//
//  Created by Renic Lin on 2025/3/21.
//

import SwiftData
import SwiftUI

@main
struct MyCalcApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(
                for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                #if os(macOS)
                    .frame(width: 360, height: 530)
                    .fixedSize()
                #endif
        }
        .modelContainer(sharedModelContainer)
    }
}
