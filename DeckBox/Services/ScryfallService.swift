// MARK: - Card Data Services
/// Services for fetching card data from external APIs.
/// Currently implements Scryfall.com as the primary data source.

import Foundation
import SwiftData

// MARK: - Card Data Service Protocol
/// Protocol defining the interface for card data services
/// Allows for easy swapping of different card data providers
protocol CardDataService {
    /// Fetches a card by name using fuzzy matching
    /// - Parameter name: The name of the card to search for
    /// - Returns: A CardDTO containing the card's data
    /// - Throws: An error if the card is not found or if there's a network error
    func fetchCard(named name: String) async throws -> CardDTO
}

// MARK: - Card Data Transfer Object
/// Data transfer object for card information
/// Maps only the fields we need from the external API response
struct CardDTO: Decodable {
    /// The name of the card
    let name: String
    
    /// The set/expansion code (e.g., "NEO" for Kamigawa: Neon Dynasty)
    let set: String
    
    /// The collector number within the set
    let collector_number: String
    
    /// Dictionary of available card images at different sizes
    /// Keys are size names (e.g., "normal", "large"), values are URLs
    let image_uris: [String: URL]?
    
    /// The card's mana cost (e.g., "{2}{W}{W}")
    let mana_cost: String?
    
    /// The converted mana cost or mana value of the card
    let cmc: Double
    
    /// The type line of the card (e.g., "Legendary Creature — Human Warrior")
    let type_line: String
    
    /// The oracle text of the card
    let oracle_text: String?
    
    /// The flavor text of the card, if any
    let flavor_text: String?
    
    /// Power, if the card is a creature
    let power: String?
    
    /// Toughness, if the card is a creature
    let toughness: String?
    
    /// Loyalty, if the card is a planeswalker
    let loyalty: String?
    
    /// The card's rarity (common, uncommon, rare, mythic)
    let rarity: String
    
    /// The set name this card is from
    let set_name: String
    
    /// Whether this card is on the Reserved List
    let reserved: Bool
    
    /// The card's artist
    let artist: String?
    
    /// The card's color identity in Magic rules
    let color_identity: [String]
    
    /// The card's colors, if any
    let colors: [String]?
    
    /// Keywords present on the card
    let keywords: [String]
    
    /// Legality in various formats (standard, modern, etc)
    let legalities: [String: String]

    enum CodingKeys: String, CodingKey {
        case name, set, collector_number, image_uris
        case mana_cost, cmc, type_line, oracle_text
        case flavor_text, power, toughness, loyalty
        case rarity, set_name, reserved
        case artist, color_identity, colors, keywords
        case legalities
    }
}

// MARK: - Scryfall Service Implementation
/// Implementation of CardDataService using Scryfall.com's API
/// Provides card data lookup with fuzzy name matching
struct ScryfallService: CardDataService {
    /// Shared URL session for making network requests
    private let session: URLSession = .shared

    /// Fetches card data from Scryfall using fuzzy name matching
    /// - Parameter name: The name of the card to search for
    /// - Returns: A CardDTO containing the matched card's data
    /// - Throws: URLError for bad URLs, NSError for 404s, and other network errors
    func fetchCard(named name: String) async throws -> CardDTO {
        // Percent-encode the query for URL safety
        guard let query = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw URLError(.badURL)
        }
        
        // Create and execute the API request
        let url = URL(string: "https://api.scryfall.com/cards/named?fuzzy=\(query)")!
        let (data, response) = try await session.data(from: url)
        
        // Handle 404 responses (Scryfall returns 404 with JSON error details)
        if let http = response as? HTTPURLResponse, http.statusCode == 404 {
            let msg = try JSONDecoder().decode([String:String].self, from: data)["details"] ?? "Card not found"
            throw NSError(domain: "ScryfallService", code: 404, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        
        // Decode the response into our DTO
        let decoder = JSONDecoder()
        return try decoder.decode(CardDTO.self, from: data)
    }
}

// MARK: - Card Model Extensions
extension Card {
    /// Creates a new Card instance from a CardDTO
    /// - Parameter dto: The data transfer object containing card data
    /// - Parameter modelContext: The SwiftData model context for creating tags
    convenience init(from dto: CardDTO, modelContext: ModelContext) {
        self.init(
            game: "MTG",
            name: dto.name,
            setCode: dto.set,
            setName: dto.set_name,
            collectorNumber: dto.collector_number,
            quantity: 1,
            imageURL: dto.image_uris?["normal"],
            manaCost: dto.mana_cost,
            cmc: dto.cmc,
            typeLine: dto.type_line,
            oracleText: dto.oracle_text,
            flavorText: dto.flavor_text,
            power: dto.power,
            toughness: dto.toughness,
            loyalty: dto.loyalty,
            rarity: dto.rarity,
            isReserved: dto.reserved,
            artist: dto.artist,
            colorIdentity: dto.color_identity,
            colors: dto.colors ?? [],
            keywords: dto.keywords,
            legalities: dto.legalities,
            tags: []
        )
        
        // Automatically add tags based on card attributes
        if dto.reserved {
            addReservedListTag(modelContext: modelContext)
        }
        addRarityTag(dto.rarity, modelContext: modelContext)
    }
    
    /// Adds the Reserved List tag to the card if it doesn't already exist
    private func addReservedListTag(modelContext: ModelContext) {
        // Try to find existing Reserved List tag
        let descriptor = FetchDescriptor<Tag>(
            predicate: #Predicate<Tag> { tag in
                tag.name == "Reserved List"
            }
        )
        
        if let existingTag = try? modelContext.fetch(descriptor).first {
            if !tags.contains(where: { $0.id == existingTag.id }) {
                tags.append(existingTag)
            }
        } else {
            let tag = Tag(name: "Reserved List", color: "gold", category: "Special")
            modelContext.insert(tag)
            tags.append(tag)
        }
    }
    
    /// Adds a rarity tag to the card if it doesn't already exist
    /// - Parameters:
    ///   - rarity: The rarity string from Scryfall
    ///   - modelContext: The SwiftData model context for creating tags
    private func addRarityTag(_ rarity: String, modelContext: ModelContext) {
        let tagName = rarity.capitalized
        
        // Try to find existing rarity tag
        let descriptor = FetchDescriptor<Tag>(
            predicate: #Predicate<Tag> { tag in
                tag.name == tagName
            }
        )
        
        if let existingTag = try? modelContext.fetch(descriptor).first {
            if !tags.contains(where: { $0.id == existingTag.id }) {
                tags.append(existingTag)
            }
        } else {
            let color: String
            switch rarity.lowercased() {
            case "common": color = "mtgWhite"
            case "uncommon": color = "mtgBlue"
            case "rare": color = "gold"
            case "mythic": color = "mtgRed"
            default: color = "mtgBlue"
            }
            
            let tag = Tag(name: tagName, color: color, category: "Rarity")
            modelContext.insert(tag)
            tags.append(tag)
        }
    }
}
