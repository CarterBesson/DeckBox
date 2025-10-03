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
            if let url = card.imageURL ?? card.faces.first?.imageURL {
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
    // Scanner state for adding directly to this group
    @State private var isScanning = false
    @State private var batchScanCount: Int = 0
    @State private var lastScannedNames: [String] = []
    
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
            CardDetailRouter(card: card)
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
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isScanning = true
                } label: {
                    Image(systemName: "camera")
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
        .sheet(isPresented: $isScanning) {
            ZStack(alignment: .top) {
                // Keep the scanner alive and stream cards as they're seen
                CardScannerView(
                    batchMode: true,
                    onCardFound: { scannedName in
                        // Add scanned cards directly to the current group. If the card
                        // does not exist in the library, create it; otherwise do not
                        // increase owned quantity, only the group quantity.
                        Task { @MainActor in
                            do {
                                if let existing = try CardLibraryManager.consolidateCards(named: scannedName, in: modelContext) {
                                    let current = group.quantity(for: existing)
                                    group.setQuantity(current + 1, for: existing)
                                } else {
                                    let dto = try await ScryfallService().fetchCard(named: scannedName)
                                    let card = try CardLibraryManager.upsertCard(from: dto, in: modelContext)
                                    group.setQuantity(1, for: card)
                                }
                            } catch {
                                print("Lookup failed: \(error)")
                                return
                            }

                            // Update HUD counters
                            batchScanCount += 1
                            lastScannedNames.insert(scannedName, at: 0)
                            if lastScannedNames.count > 5 { lastScannedNames.removeLast(lastScannedNames.count - 5) }
                        }
                    },
                    onScannedText: { _ in }, // unused in batch flow
                    onFinish: {
                        isScanning = false
                    }
                )

                // HUD overlay
                VStack(spacing: 8) {
                    HStack {
                        Label("\(batchScanCount) added", systemImage: "checkmark.circle")
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                        Spacer()
                        Button {
                            isScanning = false
                        } label: {
                            Text("Done")
                                .font(.headline)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .accessibilityLabel("Done")
                    }
                    .padding(.top, 12)
                    .padding(.horizontal)

                    if !lastScannedNames.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(lastScannedNames.prefix(3), id: \.self) { name in
                                Text(name)
                                    .lineLimit(1)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Capsule())
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                    }

                    Spacer()
                }
            }
        }
    }
}

