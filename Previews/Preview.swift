import SwiftUI

#Preview("主页") {
    HomeView()
        .frame(width: 1180, height: 780)
}

#Preview("编辑器") {
    EditorView(controller: EditorController())
        .frame(width: 940, height: 720)
}

#Preview("设置") {
    SettingsView()
        .frame(width: 780, height: 620)
}

#Preview("关于") {
    SettingsView()
        .frame(width: 780, height: 620)
        .onAppear { SettingsModel.shared.page = "about" }
}

#Preview("OOBE") {
    OnboardingView(model: OnboardingModel())
        .frame(width: 640, height: 500)
}

#Preview("启动浮层") {
    SplashView()
        .frame(width: 400, height: 280)
        .background(.gray.opacity(0.2))
}
