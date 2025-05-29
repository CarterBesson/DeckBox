// MARK: - Magic: The Gathering Color Extensions
/// SwiftUI Color extensions for Magic: The Gathering colors and related functionality.
/// Provides standard MTG colors, guild colors, and utility functions for color management.

import SwiftUI

extension Color {
    // MARK: - Standard MTG Colors
    /// The five basic Magic colors
    
    /// White mana color (#F9FAF4)
    static let mtgWhite = Color(hex: "#F9FAF4")
    
    /// Blue mana color (#0E68AB)
    static let mtgBlue = Color(hex: "#0E68AB")
    
    /// Black mana color (#150B00)
    static let mtgBlack = Color(hex: "#150B00")
    
    /// Red mana color (#D3202A)
    static let mtgRed = Color(hex: "#D3202A")
    
    /// Green mana color (#00733D)
    static let mtgGreen = Color(hex: "#00733D")
    
    // MARK: - Guild Colors
    /// Two-color combinations from Ravnica guilds
    
    /// Azorius (White/Blue) guild color (#8CC1E7)
    static let azorius = Color(hex: "#8CC1E7")
    
    /// Dimir (Blue/Black) guild color (#0B61A4)
    static let dimir = Color(hex: "#0B61A4")
    
    /// Rakdos (Black/Red) guild color (#8B1B1B)
    static let rakdos = Color(hex: "#8B1B1B")
    
    /// Gruul (Red/Green) guild color (#BE4D00)
    static let gruul = Color(hex: "#BE4D00")
    
    /// Selesnya (Green/White) guild color (#94B053)
    static let selesnya = Color(hex: "#94B053")
    
    /// Orzhov (White/Black) guild color (#4B3B62)
    static let orzhov = Color(hex: "#4B3B62")
    
    /// Izzet (Blue/Red) guild color (#BA3B3B)
    static let izzet = Color(hex: "#BA3B3B")
    
    /// Golgari (Black/Green) guild color (#275133)
    static let golgari = Color(hex: "#275133")
    
    /// Boros (Red/White) guild color (#B65A21)
    static let boros = Color(hex: "#B65A21")
    
    /// Simic (Green/Blue) guild color (#109B89)
    static let simic = Color(hex: "#109B89")
    
    // MARK: - Special Colors
    /// Additional colors for special card types
    
    /// Color for artifact cards (#C0C0C0)
    static let artifact = Color(hex: "#C0C0C0")
    
    /// Color for multicolored cards (#D4AF37)
    static let gold = Color(hex: "#D4AF37")
    
    /// Color for colorless cards (#A8A8A8)
    static let colorless = Color(hex: "#A8A8A8")
    
    /// Color for land cards (#8B7355)
    static let land = Color(hex: "#8B7355")
    
    // MARK: - Utility Functions
    
    /// Converts a color name string to its corresponding Color value
    /// - Parameter name: The name of the color (e.g., "mtgBlue", "azorius", "artifact")
    /// - Returns: The corresponding Color value, or .mtgBlue if the name is not recognized
    static func fromName(_ name: String) -> Color {
        switch name {
        case "mtgWhite": return .mtgWhite
        case "mtgBlue": return .mtgBlue
        case "mtgBlack": return .mtgBlack
        case "mtgRed": return .mtgRed
        case "mtgGreen": return .mtgGreen
        case "azorius": return .azorius
        case "dimir": return .dimir
        case "rakdos": return .rakdos
        case "gruul": return .gruul
        case "selesnya": return .selesnya
        case "orzhov": return .orzhov
        case "izzet": return .izzet
        case "golgari": return .golgari
        case "boros": return .boros
        case "simic": return .simic
        case "artifact": return .artifact
        case "gold": return .gold
        case "colorless": return .colorless
        case "land": return .land
        default: return .mtgBlue
        }
    }
    
    /// Creates a Color from a hexadecimal color string
    /// - Parameter hex: The hex color string (e.g., "#FF0000")
    /// Supports the following formats:
    /// - 3 digits: RGB
    /// - 6 digits: RRGGBB
    /// - 8 digits: AARRGGBB
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 