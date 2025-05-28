//
//  Tag.swift
//  DeckBox
//
//  Created by Carter Besson on 5/27/25.
//

import Foundation
import SwiftData

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
