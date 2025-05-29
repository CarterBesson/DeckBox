// MARK: - DeckBox App
/// The main entry point for the DeckBox application.
/// This app manages card collections, decks, and related game components using SwiftData for persistence.

import SwiftUI
import SwiftData

@main
struct DeckBoxApp: App {
    /// Shared SwiftData model container that manages the app's persistent storage
    /// Contains schemas for Cards, Tags, CardGroups, and GroupTypes
    var sharedModelContainer: ModelContainer = {
        // Define the data schema for the app
        let schema = Schema([
            Card.self,
            Tag.self,
            CardGroup.self,
            GroupType.self
        ])
        
        // Configure the model storage (persistent, not in-memory)
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        // Set up the main window group with ContentView and inject the model container
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
