// MARK: - Tag Model
/// Represents a tag that can be applied to cards for organization and filtering.
/// Tags provide a flexible way to categorize and group cards based on various attributes
/// such as rarity, condition, or any user-defined criteria.

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
    /// Unique identifier for the tag
    @Attribute(.unique) var id: UUID = UUID()
    
    /// Unique name of the tag (e.g., "Foil", "Damaged", "Reserved List")
    @Attribute(.unique) var name: String
    
    /// Color used to visually represent the tag in the UI
    /// Can be a named color or hex value
    var color: String = "blue"
    
    /// Optional category to organize tags into groups
    /// (e.g., "Condition", "Rarity", "Special Attributes")
    var category: String?
    
    /// Timestamp when the tag was created
    var createdAt: Date = Date()
    
    /// Cards that have this tag applied
    /// Inverse relationship to Card.tags
    @Relationship(inverse: \Card.tags) var cards: [Card] = []
    
    /// Creates a new Tag instance
    /// - Parameters:
    ///   - name: Unique name for the tag
    ///   - color: Color to represent the tag (defaults to "blue")
    ///   - category: Optional category for organizing tags
    init(name: String, color: String = "blue", category: String? = nil) {
        self.id = UUID()
        self.name = name
        self.color = color
        self.category = category
    }
}
