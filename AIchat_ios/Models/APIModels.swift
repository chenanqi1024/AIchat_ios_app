import Foundation

struct APIEnvelope<T: Decodable>: Decodable {
    let success: Bool
    let code: String?
    let message: String?
    let data: T?
}

struct SendCodeResult: Decodable {
    let bizId: String?
    let expiresIn: Int
    let retryAfter: Int
}

struct LoginSession: Decodable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let user: AppUser
}

struct AppUser: Codable, Equatable {
    let id: Int
    let countryCode: String
    let phoneNumber: String
}

struct RolesResult: Decodable {
    let roles: [ChatRole]
}

struct ChatRole: Codable, Identifiable, Equatable, Hashable {
    let id: Int
    let key: String
    let nickname: String
    let description: String
    let avatarUrl: String?
    let backgroundUrl: String?
}

enum MessageSender: String, Codable {
    case user
    case assistant
}

struct ChatMessage: Codable, Identifiable, Equatable {
    let id: Int
    let sender: MessageSender
    var content: String
    let createdAt: String?
    var localImageData: Data? = nil
}

struct ChatHistoryResult: Decodable {
    let conversationId: Int?
    let roleId: Int
    let messages: [ChatMessage]
    let hasMore: Bool
    let nextBeforeId: Int?
}

struct ClearHistoryResult: Decodable {
    let conversationId: Int?
    let roleId: Int
    let deletedCount: Int
}

struct ChatStartEvent: Decodable {
    let conversationId: Int
    let roleId: Int
    let userMessage: ChatMessage
}

struct ChatDeltaEvent: Decodable {
    let content: String
}

struct ChatDoneEvent: Decodable {
    let assistantMessage: ChatMessage
    let usage: ChatUsage?
}

struct ChatUsage: Decodable {
    let totalTokens: Int?

    enum CodingKeys: String, CodingKey {
        case totalTokens = "total_tokens"
    }
}

struct ChatErrorEvent: Decodable {
    let code: String
    let message: String
}

enum ChatStreamEvent {
    case start(ChatStartEvent)
    case delta(String)
    case done(ChatDoneEvent)
    case failure(APIError)
}

enum APIError: LocalizedError, Identifiable, Equatable {
    case missingData
    case missingToken
    case server(code: String, message: String)
    case transport(message: String)

    var id: String {
        switch self {
        case .missingData:
            return "missingData"
        case .missingToken:
            return "missingToken"
        case .server(let code, let message):
            return "\(code)-\(message)"
        case .transport(let message):
            return "transport-\(message)"
        }
    }

    var errorDescription: String? {
        switch self {
        case .missingData:
            return "服务器返回数据为空"
        case .missingToken:
            return "请先登录后继续"
        case .server(_, let message):
            return message
        case .transport(let message):
            return message
        }
    }

    var requiresLogin: Bool {
        switch self {
        case .server(let code, _):
            return ["AUTH_REQUIRED", "INVALID_TOKEN", "TOKEN_EXPIRED"].contains(code)
        case .missingToken:
            return true
        case .missingData, .transport:
            return false
        }
    }
}
