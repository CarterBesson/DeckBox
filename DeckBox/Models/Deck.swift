//
//  Deck.swift
//  DeckBox
//
//  Created by Carter Besson on 7/6/25.
//

import Foundation
import SwiftData

// MARK: - DeckFormat

enum DeckFormat: String, Codable, CaseIterable, Sendable {
    case standard, pioneer, modern, legacy, vintage, pauper, commander, generic
}

struct DeckRules: Sendable {
    let minMain: Int
    let maxMain: Int?
    let maxCopies: Int?
    let sideboardMax: Int
    let allowCommander: Bool
    let commanderCountRange: ClosedRange<Int>
}

extension DeckFormat {
    var rules: DeckRules {
        switch self {
        case .standard:
            return DeckRules(minMain: 60, maxMain: nil, maxCopies: 4, sideboardMax: 15, allowCommander: false, commanderCountRange: 0...0)
        case .pioneer, .modern, .legacy, .vintage, .pauper:
            return DeckRules(minMain: 60, maxMain: nil, maxCopies: 4, sideboardMax: 15, allowCommander: false, commanderCountRange: 0...0)
        case .commander:
            // EDH: 100-card singleton, no sideboard (common case)
            return DeckRules(minMain: 100, maxMain: 100, maxCopies: 1, sideboardMax: 0, allowCommander: true, commanderCountRange: 1...2)
        case .generic:
            return DeckRules(minMain: 0, maxMain: nil, maxCopies: nil, sideboardMax: 0, allowCommander: false, commanderCountRange: 0...0)
        
        }
    }
}

// MARK: - Board

enum Board: String, Codable, CaseIterable, Sendable {
    case main
    case side
}

// MARK: - DeckEntry

@Model
final class DeckEntry {
    var deck: Deck?
    var card: Card
    var quantity: Int
    var board: Board
    var isCommander: Bool

    init(card: Card, quantity: Int = 1, board: Board = .main, isCommander: Bool = false, deck: Deck? = nil) {
        self.card = card
        self.quantity = quantity
        self.board = board
        self.isCommander = isCommander
        self.deck = deck
    }
}

// MARK: - Deck

@Model
final class Deck {
    var name: String?
    var format: DeckFormat
    @Relationship(deleteRule: .cascade, inverse: \DeckEntry.deck) var entries: [DeckEntry] = []

    init(name: String? = nil, format: DeckFormat = .standard, entries: [DeckEntry] = []) {
        self.name = name
        self.format = format
        self.entries = entries
    }

    // MARK: Derived counts

    var mainboardCount: Int {
        entries.lazy.filter { $0.board == .main }.reduce(0) { $0 + $1.quantity }
    }

    var sideboardCount: Int {
        entries.lazy.filter { $0.board == .side }.reduce(0) { $0 + $1.quantity }
    }

    var commandersCount: Int {
        entries.lazy.filter { $0.isCommander }.count
    }

    // MARK: Validation

    enum DeckValidationError: Equatable, Error, LocalizedError {
        case mainboardTooSmall(min: Int, actual: Int)
        case mainboardTooLarge(max: Int, actual: Int)
        case sideboardTooLarge(max: Int, actual: Int)
        case sideboardNotAllowed(actual: Int)
        case tooManyCopies(maxAllowed: Int, cardName: String, actual: Int)
        case commanderNotAllowed
        case commanderCountOutOfRange(expected: ClosedRange<Int>, actual: Int)
        case illegalCard(cardName: String, format: DeckFormat)

        var errorDescription: String? {
            switch self {
            case .mainboardTooSmall(let min, let actual):
                return "Mainboard has \(actual) cards; minimum is \(min)."
            case .mainboardTooLarge(let max, let actual):
                return "Mainboard has \(actual) cards; maximum is \(max)."
            case .sideboardTooLarge(let max, let actual):
                return "Sideboard has \(actual) cards; maximum is \(max)."
            case .sideboardNotAllowed(let actual):
                return "This format does not allow sideboards, but you have \(actual) cards in sideboard."
            case .tooManyCopies(let max, let name, let actual):
                return "Too many copies of \(name): \(actual) (max \(max))."
            case .commanderNotAllowed:
                return "This format does not use a commander."
            case .commanderCountOutOfRange(let expected, let actual):
                return "Commander count \(actual) is not in allowed range \(expected)."
            case .illegalCard(let name, let format):
                return "\(name) is not legal in \(format.rawValue.capitalized)."
            }
        }
    }

    /// Validate the deck against the current `format` rules.
    /// - Parameters:
    ///   - isCardLegal: Optional legality check for a given card in the current format. Return `true` for legal.
    ///   - displayName: Optional closure used to display a human readable card name in error messages.
    func validate(
        isCardLegal: ((Card, DeckFormat) -> Bool)? = nil,
        displayName: ((Card) -> String)? = nil
    ) -> [DeckValidationError] {
        let rules = format.rules
        var errors: [DeckValidationError] = []

        // Mainboard size checks
        if mainboardCount < rules.minMain {
            errors.append(.mainboardTooSmall(min: rules.minMain, actual: mainboardCount))
        }
        if let max = rules.maxMain, mainboardCount > max {
            errors.append(.mainboardTooLarge(max: max, actual: mainboardCount))
        }

        // Sideboard checks
        if rules.sideboardMax == 0 {
            if sideboardCount > 0 { errors.append(.sideboardNotAllowed(actual: sideboardCount)) }
        } else if sideboardCount > rules.sideboardMax {
            errors.append(.sideboardTooLarge(max: rules.sideboardMax, actual: sideboardCount))
        }

        // Commander checks
        if !rules.allowCommander, commandersCount > 0 {
            errors.append(.commanderNotAllowed)
        }
        if rules.allowCommander && !rules.commanderCountRange.contains(commandersCount) {
            errors.append(.commanderCountOutOfRange(expected: rules.commanderCountRange, actual: commandersCount))
        }

        // Max copies per card (mainboard only)
        if let maxCopies = rules.maxCopies {
            var countsByCard: [ObjectIdentifier: Int] = [:]
            for e in entries where e.board == .main {
                let key = ObjectIdentifier(e.card)
                countsByCard[key, default: 0] += e.quantity
            }
            for e in entries where e.board == .main {
                let key = ObjectIdentifier(e.card)
                let total = countsByCard[key] ?? 0
                if total > maxCopies {
                    let name = displayName?(e.card) ?? "card"
                    errors.append(.tooManyCopies(maxAllowed: maxCopies, cardName: name, actual: total))
                    countsByCard[key] = nil // only one error per unique card
                }
            }
        }

        // Optional legality check
        if let isCardLegal {
            for e in entries where e.board == .main {
                if !isCardLegal(e.card, format) {
                    let name = displayName?(e.card) ?? "card"
                    errors.append(.illegalCard(cardName: name, format: format))
                }
            }
        }

        return errors
    }
}
