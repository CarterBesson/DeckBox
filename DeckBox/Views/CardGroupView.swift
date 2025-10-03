// MARK: - Groups View (Unified)
// Shows all card groups (decks, cubes, etc.) in one place with grid/list toggle
// Uses a representative card from each group for the visual preview.

import SwiftUI
import SwiftData

// MARK: - Local View Mode (mirrors CardListView style)
private enum GroupsViewMode { case list, grid }

extension DeckFormat: Identifiable {
    var id: Self { self }
    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .pioneer: return "Pioneer"
        case .modern: return "Modern"
        case .legacy: return "Legacy"
        case .vintage: return "Vintage"
        case .pauper: return "Pauper"
        case .commander: return "Commander"
        case .generic: return "Other"
        }
    }
}

// MARK: - Group Row (List)
private struct GroupListItem: View {
    let group: CardGroup
    @Environment(\.modelContext) private var modelContext

    private var representativeCard: Card? {
        group.cards.first(where: { ($0.imageURL ?? $0.faces.first?.imageURL) != nil }) ?? group.cards.first
    }

    private var thumbnail: some View {
        Group {
            if let url = representativeCard?.imageURL ?? representativeCard?.faces.first?.imageURL {
                AsyncImage(url: url, transaction: Transaction(animation: .none)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        Color.gray.opacity(0.3)
                    }
                }
            } else {
                Color.gray.opacity(0.3)
            }
        }
        .frame(width: 48, height: 64)
        .clipped()
        .cornerRadius(6)
    }

    var body: some View {
        NavigationLink(value: group) {
            HStack(spacing: 12) {
                thumbnail
                VStack(alignment: .leading, spacing: 2) {
                    Text(group.name)
                        .font(.headline)
                        .lineLimit(1)
                    Text("\(group.cards.count) \(group.cards.count == 1 ? "card" : "cards")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                modelContext.delete(group)
            } label: { Label("Delete", systemImage: "trash") }
        }
        .contextMenu {
            Button(role: .destructive) {
                modelContext.delete(group)
            } label: { Label("Delete", systemImage: "trash") }
        }
    }
}

// MARK: - Group Tile (Grid)
private struct GroupGridItem: View {
    let group: CardGroup
    @Environment(\.modelContext) private var modelContext

    private let cornerRadius: CGFloat = 10

    private var representativeCard: Card? {
        group.cards.first(where: { ($0.imageURL ?? $0.faces.first?.imageURL) != nil }) ?? group.cards.first
    }

    private var cover: some View {
        Group {
            if let url = representativeCard?.imageURL ?? representativeCard?.faces.first?.imageURL {
                GeometryReader { _ in
                    AsyncImage(url: url, transaction: Transaction(animation: .none)) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().aspectRatio(contentMode: .fit)
                        default:
                            Color.gray.opacity(0.3)
                        }
                    }
                }
                .aspectRatio(CGSize(width: 5, height: 7), contentMode: .fit)
            } else {
                Color.gray.opacity(0.3)
                    .aspectRatio(CGSize(width: 5, height: 7), contentMode: .fit)
            }
        }
        .cornerRadius(cornerRadius)
    }

    var body: some View {
        NavigationLink(value: group) {
            VStack(alignment: .leading, spacing: 6) {
                cover
                Text(group.name)
                    .font(.headline)
                    .lineLimit(2)
                Text("\(group.cards.count) \(group.cards.count == 1 ? "card" : "cards")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(6)
            .background(Color(UIColor.systemGray6).opacity(0.6))
            .cornerRadius(cornerRadius)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                modelContext.delete(group)
            } label: { Label("Delete", systemImage: "trash") }
        }
    }
}

// MARK: - Main Groups View
struct CardGroupView: View {
    // MARK: Queries
    /// All groups across all types
    @Query(sort: \CardGroup.name) private var groups: [CardGroup]
    /// All group types (used when creating a new group)
    @Query(sort: \GroupType.name) private var groupTypes: [GroupType]

    // MARK: Environment
    @Environment(\.modelContext) private var modelContext

    // MARK: State
    @State private var viewMode: GroupsViewMode = .grid
    @State private var isAddingGroup = false
    @State private var newGroupName = ""
    @State private var selectedTypeForNewGroup: GroupType?
    @State private var selectedDeckFormat: DeckFormat = .standard

    // MARK: Body
    var body: some View {
        Group {
            switch viewMode {
            case .list:
                List {
                    ForEach(groups) { group in
                        GroupListItem(group: group)
                    }
                }
            case .grid:
                ScrollView {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 16)],
                        spacing: 16
                    ) {
                        ForEach(groups) { group in
                            GroupGridItem(group: group)
                                .id(group.id)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Groups")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(for: CardGroup.self) { group in
            CardGroupDetailView(group: group)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation { viewMode = (viewMode == .list) ? .grid : .list }
                } label: {
                    Image(systemName: viewMode == .list ? "square.grid.2x2" : "list.bullet")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if selectedTypeForNewGroup == nil {
                        selectedTypeForNewGroup = groupTypes.first(where: { $0.name == "Decks" }) ?? groupTypes.first
                    }
                    isAddingGroup = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear {
            // Ensure built-in types exist for creation flow
            if groupTypes.isEmpty {
                for type in GroupType.builtInTypes { modelContext.insert(type) }
            }
        }
        // MARK: Add Group Sheet
        .sheet(isPresented: $isAddingGroup) {
            NavigationStack {
                Form {
                    Section(header: Text("Group Details")) {
                        TextField("Name", text: $newGroupName)
                        Picker("Type", selection: $selectedTypeForNewGroup) {
                            ForEach(groupTypes) { type in
                                Label(type.name, systemImage: type.iconName).tag(Optional(type))
                            }
                        }
                    }
                    if selectedTypeForNewGroup?.name == "Decks" {
                        Section(header: Text("Deck Options")) {
                            Picker("Deck Format", selection: $selectedDeckFormat) {
                                ForEach(DeckFormat.allCases) { format in
                                    Text(format.displayName).tag(format)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                }
                .navigationTitle("New Group")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(action: { resetNewGroupForm() }) {
                            Image(systemName: "xmark")
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(action: {
                            guard let type = selectedTypeForNewGroup else { return }

                            // Create the group
                            let group = CardGroup(name: newGroupName, type: type)

                            // If this is a Deck, attach the chosen format
                            if type.name == "Decks" {
                                // NOTE: Assumes your model has `deckFormat` (DeckFormat or DeckFormat?)
                                // Adjust the property name if your model differs.
                                group.deckFormat = selectedDeckFormat
                            }

                            modelContext.insert(group)
                            resetNewGroupForm()
                        }) {
                            Image(systemName: "checkmark")
                        }
                        .disabled(newGroupName.isEmpty || selectedTypeForNewGroup == nil)
                    }
                }
            }
        }
    }

    // MARK: Helpers
    private func resetNewGroupForm() {
        newGroupName = ""
        selectedTypeForNewGroup = nil
        selectedDeckFormat = .standard
        isAddingGroup = false
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        CardGroupView()
    }
    .modelContainer(for: [CardGroup.self, Card.self, GroupType.self], inMemory: true)
}
