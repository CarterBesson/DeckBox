//
//  Card.swift
//  DeckBox
//
//  Created by Carter Besson on 5/24/25.
//

// MARK: - Card Model
/// Represents a trading card in the system.
/// This model stores all relevant information about a single unique card, including its
/// game, name, set information, quantity owned, and associated metadata.

import Foundation
import SwiftData

//Trading-card model
@Model
final class Card{
    /// Unique identifier for the card
    @Attribute(.unique) var id: UUID = UUID()
    
    /// The game this card belongs to (e.g., "Magic: The Gathering", "Pokemon")
    var game: String = ""
    
    /// The name of the card as it appears on the physical card
    var name: String = ""
    
    /// The set/expansion code this card belongs to (optional)
    var setCode: String?
    
    /// The collector number within the set (optional)
    var collectorNumber: String?
    
    /// The quantity of this card owned by the user
    var quantity: Int = 1
    
    /// URL to the card's image, if available
    var imageURL: URL? = nil
    
    /// Tags associated with this card (e.g., "Rare", "Foil", "Reserved List")
    /// Will be deleted when the card is deleted (cascade)
    @Relationship(deleteRule: .cascade) var tags: [Tag] = []
    
    /// Groups this card belongs to (e.g., decks, collections)
    /// Card-group relationship will be nullified when card is deleted
    @Relationship(deleteRule: .nullify) var groups: [CardGroup] = []
    
    /// Creates a new Card instance with the specified properties
    /// - Parameters:
    ///   - game: The game this card belongs to
    ///   - name: The name of the card
    ///   - setCode: The set/expansion code (optional)
    ///   - collectorNumber: The collector number within the set (optional)
    ///   - quantity: Number of copies owned (defaults to 1)
    ///   - imageURL: URL to the card's image (optional)
    ///   - tags: Array of tags associated with the card (defaults to empty)
    init(game: String,
         name: String,
         setCode: String? = nil,
         collectorNumber: String? = nil,
         quantity: Int = 1,
         imageURL: URL? = nil,
         tags: [Tag] = [] ) {
        self.game = game
        self.name = name
        self.setCode = setCode
        self.collectorNumber = collectorNumber
        self.quantity = quantity
        self.tags = tags
        self.imageURL = imageURL
    }
}
