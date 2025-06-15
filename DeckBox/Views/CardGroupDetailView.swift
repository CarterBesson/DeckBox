import SwiftUI
import SwiftData

// MARK: - Card Tag Display
/// A view that displays up to 3 tags for a card with an overflow indicator
private struct CardTagDisplay: View {
    let tags: [Tag]
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(tags.prefix(3), id: \.name) { tag in
                HStack(spacing: 2) {
                    Circle()
                        .fill(Color.fromName(tag.color))
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .stroke(Color.tagBorder(colorName: tag.color, colorScheme: colorScheme), lineWidth: 1)
                        )
                }
                .padding(.vertical, 2)
                .padding(.horizontal, 4)
                .background(Color.tagBackground(colorName: tag.color, colorScheme: colorScheme))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.tagBorder(colorName: tag.color, colorScheme: colorScheme), lineWidth: 1)
                )
            }
            if tags.count > 3 {
                Text("+\(tags.count - 3)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Card Row View
/// A view that displays a single card row in the group
private struct CardRowView: View {
    let card: Card
    let group: CardGroup
    
    var body: some View {
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
                
                // Tag visualization
                CardTagDisplay(tags: card.tags)
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                group.setQuantity(0, for: card)
            } label: {
                Label("Remove", systemImage: "minus.circle")
            }
        }
    }
}

// MARK: - View Mode
/// Enum to control whether cards are displayed in a list or grid
private enum ViewMode {
    case list
    case grid
}

// MARK: - Card Grid Item View
/// A single card item in the grid
private struct CardGridItem: View {
    let card: Card
    let group: CardGroup
    @Environment(\.colorScheme) private var colorScheme
    
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
            let quantity = group.quantity(for: card)
            if quantity > 1 {
                Text("×\(quantity)")
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
                group.setQuantity(0, for: card)
            } label: {
                Label("Remove", systemImage: "minus.circle")
            }
        }
    }
}

// MARK: - Card Group Detail View
/// A view that displays the details of a card group, including a list of cards and their quantities.
/// Allows for navigation to card details and adding new cards to the group.
struct CardGroupDetailView: View {
    @Bindable var group: CardGroup
    @Environment(\.modelContext) private var modelContext
    @State private var isAddingCards = false
    @State private var searchText = ""
    @State private var viewMode: ViewMode = .grid
    
    /// Returns cards in the group sorted alphabetically by name
    private var sortedCards: [Card] {
        group.cards.sorted { $0.name < $1.name }
    }
    
    var body: some View {
        Group {
            switch viewMode {
            case .list:
                List {
                    ForEach(sortedCards) { card in
                        CardRowView(card: card, group: group)
                    }
                }
            case .grid:
                ScrollView {
                    LazyVGrid(
                        columns: [
                            GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 16)
                        ],
                        spacing: 16
                    ) {
                        ForEach(sortedCards) { card in
                            CardGridItem(card: card, group: group)
                                .id(card.id)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Card.self) { card in
            CardDetailView(card: card)
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

// MARK: - Card Selection Row View
/// A view that displays a single card row in the card selection list
private struct CardSelectionRowView: View {
    let card: Card
    let group: CardGroup
    let remainingQuantity: Int
    @Binding var selectedQuantities: [UUID: Int]
    
    var body: some View {
        HStack {
            // Card information section
            VStack(alignment: .leading) {
                HStack {
                    Text(card.name)
                    CardTagDisplay(tags: card.tags)
                }
                Text("Library: ×\(card.quantity) • In Group: ×\(group.quantity(for: card))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if remainingQuantity > 0 {
                // Quantity selection controls
                Stepper(
                    value: Binding(
                        get: { selectedQuantities[card.id] ?? 1 },
                        set: { selectedQuantities[card.id] = $0 }
                    ),
                    in: 1...remainingQuantity
                ) {
                    Text("\(selectedQuantities[card.id] ?? 1)")
                        .monospacedDigit()
                        .frame(minWidth: 25)
                }
                
                // Add button
                Button {
                    let quantity = selectedQuantities[card.id] ?? 1
                    group.setQuantity(group.quantity(for: card) + quantity, for: card)
                    selectedQuantities[card.id] = 1 // Reset quantity
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.blue)
                }
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
                let remainingQuantity = card.quantity - group.quantity(for: card)
                CardSelectionRowView(
                    card: card,
                    group: group,
                    remainingQuantity: remainingQuantity,
                    selectedQuantities: $selectedQuantities
                )
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