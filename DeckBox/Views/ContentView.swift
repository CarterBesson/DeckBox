// MARK: - Content View
/// The main view of the DeckBox application.
/// Shows the card library with integrated navigation to groups.

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        NavigationStack {
            CardListView()
        }
    }
}

/// Preview provider for ContentView
/// Uses an in-memory model container for testing
#Preview {
    ContentView()
        .modelContainer(for: Card.self, inMemory: true)
}