// MARK: - Card Selection Row View
/// A view that displays a single card row in the card selection list
private struct CardSelectionRowView: View {
    let card: Card
    let group: CardGroup
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack {
            // Card name only (no tag indicators)
            Text(card.name)
                .lineLimit(1)
                .font(.headline)

            Spacer()

            // Direct quantity controls for this group
            HStack(spacing: 12) {
                Button {
                    let current = group.quantity(for: card)
                    if current > 0 {
                        group.setQuantity(current - 1, for: card)
                    }
                } label: {
                    Image(systemName: "minus")
                }
                .disabled(group.quantity(for: card) == 0)

                Text("\(group.quantity(for: card))")
                    .monospacedDigit()
                    .frame(minWidth: 24)

                Button {
                    let current = group.quantity(for: card)
                    group.setQuantity(current + 1, for: card)
                } label: {
                    Image(systemName: "plus")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Card Selection View
/// A view that allows users to select and add cards to a group.
/// Includes search functionality, quantity selection for each card, and bulk import.
struct CardSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Card.name) private var allCards: [Card]
    var group: CardGroup
    @State private var searchText = ""
    @State private var isBulkMode = false
    @State private var bulkText = ""
    @State private var isImporting = false
    @State private var importProgress: (current: Int, total: Int)?
    @State private var importError: String?
    @State private var importedCards: [(card: Card, quantity: Int, owned: Bool)] = []
    
    /// Filters cards based on search text
    private var filteredCards: [Card] {
        if searchText.isEmpty {
            return allCards
        }
        return allCards.filter { card in
            card.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    /// Parses a deck list text into card names and quantities
    private func parseDeckList(_ text: String) -> [(name: String, quantity: Int)] {
        let lines = text.components(separatedBy: .newlines)
        var cards: [(name: String, quantity: Int)] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            
            // Try to match patterns like "2 Card Name" or "2x Card Name"
            let components = trimmed.components(separatedBy: .whitespaces)
            if components.count >= 2 {
                let quantityStr = components[0].trimmingCharacters(in: CharacterSet(charactersIn: "xX"))
                if let quantity = Int(quantityStr) {
                    let name = components.dropFirst().joined(separator: " ")
                    cards.append((name: name, quantity: quantity))
                }
            }
        }
        
        return cards
    }
    
    /// Imports cards from a deck list
    @MainActor
    private func importDeckList() async {
        let cards = parseDeckList(bulkText)
        importProgress = (0, cards.count)
        importedCards = []
        
        for (index, cardInfo) in cards.enumerated() {
            do {
                // First check if we already have this card in our collection
                let existingCard = allCards.first { $0.name.lowercased() == cardInfo.name.lowercased() }

                if let existingCard = existingCard,
                   let primary = try CardLibraryManager.consolidateCards(named: existingCard.name, in: modelContext) {
                    // Card exists in collection, just add it to the group
                    let updatedQuantity = group.quantity(for: primary) + cardInfo.quantity
                    group.setQuantity(updatedQuantity, for: primary)
                    importedCards.append((card: primary, quantity: cardInfo.quantity, owned: primary.quantity > 0))
                } else {
                    // Card doesn't exist (or consolidation failed), fetch it and add to collection
                    let dto = try await ScryfallService().fetchCard(named: cardInfo.name)
                    let card = try CardLibraryManager.upsertCard(from: dto, in: modelContext)
                    group.setQuantity(cardInfo.quantity, for: card)
                    importedCards.append((card: card, quantity: cardInfo.quantity, owned: false))
                }
                
                importProgress = (index + 1, cards.count)
            } catch {
                importError = "Failed to import \(cardInfo.name): \(error.localizedDescription)"
                break
            }
        }
        
        isImporting = false
    }
    
    var body: some View {
        NavigationStack {
            if isBulkMode {
                Form {
                    Section {
                        TextEditor(text: $bulkText)
                            .frame(minHeight: 200)
                    } header: {
                        Text("Paste Deck List")
                    } footer: {
                        Text("Enter one card per line with quantity (e.g., '2 Lightning Bolt' or '2x Lightning Bolt')")
                    }
                    
                    if let progress = importProgress {
                        Section {
                            ProgressView(value: Double(progress.current), total: Double(progress.total)) {
                                Text("Importing cards...")
                            }
                            Text("\(progress.current) of \(progress.total) cards imported")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if !importedCards.isEmpty {
                        Section("Imported Cards") {
                            ForEach(importedCards, id: \.card.id) { item in
                                HStack {
                                    Text(item.card.name)
                                    Spacer()
                                    Text("×\(item.quantity)")
                                        .foregroundStyle(.secondary)
                                    if !item.owned {
                                        Text("Not owned")
                                            .font(.caption)
                                            .foregroundStyle(.red)
                                    }
                                }
                            }
                        }
                    }
                    
                    if let error = importError {
                        Section {
                            Text(error)
                                .foregroundStyle(.red)
                        }
                    }
                }
                .navigationTitle("Bulk Import")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Import") {
                            isImporting = true
                            Task {
                                await importDeckList()
                            }
                        }
                        .disabled(bulkText.isEmpty || isImporting)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            isBulkMode = false
                        } label: {
                            Label("Manual Picker", systemImage: "list.bullet")
                        }
                        .disabled(isImporting)
                        .accessibilityLabel("Switch to manual picker")
                    }
                }
            } else {
                List {
                    ForEach(filteredCards) { card in
                        CardSelectionRowView(
                            card: card,
                            group: group
                        )
                    }
                }
                .searchable(text: $searchText, prompt: "Search cards...")
                .navigationTitle("Add Cards")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            isBulkMode = true
                        } label: {
                            Label("Bulk Import", systemImage: "text.badge.plus")
                        }
                    }
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
