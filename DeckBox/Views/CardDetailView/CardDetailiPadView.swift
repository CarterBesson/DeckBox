//
//  CardDetailiPadView.swift
//  DeckBox
//
//  Created by Carter Besson on 6/27/25.
//

import SwiftUI
import SwiftData

struct CardDetailiPadView: View {
    @Bindable var card: Card
    @Environment(\.colorScheme) private var colorScheme
    @State private var isAddingTag = false
    private let shownFormats = ["standard", "modern", "commander"]
    
    var body: some View {
        HStack(alignment: .top, spacing: 24) {
            
            //Fixed-width image column
            CardImageSection(card: card)
                .frame(width: 300)
            // Scrollable right column
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // show metadata for each face (or single face if no split)
                    if card.faces.isEmpty {
                        CardMetadataSection(card: card, face: nil)
                        Divider()
                    } else {
                        ForEach(card.faces, id: \.self) { face in
                            CardMetadataSection(card: card, face: face)
                            Divider()
                        }
                    }
                    LegalitiesSection(card: card, shownFormats: shownFormats)
                    Divider()
                    QuantitySection(card: card)
                    TagsSection(card: card,
                                colorScheme: colorScheme,
                                onAdd: { isAddingTag = true })
                }
                .padding(.vertical)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal)
        .navigationTitle(card.name)
        .sheet(isPresented: $isAddingTag) {
            AddTagSheet(card: card, isPresented: $isAddingTag)
        }
    }
}
