//
//  SearchView.swift
//  DeckBox
//
//  Created by Carter Besson on 5/24/25.
//

import SwiftUI
import SwiftData

struct SearchView: View {
    @State private var searchText = ""
    @Query(sort: \Card.name) private var cards: [Card]
    
    private var filteredCards: [Card] {
        if searchText.isEmpty {
            return []
        }
        return cards.filter { card in
            card.name.localizedCaseInsensitiveContains(searchText) ||
            card.tags.contains(where: { $0.name.localizedCaseInsensitiveContains(searchText) }) ||
            (card.setName?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            card.typeLine.localizedCaseInsensitiveContains(searchText) ||
            (card.oracleText?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            card.colorIdentity.contains(where: { $0.localizedCaseInsensitiveContains(searchText) }) ||
            card.keywords.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
        }
    }
    
    var body: some View {
        List {
            ForEach(filteredCards) { card in
                NavigationLink(value: card) {
                    VStack(alignment: .leading) {
                        Text(card.name)
                            .font(.headline)
                        if let setName = card.setName {
                            Text(setName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search cards...")
        .navigationDestination(for: Card.self) { card in
            CardDetailView(card: card)
        }
    }
}

#Preview {
    NavigationStack {
        SearchView()
    }
    .modelContainer(for: Card.self, inMemory: true)
} 