//
//  CardListView.swift
//  DeckBox
//
//  Created by Carter Besson on 5/24/25.
//
// MARK: - Card List View
/// The main view for browsing and managing the card library.
/// Provides filtering by tags, searching, and various card management actions.
/// Supports scanning cards using the camera and adding them to the library.

import SwiftUI
import SwiftData

// MARK: - View Mode
/// Enum to control whether cards are displayed in a list or grid
private enum ViewMode {
    case list
    case grid
}

// MARK: - Tag Filter Item View
/// A single tag item in the filter bar
private struct TagFilterItem: View {
    let tag: Tag
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.fromName(tag.color))
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(Color.tagBorder(colorName: tag.color, colorScheme: colorScheme), lineWidth: 1)
                )
            Text(tag.name)
                .foregroundColor(isSelected ? Color.tagText(colorName: tag.color, colorScheme: colorScheme) : .primary)
            if tag.cards.count > 0 {
                Text("\(tag.cards.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isSelected ? Color.tagBackground(colorName: tag.color, colorScheme: colorScheme) : Color(.systemGray6))
        .overlay(
            Capsule()
                .stroke(isSelected ? Color.tagBorder(colorName: tag.color, colorScheme: colorScheme) : Color.clear, lineWidth: 1)
        )
        .clipShape(Capsule())
        .onTapGesture(perform: action)
    }
}

