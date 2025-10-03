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
    
    /// Whether this card has multiple faces
    let card_faces: [CardFaceDTO]?
    
    /// The layout of the card (e.g., "normal", "split", "transform")
    let layout: String

    enum CodingKeys: String, CodingKey {
        case name, set, collector_number, image_uris
        case mana_cost, cmc, type_line, oracle_text
        case flavor_text, power, toughness, loyalty
        case rarity, set_name, reserved
        case artist, color_identity, colors, keywords
        case legalities, card_faces, layout
    }
}

/// Data transfer object for a single face of a double-sided card
struct CardFaceDTO: Decodable {
    /// The name of this face
    let name: String
    
    /// Dictionary of available card images at different sizes
    let image_uris: [String: URL]?
    
    /// The card's mana cost
    let mana_cost: String?
    
    /// The type line of the card
    let type_line: String
    
    /// The oracle text of the card
    let oracle_text: String?
    
    /// The flavor text of the card
    let flavor_text: String?
    
    /// Power, if the card is a creature
    let power: String?
    
    /// Toughness, if the card is a creature
    let toughness: String?
    
    /// Loyalty, if the card is a planeswalker
    let loyalty: String?
    
    /// The card's artist
    let artist: String?
    
    /// The card's colors
    let colors: [String]?
}

// MARK: - Scryfall Rate Limiter
/// Manages rate limiting for Scryfall API requests
/// Ensures we don't exceed Scryfall's recommended limits
actor ScryfallRateLimiter {
    /// Minimum delay between requests (in seconds)
    private let minDelay: TimeInterval = 0.1 // 100ms between requests
    
    /// Time of the last request
    private var lastRequestTime: Date = .distantPast
    
    /// Waits if necessary to maintain the rate limit
    func waitForNextRequest() async {
        let now = Date()
        let timeSinceLastRequest = now.timeIntervalSince(lastRequestTime)
        
        if timeSinceLastRequest < minDelay {
            let waitTime = minDelay - timeSinceLastRequest
            try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
        }
        
        lastRequestTime = Date()
    }
}

// MARK: - Scryfall Service Implementation
/// Implementation of CardDataService using Scryfall.com's API
/// Provides card data lookup with fuzzy name matching
struct ScryfallService: CardDataService {
    /// Shared URL session for making network requests
    private let session: URLSession = .shared
    
    /// Rate limiter to ensure we don't exceed Scryfall's limits
    private let rateLimiter = ScryfallRateLimiter()
    
    /// Maximum number of retries for rate-limited requests
    private let maxRetries = 3

    /// Fetches card data from Scryfall using fuzzy name matching
    /// - Parameter name: The name of the card to search for
    /// - Returns: A CardDTO containing the matched card's data
    /// - Throws: URLError for bad URLs, NSError for 404s, and other network errors
    func fetchCard(named name: String) async throws -> CardDTO {
        // Percent-encode the query for URL safety
        guard let query = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw URLError(.badURL)
        }
        
        var retryCount = 0
        while true {
            do {
                // Wait for rate limiter before making request
                await rateLimiter.waitForNextRequest()
                
                // Create and execute the API request
                let url = URL(string: "https://api.scryfall.com/cards/named?fuzzy=\(query)")!
                var request = URLRequest(url: url)
                request.setValue("DeckBox/1.0 (https://github.com/carterbesson/deckbox; carterbesson@email.com)", forHTTPHeaderField: "User-Agent")
                request.setValue("application/json", forHTTPHeaderField: "Accept")
                let (data, response) = try await session.data(for: request)
                
                // Handle HTTP status codes
                if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 200:
                        // Success - decode the response
                        let decoder = JSONDecoder()
                        return try decoder.decode(CardDTO.self, from: data)
                        
                    case 404:
                        // Card not found
                        let msg = try JSONDecoder().decode([String:String].self, from: data)["details"] ?? "Card not found"
                        throw NSError(domain: "ScryfallService", code: 404, userInfo: [NSLocalizedDescriptionKey: msg])
                        
                    case 429:
                        // Rate limited - retry after delay if we haven't exceeded max retries
                        if retryCount < maxRetries {
                            retryCount += 1
                            // Exponential backoff: wait longer with each retry
                            try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(retryCount)) * 1_000_000_000))
                            continue
                        }
                        throw NSError(domain: "ScryfallService", code: 429, userInfo: [NSLocalizedDescriptionKey: "Rate limit exceeded"])
                        
                    default:
                        throw URLError(.badServerResponse)
                    }
                }
                
                // If we can't cast to HTTPURLResponse, something is wrong
                throw URLError(.badServerResponse)
            } catch {
                // If this was a retry and we got an error, throw it
                if retryCount > 0 {
                    throw error
                }
                // Otherwise, if it's a network error, retry once
                if (error as? URLError)?.code == .networkConnectionLost {
                    retryCount += 1
                    continue
                }
                // For all other errors, throw immediately
                throw error
            }
        }
    }
}

// MARK: - Card Model Extensions
extension Card {
    // MARK: - Resolved metadata helpers
    struct ResolvedFaceData {
        let name: String
        let imageURL: URL?
        let manaCost: String?
        let typeLine: String
        let oracleText: String?
        let flavorText: String?
        let power: String?
        let toughness: String?
        let loyalty: String?
        let artist: String?
        let colors: [String]
    }

    struct ResolvedCardData {
        let imageURL: URL?
        let faces: [ResolvedFaceData]
        let manaCost: String?
        let typeLine: String
        let oracleText: String?
        let flavorText: String?
        let power: String?
        let toughness: String?
        let loyalty: String?
        let artist: String?
        let colors: [String]
    }

