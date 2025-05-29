// MARK: - Content View
/// The main view of the DeckBox application.
/// Implements a tab-based navigation structure with two main sections:
/// 1. Cards - For browsing and managing the card library
/// 2. Groups - For managing decks, cubes, and other card collections

import SwiftUI
import SwiftData

struct ContentView: View {
    /// Currently selected tab index (0 = Cards, 1 = Groups)
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Cards Tab - Shows the card library
            NavigationStack {
                CardListView()
            }
            .tabItem {
                Label("Cards", systemImage: "rectangle.stack")
            }
            .tag(0)
            
            // Groups Tab - Shows decks, cubes, and other collections
            NavigationStack {
                CardGroupView()
            }
            .tabItem {
                Label("Groups", systemImage: "folder")
            }
            .tag(1)
        }
    }
}

/// Preview provider for ContentView
/// Uses an in-memory model container for testing
#Preview {
    ContentView()
        .modelContainer(for: Card.self, inMemory: true)
}
