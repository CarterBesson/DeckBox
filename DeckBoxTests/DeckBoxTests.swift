//
//  DeckBoxTests.swift
//  DeckBoxTests
//
//  Created by Carter Besson on 5/24/25.
//

import Testing
@testable import DeckBox

struct DeckBoxTests {

    @Test("setQuantity > 0 adds card")
    func testSetQuantityAddsCard() async throws {
        let card = Card(game: "Magic", name: "Island", quantity: 4)
        let group = CardGroup(name: "Test Group", type: nil)

        group.setQuantity(3, for: card)

        #expect(group.cards.contains(where: { $0.id == card.id }))
        #expect(group.quantity(for: card) == 3)
    }

    @Test("setQuantity 0 removes card")
    func testSetQuantityRemovesCard() async throws {
        let card = Card(game: "Magic", name: "Island", quantity: 4)
        let group = CardGroup(name: "Test Group", type: nil)

        group.setQuantity(2, for: card)
        group.setQuantity(0, for: card)

        #expect(!group.cards.contains(where: { $0.id == card.id }))
        #expect(group.quantity(for: card) == 0)
    }

}
