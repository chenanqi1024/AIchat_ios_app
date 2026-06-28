import PhotosUI
import SwiftUI
import UIKit

struct ChatView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authStore: AuthStore
    @StateObject private var viewModel: ChatViewModel
    @State private var isShowingLogin = false
    @State private var isShowingClearConfirm = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var selectedImageDataURL: String?
    @State private var isProcessingImage = false
    @State private var imageErrorMessage: String?

    private let horizontalInset: CGFloat = 24

    private let quickTopics = [
        "今天有点累",
        "安慰我一下",
        "陪我聊聊天",
        "听我说说话"
    ]

    init(role: ChatRole) {
        _viewModel = StateObject(wrappedValue: ChatViewModel(role: role))
    }

    var body: some View {
        ZStack {
            ChatPatternBackgroundView(imageURL: viewModel.role.backgroundImageURL)

            VStack(spacing: 0) {
                topNavigation
                messagesView
                quickTopicsView
                composer
            }
            .ignoresSafeArea(edges: .top)
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .confirmationDialog("清空与 \(viewModel.role.displayName) 的聊天记录？", isPresented: $isShowingClearConfirm, titleVisibility: .visible) {
            Button("清空聊天", role: .destructive) {
                Task { await clearHistory() }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("该操作只会清空当前账号与此角色的聊天历史。")
        }
        .fullScreenCover(isPresented: $isShowingLogin) {
            LoginSheetView()
                .environmentObject(authStore)
        }
        .task {
            await loadHistory()
        }
        .onChange(of: authStore.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                Task { await loadHistory() }
            }
        }
        .onChange(of: selectedPhotoItem) { _, item in
            Task { await processSelectedPhoto(item) }
        }
        .onDisappear {
            viewModel.cancelStream()
        }
    }

    private var topNavigation: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(AppTheme.elevated, in: Circle())
            }
            .buttonStyle(.plain)

            RemoteImageView(urlString: viewModel.role.avatarImageURL)
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .overlay(Circle().stroke(.white, lineWidth: 2))
                .shadow(color: .black.opacity(0.08), radius: 5, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.role.displayName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(viewModel.role.chatTag)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.textMuted)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Button {
                isShowingClearConfirm = true
            } label: {
                Image(systemName: "trash")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(AppTheme.elevated, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, horizontalInset)
        .padding(.top, 48)
        .padding(.bottom, 12)
        .background(.white.opacity(0.90))
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.white.opacity(0.50))
                .frame(height: 1)
        }
    }

    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 16) {
                    if viewModel.hasMore {
                        Button {
                            Task { await loadEarlier() }
                        } label: {
                            if viewModel.isLoadingEarlier {
                                ProgressView()
                                    .tint(AppTheme.primary)
                            } else {
                                Text("加载更早消息")
                                    .font(.footnote.weight(.semibold))
                            }
                        }
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.vertical, 8)
                    }

                    if viewModel.isLoadingHistory {
                        ProgressView("加载聊天记录")
                            .tint(AppTheme.primary)
                            .foregroundStyle(AppTheme.textSecondary)
                            .padding(.top, 80)
                    } else if viewModel.messages.isEmpty {
                        welcomeState
                            .padding(.top, 16)
                    }

                    ForEach(viewModel.messages) { message in
                        MessageBubbleView(message: message, assistantAvatarURL: viewModel.role.avatarImageURL)
                            .id(message.id)
                    }
                }
                .padding(.horizontal, horizontalInset)
                .padding(.top, 16)
                .padding(.bottom, 8)
            }
            .onChange(of: viewModel.messages) { _, messages in
                guard let last = messages.last else { return }
                withAnimation(.easeOut(duration: 0.22)) {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }

    private var welcomeState: some View {
        HStack(alignment: .top, spacing: 10) {
            RemoteImageView(urlString: viewModel.role.avatarImageURL)
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                .padding(.top, 4)

            Text(viewModel.role.welcomeMessage)
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.textAssistant)
                .lineSpacing(3)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .leading)
                .background(AppTheme.surface, in: UnevenRoundedRectangle(
                    topLeadingRadius: 16,
                    bottomLeadingRadius: 4,
                    bottomTrailingRadius: 16,
                    topTrailingRadius: 16,
                    style: .continuous
                ))
                .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)

            Spacer(minLength: 36)
        }
    }

    private var quickTopicsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(quickTopics, id: \.self) { topic in
                    Button {
                        viewModel.draft = topic
                    } label: {
                        Text(topic)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppTheme.textPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(AppTheme.surface, in: Capsule())
                            .overlay(Capsule().stroke(AppTheme.gray100, lineWidth: 1))
                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 3)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isSending)
                }
            }
            .padding(.horizontal, horizontalInset)
            .padding(.vertical, 8)
        }
    }

    private var composer: some View {
        VStack(spacing: 8) {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.warm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, horizontalInset)
            }

            if let imageErrorMessage {
                Text(imageErrorMessage)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.warm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, horizontalInset)
            }

            if selectedImageData != nil || isProcessingImage {
                imageAttachmentPreview
            }

            HStack(alignment: .bottom, spacing: 8) {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                    Image(systemName: isProcessingImage ? "hourglass" : "photo")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(isProcessingImage ? AppTheme.textTertiary : AppTheme.textPrimary)
                        .frame(width: 40, height: 40)
                        .background(AppTheme.gray100, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isSending || isProcessingImage)

                TextField("说点什么...", text: $viewModel.draft, axis: .vertical)
                    .lineLimit(1...5)
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.textAssistant)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(AppTheme.gray100, in: RoundedRectangle(cornerRadius: 24, style: .continuous))

                Button {
                    if viewModel.isSending {
                        viewModel.cancelStream()
                    } else {
                        let didSend = viewModel.send(
                            token: authStore.accessToken,
                            imageDataURL: selectedImageDataURL,
                            localImageData: selectedImageData
                        ) {
                            authStore.clear()
                            isShowingLogin = true
                        }
                        if didSend {
                            clearSelectedImage()
                        }
                    }
                } label: {
                    Image(systemName: viewModel.isSending ? "stop.fill" : "paperplane.fill")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(viewModel.isSending || canSend ? .white : AppTheme.textTertiary)
                        .frame(width: 40, height: 40)
                        .background(sendButtonBackground, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.isSending && !canSend)
            }
            .padding(.horizontal, horizontalInset)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(.white.opacity(0.82))
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.gray.opacity(0.14))
            .frame(height: 1)
        }
    }

    @ViewBuilder
    private var imageAttachmentPreview: some View {
        HStack(spacing: 12) {
            Group {
                if let selectedImageData,
                   let image = UIImage(data: selectedImageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        AppTheme.gray100
                        ProgressView()
                            .tint(AppTheme.primary)
                    }
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text(isProcessingImage ? "正在处理图片" : "图片已添加")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.textPrimary)

            Spacer(minLength: 0)

            if selectedImageData != nil {
                Button {
                    clearSelectedImage()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(width: 28, height: 28)
                        .background(AppTheme.gray100, in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(AppTheme.surface.opacity(0.88), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.gray100, lineWidth: 1)
        )
        .padding(.horizontal, horizontalInset)
    }

    private var hasDraft: Bool {
        !viewModel.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var hasImage: Bool {
        selectedImageDataURL != nil && selectedImageData != nil
    }

    private var canSend: Bool {
        !isProcessingImage && (hasDraft || hasImage)
    }

    private var sendButtonBackground: AnyShapeStyle {
        if viewModel.isSending || canSend {
            return AnyShapeStyle(AppTheme.heroGradient)
        }
        return AnyShapeStyle(Color.gray.opacity(0.28))
    }

    private func loadHistory() async {
        if let error = await viewModel.loadHistory(token: authStore.accessToken), error.requiresLogin {
            authStore.clear()
            isShowingLogin = true
        }
    }

    private func loadEarlier() async {
        if let error = await viewModel.loadEarlier(token: authStore.accessToken), error.requiresLogin {
            authStore.clear()
            isShowingLogin = true
        }
    }

    private func clearHistory() async {
        if let error = await viewModel.clearHistory(token: authStore.accessToken), error.requiresLogin {
            authStore.clear()
            isShowingLogin = true
        }
    }

    @MainActor
    private func processSelectedPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }

        isProcessingImage = true
        imageErrorMessage = nil
        selectedImageData = nil
        selectedImageDataURL = nil

        do {
            guard let originalData = try await item.loadTransferable(type: Data.self) else {
                throw ChatImageCompressionError.invalidImage
            }

            let attachment = try await Task.detached(priority: .userInitiated) {
                try ChatImageCompressor.compress(originalData)
            }.value

            selectedImageData = attachment.data
            selectedImageDataURL = attachment.dataURL
        } catch {
            imageErrorMessage = error.localizedDescription
            selectedPhotoItem = nil
        }

        isProcessingImage = false
    }

    private func clearSelectedImage() {
        selectedPhotoItem = nil
        selectedImageData = nil
        selectedImageDataURL = nil
        imageErrorMessage = nil
    }
}

private struct CompressedImageAttachment {
    let data: Data
    let dataURL: String
}

private enum ChatImageCompressionError: LocalizedError {
    case invalidImage
    case compressionFailed
    case imageTooLarge

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "无法读取这张图片"
        case .compressionFailed:
            return "图片压缩失败，请换一张图片试试"
        case .imageTooLarge:
            return "图片压缩后仍超过 6MB，请换一张更小的图片"
        }
    }
}