    private static let imagePreferenceOrder = [
        "normal",
        "large",
        "png",
        "border_crop",
        "art_crop",
        "small"
    ]

    static func resolvedData(from dto: CardDTO) -> ResolvedCardData {
        let cardLevelImage = preferredImageURL(from: dto.image_uris)

        let faceData: [ResolvedFaceData] = (dto.card_faces ?? []).map { face in
            let faceImage = preferredImageURL(from: face.image_uris, fallback: cardLevelImage)
            return ResolvedFaceData(
                name: face.name,
                imageURL: faceImage,
                manaCost: face.mana_cost,
                typeLine: face.type_line,
                oracleText: face.oracle_text,
                flavorText: face.flavor_text,
                power: face.power,
                toughness: face.toughness,
                loyalty: face.loyalty,
                artist: face.artist,
                colors: face.colors ?? []
            )
        }

        let primaryFace = faceData.first
        let resolvedImage = preferredImageURL(from: dto.image_uris, fallback: primaryFace?.imageURL)

        return ResolvedCardData(
            imageURL: resolvedImage,
            faces: faceData,
            manaCost: primaryFace?.manaCost ?? dto.mana_cost,
            typeLine: primaryFace?.typeLine ?? dto.type_line,
            oracleText: primaryFace?.oracleText ?? dto.oracle_text,
            flavorText: primaryFace?.flavorText ?? dto.flavor_text,
            power: primaryFace?.power ?? dto.power,
            toughness: primaryFace?.toughness ?? dto.toughness,
            loyalty: primaryFace?.loyalty ?? dto.loyalty,
            artist: primaryFace?.artist ?? dto.artist,
            colors: primaryFace?.colors ?? dto.colors ?? []
        )
    }

    private static func preferredImageURL(from dictionary: [String: URL]?, fallback: URL? = nil) -> URL? {
        guard let dictionary = dictionary else { return fallback }
        for key in imagePreferenceOrder {
            if let url = dictionary[key] {
                return url
            }
        }
        return fallback
    }

    private static func applyResolvedFaces(_ faces: [ResolvedFaceData], to card: Card) {
        if faces.isEmpty {
            card.faces.removeAll()
            return
        }

        // Trim any extra stored faces beyond what we received from Scryfall
        while card.faces.count > faces.count {
            card.faces.removeLast()
        }

        for (index, face) in faces.enumerated() {
            if index < card.faces.count {
                let existing = card.faces[index]
                existing.name = face.name
                existing.imageURL = face.imageURL
                existing.manaCost = face.manaCost
                existing.typeLine = face.typeLine
                existing.oracleText = face.oracleText
                existing.flavorText = face.flavorText
                existing.power = face.power
                existing.toughness = face.toughness
                existing.loyalty = face.loyalty
                existing.artist = face.artist
                existing.colors = face.colors
            } else {
                let newFace = CardFace(
                    name: face.name,
                    imageURL: face.imageURL,
                    manaCost: face.manaCost,
                    typeLine: face.typeLine,
                    oracleText: face.oracleText,
                    flavorText: face.flavorText,
                    power: face.power,
                    toughness: face.toughness,
                    loyalty: face.loyalty,
                    artist: face.artist,
                    colors: face.colors
                )
                card.faces.append(newFace)
            }
        }
    }

    /// Creates a new Card instance from a CardDTO
    /// - Parameter dto: The data transfer object containing card data
    /// - Parameter modelContext: The SwiftData model context for creating tags
    convenience init(from dto: CardDTO, modelContext: ModelContext) {
        let resolved = Card.resolvedData(from: dto)
        let faces = resolved.faces.map { face in
            CardFace(
                name: face.name,
                imageURL: face.imageURL,
                manaCost: face.manaCost,
                typeLine: face.typeLine,
                oracleText: face.oracleText,
                flavorText: face.flavorText,
                power: face.power,
                toughness: face.toughness,
                loyalty: face.loyalty,
                artist: face.artist,
                colors: face.colors
            )
        }

        self.init(
            game: "MTG",
            name: dto.name,
            setCode: dto.set,
            setName: dto.set_name,
            collectorNumber: dto.collector_number,
            quantity: 1,
            imageURL: resolved.imageURL,
            manaCost: resolved.manaCost,
            cmc: dto.cmc,
            typeLine: resolved.typeLine,
            oracleText: resolved.oracleText,
            flavorText: resolved.flavorText,
            power: resolved.power,
            toughness: resolved.toughness,
            loyalty: resolved.loyalty,
            rarity: dto.rarity,
            isReserved: dto.reserved,
            artist: resolved.artist,
            colorIdentity: dto.color_identity,
            colors: resolved.colors,
            keywords: dto.keywords,
            legalities: dto.legalities,
            tags: [],
            layout: dto.layout,
            faces: faces
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

    static func applyResolvedData(_ resolved: ResolvedCardData, to card: Card) {
        if let imageURL = resolved.imageURL {
            card.imageURL = imageURL
        }
        card.manaCost = resolved.manaCost
        card.typeLine = resolved.typeLine
        card.oracleText = resolved.oracleText
        card.flavorText = resolved.flavorText
        card.power = resolved.power
        card.toughness = resolved.toughness
        card.loyalty = resolved.loyalty
        card.artist = resolved.artist
        card.colors = resolved.colors

        applyResolvedFaces(resolved.faces, to: card)
    }
}
