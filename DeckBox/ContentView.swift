//
//  CardListView.swift
//  DeckBox
//
//  Created by Carter Besson on 5/24/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        CardListView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Card.self, inMemory: true)
}
