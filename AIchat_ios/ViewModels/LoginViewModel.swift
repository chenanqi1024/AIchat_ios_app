import Combine
import Foundation

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var phoneNumber = ""
    @Published var verifyCode = ""
    @Published var errorMessage: String?
    @Published var isSendingCode = false
    @Published var isLoggingIn = false
    @Published var retryAfter = 0

    private var timerCancellable: AnyCancellable?
    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    var canSendCode: Bool {
        isValidPhone && !isSendingCode && retryAfter == 0
    }

    var canLogin: Bool {
        isValidPhone && verifyCode.count >= 4 && !isLoggingIn
    }

    func sendCode() async {
        guard isValidPhone else {
            errorMessage = "请输入 11 位中国大陆手机号"
            return
        }

        errorMessage = nil
        isSendingCode = true
        defer { isSendingCode = false }

        do {
            let result = try await apiClient.sendCode(phoneNumber: phoneNumber)
            startCountdown(seconds: result.retryAfter)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func login(authStore: AuthStore) async -> Bool {
        guard canLogin else {
            errorMessage = "请输入手机号和验证码"
            return false
        }

        errorMessage = nil
        isLoggingIn = true
        defer { isLoggingIn = false }

        do {
            let session = try await apiClient.login(phoneNumber: phoneNumber, verifyCode: verifyCode)
            authStore.update(with: session)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private var isValidPhone: Bool {
        phoneNumber.count == 11 && phoneNumber.allSatisfy(\.isNumber)
    }

    private func startCountdown(seconds: Int) {
        retryAfter = max(seconds, 0)
        timerCancellable?.cancel()

        guard retryAfter > 0 else { return }

        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                if self.retryAfter > 0 {
                    self.retryAfter -= 1
                }
                if self.retryAfter == 0 {
                    self.timerCancellable?.cancel()
                    self.timerCancellable = nil
                }
            }
    }
}
