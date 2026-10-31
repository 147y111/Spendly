import SwiftUI

struct ProfileRootView: View {
    @EnvironmentObject var userStore: UserStore
    @EnvironmentObject var appSettings: AppSettings

    var body: some View {
        NavigationStack {
            ProfileView()
                .environmentObject(userStore)
                .environmentObject(appSettings)
        }
    }
}

#Preview {
    ProfileRootView()
        .environmentObject(UserStore())
        .environmentObject(AppSettings())
}
