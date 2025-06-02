import SwiftUI
import SwiftData

// MARK: - Card Group Detail View
/// A view that displays the details of a card group, including a list of cards and their quantities.
/// Allows for navigation to card details and adding new cards to the group.
struct CardGroupDetailView: View {
    @Bindable var group: CardGroup
    @Environment(\.modelContext) private var modelContext
    @State private var isAddingCards = false
    @State private var searchText = ""
    
    /// Returns cards in the group sorted alphabetically by name
    private var sortedCards: [Card] {
        group.cards.sorted { $0.name < $1.name }
    }
    
    var body: some View {
        List {
            // Display each card in the group with its quantity and tags
            ForEach(sortedCards) { card in
                NavigationLink(value: card) {
                    HStack {
                        // Card name display
                        Text(card.name)
                            .font(.headline)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Quantity indicator
                        Text("×\(group.quantity(for: card))")
                            .foregroundStyle(.secondary)
                        
                        // Tag visualization section
                        // Shows up to 3 tags as colored circles, with a count for additional tags
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
                // Swipe action to remove card from group
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        group.setQuantity(0, for: card)
                    } label: {
                        Label("Remove", systemImage: "minus.circle")
                    }
                }
            }
        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Card.self) { card in
            CardDetailView(card: card)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isAddingCards = true
                } label: {
                    Label("Add Cards", systemImage: "plus")
                }
            }
        }
        // Sheet for adding new cards to the group
        .sheet(isPresented: $isAddingCards) {
            NavigationStack {
                CardSelectionView(group: group)
            }
        }
    }
}

// MARK: - Card Selection View
/// A view that allows users to select and add cards to a group.
/// Includes search functionality and quantity selection for each card.
struct CardSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Card.name) private var allCards: [Card]
    var group: CardGroup
    @State private var searchText = ""
    @State private var selectedQuantities: [UUID: Int] = [:]
    
    /// Filters cards based on search text and availability
    /// Only shows cards that have remaining quantity available to add to the group
    private var filteredCards: [Card] {
        if searchText.isEmpty {
            return allCards.filter { card in
                let remaining = card.quantity - group.quantity(for: card)
                return remaining > 0
            }
        }
        return allCards.filter { card in
            let remaining = card.quantity - group.quantity(for: card)
            return remaining > 0 && card.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        List {
            ForEach(filteredCards) { card in
                HStack {
                    // Card information section
                    VStack(alignment: .leading) {
                        Text(card.name)
                        Text("Library: ×\(card.quantity) • In Group: ×\(group.quantity(for: card))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    
                    let remainingQuantity = card.quantity - group.quantity(for: card)
                    if remainingQuantity > 0 {
                        // Quantity selection controls
                        // Allows users to specify how many copies of the card to add
                        Stepper(
                            value: Binding(
                                get: { selectedQuantities[card.id] ?? 1 },
                                set: { selectedQuantities[card.id] = $0 }
                            ),
                            // Limit the maximum quantity based on available cards
                            in: 1...remainingQuantity
                        ) {
                            Text("\(selectedQuantities[card.id] ?? 1)")
                                .monospacedDigit()
                                .frame(minWidth: 25)
                        }
                        
                        // Add button to confirm quantity selection
                        Button {
                            let quantity = selectedQuantities[card.id] ?? 1
                            group.setQuantity(group.quantity(for: card) + quantity, for: card)
                            selectedQuantities[card.id] = 1 // Reset quantity after adding
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search cards...")
        .navigationTitle("Add Cards")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Preview Provider
#Preview {
    NavigationStack {
        let previewGroup = CardGroup(name: "Sample Deck", type: GroupType(name: "Decks", iconName: "rectangle.on.rectangle", isBuiltIn: true))
        return CardGroupDetailView(group: previewGroup)
    }
    .modelContainer(for: CardGroup.self, inMemory: true)
} 