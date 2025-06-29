//
//  CardDetailRouter.swift
//  DeckBox
//
//  Created by Carter Besson on 6/28/25.
//

import SwiftUI
import SwiftData


/// Call **this** from anywhere else in the app instead of the old CardDetailView.
struct CardDetailRouter: View {
    @Bindable var card: Card
    @Environment(\.horizontalSizeClass) private var hSizeClass

    var body: some View {
        Group {
            if hSizeClass == .regular {
                CardDetailiPadView(card: card)
            } else {
                CardDetailiPhoneView(card: card)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Card.self, inMemory: true)
}
