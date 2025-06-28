//
//  CardDetailiPhoneView.swift
//  DeckBox
//
//  Created by Carter Besson on 6/27/25.
//

import SwiftUI
import SwiftData

struct CardDetailiPhoneView: View {
    @Bindable var card: Card
    @Environment(\.colorScheme) private var colorScheme
    private let shownFormats = ["standard", "modern", "commander"]
    
    private var currentFace: CardFace? {
        card.faces.first
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                CardImageSection(card: card)
                CardMetadataSection(card: card, face: currentFace)
                Divider()
                LegalitiesSection(card: card, shownFormats: shownFormats)
                Divider()
                QuantitySection(card: card)
                TagsSection(card: card, colorScheme: colorScheme)
            }
            .padding()
        }
        .navigationTitle(card.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
