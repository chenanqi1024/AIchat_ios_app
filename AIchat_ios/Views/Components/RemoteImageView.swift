import NukeUI
import SwiftUI

struct RemoteImageView: View {
    let urlString: String?
    var contentMode: ContentMode = .fill

    var body: some View {
        if let urlString,
           let url = URL(string: urlString) {
            LazyImage(url: url) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                } else if state.error != nil {
                    placeholder
                } else {
                    ZStack {
                        placeholder
                        ProgressView()
                            .tint(AppTheme.primary)
                    }
                }
            }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        LinearGradient(
            colors: [AppTheme.elevated, Color(red: 0.90, green: 0.88, blue: 0.96)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
