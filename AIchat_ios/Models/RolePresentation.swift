import Foundation

struct FigmaRoleVisual: Equatable {
    let id: Int
    let key: String
    let nickname: String
    let onboardingDescription: String
    let homeTag: String
    let homeDescription: String
    let chatTag: String
    let greeting: String
    let welcomeMessage: String
    let avatarURL: String
    let backgroundURL: String

    static let all: [FigmaRoleVisual] = [
        FigmaRoleVisual(
            id: 1,
            key: "naitang",
            nickname: "奶糖",
            onboardingDescription: "猫咪系陪伴角色",
            homeTag: "猫咪系",
            homeDescription: "喵~ 想要被温柔陪伴的一天",
            chatTag: "猫咪系陪伴角色",
            greeting: "今天也要开心喵~",
            welcomeMessage: "喵呜，我是奶糖，今天也想黏在你身边陪你聊天呀。你想先跟我说说现在的心情，还是让我蹭蹭你再开始？",
            avatarURL: "https://zzz-pet.oss-cn-hangzhou.aliyuncs.com/image/chat_avatar_cat.jpg",
            backgroundURL: "https://zzz-pet.oss-cn-hangzhou.aliyuncs.com/image/chat_bg_cat.jpg"
        ),
        FigmaRoleVisual(
            id: 2,
            key: "wanqing",
            nickname: "晚晴",
            onboardingDescription: "温柔成熟的姐姐型陪伴角色",
            homeTag: "温柔姐姐",
            homeDescription: "愿意倾听你所有的心事",
            chatTag: "温柔姐姐型陪伴角色",
            greeting: "有什么想聊的吗？",
            welcomeMessage: "你好呀，我是晚晴。看起来你今天也经历了很多事情呢，想和我聊聊吗？我会一直陪着你的。",
            avatarURL: "https://zzz-pet.oss-cn-hangzhou.aliyuncs.com/image/chat_avatar_girl.jpg",
            backgroundURL: "https://zzz-pet.oss-cn-hangzhou.aliyuncs.com/image/chat_bg_girl.jpg"
        ),
        FigmaRoleVisual(
            id: 3,
            key: "yaochuan",
            nickname: "曜川",
            onboardingDescription: "阳光帅气的少年型陪伴角色",
            homeTag: "阳光少年",
            homeDescription: "用笑容驱散你的阴霾",
            chatTag: "阳光少年型陪伴角色",
            greeting: "嘿！今天过得怎么样？",
            welcomeMessage: "嘿！我是曜川，很高兴能陪你聊天。不管遇到什么事，我都会在你身边的！今天过得怎么样？",
            avatarURL: "https://zzz-pet.oss-cn-hangzhou.aliyuncs.com/image/chat_avatar_boy.jpg",
            backgroundURL: "https://zzz-pet.oss-cn-hangzhou.aliyuncs.com/image/chat_bg_boy.jpg"
        ),
        FigmaRoleVisual(
            id: 4,
            key: "xiaofu",
            nickname: "小芙",
            onboardingDescription: "梦境系精灵陪伴角色",
            homeTag: "梦境精灵",
            homeDescription: "在梦境中寻找温暖的陪伴",
            chatTag: "梦境精灵陪伴角色",
            greeting: "要一起做个美梦吗？",
            welcomeMessage: "嗨~ 我是小芙，来自梦境的精灵。在这里，你可以和我分享任何想说的话，就像在温柔的梦里一样安心。",
            avatarURL: "https://zzz-pet.oss-cn-hangzhou.aliyuncs.com/image/chat_avatar_elf.jpg",
            backgroundURL: "https://zzz-pet.oss-cn-hangzhou.aliyuncs.com/image/chat_bg_elf.jpg"
        )
    ]

    static func match(for role: ChatRole) -> FigmaRoleVisual? {
        all.first { $0.key == role.key } ?? all.first { $0.id == role.id }
    }
}

extension ChatRole {
    static let figmaDefaults: [ChatRole] = FigmaRoleVisual.all.map { visual in
        ChatRole(
            id: visual.id,
            key: visual.key,
            nickname: visual.nickname,
            description: visual.onboardingDescription,
            avatarUrl: visual.avatarURL,
            backgroundUrl: visual.backgroundURL
        )
    }

    static func figmaOrdered(_ roles: [ChatRole]) -> [ChatRole] {
        var remaining = roles
        var ordered: [ChatRole] = []

        for visual in FigmaRoleVisual.all {
            if let index = remaining.firstIndex(where: { $0.key == visual.key || $0.id == visual.id }) {
                ordered.append(remaining.remove(at: index))
            } else {
                ordered.append(
                    ChatRole(
                        id: visual.id,
                        key: visual.key,
                        nickname: visual.nickname,
                        description: visual.onboardingDescription,
                        avatarUrl: visual.avatarURL,
                        backgroundUrl: visual.backgroundURL
                    )
                )
            }
        }

        return ordered + remaining
    }

    var figmaVisual: FigmaRoleVisual? {
        FigmaRoleVisual.match(for: self)
    }

    var displayName: String {
        figmaVisual?.nickname ?? nickname
    }

    var onboardingDescription: String {
        figmaVisual?.onboardingDescription ?? description
    }

    var homeDescription: String {
        figmaVisual?.homeDescription ?? description
    }

    var displayTag: String {
        figmaVisual?.homeTag ?? description.replacingOccurrences(of: "陪伴角色", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var chatTag: String {
        figmaVisual?.chatTag ?? description
    }

    var greeting: String {
        figmaVisual?.greeting ?? "我在这里，随时听你说。"
    }

    var welcomeMessage: String {
        figmaVisual?.welcomeMessage ?? "你好，我是 \(displayName)。把想说的话慢慢告诉我吧，我会认真听。"
    }

    var avatarImageURL: String? {
        figmaVisual?.avatarURL ?? avatarUrl
    }

    var backgroundImageURL: String? {
        figmaVisual?.backgroundURL ?? backgroundUrl
    }
}
