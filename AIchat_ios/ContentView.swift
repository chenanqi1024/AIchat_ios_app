//
//  ContentView.swift
//  AIchat_ios
//
//  Created by chenanqi on 2026/6/28.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authStore = AuthStore()

    var body: some View {
        AppRootView()
            .environmentObject(authStore)
            .tint(AppTheme.primary)
    }
}

#Preview {
    ContentView()
}
