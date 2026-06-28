import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var authStore: AuthStore
    @StateObject private var viewModel = RoleListViewModel()
    @State private var selectedIndex = 0
    @State private var carouselPosition: Int?
    @State private var isShowingLogin = false

    let onFinish: (ChatRole?) -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                AppTheme.backgroundGradient.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        header
                            .padding(.bottom, 32)

                        carousel(containerWidth: proxy.size.width - 48)
                            .padding(.bottom, 32)

                        pageDots
                            .padding(.bottom, 32)

                        startButton
                            .padding(.horizontal, 16)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 48)
                    .padding(.bottom, 32)
                }
            }
        }
        .task {
            if viewModel.roles.isEmpty {
                await viewModel.loadRoles()
            }
        }
        .onChange(of: viewModel.roles) { _, roles in
            guard !roles.isEmpty else { return }
            if selectedIndex >= roles.count {
                selectedIndex = 0
            }
            if carouselPosition == nil {
                carouselPosition = selectedIndex
            }
        }
        .fullScreenCover(isPresented: $isShowingLogin) {
            LoginSheetView()
                .environmentObject(authStore)
        }
        .onChange(of: authStore.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                isShowingLogin = false
                onFinish(selectedRole)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .medium))
                Text("欢迎来到陪伴世界")
                    .font(.system(size: 14))
            }
            .foregroundStyle(AppTheme.purple400)
            .padding(.bottom, 12)

            Text("选择你的陪伴角色")
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.bottom, 12)

            Text("每位角色都有不同的性格与陪伴方式")
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.textMuted)
        }
        .multilineTextAlignment(.center)
    }

    @ViewBuilder
    private func carousel(containerWidth: CGFloat) -> some View {
        if viewModel.isLoading && viewModel.roles.isEmpty {
            loadingCard
        } else if let errorMessage = viewModel.errorMessage, viewModel.roles.isEmpty {
            errorCard(errorMessage)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(Array(viewModel.roles.enumerated()), id: \.offset) { index, role in
                        OnboardingRoleCard(role: role)
                            .frame(width: max(containerWidth - 80, 240), height: 480)
                            .padding(.horizontal, 8)
                            .id(index)
                            .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                                content
                                    .opacity(phase.isIdentity ? 1 : 0.4)
                                    .scaleEffect(phase.isIdentity ? 1 : 0.85)
                            }
                    }
                }
                .scrollTargetLayout()
            }
            .contentMargins(.horizontal, 40, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $carouselPosition)
            .frame(height: 480)
            .onAppear {
                if carouselPosition == nil {
                    carouselPosition = selectedIndex
                }
            }
            .onChange(of: carouselPosition) { _, newValue in
                if let newValue {
                    selectedIndex = newValue
                }
            }
        }
    }

    private var loadingCard: some View {
        VStack(spacing: 14) {
            ProgressView()
                .tint(AppTheme.primary)
            Text("正在加载陪伴角色")
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 480)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.10), radius: 18, x: 0, y: 12)
    }

    private func errorCard(_ message: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "wifi.exclamationmark")
                .font(.title2)
                .foregroundStyle(AppTheme.primary)
            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.textMuted)
                .multilineTextAlignment(.center)
            Button("重新加载") {
                Task { await viewModel.loadRoles() }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 480)
        .padding(.horizontal, 18)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.10), radius: 18, x: 0, y: 12)
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(viewModel.roles.indices, id: \.self) { index in
                Capsule()
                    .fill(index == selectedIndex ? AnyShapeStyle(AppTheme.heroGradient) : AnyShapeStyle(AppTheme.gray300))
                    .frame(width: index == selectedIndex ? 32 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.30), value: selectedIndex)
            }
        }
        .frame(height: 8)
    }

    private var startButton: some View {
        Button {
            if authStore.isAuthenticated {
                onFinish(selectedRole)
            } else {
                isShowingLogin = true
            }
        } label: {
            Text("开始聊天")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppTheme.heroGradient, in: Capsule())
                .shadow(color: AppTheme.primary.opacity(0.28), radius: 16, x: 0, y: 10)
        }
        .buttonStyle(.plain)
        .disabled(viewModel.roles.isEmpty)
        .opacity(viewModel.roles.isEmpty ? 0.55 : 1)
    }

    private var selectedRole: ChatRole? {
        guard viewModel.roles.indices.contains(selectedIndex) else {
            return viewModel.roles.first
        }
        return viewModel.roles[selectedIndex]
    }
}

private struct OnboardingRoleCard: View {
    let role: ChatRole

    var body: some View {
        ZStack {
            RemoteImageView(urlString: role.backgroundImageURL)
                .opacity(0.30)

            LinearGradient(
                colors: [.white.opacity(0.60), .white.opacity(0.40), .white.opacity(0.80)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 0) {
                RemoteImageView(urlString: role.avatarImageURL)
                    .frame(width: 160, height: 160)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white, lineWidth: 4))
                    .shadow(color: .black.opacity(0.18), radius: 22, x: 0, y: 12)
                    .padding(.bottom, 24)

                Text(role.displayName)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(.bottom, 8)

                Text(role.onboardingDescription)
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineSpacing(3)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 260)
            }
            .padding(.horizontal, 32)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [AppTheme.purple100.opacity(0.40), AppTheme.pink100.opacity(0.40)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .blur(radius: 22)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, 32)
                .padding(.trailing, 32)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [AppTheme.blue100.opacity(0.40), AppTheme.purple100.opacity(0.40)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 96, height: 96)
                .blur(radius: 24)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(.bottom, 32)
                .padding(.leading, 32)
        }
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.10), radius: 18, x: 0, y: 10)
    }
}
