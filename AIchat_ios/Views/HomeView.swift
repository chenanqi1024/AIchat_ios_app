import SwiftUI

struct HomeView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = true
    @AppStorage("selectedRoleId") private var selectedRoleId = 0
    @EnvironmentObject private var authStore: AuthStore
    @StateObject private var viewModel = RoleListViewModel()
    @State private var isShowingLogin = false
    @State private var isShowingSettings = false
    @State private var selectedRole: ChatRole?
    @State private var pendingRole: ChatRole?
    @State private var launchRole: ChatRole?

    init(initialRole: ChatRole? = nil) {
        _launchRole = State(initialValue: initialRole)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topTrailing) {
                AppBackgroundView(imageURL: featuredRole?.backgroundImageURL)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        welcomeSection
                        featuredSection
                        allRolesSection
                        quickActionsSection
                        recentChatsSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 48)
                    .padding(.bottom, 80)
                }
                .refreshable {
                    await reloadHomeData()
                }

                settingsButton
                    .padding(.top, 48)
                    .padding(.trailing, 24)
                    .zIndex(10)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $selectedRole) { role in
                ChatView(role: role)
            }
            .fullScreenCover(isPresented: $isShowingLogin) {
                LoginSheetView()
                    .environmentObject(authStore)
            }
            .fullScreenCover(isPresented: $isShowingSettings) {
                SettingsView()
                    .environmentObject(authStore)
            }
            .task {
                await reloadHomeData()
                openLaunchRoleIfNeeded()
            }
            .onChange(of: authStore.isAuthenticated) { _, isAuthenticated in
                if isAuthenticated, let role = pendingRole {
                    pendingRole = nil
                    selectedRoleId = role.id
                    selectedRole = role
                }
                Task { await viewModel.loadRecentChats(token: authStore.accessToken) }
            }
            .onChange(of: viewModel.roles) { _, roles in
                if selectedRoleId == 0, let first = roles.first {
                    selectedRoleId = first.id
                }
                Task { await viewModel.loadRecentChats(token: authStore.accessToken) }
            }
        }
    }

    private var welcomeSection: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primary)

                    Text(greetingText)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(AppTheme.textPrimary)
                }

                Text("今天想和谁聊聊天？")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.textMuted)
            }

            Spacer(minLength: 12)
        }
        .padding(.trailing, 56)
    }

    private var settingsButton: some View {
        Button {
            isShowingSettings = true
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppTheme.purple600)
                .frame(width: 44, height: 44)
                .background(AppTheme.surface.opacity(0.88), in: Circle())
                .overlay(
                    Circle()
                        .stroke(.white.opacity(0.80), lineWidth: 1)
                )
                .shadow(color: AppTheme.primary.opacity(0.14), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .accessibilityLabel("设置")
    }

    @ViewBuilder
    private var featuredSection: some View {
        if viewModel.isLoading && viewModel.roles.isEmpty {
            ProgressView("正在加载角色")
                .tint(AppTheme.primary)
                .foregroundStyle(AppTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(28)
                .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
        } else if let errorMessage = viewModel.errorMessage, viewModel.roles.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.title2)
                    .foregroundStyle(AppTheme.primary)
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                Button("重新加载") {
                    Task { await reloadHomeData() }
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
        } else if let role = featuredRole {
            FeaturedRoleCard(role: role) {
                open(role)
            }
        }
    }

    private var allRolesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("所有角色")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.roles) { role in
                        RoleTileView(role: role, isSelected: role.id == selectedRoleId) {
                            selectedRoleId = role.id
                            open(role)
                        }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
            }
        }
    }

    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            QuickActionButton(
                title: "继续聊天",
                systemImage: "message.circle.fill",
                iconGradient: AppTheme.purplePinkSoftGradient,
                tint: AppTheme.purple600
            ) {
                open(viewModel.recentChats.first?.role ?? featuredRole)
            }

            QuickActionButton(
                title: "聊天记录",
                systemImage: "clock.fill",
                iconGradient: AppTheme.bluePurpleSoftGradient,
                tint: AppTheme.blue600
            ) {
                open(viewModel.recentChats.first?.role ?? featuredRole)
            }

            QuickActionButton(
                title: "重新选择",
                systemImage: "arrow.clockwise",
                iconGradient: AppTheme.pinkPurpleSoftGradient,
                tint: AppTheme.pink600
            ) {
                hasSeenOnboarding = false
            }
        }
    }

    private var recentChatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近聊天")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.horizontal, 4)

            VStack(spacing: 8) {
                if !authStore.isAuthenticated {
                    RecentChatPlaceholder(text: "登录后查看最近聊天")
                } else if viewModel.isLoadingRecentChats {
                    ProgressView("正在同步聊天记录")
                        .tint(AppTheme.primary)
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(20)
                        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                } else if viewModel.recentChats.isEmpty {
                    RecentChatPlaceholder(text: "暂无最近聊天")
                } else {
                    ForEach(viewModel.recentChats) { chat in
                        RecentChatRow(chat: chat) {
                            open(chat.role)
                        }
                    }
                }
            }
        }
    }

    private var featuredRole: ChatRole? {
        viewModel.roles.first { $0.id == selectedRoleId } ?? viewModel.roles.first
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            return "早上好"
        }
        if hour < 18 {
            return "下午好"
        }
        return "晚上好"
    }

    private func reloadHomeData() async {
        if viewModel.roles.isEmpty {
            await viewModel.loadRoles()
        } else {
            await viewModel.loadRoles()
        }
        await viewModel.loadRecentChats(token: authStore.accessToken)
    }

    private func open(_ role: ChatRole?) {
        guard let role else { return }
        selectedRoleId = role.id
        if authStore.isAuthenticated {
            selectedRole = role
        } else {
            pendingRole = role
            isShowingLogin = true
        }
    }

    private func openLaunchRoleIfNeeded() {
        guard let role = launchRole else { return }
        launchRole = nil
        selectedRoleId = role.id
        open(role)
    }
}