private enum ChatImageCompressor {
    private static let maxSide: CGFloat = 1440
    private static let maxBytes = 6 * 1024 * 1024

    static func compress(_ data: Data) throws -> CompressedImageAttachment {
        guard let image = UIImage(data: data) else {
            throw ChatImageCompressionError.invalidImage
        }

        let resizedImage = resize(image)
        let qualities: [CGFloat] = [0.86, 0.78, 0.70, 0.62, 0.55, 0.48]

        for quality in qualities {
            guard let jpegData = resizedImage.jpegData(compressionQuality: quality) else {
                continue
            }
            if jpegData.count <= maxBytes {
                return CompressedImageAttachment(
                    data: jpegData,
                    dataURL: "data:image/jpeg;base64,\(jpegData.base64EncodedString())"
                )
            }
        }

        throw ChatImageCompressionError.imageTooLarge
    }

    private static func resize(_ image: UIImage) -> UIImage {
        let pixelSize = CGSize(
            width: image.cgImage.map { CGFloat($0.width) } ?? image.size.width * image.scale,
            height: image.cgImage.map { CGFloat($0.height) } ?? image.size.height * image.scale
        )

        let longSide = max(pixelSize.width, pixelSize.height)
        guard longSide > 0 else { return image }

        let ratio = min(1, maxSide / longSide)
        let targetSize = CGSize(
            width: max(1, floor(pixelSize.width * ratio)),
            height: max(1, floor(pixelSize.height * ratio))
        )

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        return UIGraphicsImageRenderer(size: targetSize, format: format).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: targetSize))
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
