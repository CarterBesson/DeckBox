// MARK: - Content View
/// The main view of the DeckBox application.
/// Shows the card library with integrated navigation to groups.

import SwiftUI
import SwiftData

struct ContentView: View {    
    var body: some View {
        TabView {
            Tab("Library", systemImage: "books.vertical") {
                NavigationStack {
                    CardListView()
                        .navigationTitle("Library")
                        .navigationBarTitleDisplayMode(.large)
                }
            }
            
            Tab("Groups", systemImage: "folder") {
                NavigationStack {
                    CardGroupView()
                        .navigationTitle("Groups")
                        .navigationBarTitleDisplayMode(.large)
                }
            }
            
            Tab("Tags", systemImage: "tag") {
                NavigationStack {
                    TagManagementView()
                        .navigationTitle("Tags")
                        .navigationBarTitleDisplayMode(.large)
                }
            }
            
            Tab(role: .search) {
                NavigationStack {
                    SearchView()
                        .navigationTitle("Search")
                        .navigationBarTitleDisplayMode(.large)
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Card.self, inMemory: true)
}

extension View {
    func selected(_ isSelected: Bool) -> some View {
        self.background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
    }
}
