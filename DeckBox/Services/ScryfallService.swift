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

    enum CodingKeys: String, CodingKey {
        case name
        case set
        case collector_number
        case image_uris
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
    /// Initializes a card with game set to "MTG" and quantity to 1
    convenience init(from dto: CardDTO) {
        self.init(
            game: "MTG",
            name: dto.name,
            setCode: dto.set,
            collectorNumber: dto.collector_number,
            quantity: 1,
            tags: []
        )
        self.imageURL = dto.image_uris?["normal"]
    }
}
