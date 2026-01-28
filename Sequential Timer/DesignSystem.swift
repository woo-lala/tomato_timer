
import SwiftUI
import UIKit

// MARK: - Color Extensions from MaDay
extension Color {
    init(hex: String, alpha: Double = 1.0) {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased().replacingOccurrences(of: "#", with: "")
        
        let mappings: [String: String] = [
            "3D7AF5": "6B93D6", // Primary
            "2F63C8": "4A70B6", // PrimaryStrong
            "FF3B30": "D65C54", // Destructive
            "26BA67": "5FA879", // Fitness
            "FFC23F": "D6B567", // Learning
            "E94E3D": "C26D64", // Youtube
            "2EB97F": "67A88F", // Shopping
            "6B7280": "8E939E"  // Cooking
        ]
        
        if let darkHex = mappings[cleaned] {
            self.init(uiColor: UIColor { trait in
                return trait.userInterfaceStyle == .dark
                    ? UIColor(hex: darkHex, alpha: alpha)
                    : UIColor(hex: cleaned, alpha: alpha)
            })
            return
        }

        self.init(uiColor: UIColor(hex: cleaned, alpha: alpha))
    }
    
    private static func semantic(light: String, dark: String) -> Color {
        return Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark
                ? UIColor(hex: dark)
                : UIColor(hex: light)
        })
    }
    
    // Core Palette
    static let mdPrimary = semantic(light: "3D7AF5", dark: "5E89D6")
    static let mdPrimaryStrong = semantic(light: "2F63C8", dark: "4A70B6")
    static let mdDestructive = semantic(light: "FF3B30", dark: "D65C54")
    static let mdBackground = semantic(light: "F2F2F7", dark: "121212")
    static let mdCard = semantic(light: "FFFFFF", dark: "1C1C1E")
    static let mdTextPrimary = semantic(light: "000000", dark: "E1E1E1")
    static let mdTextSecondary = semantic(light: "8E8E93", dark: "A0A0A0")
    
    // Category Colors
    static let mdWork = semantic(light: "3D7AF5", dark: "6B93D6")
    static let mdFitness = semantic(light: "26BA67", dark: "5FA879")
    static let mdLearning = semantic(light: "FFC23F", dark: "D6B567")

    static let mdBorder = Color(UIColor { trait in
        return trait.userInterfaceStyle == .dark ? UIColor(white: 1.0, alpha: 0.15) : UIColor(white: 0.0, alpha: 0.08)
    })
    
    static let mdShadow = Color(UIColor { trait in
        return trait.userInterfaceStyle == .dark ? UIColor(white: 0.0, alpha: 0.5) : UIColor(white: 0.0, alpha: 0.05)
    })
}

extension UIColor {
    convenience init(hex: String, alpha: Double = 1.0) {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cleaned.hasPrefix("#") {
            cleaned.removeFirst()
        }

        var rgb: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&rgb)

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b, alpha: CGFloat(alpha))
    }
}

// MARK: - Design System Constants
enum AppColor {
    static let background = Color.mdBackground
    static let surface = Color.mdCard
    static let primary = Color.mdPrimary
    static let primaryStrong = Color.mdPrimaryStrong
    static let textPrimary = Color.mdTextPrimary
    static let textSecondary = Color.mdTextSecondary
    static let border = Color.mdBorder
    static let shadow = Color.mdShadow
    static let white = Color.white
    
    // Categories
    static let work = Color.mdWork
    static let fitness = Color.mdFitness
    static let learning = Color.mdLearning
}

enum AppFont {
    static func largeTitle() -> Font { .system(size: 34, weight: .bold) }
    static func title() -> Font { .system(size: 20, weight: .bold) }
    static func headline() -> Font { .system(size: 18, weight: .semibold) }
    static func heading() -> Font { .system(size: 17, weight: .semibold) } // Added
    static func body() -> Font { .system(size: 15, weight: .regular) }
    static func callout() -> Font { .system(size: 14, weight: .medium) } // Added
    static func button() -> Font { .system(size: 16, weight: .semibold) }
    static func caption() -> Font { .system(size: 13, weight: .regular) }
}

enum AppSpacing {
    static let small: CGFloat = 8
    static let smallPlus: CGFloat = 12 // Added
    static let medium: CGFloat = 16
    static let mediumPlus: CGFloat = 20
    static let large: CGFloat = 24 // Added
    static let xLarge: CGFloat = 32
}

enum AppRadius {
    static let standard: CGFloat = 16
    static let button: CGFloat = 12
}

// MARK: - Shared Notification Models
enum NotificationMode: String, CaseIterable, Codable {
    case sound
    case vibration
    case soundAndVibration
}

public enum NotificationSound: String, CaseIterable, Codable {
    case `default` = "기본"
    case short = "짧은 알림"
    case soft = "부드러운 알림"
    
    public var audioResourceName: String? {
        switch self {
        case .default: return nil // System default
        case .short: return "short_alert" // bundled sound name
        case .soft: return "soft_chime"
        }
    }
}

enum VibrationPattern: String, CaseIterable, Codable {
    case `default` = "기본"
    case short = "짧은 진동"
    case double = "두 번 진동"
    case heavy = "강한 진동"
}

struct NotificationConfiguration: Codable {
    var mode: NotificationMode
    var sound: NotificationSound
    var vibration: VibrationPattern
    
    static let `default` = NotificationConfiguration(mode: .sound, sound: .default, vibration: .default)
}
