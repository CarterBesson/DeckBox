//
//  CardDetailComponents.swift
//  DeckBox
//
//  Created by Carter Besson on 6/27/25.
//

import SwiftUI
import SwiftData

struct CardImageSection: View {
    @Bindable var card: Card
    @State private var selectedFaceIndex = 0
    
    private var isDoubleSided: Bool {
        card.layout == "transform" || card.layout == "modal_dfc" || card.layout == "split"
    }
    
    private var currentFace: CardFace? {
        guard isDoubleSided, !card.faces.isEmpty else { return nil }
        return card.faces[selectedFaceIndex]
    }
    
    var body: some View {
        VStack {
            if isDoubleSided {
                // Front / back (or split) image
                if let url = currentFace?.imageURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable()
                               .aspectRatio(contentMode: .fit)
                        default:
                            Color.gray.opacity(0.3)
                        }
                    }
                    .cornerRadius(8)
                }

                // Face‑picker arrows
                HStack {
                    Button {
                        selectedFaceIndex = (selectedFaceIndex - 1 + card.faces.count) % card.faces.count
                    } label: {
                        Image(systemName: "arrow.left.circle.fill")
                    }
                    .disabled(card.faces.count <= 1)

                    Text("\(selectedFaceIndex + 1)/\(card.faces.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button {
                        selectedFaceIndex = (selectedFaceIndex + 1) % card.faces.count
                    } label: {
                        Image(systemName: "arrow.right.circle.fill")
                    }
                    .disabled(card.faces.count <= 1)
                }
            } else if let url = card.imageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable()
                           .aspectRatio(contentMode: .fit)
                    default:
                        Color.gray.opacity(0.3)
                    }
                }
                .cornerRadius(8)
            }
        }
    }
}


struct CardMetadataSection: View {
    @Bindable var card: Card
    let face: CardFace?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Name + mana cost
            HStack {
                Text(face?.name ?? card.name).font(.title2).bold()
                Spacer()
                if let mana = face?.manaCost { Text(mana).foregroundStyle(.secondary)}
            }
            
            // Type line
            Text(face?.typeLine ?? card.typeLine).foregroundStyle(.secondary)
            
            //Set + collector number
            HStack {
                if let setName = card.setName { Text(setName) }
                Spacer()
                if let num = card.collectorNumber { Text("#\(num)")}
            }
            .font(.subheadline).foregroundStyle(.secondary)
            
            // Oracle / flavor text
            if let oracle = face?.oracleText { Text(oracle).padding(.vertical, 2)}
            if let flavor = face?.flavorText { Text(flavor).italic().foregroundStyle(.secondary)}
            
            // P/T or loyalty
            if let p = face?.power, let t = face?.toughness {
                Text("\(p)/\(t)").font(.headline)
            } else if let loyalty = face?.loyalty {
                Text("Loyalty: \(loyalty)").font(.headline)
            }
            
            // Artist
            if let artist = face?.artist {
                Text("Illustrated by \(artist)").font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}


struct LegalitiesSection: View {
    @Bindable var card: Card
    var shownFormats: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Format Legality:").bold().font(.subheadline)
            ForEach(shownFormats, id: \.self) { fmt in
                if let legality = card.legalities[fmt] {
                    HStack {
                        Text(fmt.capitalized).font(.caption)
                        Spacer()
                        Text(legality.capitalized).font(.caption)
                            .font(.caption)
                            .foregroundStyle(legality.lowercased() == "legal" ? .green : .red)
                    }
                }
            }
        }
    }
}

struct QuantitySection: View {
    @Bindable var card: Card
    var body: some View {
        Stepper("Quantity: \(card.quantity)", value: $card.quantity, in: 1...99)
    }
}

// MARK: – Tags

