//
//  CardDetailView.swift
//  DeckBox
//
//  Created by Carter Besson on 5/24/25.
//

// MARK: - Card Detail View
/// Detailed view for a single card, showing its image, metadata, and tags.
/// Allows editing of card quantity and management of tags.

import SwiftUI
import SwiftData

struct CardDetailView: View {
    /// The card being displayed and edited
    @Bindable var card: Card             // SwiftData auto–bindable
    @Environment(\.modelContext) private var modelContext

    // MARK: - View State
    
    /// Controls visibility of the add tag sheet
    @State private var isAddingTag = false
    @State private var newTagName   = ""

    // MARK: – Subviews

    /// Displays the card's image if available
    /// Shows a placeholder if the image is loading or unavailable
    private var cardImageSection: some View {
        Group {
            if let url = card.imageURL {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(8)
                } placeholder: {
                    Color.gray.opacity(0.3)
                        .frame(height: 200)
                }
            }
        }
    }

    /// Section for displaying and managing card tags
    /// Shows a horizontal scrolling list of tags with delete functionality
    private var tagsSection: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Tags")
                    .font(.headline)
                Spacer()
                Button {
                    isAddingTag = true
                } label: {
                    Label("Add Tag", systemImage: "plus.circle")
                        .labelStyle(.iconOnly)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(card.tags, id: \.name) { tag in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.fromName(tag.color))
                                .frame(width: 8, height: 8)
                            Text(tag.name)
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.fromName(tag.color).opacity(0.2))
                        .clipShape(Capsule())
                        .onTapGesture {
                            if let idx = card.tags.firstIndex(where: { $0.name == tag.name }) {
                                card.tags.remove(at: idx)
                            }
                        }
                    }
                }
            }
            .frame(height: card.tags.isEmpty ? 0 : nil)
        }
    }

    /// Sheet view for adding new tags to the card
    /// Provides tag search, selection from existing tags, and creation of new tags
    private var addTagSheet: some View {
        NavigationStack {
            List {
                // Search field
                Section {
                    TextField("Search tags...", text: $newTagName)
                }
                
                // Existing tags section
                Section {
                    let existingTags = try? modelContext.fetch(FetchDescriptor<Tag>(sortBy: [SortDescriptor(\.name)]))
                    if let tags = existingTags {
                        ForEach(tags.filter { tag in
                            !card.tags.contains { $0.name == tag.name } &&
                            (newTagName.isEmpty || tag.name.localizedCaseInsensitiveContains(newTagName))
                        }, id: \.name) { tag in
                            HStack {
                                Circle()
                                    .fill(Color(tag.color))
                                    .frame(width: 12, height: 12)
                                Text(tag.name)
                                if let category = tag.category {
                                    Spacer()
                                    Text(category)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                card.tags.append(tag)
                                isAddingTag = false
                                newTagName = ""
                            }
                        }
                    }
                } header: {
                    Text("Existing Tags")
                }
                
                // New tag creation section
                if !newTagName.isEmpty {
                    Section {
                        Button("Create \"\(newTagName)\"") {
                            let trimmed = newTagName.trimmingCharacters(in: .whitespaces)
                            guard !trimmed.isEmpty else { return }
                            let tag = Tag(name: trimmed)
                            modelContext.insert(tag)
                            card.tags.append(tag)
                            isAddingTag = false
                            newTagName = ""
                        }
                    }
                }
            }
            .navigationTitle("Add Tag")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isAddingTag = false
                        newTagName = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    NavigationLink {
                        TagManagementView()
                    } label: {
                        Label("Manage", systemImage: "gear")
                    }
                }
            }
        }
    }

    // MARK: – Body

    var body: some View {
        ScrollView {
            cardImageSection

            VStack(alignment: .leading, spacing: 12) {
                // Card name and mana cost
                HStack {
                    Text(card.name)
                        .font(.title2)
                        .bold()
                    Spacer()
                    if let manaCost = card.manaCost {
                        Text(manaCost)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }

                // Type line
                Text(card.typeLine)
                    .font(.headline)
                    .foregroundStyle(.secondary)

                // Set information
                HStack {
                    if let setName = card.setName {
                        Text(setName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if let collectorNumber = card.collectorNumber {
                        Text("#\(collectorNumber)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                // Oracle text
                if let oracleText = card.oracleText {
                    Text(oracleText)
                        .padding(.vertical, 4)
                }

                // Flavor text
                if let flavorText = card.flavorText {
                    Text(flavorText)
                        .italic()
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                }

                // Power/Toughness or Loyalty
                if let power = card.power, let toughness = card.toughness {
                    Text("\(power)/\(toughness)")
                        .font(.headline)
                } else if let loyalty = card.loyalty {
                    Text("Loyalty: \(loyalty)")
                        .font(.headline)
                }

                // Artist credit
                if let artist = card.artist {
                    Text("Illustrated by \(artist)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()

                // Card details section
                Group {
                    // Rarity and Reserved List status
                    HStack {
                        Text(card.rarity.capitalized)
                            .font(.subheadline)
                        if card.isReserved {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                            Text("Reserved List")
                                .font(.subheadline)
                        }
                    }

                    // Colors and Color Identity
                    if !card.colors.isEmpty {
                        Text("Colors: \(card.colors.joined(separator: ", "))")
                            .font(.subheadline)
                    }
                    if !card.colorIdentity.isEmpty {
                        Text("Color Identity: \(card.colorIdentity.joined(separator: ", "))")
                            .font(.subheadline)
                    }

                    // Keywords
                    if !card.keywords.isEmpty {
                        Text("Keywords: \(card.keywords.joined(separator: ", "))")
                            .font(.subheadline)
                    }

                    // Legalities
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Format Legality:")
                            .font(.subheadline)
                            .bold()
                        ForEach(Array(card.legalities.sorted(by: { $0.key < $1.key })), id: \.key) { format, legality in
                            HStack {
                                Text(format.capitalized)
                                    .font(.caption)
                                Spacer()
                                Text(legality.capitalized)
                                    .font(.caption)
                                    .foregroundStyle(legality == "legal" ? .green : .red)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Divider()

                // Quantity stepper
                Stepper("Quantity: \(card.quantity)",
                        value: $card.quantity,
                        in: 1...99)

                // Tags section
                tagsSection
            }
            .padding()
        }
        .navigationTitle(card.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isAddingTag) {
            addTagSheet
        }
    }
}

/// Preview provider for CardDetailView
/// Uses an in-memory model container for testing
#Preview {
    ContentView()
        .modelContainer(for: Card.self, inMemory: true)
}
