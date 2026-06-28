import SwiftUI

struct AppRootView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @EnvironmentObject private var authStore: AuthStore
    @State private var launchRole: ChatRole?

    var body: some View {
        Group {
            if hasSeenOnboarding {
                HomeView(initialRole: launchRole)
            } else {
                OnboardingView { role in
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.88)) {
                        launchRole = role
                        hasSeenOnboarding = true
                    }
                }
            }
        }
        .environmentObject(authStore)
    }
}
