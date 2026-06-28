import Alamofire
import Foundation

enum APIConfig {
    static let loginBaseURL = "https://aichat-login-kemznyglgb.cn-hangzhou.fcapp.run"
    static let chatBaseURL = "https://aichat-chat-nitnspniec.cn-hangzhou.fcapp.run"
}

final class APIClient {
    static let shared = APIClient()

    private let decoder = JSONDecoder()

    private init() {}

    func sendCode(countryCode: String = "86", phoneNumber: String) async throws -> SendCodeResult {
        try await request(
            baseURL: APIConfig.loginBaseURL,
            path: "/send-code",
            method: .post,
            parameters: [
                "countryCode": countryCode,
                "phoneNumber": phoneNumber
            ]
        )
    }

    func login(countryCode: String = "86", phoneNumber: String, verifyCode: String) async throws -> LoginSession {
        try await request(
            baseURL: APIConfig.loginBaseURL,
            path: "/login",
            method: .post,
            parameters: [
                "countryCode": countryCode,
                "phoneNumber": phoneNumber,
                "verifyCode": verifyCode
            ]
        )
    }

    func fetchRoles() async throws -> [ChatRole] {
        let result: RolesResult = try await request(
            baseURL: APIConfig.chatBaseURL,
            path: "/roles",
            method: .get
        )
        return result.roles
    }

    func fetchHistory(roleId: Int, beforeId: Int? = nil, limit: Int = 50, token: String) async throws -> ChatHistoryResult {
        var parameters: Parameters = [
            "roleId": roleId,
            "limit": min(max(limit, 1), 100)
        ]
        if let beforeId {
            parameters["beforeId"] = beforeId
        }

        return try await request(
            baseURL: APIConfig.chatBaseURL,
            path: "/history",
            method: .get,
            parameters: parameters,
            token: token
        )
    }

    func clearHistory(roleId: Int, token: String) async throws -> ClearHistoryResult {
        try await request(
            baseURL: APIConfig.chatBaseURL,
            path: "/history",
            method: .delete,
            parameters: ["roleId": roleId],
            token: token,
            encoding: URLEncoding.queryString
        )
    }

    @discardableResult
    func streamChat(
        roleId: Int,
        message: String?,
        imageDataURL: String? = nil,
        token: String,
        onEvent: @escaping (ChatStreamEvent) -> Void,
        onComplete: @escaping (Result<Void, APIError>) -> Void
    ) -> DataStreamRequest {
        let url = APIConfig.chatBaseURL + "/chat"
        let headers: HTTPHeaders = [
            .accept("text/event-stream"),
            .contentType("application/json"),
            .authorization(bearerToken: token)
        ]
        let parameters = StreamChatPayload(roleId: roleId, message: message, image: imageDataURL, stream: true)

        var buffer = ""
        let request = AF.streamRequest(
            url,
            method: .post,
            parameters: parameters,
            encoder: JSONParameterEncoder.default,
            headers: headers
        )
        .validate(statusCode: 200..<300)

        request.responseStreamString { [weak self] stream in
            guard let self else { return }

            switch stream.event {
            case .stream(let result):
                switch result {
                case .success(let chunk):
                    self.consume(chunk: chunk, buffer: &buffer, onEvent: onEvent)
                case .failure(let error):
                    onComplete(.failure(.transport(message: error.localizedDescription)))
                }
            case .complete(let completion):
                if !buffer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    self.parseSSEBlock(buffer, onEvent: onEvent)
                    buffer = ""
                }

                if let error = completion.error {
                    onComplete(.failure(.transport(message: error.localizedDescription)))
                } else {
                    onComplete(.success(()))
                }
            }
        }

        return request
    }

    private func request<T: Decodable>(
        baseURL: String,
        path: String,
        method: HTTPMethod,
        parameters: Parameters? = nil,
        token: String? = nil,
        encoding: ParameterEncoding? = nil
    ) async throws -> T {
        var headers: HTTPHeaders = [.accept("application/json")]
        if method != .get {
            headers.add(.contentType("application/json"))
        }
        if let token {
            headers.add(.authorization(bearerToken: token))
        }

        let selectedEncoding = encoding ?? ((method == .get) ? URLEncoding.default : JSONEncoding.default)

        do {
            let response = await AF.request(
                baseURL + path,
                method: method,
                parameters: parameters,
                encoding: selectedEncoding,
                headers: headers
            )
            .serializingData()
            .response

            if let error = response.error {
                throw APIError.transport(message: error.localizedDescription)
            }

            guard let statusCode = response.response?.statusCode else {
                throw APIError.transport(message: "服务器无响应")
            }

            let data = response.data ?? Data()

            guard 200..<300 ~= statusCode else {
                if let envelope = try? decoder.decode(APIErrorEnvelope.self, from: data) {
                    throw APIError.server(
                        code: envelope.code ?? "HTTP_\(statusCode)",
                        message: envelope.message ?? "请求失败，请稍后重试"
                    )
                }
                throw APIError.transport(message: "请求失败（HTTP \(statusCode)）")
            }

            let envelope = try decoder.decode(APIEnvelope<T>.self, from: data)

            guard envelope.success else {
                throw APIError.server(
                    code: envelope.code ?? "UNKNOWN_ERROR",
                    message: envelope.message ?? "请求失败，请稍后重试"
                )
            }
            guard let data = envelope.data else {
                throw APIError.missingData
            }
            return data
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.transport(message: error.localizedDescription)
        }
    }

    private func consume(chunk: String, buffer: inout String, onEvent: (ChatStreamEvent) -> Void) {
        buffer += chunk.replacingOccurrences(of: "\r\n", with: "\n")

        while let range = buffer.range(of: "\n\n") {
            let block = String(buffer[..<range.lowerBound])
            buffer.removeSubrange(buffer.startIndex..<range.upperBound)
            parseSSEBlock(block, onEvent: onEvent)
        }
    }

    private func parseSSEBlock(_ block: String, onEvent: (ChatStreamEvent) -> Void) {
        var eventName = ""
        var dataLines: [String] = []

        for line in block.split(separator: "\n", omittingEmptySubsequences: false) {
            if line.hasPrefix("event:") {
                eventName = line.dropFirst("event:".count).trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("data:") {
                dataLines.append(line.dropFirst("data:".count).trimmingCharacters(in: .whitespaces))
            }
        }

        let data = dataLines.joined(separator: "\n")
        guard let payload = data.data(using: .utf8) else { return }

        do {
            switch eventName {
            case "start":
                onEvent(.start(try decoder.decode(ChatStartEvent.self, from: payload)))
            case "delta":
                let delta = try decoder.decode(ChatDeltaEvent.self, from: payload)
                onEvent(.delta(delta.content))
            case "done":
                onEvent(.done(try decoder.decode(ChatDoneEvent.self, from: payload)))
            case "error":
                let error = try decoder.decode(ChatErrorEvent.self, from: payload)
                onEvent(.failure(.server(code: error.code, message: error.message)))
            default:
                break
            }
        } catch {
            onEvent(.failure(.transport(message: "解析流式响应失败")))
        }
    }
}

private struct StreamChatPayload: Encodable, Sendable {
    let roleId: Int
    let message: String?
    let image: String?
    let stream: Bool
}

private struct APIErrorEnvelope: Decodable {
    let success: Bool?
    let code: String?
    let message: String?
}