/// Horizontal list of a card’s tags with color dots and delete‑on‑tap.
/// `onAdd` is a callback for the enclosing view to present an “add tag” sheet.
struct TagsSection: View {
    @Bindable var card: Card
    var colorScheme: ColorScheme
    var onAdd: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Tags")
                    .font(.headline)
                Spacer()
                Button(action: onAdd) {
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
                                .overlay(
                                    Circle()
                                        .stroke(
                                            Color.tagBorder(
                                                colorName: tag.color,
                                                colorScheme: colorScheme
                                            ),
                                            lineWidth: 1
                                        )
                                )
                            Text(tag.name)
                                .foregroundColor(
                                    Color.tagText(
                                        colorName: tag.color,
                                        colorScheme: colorScheme
                                    )
                                )
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(
                            Color.tagBackground(
                                colorName: tag.color,
                                colorScheme: colorScheme
                            )
                        )
                        .overlay(
                            Capsule()
                                .stroke(
                                    Color.tagBorder(
                                        colorName: tag.color,
                                        colorScheme: colorScheme
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .clipShape(Capsule())
                        .onTapGesture {
                            if let idx = card.tags.firstIndex(
                                where: { $0.name == tag.name }
                            ) {
                                card.tags.remove(at: idx)
                            }
                        }
                    }
                }
            }
            .frame(height: card.tags.isEmpty ? 0 : nil)
        }
    }
}

// MARK: – Attributes (rarity, colors, keywords, etc.)

/// Compact block that lists rarity, reserved‑list flag, colors, identity, and keywords.
/// Pure display; no state.
struct CardAttributesSection: View {
    @Bindable var card: Card

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Rarity and Reserved List
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

            // Colors
            if !card.colors.isEmpty {
                Text("Colors: \(card.colors.joined(separator: ", "))")
                    .font(.subheadline)
            }

            // Color Identity
            if !card.colorIdentity.isEmpty {
                Text("Color Identity: \(card.colorIdentity.joined(separator: ", "))")
                    .font(.subheadline)
            }

            // Keywords
            if !card.keywords.isEmpty {
                Text("Keywords: \(card.keywords.joined(separator: ", "))")
                    .font(.subheadline)
            }
        }
    }
}

// MARK: – Add‑Tag Sheet

/// A reusable sheet for searching existing tags or creating a new one.
/// It dismisses itself via the `isPresented` binding.
struct AddTagSheet: View {
    @Bindable var card: Card
    @Binding var isPresented: Bool

    @Environment(\.modelContext) private var modelContext
    @State private var tagSearch = ""

    var body: some View {
        NavigationStack {
            List {
                // Search field
                Section {
                    TextField("Search tags…", text: $tagSearch)
                }

                // Existing tags
                Section {
                    let existingTags = try? modelContext.fetch(
                        FetchDescriptor<Tag>(sortBy: [SortDescriptor(\.name)])
                    )
                    if let tags = existingTags {
                        ForEach(tags.filter { tag in
                            !card.tags.contains { $0.name == tag.name } &&
                            (tagSearch.isEmpty || tag.name.localizedCaseInsensitiveContains(tagSearch))
                        }, id: \.name) { tag in
                            HStack {
                                Circle()
                                    .fill(Color(tag.color))
                                    .frame(width: 12, height: 12)
                                    .overlay(Circle().stroke(Color.primary, lineWidth: 1))
                                Text(tag.name)
                                if let cat = tag.category {
                                    Spacer()
                                    Text(cat)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                card.tags.append(tag)
                                isPresented = false
                                tagSearch = ""
                            }
                        }
                    }
                } header: { Text("Existing Tags") }

                // Create new tag
                if !tagSearch.trimmingCharacters(in: .whitespaces).isEmpty {
                    Section {
                        Button("Create \"\(tagSearch)\"") {
                            let trimmed = tagSearch.trimmingCharacters(in: .whitespaces)
                            guard !trimmed.isEmpty else { return }
                            let tag = Tag(name: trimmed)
                            modelContext.insert(tag)
                            card.tags.append(tag)
                            isPresented = false
                            tagSearch = ""
                        }
                    }
                }
            }
            .navigationTitle("Add Tag")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                        tagSearch = ""
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
}
