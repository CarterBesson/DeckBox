//
//  ScryfallService.swift
//  DeckBox
//
//  Created by Carter Besson on 5/25/25.
//

import Foundation
import SwiftData

// 1. Define a protocol so we can swap implementations later
protocol CardDataService {
  /// Fetches a card by (fuzzy) name. Throws on 404 or network error.
  func fetchCard(named name: String) async throws -> CardDTO
}

// 2. DTO matching just the fields we care about
struct CardDTO: Decodable {
  let name: String
  let set: String
  let collector_number: String
  let image_uris: [String: URL]?

  enum CodingKeys: String, CodingKey {
    case name
    case set
    case collector_number
    case image_uris
  }
}

// 3. Scryfall implementation
struct ScryfallService: CardDataService {
  private let session: URLSession = .shared

  func fetchCard(named name: String) async throws -> CardDTO {
    // percent-encode the query
    guard let query = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
      throw URLError(.badURL)
    }
    let url = URL(string: "https://api.scryfall.com/cards/named?fuzzy=\(query)")!
    let (data, response) = try await session.data(from: url)
    // handle 404: Scryfall returns 404 with JSON error
    if let http = response as? HTTPURLResponse, http.statusCode == 404 {
      let msg = try JSONDecoder().decode([String:String].self, from: data)["details"] ?? "Card not found"
      throw NSError(domain: "ScryfallService", code: 404, userInfo: [NSLocalizedDescriptionKey: msg])
    }
    // decode into our DTO
    let decoder = JSONDecoder()
    return try decoder.decode(CardDTO.self, from: data)
  }
}

extension Card {
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
