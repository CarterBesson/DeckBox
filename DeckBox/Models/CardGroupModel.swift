// MARK: - Card Organization Models
/// This file contains models for organizing cards into groups (decks, cubes, collections)
/// and defining different types of groups with their own rules and characteristics.

import Foundation
import SwiftData

// MARK: - Group Type
/// Represents a category of card groups (e.g., Decks, Cubes)
/// Defines the characteristics and rules for groups of that type
@Model
class GroupType {
    /// Unique identifier for the group type
    @Attribute(.unique) var id: UUID
    
    /// Name of the group type (e.g., "Decks", "Cubes")
    var name: String
    
    /// SF Symbol name for the icon representing this type
    var iconName: String
    
    /// Whether this is a built-in type that can't be modified by users
    var isBuiltIn: Bool
    
    /// Additional metadata for storing type-specific rules and settings
    /// This will be useful later for custom rules and restrictions
    var metadata: [String: String]
    
    /// Groups of this type (e.g., all decks if this is the "Decks" type)
    /// Will be deleted when the group type is deleted (cascade)
    @Relationship(deleteRule: .cascade)
    var groups: [CardGroup] = []
    
    /// Creates a new GroupType instance
    /// - Parameters:
    ///   - name: Name of the group type
    ///   - iconName: SF Symbol name for the icon
    ///   - isBuiltIn: Whether this is a system-defined type
    init(name: String, iconName: String, isBuiltIn: Bool = false) {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
        self.isBuiltIn = isBuiltIn
        self.metadata = [:]
    }
    
    /// Returns the default built-in group types for the application
    static var builtInTypes: [GroupType] {
        [
            GroupType(name: "Decks", iconName: "rectangle.on.rectangle", isBuiltIn: true),
            GroupType(name: "Cubes", iconName: "square.stack.3d.up", isBuiltIn: true)
        ]
    }
}

// MARK: - Card Group
/// Represents a collection of cards (e.g., a deck, cube, or other collection)
/// Tracks both the cards in the group and their quantities
@Model
class CardGroup {
    /// Unique identifier for the group
    @Attribute(.unique) var id: UUID
    
    /// Name of the group (e.g., "Modern Burn", "Vintage Cube")
    var name: String
    
    /// Maps card IDs to their quantities in this group
    var cardQuantities: [UUID: Int]
    
    /// The type of this group (e.g., Deck, Cube)
    /// Relationship will be nullified if the type is deleted
    @Relationship(deleteRule: .nullify, inverse: \GroupType.groups)
    var type: GroupType?
    
    /// The deck format for this group, if this is a deck (e.g., Standard, Modern, Commander)
    var deckFormat: DeckFormat?
    
    /// Cards that are part of this group
    /// Many-to-many relationship with Card model
    @Relationship(deleteRule: .nullify, inverse: \Card.groups)
    var cards: [Card]
    
    /// Creates a new CardGroup instance
    /// - Parameters:
    ///   - name: Name of the group
    ///   - type: Type of the group (optional)
    ///   - cards: Initial cards in the group (defaults to empty)
    init(name: String, type: GroupType?, cards: [Card] = []) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.cards = cards
        self.cardQuantities = [:]
    }
    
    /// Gets the quantity of a specific card in this group
    /// - Parameter card: The card to check
    /// - Returns: The quantity of the card in this group (0 if not present)
    func quantity(for card: Card) -> Int {
        return cardQuantities[card.id] ?? 0
    }
    
    /// Sets the quantity of a specific card in this group
    /// - Parameters:
    ///   - quantity: The new quantity to set (0 or negative to remove)
    ///   - card: The card to update
    /// If quantity is 0 or negative, removes the card from the group
    /// Otherwise, adds or updates the card's quantity (limited by available copies)
    func setQuantity(_ quantity: Int, for card: Card) {
        if quantity <= 0 {
            cardQuantities.removeValue(forKey: card.id)
            cards.removeAll { $0.id == card.id }
        } else {
            cardQuantities[card.id] = min(quantity, card.quantity)
            if !cards.contains(where: { $0.id == card.id }) {
                cards.append(card)
            }
        }
    }
}

