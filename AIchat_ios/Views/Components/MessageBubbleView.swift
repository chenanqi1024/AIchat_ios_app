import SwiftUI
import UIKit

struct MessageBubbleView: View {
    let message: ChatMessage
    let assistantAvatarURL: String?

    private var isUser: Bool {
        message.sender == .user
    }

    private var maxContentWidth: CGFloat {
        UIScreen.main.bounds.width * 0.72
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if isUser {
                Spacer(minLength: 56)
            } else {
                assistantAvatar
            }

            messageContent

            if !isUser {
                Spacer(minLength: 56)
            }
        }
    }

    private var messageContent: some View {
        VStack(alignment: isUser ? .trailing : .leading, spacing: 6) {
            if let localImageData = message.localImageData,
               let image = UIImage(data: localImageData) {
                imageAttachment(image)
            }

            if message.content.isEmpty && !isUser && message.localImageData == nil {
                thinkingBubble
            } else if !message.content.isEmpty {
                textBubble(message.content)
            }
        }
        .frame(maxWidth: maxContentWidth, alignment: isUser ? .trailing : .leading)
    }

    private var thinkingBubble: some View {
        HStack(spacing: 8) {
            ProgressView()
                .tint(AppTheme.primary)

            Text("思考中")
                .font(.system(size: 14))
        }
        .foregroundStyle(AppTheme.textAssistant)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            AppTheme.surface,
            in: UnevenRoundedRectangle(
                topLeadingRadius: 16,
                bottomLeadingRadius: 4,
                bottomTrailingRadius: 16,
                topTrailingRadius: 16,
                style: .continuous
            )
        )
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
    }

    private func textBubble(_ content: String) -> some View {
        ViewThatFits(in: .horizontal) {
            bubbleText(content)
                .fixedSize(horizontal: true, vertical: false)

            bubbleText(content)
                .frame(maxWidth: maxContentWidth, alignment: isUser ? .trailing : .leading)
        }
    }

    private func bubbleText(_ content: String) -> some View {
        Text(content)
            .font(.system(size: 14))
            .lineSpacing(3)
            .textSelection(.enabled)
            .foregroundStyle(isUser ? Color.white : AppTheme.textAssistant)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                isUser ? AnyShapeStyle(AppTheme.heroGradient) : AnyShapeStyle(AppTheme.surface),
                in: UnevenRoundedRectangle(
                    topLeadingRadius: 16,
                    bottomLeadingRadius: isUser ? 16 : 4,
                    bottomTrailingRadius: isUser ? 4 : 16,
                    topTrailingRadius: 16,
                    style: .continuous
                )
            )
            .shadow(color: .black.opacity(isUser ? 0 : 0.08), radius: isUser ? 0 : 6, x: 0, y: isUser ? 0 : 3)
    }

    private func imageAttachment(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: min(220, maxContentWidth), maxHeight: 220)
            .padding(4)
            .background(AppTheme.surface.opacity(0.96), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.88), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.10), radius: 10, x: 0, y: 6)
    }

    private var assistantAvatar: some View {
        RemoteImageView(urlString: assistantAvatarURL)
            .frame(width: 32, height: 32)
            .clipShape(Circle())
            .padding(.top, 4)
    }
}
