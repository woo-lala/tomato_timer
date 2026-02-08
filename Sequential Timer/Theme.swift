import SwiftUI
import Combine
import Foundation

enum ThemeMode: String, CaseIterable {
    case light
    case dark
}

enum AccentColorType: String, CaseIterable {
    case blue
    case coral
}

enum ThemeSelection: String, CaseIterable, Identifiable {
    case system
    case lightBlue
    case lightCoral
    case darkBlue
    case darkCoral

    var id: String { rawValue }

    var displayKey: String {
        switch self {
        case .system: return "settings.theme.system"
        case .lightBlue: return "settings.theme.lightBlue"
        case .lightCoral: return "settings.theme.lightCoral"
        case .darkBlue: return "settings.theme.darkBlue"
        case .darkCoral: return "settings.theme.darkCoral"
        }
    }
}

struct ThemePalette {
    let background: Color
    let surface: Color
    let textPrimary: Color
    let textSecondary: Color
    let accent: Color
    let border: Color
    let shadow: Color

    static let lightBlue = ThemePalette(
        background: Color(hex: "F2F2F7"),
        surface: Color(hex: "FFFFFF"),
        textPrimary: Color(hex: "000000"),
        textSecondary: Color(hex: "8E8E93"),
        accent: Color(hex: "3D7AF5"),
        border: Color.black.opacity(0.08),
        shadow: Color.black.opacity(0.05)
    )

    static let lightCoral = ThemePalette(
        background: Color(hex: "F2F2F7"),
        surface: Color(hex: "FFFFFF"),
        textPrimary: Color(hex: "000000"),
        textSecondary: Color(hex: "8E8E93"),
        accent: Color(hex: "E86B5E"),
        border: Color.black.opacity(0.08),
        shadow: Color.black.opacity(0.05)
    )

    static let darkBlue = ThemePalette(
        background: Color(hex: "121212"),
        surface: Color(hex: "1C1C1E"),
        textPrimary: Color(hex: "E1E1E1"),
        textSecondary: Color(hex: "A0A0A0"),
        accent: Color(hex: "5E89D6"),
        border: Color.white.opacity(0.15),
        shadow: Color.black.opacity(0.5)
    )

    static let darkCoral = ThemePalette(
        background: Color(hex: "121212"),
        surface: Color(hex: "1C1C1E"),
        textPrimary: Color(hex: "E1E1E1"),
        textSecondary: Color(hex: "A0A0A0"),
        accent: Color(hex: "C86A62"),
        border: Color.white.opacity(0.15),
        shadow: Color.black.opacity(0.5)
    )
}

final class ThemeStore: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    @AppStorage("theme.selection") private var selectionRaw: String = ThemeSelection.system.rawValue {
        willSet { objectWillChange.send() }
    }

    var selection: ThemeSelection {
        get { ThemeSelection(rawValue: selectionRaw) ?? .system }
        set { selectionRaw = newValue.rawValue }
    }

    var preferredColorScheme: ColorScheme? {
        switch selection {
        case .system:
            return nil
        case .lightBlue, .lightCoral:
            return .light
        case .darkBlue, .darkCoral:
            return .dark
        }
    }

    func palette(for scheme: ColorScheme) -> ThemePalette {
        switch selection {
        case .system:
            return scheme == .dark ? .darkBlue : .lightBlue
        case .lightBlue:
            return .lightBlue
        case .lightCoral:
            return .lightCoral
        case .darkBlue:
            return .darkBlue
        case .darkCoral:
            return .darkCoral
        }
    }
}

private struct ThemePaletteKey: EnvironmentKey {
    static let defaultValue: ThemePalette = .lightBlue
}

extension EnvironmentValues {
    var themePalette: ThemePalette {
        get { self[ThemePaletteKey.self] }
        set { self[ThemePaletteKey.self] = newValue }
    }
}

struct ThemeProvider: ViewModifier {
    @ObservedObject var themeStore: ThemeStore
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content.environment(\.themePalette, themeStore.palette(for: colorScheme))
    }
}
