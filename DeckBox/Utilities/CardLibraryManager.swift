import Foundation
import SwiftData

/// Helpers for keeping the local card library free of duplicates while adding cards.
enum CardLibraryManager {
    /// Adds a card to the library, merging with an existing record when the name already exists.
    @MainActor
    static func upsertCard(from dto: CardDTO, in context: ModelContext) throws -> Card {
        let matches = try fetchCards(named: dto.name, in: context)

        guard let primary = matches.first else {
            let card = Card(from: dto, modelContext: context)
            context.insert(card)
            return card
        }

        var totalQuantity = primary.quantity
        for duplicate in matches.dropFirst() {
            totalQuantity += duplicate.quantity
            mergeDuplicate(duplicate, into: primary)
            context.delete(duplicate)
        }

        primary.quantity = totalQuantity + 1
        refreshMetadata(for: primary, using: dto, in: context)
        primary.lastUpdated = Date()
        return primary
    }

    /// Collapses duplicate card rows for the provided card name without changing the overall quantity.
    @MainActor
    @discardableResult
    static func consolidateCards(named name: String, in context: ModelContext) throws -> Card? {
        let matches = try fetchCards(named: name, in: context)
        guard let primary = matches.first else { return nil }

        var totalQuantity = primary.quantity
        for duplicate in matches.dropFirst() {
            totalQuantity += duplicate.quantity
            mergeDuplicate(duplicate, into: primary)
            context.delete(duplicate)
        }

        primary.quantity = totalQuantity
        if primary.imageURL == nil, let fallback = primary.faces.first?.imageURL {
            primary.imageURL = fallback
        }
        primary.lastUpdated = Date()
        return primary
    }
}

// MARK: - Private helpers
private extension CardLibraryManager {
    @MainActor
    static func fetchCards(named name: String, in context: ModelContext) throws -> [Card] {
        let descriptor = FetchDescriptor<Card>(
            predicate: #Predicate<Card> { card in
                card.name == name
            }
        )
        return try context.fetch(descriptor)
    }

    @MainActor
    static func mergeDuplicate(_ duplicate: Card, into primary: Card) {
        for tag in duplicate.tags where !primary.tags.contains(where: { $0.id == tag.id }) {
            primary.tags.append(tag)
        }

        for group in Array(duplicate.groups) {
            let duplicateQuantity = group.cardQuantities[duplicate.id] ?? duplicate.quantity
            let existingQuantity = group.cardQuantities[primary.id] ?? 0
            group.cardQuantities[primary.id] = existingQuantity + duplicateQuantity
            group.cardQuantities.removeValue(forKey: duplicate.id)

            if !group.cards.contains(where: { $0.id == primary.id }) {
                group.cards.append(primary)
            }
            group.cards.removeAll { $0.id == duplicate.id }

            if !primary.groups.contains(where: { $0.id == group.id }) {
                primary.groups.append(group)
            }
        }
    }

    @MainActor
    static func refreshMetadata(for card: Card, using dto: CardDTO, in context: ModelContext) {
        let resolved = Card.resolvedData(from: dto)
        Card.applyResolvedData(resolved, to: card)

        card.name = dto.name
        card.setCode = dto.set
        card.setName = dto.set_name
        card.collectorNumber = dto.collector_number
        card.layout = dto.layout
        card.rarity = dto.rarity
        card.isReserved = dto.reserved
        card.colorIdentity = dto.color_identity
        card.keywords = dto.keywords
        card.legalities = dto.legalities
        card.cmc = dto.cmc

        // Ensure faces are tracked by SwiftData when newly created
        for face in card.faces where face.modelContext == nil {
            context.insert(face)
        }
    }
}
