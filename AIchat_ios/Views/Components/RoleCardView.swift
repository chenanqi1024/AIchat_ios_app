import SwiftUI

struct RoleCardView: View {
    let role: ChatRole
    let isLocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                RemoteImageView(urlString: role.backgroundImageURL)
                    .frame(height: 190)
                    .clipped()

                LinearGradient(
                    colors: [.white.opacity(0.10), .white.opacity(0.88)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .bottom, spacing: 14) {
                        RemoteImageView(urlString: role.avatarImageURL)
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(.white.opacity(0.32), lineWidth: 1)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(role.displayName)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(AppTheme.textPrimary)

                            Text(role.homeDescription)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textSecondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }

                        Spacer()
                    }

                    HStack {
                        Label(isLocked ? "登录后聊天" : "开始聊天", systemImage: isLocked ? "lock.fill" : "sparkles")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.82))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .background(AppTheme.heroGradient, in: Capsule())
                }
                .padding(18)
            }
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.75), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.10), radius: 16, x: 0, y: 12)
        }
        .buttonStyle(.plain)
    }
}
