import Combine
import Foundation

struct RecentChatPreview: Identifiable, Equatable {
    var id: Int { role.id }

    let role: ChatRole
    let lastMessage: String
    let timeText: String
}

@MainActor
final class RoleListViewModel: ObservableObject {
    @Published private(set) var roles: [ChatRole] = []
    @Published private(set) var recentChats: [RecentChatPreview] = []
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var isLoadingRecentChats = false

    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func loadRoles() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            roles = ChatRole.figmaOrdered(try await apiClient.fetchRoles())
        } catch {
            roles = ChatRole.figmaDefaults
            errorMessage = error.localizedDescription
        }
    }

    func loadRecentChats(token: String?) async {
        guard let token, !token.isEmpty, !roles.isEmpty else {
            recentChats = []
            return
        }
        guard !isLoadingRecentChats else { return }

        isLoadingRecentChats = true
        defer { isLoadingRecentChats = false }

        var previews: [RecentChatPreview] = []

        for role in roles {
            do {
                let result = try await apiClient.fetchHistory(roleId: role.id, limit: 20, token: token)
                guard let message = result.messages.last else { continue }
                previews.append(
                    RecentChatPreview(
                        role: role,
                        lastMessage: message.content,
                        timeText: Self.relativeTimeText(from: message.createdAt)
                    )
                )
            } catch {
                continue
            }
        }

        recentChats = previews
    }

    private static func relativeTimeText(from createdAt: String?) -> String {
        guard let createdAt,
              let date = ISO8601DateFormatter.apiDateFormatter.date(from: createdAt) else {
            return "刚刚"
        }

        if Calendar.current.isDateInToday(date) {
            return DateFormatter.chatTimeFormatter.string(from: date)
        }

        if Calendar.current.isDateInYesterday(date) {
            return "昨天 " + DateFormatter.chatTimeFormatter.string(from: date)
        }

        return DateFormatter.chatDateFormatter.string(from: date)
    }
}

private extension ISO8601DateFormatter {
    static let apiDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}

private extension DateFormatter {
    static let chatTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    static let chatDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter
    }()
}