// MARK: - Card List Item View
/// A single card item in the list
private struct CardListItem: View {
    let card: Card
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationLink(value: card) {
            HStack {
                Text(card.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                // Tag indicators
                HStack(spacing: 4) {
                    ForEach(card.tags.prefix(3), id: \.name) { tag in
                        Circle()
                            .fill(Color.fromName(tag.color))
                            .frame(width: 8, height: 8)
                            .overlay(
                                Circle()
                                    .stroke(Color.tagBorder(colorName: tag.color, colorScheme: colorScheme), lineWidth: 1)
                            )
                    }
                    if card.tags.count > 3 {
                        Text("+\(card.tags.count - 3)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                modelContext.delete(card)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Card Grid Item View
/// A single card item in the grid
private struct CardGridItem: View {
    let card: Card
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    // Cache expensive computations
    private let imageHeight: CGFloat = 200
    private let cornerRadius: CGFloat = 8
    private let maxTagsShown = 3
    
    private var tagView: some View {
        HStack(spacing: 4) {
            ForEach(Array(card.tags.prefix(maxTagsShown)), id: \.id) { tag in
                Circle()
                    .fill(Color.fromName(tag.color))
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(Color.tagBorder(colorName: tag.color, colorScheme: colorScheme), lineWidth: 1)
                    )
            }
            if card.tags.count > maxTagsShown {
                Text("+\(card.tags.count - maxTagsShown)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var cardImage: some View {
        Group {
            if let url = card.imageURL {
                GeometryReader { geometry in
                    AsyncImage(
                        url: url,
                        transaction: Transaction(animation: .none)
                    ) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        default:
                            Color.gray.opacity(0.3)
                        }
                    }
                }
                .aspectRatio(CGSize(width: 5, height: 7), contentMode: .fit)
                .cornerRadius(cornerRadius)
            } else {
                Color.gray.opacity(0.3)
                    .aspectRatio(CGSize(width: 5, height: 7), contentMode: .fit)
                    .cornerRadius(cornerRadius)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var quantityBadge: some View {
        Group {
            if card.quantity > 1 {
                Text("×\(card.quantity)")
                    .font(.caption)
                    .padding(4)
                    .background(.ultraThinMaterial)
                    .cornerRadius(4)
                    .padding(4)
            }
        }
    }
    
    var body: some View {
        NavigationLink(value: card) {
            VStack(alignment: .leading, spacing: 4) {
                cardImage
                    .overlay(alignment: .topTrailing) {
                        quantityBadge
                    }
                
                Text(card.name)
                    .font(.headline)
                    .lineLimit(1)
                
                tagView
                    .padding(.bottom, 4)
            }
            .background(Color(.systemGray6).opacity(0.5))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                modelContext.delete(card)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct CardListView: View {
    // MARK: - Tabs
    private enum Tab {
        case library
        case groups
        case tags
    }

    // MARK: - Properties
    
    /// All cards in the library, sorted by name
    @Query(sort: \Card.name) private var cards: [Card]
    
    /// All available tags for filtering
    @Query(sort: \Tag.name) private var allTags: [Tag]
    
    /// Available group types for filtering (e.g., Decks, Cubes)
    @Query(sort: \GroupType.name) private var groupTypes: [GroupType]
    
    /// SwiftData model context for database operations
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // MARK: - View State
    
    /// Current view mode (list or grid)
    @State private var viewMode: ViewMode = .grid
    
    /// Navigation path for programmatic navigation
    @State private var navigationPath = NavigationPath()
    
    /// Controls visibility of the add card sheet
    @State private var isAdding = false
    
    /// Controls visibility of the card scanner
    @State private var isScanning = false
    
    /// Currently selected tags for filtering. Cards must contain all selected tags to be shown.
    @State private var selectedTags: [Tag] = []
    
    /// Current search text
    @State private var searchText = ""
    
    /// Controls visibility of the add group sheet
    @State private var isAddingGroup = false
    
    /// New group name for adding a new group
    @State private var newGroupName = ""
    
    /// The most recently added card to navigate to
    @State private var newlyAddedCard: Card? = nil

    /// Currently selected tab
    @State private var selectedTab: Tab = .library
    
    /// Controls visibility of search sheet in Library tab
    @State private var isSearching = false
    
    /// Selected group type in Groups tab for filtering
    @State private var selectedGroupTypeInGroups: GroupType? = nil

    // MARK: - Computed Properties
    
    /// Returns filtered cards based on selected tags and search text
    private var filteredCards: [Card] {
        var filtered = cards
        
        // Filter by search text if any
        if !searchText.isEmpty {
            filtered = filtered.filter { card in
                card.name.localizedCaseInsensitiveContains(searchText) ||
                card.tags.contains(where: { $0.name.localizedCaseInsensitiveContains(searchText) }) ||
                (card.setName?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                card.typeLine.localizedCaseInsensitiveContains(searchText) ||
                (card.oracleText?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                card.colorIdentity.contains(where: { $0.localizedCaseInsensitiveContains(searchText) }) ||
                card.keywords.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
            }
        }
        
        // Filter by selected tags
        if !selectedTags.isEmpty {
            filtered = filtered.filter { card in
                selectedTags.allSatisfy { tag in
                    card.tags.contains(where: { $0.id == tag.id })
                }
            }
        }
        
        return filtered
    }
    
    /// Returns filtered groups based on selected group type and search text
    private var filteredGroups: [CardGroup] {
        guard let type = selectedGroupTypeInGroups else {
            return []
        }

        let groups = type.groups.sorted { $0.name < $1.name }
        if searchText.isEmpty {
            return groups
        }

        return groups.filter { group in
            group.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // MARK: - Subviews
    
    /// Horizontal scrolling tag filter with categories
    private var tagFilterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All cards filter option
                HStack(spacing: 4) {
                    Image(systemName: "tag")
                        .foregroundStyle(.secondary)
                    Text("All")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedTags.isEmpty ? Color.tagBackground(colorName: "mtgBlue", colorScheme: colorScheme) : Color(.systemGray6))
                .clipShape(Capsule())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTags.removeAll()
                    }
                }
                
                // Group and display tags by category
                let groupedTags = Dictionary(grouping: allTags) { $0.category ?? "" }
                ForEach(groupedTags.keys.sorted(), id: \.self) { category in
                    if let tags = groupedTags[category] {
                        if !category.isEmpty {
                            Divider()
                                .frame(height: 24)
                            Text(category)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        ForEach(tags.sorted(by: { $0.name < $1.name }), id: \.id) { tag in
                            TagFilterItem(
                                tag: tag,
                                isSelected: selectedTags.contains(where: { $0.id == tag.id }),
                                action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        if selectedTags.contains(where: { $0.id == tag.id }) {
                                            selectedTags.removeAll { $0.id == tag.id }
                                        } else {
                                            selectedTags.append(tag)
                                        }
                                    }
                                }
                            )
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Library Tab View
    private var libraryTabView: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                tagFilterView
                    .padding(.vertical, 8)
            }
            
            Divider()
            
            Group {
                switch viewMode {
                case .list:
                    List {
                        ForEach(filteredCards) { card in
                            CardListItem(card: card)
                        }
                        .onDelete(perform: delete)
                    }
                case .grid:
                    ScrollView {
                        LazyVGrid(
                            columns: [
                                GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 16)
                            ],
                            spacing: 16
                        ) {
                            ForEach(filteredCards) { card in
                                CardGridItem(card: card)
                                    .id(card.id)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    withAnimation {
                        viewMode = viewMode == .list ? .grid : .list
                    }
                } label: {
                    Image(systemName: viewMode == .list ? "square.grid.2x2" : "list.bullet")
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            Button {
                isAdding = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.accentColor)
                    .clipShape(Circle())
                    .shadow(radius: 4, y: 2)
            }
            .padding(.trailing, 15)
            .padding(.bottom, 15)
        }
        .sheet(isPresented: $isAdding) {
            AddCardView(newlyAddedCard: $newlyAddedCard)
        }
        .sheet(isPresented: $isScanning) {
            CardScannerView(
                onScannedText: { scannedName in
                    Task {
                        do {
                            let dto = try await ScryfallService().fetchCard(named: scannedName)
                            let card = Card(from: dto, modelContext: modelContext)
                            modelContext.insert(card)
                            newlyAddedCard = card
                            isScanning = false
                        } catch {
                            print("Lookup failed: \(error)")
                        }
                    }
                },
                onFinish: {
                    isScanning = false
                }
            )
        }
        .navigationDestination(for: Card.self) { card in
            CardDetailView(card: card)
        }
    }

    // MARK: - Groups Tab View
    private var groupsTabView: some View {
        NavigationStack {
            List {
                Section {
                    Button("All Groups") {
                        selectedGroupTypeInGroups = nil
                        searchText = ""
                    }
                    .font(selectedGroupTypeInGroups == nil ? .headline : .body)
                }
                
                Section("Group Types") {
                    ForEach(groupTypes) { type in
                        Button {
                            selectedGroupTypeInGroups = type
                            searchText = ""
                        } label: {
                            HStack {
                                Label(type.name, systemImage: type.iconName)
                                Spacer()
                                Text("\(type.groups.count)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .font(selectedGroupTypeInGroups?.id == type.id ? .headline : .body)
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Groups")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isAddingGroup = true
                    } label: {
                        Label("Add Group", systemImage: "plus")
                    }
                    .disabled(selectedGroupTypeInGroups == nil)
                }
            }
            if let type = selectedGroupTypeInGroups {
                List {
                    ForEach(filteredGroups) { group in
                        NavigationLink(value: group) {
                            HStack {
                                Label(group.name, systemImage: type.iconName)
                                Spacer()
                                Text("\(group.cards.count)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                modelContext.delete(group)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .navigationTitle(type.name)
            } else {
                Text("Select a group type")
                    .foregroundStyle(.secondary)
            }
        }
        .sheet(isPresented: $isAddingGroup) {
            NavigationStack {
                Form {
                    TextField("Name", text: $newGroupName)
                }
                .navigationTitle("New \(selectedGroupTypeInGroups?.name.dropLast() ?? "Group")")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            resetNewGroupForm()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            if let type = selectedGroupTypeInGroups {
                                let group = CardGroup(name: newGroupName, type: type)
                                modelContext.insert(group)
                            }
                            resetNewGroupForm()
                        }
                        .disabled(newGroupName.isEmpty)
                    }
                }
            }
        }
    }

    // MARK: - Tags Tab View
    private var tagsTabView: some View {
        NavigationStack {
            TagManagementView()
                .navigationTitle("Tags")
        }
    }

    // MARK: - Body
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            libraryTabView
                .navigationDestination(for: CardGroup.self) { group in
                    CardGroupDetailView(group: group)
                }
                .onChange(of: newlyAddedCard) { _, card in
                    if let card = card {
                        isAdding = false
                        isScanning = false
                        navigationPath.append(card)
                        // Reset the newlyAddedCard after navigation
                        newlyAddedCard = nil
                    }
                }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Deletes cards at the specified offsets from the filtered cards array
    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let card = filteredCards[index]
            modelContext.delete(card)
        }
    }
    
    /// Resets the new group form and dismisses the sheet
    private func resetNewGroupForm() {
        newGroupName = ""
        isAddingGroup = false
    }
}

private struct AddButton: View {
    @Environment(\.modelContext) private var ctx
    // Inject the service (for now, hard-code ScryfallService)
    private let service: CardDataService = ScryfallService()
    
    var body: some View {
        Button {
            Task {
                do {
                    // Replace with a prompt or scan result later
                    let dto = try await service.fetchCard(named: "Black Lotus")
                    let card = Card(from: dto, modelContext: ctx)
                    ctx.insert(card)
                } catch {
                    // Show an alert on failure
                    print("Lookup failed: \(error.localizedDescription)")
                }
            }
        } label: {
            Label("Add", systemImage: "plus")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Card.self, inMemory: true)
}
