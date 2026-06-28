import SwiftUI

struct LoginSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authStore: AuthStore
    @StateObject private var viewModel = LoginViewModel()

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            Color.black.opacity(0.50)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            VStack(spacing: 0) {
                header
                form
            }
            .frame(maxWidth: 384)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.20), radius: 28, x: 0, y: 16)
            .padding(.horizontal, 16)
        }
        .presentationBackground(.clear)
    }

    private var header: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 20, weight: .medium))
                    Text("陪伴世界")
                        .font(.system(size: 14))
                }
                .foregroundStyle(AppTheme.purple400)
                .padding(.bottom, 12)

                Text("欢迎回来")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(.bottom, 4)

                Text("使用手机号验证码登录")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 24)
            .padding(.bottom, 32)
            .padding(.horizontal, 24)

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(.white.opacity(0.80), in: Circle())
            }
            .buttonStyle(.plain)
            .padding(.top, 16)
            .padding(.trailing, 16)
        }
        .background(AppTheme.purplePinkSoftGradient)
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: 0) {
            phoneField
                .padding(.bottom, 16)

            codeField
                .padding(.bottom, 24)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.warm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 12)
            }

            Button {
                Task {
                    if await viewModel.login(authStore: authStore) {
                        dismiss()
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isLoggingIn {
                        ProgressView()
                            .tint(.white)
                    }
                    Text("登录")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(viewModel.canLogin ? AnyShapeStyle(AppTheme.heroGradient) : AnyShapeStyle(AppTheme.gray300), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: viewModel.canLogin ? AppTheme.primary.opacity(0.24) : .clear, radius: 12, x: 0, y: 8)
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canLogin)
            .padding(.bottom, 16)

            agreementText
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 24)
    }

    private var phoneField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("手机号")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.horizontal, 4)

            HStack(spacing: 12) {
                HStack(spacing: 0) {
                    Text("+86")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.textPrimary)

                    Spacer(minLength: 4)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.textTertiary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .frame(width: 80)
                .background(AppTheme.gray50, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(AppTheme.gray200, lineWidth: 1)
                )

                TextField("请输入手机号", text: $viewModel.phoneNumber)
                    .keyboardType(.numberPad)
                    .textContentType(.telephoneNumber)
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(AppTheme.gray50, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(AppTheme.gray200, lineWidth: 1)
                    )
                    .onChange(of: viewModel.phoneNumber) { _, value in
                        viewModel.phoneNumber = String(value.filter { $0.isNumber }.prefix(11))
                    }
            }
        }
    }

    private var codeField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("验证码")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.horizontal, 4)

            HStack(spacing: 12) {
                TextField("请输入验证码", text: $viewModel.verifyCode)
                    .keyboardType(.numberPad)
                    .textInputAutocapitalization(.never)
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(AppTheme.gray50, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(AppTheme.gray200, lineWidth: 1)
                    )
                    .onChange(of: viewModel.verifyCode) { _, value in
                        viewModel.verifyCode = String(value.filter { $0.isNumber }.prefix(4))
                    }

                Button {
                    Task { await viewModel.sendCode() }
                } label: {
                    Text(codeButtonTitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(viewModel.canSendCode ? AppTheme.purple600 : AppTheme.textTertiary)
                        .frame(minWidth: 78)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(viewModel.canSendCode ? AppTheme.purple50 : AppTheme.gray100, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(viewModel.canSendCode ? AppTheme.primary.opacity(0.24) : AppTheme.gray200, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canSendCode)
            }
        }
    }

    private var agreementText: some View {
        (Text("登录即表示同意")
            + Text("《用户协议》").foregroundColor(AppTheme.purple400)
            + Text("和")
            + Text("《隐私政策》").foregroundColor(AppTheme.purple400))
            .font(.system(size: 12))
            .foregroundColor(AppTheme.textTertiary)
            .multilineTextAlignment(.center)
            .lineSpacing(3)
            .frame(maxWidth: .infinity)
    }

    private var codeButtonTitle: String {
        if viewModel.isSendingCode {
            return "发送中"
        }
        if viewModel.retryAfter > 0 {
            return "\(viewModel.retryAfter)秒"
        }
        return "获取验证码"
    }
}
