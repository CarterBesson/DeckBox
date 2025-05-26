//
//  CardListView.swift
//  DeckBox
//
//  Created by Carter Besson on 5/24/25.
//
import SwiftUI
import SwiftData

struct CardListView: View {
    @Query(sort: \Card.name) private var cards: [Card]
    @Query(sort: \Tag.name) private var allTags: [Tag]
    @Environment(\.modelContext) private var modelContext

    @State private var isAdding = false
    @State private var isScanning = false
    @State private var selectedTag: Tag? = nil
    @State private var searchText = ""
    
    private var filteredCards: [Card] {
        let tagFiltered = selectedTag == nil ? cards : cards.filter { $0.tags.contains(where: { $0.id == selectedTag?.id }) }
        
        if searchText.isEmpty {
            return tagFiltered
        }
        
        return tagFiltered.filter { card in
            card.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
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
    
    private var tagFilterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // All cards filter
                HStack(spacing: 4) {
                    Image(systemName: "tag")
                    Text("All")
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(selectedTag == nil ? Color.mtgBlue.opacity(0.2) : Color.clear)
                .overlay(
                    Capsule()
                        .strokeBorder(selectedTag == nil ? Color.mtgBlue : Color.clear, lineWidth: 1)
                )
                .clipShape(Capsule())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTag = nil
                    }
                }
                
                // Group tags by category
                let groupedTags = Dictionary(grouping: allTags) { $0.category ?? "" }
                ForEach(groupedTags.keys.sorted(), id: \.self) { category in
                    if let tags = groupedTags[category] {
                        Group {
                            if !category.isEmpty {
                                Divider()
                                Text(category)
                                    .font(.caption)
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
                                    Text("\(tag.cards.count)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(isSelected ? tagColor.opacity(0.2) : Color.clear)
                                .overlay(
                                    Capsule()
                                        .strokeBorder(isSelected ? tagColor : Color.clear, lineWidth: 1)
                                )
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
            }
            .padding(.horizontal)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                tagFilterView
                    .padding(.vertical, 8)
                
                Divider()
                
                List {
                    ForEach(filteredCards) { card in
                        NavigationLink(value: card) {
                            HStack {
                                Text(card.name)
                                    .font(.headline)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                // Show tags inline
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
                
                searchBar
            }
            .navigationTitle("My Cards")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isAdding = true
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isScanning = true
                    } label: {
                        Label("Scan", systemImage: "camera")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        TagManagementView()
                    } label: {
                        Label("Manage Tags", systemImage: "tag")
                    }
                }
            }
            .sheet(isPresented: $isAdding) {
                AddCardView()
            }
            .sheet(isPresented: $isScanning) {
                CardScannerView(
                    onScannedText: { scannedName in
                        Task {
                            do {
                                let dto = try await ScryfallService().fetchCard(named: scannedName)
                                let card = Card(from: dto)
                                modelContext.insert(card)
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
    }
    
    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(cards[index])
        }
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
          let card = Card(from: dto)
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
