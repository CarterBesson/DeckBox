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
    var collections: [String] = []
    
    @Relationship(deleteRule: .cascade) var tags: [Tag] = []
    
    init(game: String,
         name: String,
         setCode: String? = nil,
         collectorNumber: String? = nil,
         quantity: Int = 1,
         imageURL: URL? = nil,
         tags: [Tag] = [],
         collections: [String] = []) {
        self.game = game
        self.name = name
        self.setCode = setCode
        self.collectorNumber = collectorNumber
        self.quantity = quantity
        self.tags = tags
        self.imageURL = imageURL
        self.collections = collections
    }
}
