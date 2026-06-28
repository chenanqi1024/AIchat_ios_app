import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authStore: AuthStore
    @State private var isShowingLogin = false
    @State private var isShowingLogoutConfirmation = false

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        accountCard
                        settingsGroup
                        accountAction
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(isPresented: $isShowingLogin) {
            LoginSheetView()
                .environmentObject(authStore)
        }
        .confirmationDialog("退出当前账号？", isPresented: $isShowingLogoutConfirmation, titleVisibility: .visible) {
            Button("退出登录", role: .destructive) {
                authStore.clear()
            }

            Button("取消", role: .cancel) {}
        } message: {
            Text("退出后将无法同步最近聊天和历史记录。")
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .frame(width: 42, height: 42)
                    .background(AppTheme.surface.opacity(0.86), in: Circle())
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.80), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 6)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text("设置")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("账号与偏好")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.textMuted)
            }

            Spacer()

            Image(systemName: "gearshape.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppTheme.purple600)
                .frame(width: 42, height: 42)
                .background(AppTheme.purplePinkSoftGradient, in: Circle())
                .shadow(color: AppTheme.primary.opacity(0.14), radius: 12, x: 0, y: 6)
        }
        .padding(.horizontal, 24)
        .padding(.top, 14)
        .padding(.bottom, 8)
    }

    private var accountCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppTheme.heroGradient)
                    .frame(width: 58, height: 58)

                Image(systemName: authStore.isAuthenticated ? "person.fill" : "person.crop.circle")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(authStore.isAuthenticated ? "已登录" : "未登录")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(accountSubtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.textMuted)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(20)
        .background(AppTheme.surface.opacity(0.94), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.80), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 10)
    }

    private var settingsGroup: some View {
        VStack(spacing: 0) {
            SettingsRow(
                title: "消息通知",
                subtitle: "保持默认提醒",
                systemImage: "bell.fill",
                tint: AppTheme.purple600,
                background: AppTheme.purplePinkSoftGradient
            )

            Divider()
                .padding(.leading, 68)

            SettingsRow(
                title: "隐私与安全",
                subtitle: "账号安全状态正常",
                systemImage: "lock.shield.fill",
                tint: AppTheme.blue600,
                background: AppTheme.bluePurpleSoftGradient
            )

            Divider()
                .padding(.leading, 68)

            SettingsRow(
                title: "关于陪伴世界",
                subtitle: "AI 陪伴聊天 App",
                systemImage: "sparkles",
                tint: AppTheme.pink600,
                background: AppTheme.pinkPurpleSoftGradient
            )
        }
        .background(AppTheme.surface.opacity(0.94), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.80), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 14, x: 0, y: 8)
    }

    @ViewBuilder
    private var accountAction: some View {
        if authStore.isAuthenticated {
            Button {
                isShowingLogoutConfirmation = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                    Text("退出登录")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundStyle(AppTheme.warm)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(AppTheme.surface.opacity(0.94), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppTheme.warm.opacity(0.16), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 6)
            }
            .buttonStyle(.plain)
        } else {
            Button {
                isShowingLogin = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "person.badge.key.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text("登录账号")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(AppTheme.heroGradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: AppTheme.primary.opacity(0.22), radius: 14, x: 0, y: 8)
            }
            .buttonStyle(.plain)
        }
    }

    private var accountSubtitle: String {
        guard authStore.isAuthenticated else {
            return "登录后同步最近聊天"
        }

        if let user = authStore.user {
            return "\(user.countryCode) \(user.phoneNumber)"
        }

        return "账号状态正常"
    }
}

private struct SettingsRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    let background: LinearGradient

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 40, height: 40)
                .background(background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.textMuted)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.textTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
