//
//  Card.swift
//  DeckBox
//
//  Created by Carter Besson on 5/24/25.
//
import Foundation
import SwiftData

//Trading-card model
@Model
final class Card{
    @Attribute(.unique) var id: UUID = UUID()
    var game: String = ""
    var name: String = ""
    var setCode: String?
    var collectorNumber: String?
    var quantity: Int = 1
    var imageURL: URL? = nil
    
    @Relationship(deleteRule: .cascade) var tags: [Tag] = []
    
    init(game: String,
         name: String,
         setCode: String? = nil,
         collectorNumber: String? = nil,
         quantity: Int = 1,
         imageURL: URL? = nil,
         tags: [Tag] = []) {
        self.game = game
        self.name = name
        self.setCode = setCode
        self.collectorNumber = collectorNumber
        self.quantity = quantity
        self.tags = tags
        self.imageURL = imageURL
    }
}

@Model
final class Tag {
    @Attribute(.unique) var id: UUID = UUID()
    @Attribute(.unique) var name: String
    var color: String = "blue"  // Store as hex or named color
    var category: String?       // Optional category for organizing tags
    var createdAt: Date = Date()
    @Relationship(inverse: \Card.tags) var cards: [Card] = []
    
    init(name: String, color: String = "blue", category: String? = nil) {
        self.id = UUID()
        self.name = name
        self.color = color
        self.category = category
    }
}
