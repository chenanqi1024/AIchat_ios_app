import SwiftUI

enum AppTheme {
    static let background = Color.white
    static let surface = Color.white
    static let elevated = Color(red: 0.95, green: 0.95, blue: 0.96)
    static let primary = Color(red: 0.659, green: 0.333, blue: 0.969)
    static let pink = Color(red: 0.925, green: 0.282, blue: 0.600)
    static let secondary = Color(red: 0.219, green: 0.502, blue: 0.965)
    static let warm = Color(red: 0.86, green: 0.25, blue: 0.31)
    static let textPrimary = Color(red: 0.067, green: 0.094, blue: 0.153)
    static let textAssistant = Color(red: 0.122, green: 0.161, blue: 0.216)
    static let textSecondary = Color(red: 0.294, green: 0.333, blue: 0.388)
    static let textMuted = Color(red: 0.420, green: 0.447, blue: 0.502)
    static let textTertiary = Color(red: 0.612, green: 0.639, blue: 0.686)
    static let gray50 = Color(red: 0.976, green: 0.980, blue: 0.984)
    static let gray100 = Color(red: 0.953, green: 0.957, blue: 0.965)
    static let gray200 = Color(red: 0.898, green: 0.906, blue: 0.922)
    static let gray300 = Color(red: 0.820, green: 0.835, blue: 0.859)
    static let purple50 = Color(red: 0.980, green: 0.961, blue: 1.000)
    static let purple100 = Color(red: 0.953, green: 0.910, blue: 1.000)
    static let purple400 = Color(red: 0.753, green: 0.518, blue: 0.980)
    static let purple600 = Color(red: 0.576, green: 0.200, blue: 0.918)
    static let pink50 = Color(red: 0.992, green: 0.949, blue: 0.973)
    static let pink100 = Color(red: 0.988, green: 0.906, blue: 0.953)
    static let pink400 = Color(red: 0.957, green: 0.447, blue: 0.714)
    static let pink600 = Color(red: 0.859, green: 0.153, blue: 0.467)
    static let blue50 = Color(red: 0.937, green: 0.965, blue: 1.000)
    static let blue100 = Color(red: 0.859, green: 0.918, blue: 0.996)
    static let blue600 = Color(red: 0.149, green: 0.388, blue: 0.922)
    static let stroke = Color.black.opacity(0.10)

    static let backgroundGradient = LinearGradient(
        colors: [
            purple50,
            pink50,
            blue50
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let heroGradient = LinearGradient(
        colors: [
            primary,
            pink
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let softGradient = LinearGradient(
        colors: [
            purple100.opacity(0.60),
            pink100.opacity(0.40),
            blue100.opacity(0.60)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let purplePinkSoftGradient = LinearGradient(
        colors: [purple100, pink100],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let bluePurpleSoftGradient = LinearGradient(
        colors: [blue100, purple100],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let pinkPurpleSoftGradient = LinearGradient(
        colors: [pink100, purple100],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct GlassCardModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(AppTheme.surface.opacity(0.94))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppTheme.stroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 10)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 28) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }
}

struct AppBackgroundView: View {
    var imageURL: String?

    var body: some View {
        ZStack {
            if imageURL != nil {
                RemoteImageView(urlString: imageURL)

                LinearGradient(
                    colors: [
                        .white.opacity(0.90),
                        .white.opacity(0.85),
                        .white.opacity(0.90)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                AppTheme.backgroundGradient
            }
        }
        .ignoresSafeArea()
    }
}

struct ChatPatternBackgroundView: View {
    var imageURL: String?

    var body: some View {
        ZStack {
            if imageURL != nil {
                RemoteImageView(urlString: imageURL)
                    .ignoresSafeArea()
            } else {
                AppTheme.backgroundGradient
            }
        }
        .ignoresSafeArea()
    }
}
