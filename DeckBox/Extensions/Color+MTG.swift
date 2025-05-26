import SwiftUI

extension Color {
    // MTG Colors
    static let mtgWhite = Color(hex: "#F9FAF4")
    static let mtgBlue = Color(hex: "#0E68AB")
    static let mtgBlack = Color(hex: "#150B00")
    static let mtgRed = Color(hex: "#D3202A")
    static let mtgGreen = Color(hex: "#00733D")
    
    // Guild Colors (for multicolor tags)
    static let azorius = Color(hex: "#8CC1E7")    // W/U
    static let dimir = Color(hex: "#0B61A4")      // U/B
    static let rakdos = Color(hex: "#8B1B1B")     // B/R
    static let gruul = Color(hex: "#BE4D00")      // R/G
    static let selesnya = Color(hex: "#94B053")   // G/W
    static let orzhov = Color(hex: "#4B3B62")     // W/B
    static let izzet = Color(hex: "#BA3B3B")      // U/R
    static let golgari = Color(hex: "#275133")    // B/G
    static let boros = Color(hex: "#B65A21")      // R/W
    static let simic = Color(hex: "#109B89")      // G/U
    
    // Additional Tag Colors
    static let artifact = Color(hex: "#C0C0C0")   // For artifacts
    static let gold = Color(hex: "#D4AF37")       // For multicolor
    static let colorless = Color(hex: "#A8A8A8")  // For colorless
    static let land = Color(hex: "#8B7355")       // For lands
    
    // Convert color name to Color
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
    
    // Helper initializer for hex colors
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
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 