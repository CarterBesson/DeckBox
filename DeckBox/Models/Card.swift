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
    
    /// The full name of the set/expansion
    var setName: String?
    
    /// The collector number within the set (optional)
    var collectorNumber: String?
    
    /// The quantity of this card owned by the user
    var quantity: Int = 1
    
    /// URL to the card's image, if available
    var imageURL: URL? = nil
    
    /// The card's mana cost (e.g., "{2}{W}{W}")
    var manaCost: String?
    
    /// The converted mana cost or mana value of the card
    var cmc: Double = 0
    
    /// The type line of the card (e.g., "Legendary Creature — Human Warrior")
    var typeLine: String = ""
    
    /// The oracle text of the card
    var oracleText: String?
    
    /// The flavor text of the card
    var flavorText: String?
    
    /// Power, if the card is a creature
    var power: String?
    
    /// Toughness, if the card is a creature
    var toughness: String?
    
    /// Loyalty, if the card is a planeswalker
    var loyalty: String?
    
    /// The card's rarity (common, uncommon, rare, mythic)
    var rarity: String = ""
    
    /// Whether this card is on the Reserved List
    var isReserved: Bool = false
    
    /// The card's artist
    var artist: String?
    
    /// The card's color identity in Magic rules
    var colorIdentity: [String] = []
    
    /// The card's colors, if any
    var colors: [String] = []
    
    /// Keywords present on the card
    var keywords: [String] = []
    
    /// Legality in various formats (standard, modern, etc)
    var legalities: [String: String] = [:]
    
    /// Last time the card data was updated from Scryfall
    var lastUpdated: Date = Date()
    
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
    ///   - setName: The full name of the set/expansion (optional)
    ///   - collectorNumber: The collector number within the set (optional)
    ///   - quantity: Number of copies owned (defaults to 1)
    ///   - imageURL: URL to the card's image (optional)
    ///   - manaCost: The card's mana cost (optional)
    ///   - cmc: The converted mana cost or mana value of the card
    ///   - typeLine: The type line of the card (optional)
    ///   - oracleText: The oracle text of the card (optional)
    ///   - flavorText: The flavor text of the card (optional)
    ///   - power: Power, if the card is a creature (optional)
    ///   - toughness: Toughness, if the card is a creature (optional)
    ///   - loyalty: Loyalty, if the card is a planeswalker (optional)
    ///   - rarity: The card's rarity (optional)
    ///   - isReserved: Whether this card is on the Reserved List (optional)
    ///   - artist: The card's artist (optional)
    ///   - colorIdentity: The card's color identity in Magic rules (optional)
    ///   - colors: The card's colors, if any (optional)
    ///   - keywords: Keywords present on the card (optional)
    ///   - legalities: Legality in various formats (optional)
    ///   - tags: Array of tags associated with the card (optional)
    init(game: String,
         name: String,
         setCode: String? = nil,
         setName: String? = nil,
         collectorNumber: String? = nil,
         quantity: Int = 1,
         imageURL: URL? = nil,
         manaCost: String? = nil,
         cmc: Double = 0,
         typeLine: String = "",
         oracleText: String? = nil,
         flavorText: String? = nil,
         power: String? = nil,
         toughness: String? = nil,
         loyalty: String? = nil,
         rarity: String = "",
         isReserved: Bool = false,
         artist: String? = nil,
         colorIdentity: [String] = [],
         colors: [String] = [],
         keywords: [String] = [],
         legalities: [String: String] = [:],
         tags: [Tag] = []) {
        self.game = game
        self.name = name
        self.setCode = setCode
        self.setName = setName
        self.collectorNumber = collectorNumber
        self.quantity = quantity
        self.imageURL = imageURL
        self.manaCost = manaCost
        self.cmc = cmc
        self.typeLine = typeLine
        self.oracleText = oracleText
        self.flavorText = flavorText
        self.power = power
        self.toughness = toughness
        self.loyalty = loyalty
        self.rarity = rarity
        self.isReserved = isReserved
        self.artist = artist
        self.colorIdentity = colorIdentity
        self.colors = colors
        self.keywords = keywords
        self.legalities = legalities
        self.tags = tags
        self.lastUpdated = Date()
    }
}
