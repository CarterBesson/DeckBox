// MARK: - Content View
/// The main view of the DeckBox application.
/// Shows the card library with integrated navigation to groups.

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedTab = Tab.library
    
    @ViewBuilder
    private var tabContent: some View {
        NavigationStack {
            CardListView()
                .navigationTitle("Library")
                .navigationBarTitleDisplayMode(.large)
        }
        .tag(Tab.library)
        .tabItem {
            Label("Library", systemImage: "books.vertical")
        }
        
        NavigationStack {
            CardGroupView()
                .navigationTitle("Groups")
                .navigationBarTitleDisplayMode(.large)
        }
        .tag(Tab.groups)
        .tabItem {
            Label("Groups", systemImage: "folder")
        }
        
        NavigationStack {
            TagManagementView()
                .navigationTitle("Tags")
                .navigationBarTitleDisplayMode(.large)
        }
        .tag(Tab.tags)
        .tabItem {
            Label("Tags", systemImage: "tag")
        }
        
        NavigationStack {
            SearchView()
                .navigationTitle("Search")
                .navigationBarTitleDisplayMode(.large)
        }
        .tag(Tab.search)
        .tabItem {
            Label("Search", systemImage: "magnifyingglass")
        }
    }
    
    var body: some View {
        if horizontalSizeClass == .regular {
            TabView(selection: $selectedTab) {
                tabContent
            }
            .tabViewStyle(.sidebarAdaptable)
        } else {
            TabView(selection: $selectedTab) {
                tabContent
            }
        }
    }
}

// MARK: - Tab Items
enum Tab: Hashable {
    case library
    case groups
    case tags
    case search
}

// MARK: - Search Tab View
struct SearchTabView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Binding var selectedTab: Tab
    
    var body: some View {
        NavigationStack {
            SearchView()
                .navigationTitle("Search")
                .navigationBarTitleDisplayMode(.large)
        }
        .tag(Tab.search)
        .tabItem {
            Label("Search", systemImage: "magnifyingglass")
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
