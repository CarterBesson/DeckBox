//
//  CardDetailView.swift
//  DeckBox
//
//  Created by Carter Besson on 5/24/25.
//

import SwiftUI
import SwiftData

struct CardDetailView: View {
    @Bindable var card: Card             // SwiftData auto–bindable
    @Environment(\.modelContext) private var modelContext

    @State private var isAddingTag = false
    @State private var newTagName   = ""

    // MARK: – Subviews

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

    private var addTagSheet: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Search tags...", text: $newTagName)
                }
                
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
                // Card name
                Text(card.name)
                    .font(.title2)
                    .bold()

                // Set code & collector number
                HStack {
                    Text(card.setCode ?? "")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("#\(card.collectorNumber ?? "–")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Quantity stepper
                Stepper("Quantity: \(card.quantity)",
                        value: $card.quantity,
                        in: 1...99)

                // Tags
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

#Preview {
    ContentView()
        .modelContainer(for: Card.self, inMemory: true)
}