private struct FeaturedRoleCard: View {
    let role: ChatRole
    let action: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                RemoteImageView(urlString: role.avatarImageURL)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(.white, lineWidth: 3)
                    )
                    .shadow(color: .black.opacity(0.10), radius: 10, x: 0, y: 6)

                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 8) {
                        Text(role.displayName)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(AppTheme.textPrimary)

                        Text(role.displayTag)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppTheme.purple600)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(.white.opacity(0.80), in: Capsule())
                    }
                    .padding(.bottom, 4)

                    Text(role.homeDescription)
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(2)
                        .padding(.bottom, 8)

                    HStack(spacing: 4) {
                        Image(systemName: "message.circle")
                            .font(.system(size: 14))
                        Text(role.greeting)
                            .font(.system(size: 12))
                    }
                    .foregroundStyle(AppTheme.textMuted)
                }

                Spacer(minLength: 0)
            }

            Button(action: action) {
                Text("立即聊天")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppTheme.heroGradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: AppTheme.primary.opacity(0.18), radius: 8, x: 0, y: 6)
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .background(
            ZStack {
                RemoteImageView(urlString: role.backgroundImageURL)
                    .opacity(0.20)
                AppTheme.softGradient
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.10), radius: 18, x: 0, y: 10)
    }
}

private struct RoleTileView: View {
    let role: ChatRole
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                ZStack(alignment: .bottom) {
                    RemoteImageView(urlString: role.avatarImageURL)
                        .frame(width: 104, height: 104)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    LinearGradient(
                        colors: [.clear, .black.opacity(0.10)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.bottom, 8)

                VStack(spacing: 3) {
                    Text(role.displayName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text(role.homeDescription)
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.textMuted)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(12)
            .frame(width: 128)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

private struct QuickActionButton: View {
    let title: String
    let systemImage: String
    let iconGradient: LinearGradient
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(tint)
                    .frame(width: 40, height: 40)
                    .background(iconGradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
}

private struct RecentChatRow: View {
    let chat: RecentChatPreview
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                RemoteImageView(urlString: chat.role.avatarImageURL)
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(chat.role.displayName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppTheme.textPrimary)

                        Spacer()

                        Text(chat.timeText)
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.textTertiary)
                    }

                    Text(chat.lastMessage)
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.textMuted)
                        .lineLimit(1)
                }

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.textTertiary)
            }
            .padding(16)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
}

private struct RecentChatPlaceholder: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 14))
            .foregroundStyle(AppTheme.textMuted)
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 5)
    }
}
