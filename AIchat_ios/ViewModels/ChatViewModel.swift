import Alamofire
import Combine
import Foundation

@MainActor
final class ChatViewModel: ObservableObject {
    @Published private(set) var messages: [ChatMessage] = []
    @Published var draft = ""
    @Published var errorMessage: String?
    @Published var isLoadingHistory = false
    @Published var isLoadingEarlier = false
    @Published var isSending = false
    @Published var hasMore = false

    let role: ChatRole

    private let apiClient: APIClient
    private var nextBeforeId: Int?
    private var streamRequest: DataStreamRequest?
    private var pendingUserMessageId: Int?
    private var pendingAssistantMessageId: Int?
    private var nextTemporaryId = -1

    init(role: ChatRole, apiClient: APIClient = .shared) {
        self.role = role
        self.apiClient = apiClient
    }

    func loadHistory(token: String?) async -> APIError? {
        guard let token else {
            return .missingToken
        }

        isLoadingHistory = true
        errorMessage = nil
        defer { isLoadingHistory = false }

        do {
            let result = try await apiClient.fetchHistory(roleId: role.id, token: token)
            messages = result.messages
            hasMore = result.hasMore
            nextBeforeId = result.nextBeforeId
            return nil
        } catch let error as APIError {
            errorMessage = error.localizedDescription
            return error
        } catch {
            errorMessage = error.localizedDescription
            return .transport(message: error.localizedDescription)
        }
    }

    func loadEarlier(token: String?) async -> APIError? {
        guard let token else {
            return .missingToken
        }
        guard hasMore, let nextBeforeId, !isLoadingEarlier else {
            return nil
        }

        isLoadingEarlier = true
        errorMessage = nil
        defer { isLoadingEarlier = false }

        do {
            let result = try await apiClient.fetchHistory(roleId: role.id, beforeId: nextBeforeId, token: token)
            messages.insert(contentsOf: result.messages, at: 0)
            hasMore = result.hasMore
            self.nextBeforeId = result.nextBeforeId
            return nil
        } catch let error as APIError {
            errorMessage = error.localizedDescription
            return error
        } catch {
            errorMessage = error.localizedDescription
            return .transport(message: error.localizedDescription)
        }
    }

    @discardableResult
    func send(
        token: String?,
        imageDataURL: String? = nil,
        localImageData: Data? = nil,
        onAuthExpired: @escaping () -> Void
    ) -> Bool {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        let imageDataURL = imageDataURL?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !isSending else { return false }
        guard !text.isEmpty || imageDataURL?.isEmpty == false else { return false }
        guard let token else {
            errorMessage = APIError.missingToken.localizedDescription
            onAuthExpired()
            return false
        }

        errorMessage = nil
        draft = ""
        isSending = true

        let userId = makeTemporaryId()
        let assistantId = makeTemporaryId()
        pendingUserMessageId = userId
        pendingAssistantMessageId = assistantId

        messages.append(ChatMessage(id: userId, sender: .user, content: text, createdAt: nil, localImageData: localImageData))
        messages.append(ChatMessage(id: assistantId, sender: .assistant, content: "", createdAt: nil))

        streamRequest?.cancel()
        streamRequest = apiClient.streamChat(
            roleId: role.id,
            message: text.isEmpty ? nil : text,
            imageDataURL: imageDataURL?.isEmpty == false ? imageDataURL : nil,
            token: token,
            onEvent: { [weak self] event in
                Task { @MainActor in
                    self?.handle(event: event, onAuthExpired: onAuthExpired)
                }
            },
            onComplete: { [weak self] result in
                Task { @MainActor in
                    self?.finishStreaming(result: result, onAuthExpired: onAuthExpired)
                }
            }
        )
        return true
    }

    func clearHistory(token: String?) async -> APIError? {
        guard let token else {
            return .missingToken
        }

        errorMessage = nil

        do {
            _ = try await apiClient.clearHistory(roleId: role.id, token: token)
            messages.removeAll()
            hasMore = false
            nextBeforeId = nil
            return nil
        } catch let error as APIError {
            errorMessage = error.localizedDescription
            return error
        } catch {
            errorMessage = error.localizedDescription
            return .transport(message: error.localizedDescription)
        }
    }

    func cancelStream() {
        streamRequest?.cancel()
        streamRequest = nil
        isSending = false

        if let assistantId = pendingAssistantMessageId,
           let index = messages.firstIndex(where: { $0.id == assistantId }),
           messages[index].content.isEmpty {
            messages[index].content = "已停止回复。"
        }
    }

    private func handle(event: ChatStreamEvent, onAuthExpired: @escaping () -> Void) {
        switch event {
        case .start(let start):
            replaceMessage(id: pendingUserMessageId, with: start.userMessage)
        case .delta(let content):
            appendAssistantDelta(content)
        case .done(let done):
            replaceMessage(id: pendingAssistantMessageId, with: done.assistantMessage)
            isSending = false
        case .failure(let error):
            errorMessage = error.localizedDescription
            isSending = false
            if error.requiresLogin {
                onAuthExpired()
            }
        }
    }

    private func finishStreaming(result: Result<Void, APIError>, onAuthExpired: @escaping () -> Void) {
        streamRequest = nil
        isSending = false

        if case .failure(let error) = result {
            errorMessage = error.localizedDescription
            if error.requiresLogin {
                onAuthExpired()
            }
        }

        if let assistantId = pendingAssistantMessageId,
           let index = messages.firstIndex(where: { $0.id == assistantId }),
           messages[index].content.isEmpty,
           errorMessage == nil {
            messages[index].content = "我刚刚没有收到完整回复，请再试一次。"
        }
    }

    private func appendAssistantDelta(_ content: String) {
        guard let assistantId = pendingAssistantMessageId,
              let index = messages.firstIndex(where: { $0.id == assistantId }) else {
            return
        }
        messages[index].content += content
    }

    private func replaceMessage(id: Int?, with message: ChatMessage) {
        guard let id, let index = messages.firstIndex(where: { $0.id == id }) else {
            messages.append(message)
            return
        }
        var replacement = message
        if replacement.localImageData == nil {
            replacement.localImageData = messages[index].localImageData
        }
        messages[index] = replacement
    }

    private func makeTemporaryId() -> Int {
        defer { nextTemporaryId -= 1 }
        return nextTemporaryId
    }
}
