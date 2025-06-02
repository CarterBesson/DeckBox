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

struct CardListView: View {
    // MARK: - Properties
    
    /// All cards in the library, sorted by name
    @Query(sort: \Card.name) private var cards: [Card]
    
    /// All available tags for filtering
    @Query(sort: \Tag.name) private var allTags: [Tag]
    
    /// Available group types for filtering (e.g., Decks, Cubes)
    @Query(sort: \GroupType.name) private var groupTypes: [GroupType]
    
    /// SwiftData model context for database operations
    @Environment(\.modelContext) private var modelContext

    // MARK: - View State
    
    /// Navigation path for programmatic navigation
    @State private var navigationPath = NavigationPath()
    
    /// Controls visibility of the add card sheet
    @State private var isAdding = false
    
    /// Controls visibility of the card scanner
    @State private var isScanning = false
    
    /// Currently selected tag for filtering
    @State private var selectedTag: Tag? = nil
    
    /// Current search text
    @State private var searchText = ""
    
    /// Selected group type for filtering
    @State private var selectedGroupType: GroupType? = nil
    
    /// Controls visibility of the add group sheet
    @State private var isAddingGroup = false
    
    /// New group name for adding a new group
    @State private var newGroupName = ""
    
    /// The most recently added card to navigate to
    @State private var newlyAddedCard: Card? = nil
    
    // MARK: - Computed Properties
    
    /// Returns filtered cards based on selected tag, group type, and search text
    private var filteredCards: [Card] {
        // If a group type is selected, we don't show any cards
        guard selectedGroupType == nil else {
            return []
        }

        // Then filter by selected tag
        let tagFiltered = selectedTag == nil ? cards : cards.filter {
            $0.tags.contains(where: { $0.id == selectedTag?.id })
        }

        // Finally, filter by search text if any
        if searchText.isEmpty {
            return tagFiltered
        }

        return tagFiltered.filter { card in
            // Search card name
            if card.name.localizedCaseInsensitiveContains(searchText) {
                return true
            }
            
            // Search through tags
            if card.tags.contains(where: { $0.name.localizedCaseInsensitiveContains(searchText) }) {
                return true
            }
            
            // Search through set name if available
            if let setName = card.setName, setName.localizedCaseInsensitiveContains(searchText) {
                return true
            }
            
            // Search through type line
            if card.typeLine.localizedCaseInsensitiveContains(searchText) {
                return true
            }
            
            // Search through oracle text if available
            if let oracleText = card.oracleText, oracleText.localizedCaseInsensitiveContains(searchText) {
                return true
            }
            
            // Search through color identity
            if card.colorIdentity.contains(where: { $0.localizedCaseInsensitiveContains(searchText) }) {
                return true
            }
            
            // Search through keywords
            if card.keywords.contains(where: { $0.localizedCaseInsensitiveContains(searchText) }) {
                return true
            }
            
            return false
        }
    }
    
    /// Returns filtered groups when a group type is selected
    private var filteredGroups: [CardGroup] {
        guard let type = selectedGroupType else {
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
    
    /// Search bar view with clear button and search icon
    private var searchBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search cards...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
    }
    
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
                .background(selectedTag == nil ? Color.mtgBlue.opacity(0.2) : Color(.systemGray6))
                .clipShape(Capsule())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTag = nil
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
                            let isSelected = selectedTag?.id == tag.id
                            let tagColor = Color.fromName(tag.color)
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(tagColor)
                                    .frame(width: 8, height: 8)
                                Text(tag.name)
                                if tag.cards.count > 0 {
                                    Text("\(tag.cards.count)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isSelected ? tagColor.opacity(0.2) : Color(.systemGray6))
                            .clipShape(Capsule())
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedTag = isSelected ? nil : tag
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                // Library/Group Type Selector
                Menu {
                    Button("Library") { selectedGroupType = nil }
                    
                    ForEach(groupTypes) { type in
                        Button(type.name) { selectedGroupType = type }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedGroupType?.name ?? "Library")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Image(systemName: "chevron.down")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                
                if selectedGroupType == nil {
                    tagFilterView
                        .padding(.vertical, 8)
                }
                
                Divider()
                
                // Card List or Group List
                List {
                    if let type = selectedGroupType {
                        // Show groups for the selected type
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
                    } else {
                        // Show cards in library
                        ForEach(filteredCards) { card in
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
                        .onDelete(perform: delete)
                    }
                }
                
                searchBar
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .primaryAction) {
                    if selectedGroupType == nil {
                        NavigationLink {
                            TagManagementView()
                        } label: {
                            Label("Manage Tags", systemImage: "tag")
                        }
                    }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                Button {
                    if selectedGroupType != nil {
                        // Add new group
                        isAddingGroup = true
                    } else {
                        // Add new card
                        isAdding = true
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 4, y: 2)
                }
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.5)
                        .onEnded { _ in
                            if selectedGroupType == nil {
                                isScanning = true
                            }
                        }
                )
                .padding(.trailing, 15)
                .padding(.bottom, 70) // Increased to account for search bar
            }
            // Sheets and Navigation
            .sheet(isPresented: $isAdding) {
                AddCardView(newlyAddedCard: $newlyAddedCard)
            }
            .sheet(isPresented: $isAddingGroup) {
                NavigationStack {
                    Form {
                        TextField("Name", text: $newGroupName)
                    }
                    .navigationTitle("New \(selectedGroupType?.name.dropLast() ?? "Group")")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                resetNewGroupForm()
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Add") {
                                if let type = selectedGroupType {
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
