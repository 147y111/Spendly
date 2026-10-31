import SwiftUI
import PhotosUI

struct ChangeAvatarView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var userStore: UserStore

    private let accent = Color(hex: "7E6AD6")

    var isDark: Bool { colorScheme == .dark }
    var bg:           Color { isDark ? Color(hex: "1C1C1E") : Color(hex: "FFFAFA") }
    var cardBg:       Color { isDark ? Color(hex: "2C2C2E") : Color.white.opacity(0.85) }
    var card:         Color { isDark ? Color(hex: "2C2C2E") : Color(hex: "F7F5F5") }
    var textColor:    Color { isDark ? .white : .black.opacity(0.85) }
    var chevronColor: Color { isDark ? Color.white.opacity(0.30) : Color.black.opacity(0.30) }

    @State private var selectedImage: UIImage? = nil
    @State private var photoItem: PhotosPickerItem? = nil
    @State private var showCamera = false
    @State private var saved = false

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar(title: t("change_avatar"))
                VStack(spacing: 32) {

                    // 头像预览
                    ZStack {
                        Circle().fill(card).frame(width: 120, height: 120)
                            .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
                        if let img = selectedImage {
                            Image(uiImage: img).resizable().scaledToFill()
                                .frame(width: 120, height: 120).clipShape(Circle())
                        } else if let img = userStore.avatarImage {
                            Image(uiImage: img).resizable().scaledToFill()
                                .frame(width: 120, height: 120).clipShape(Circle())
                        } else {
                            Image(systemName: "person.fill")
                                .font(.system(size: 52, weight: .semibold)).foregroundColor(accent.opacity(0.50))
                        }
                        Circle().fill(accent).frame(width: 32, height: 32)
                            .overlay(Image(systemName: "pencil").font(.system(size: 14, weight: .semibold)).foregroundColor(.white))
                            .offset(x: 40, y: 40)
                    }
                    .padding(.top, 36)

                    VStack(spacing: 14) {
                        // 拍照 — 全屏相机
                        Button {
                            guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return }
                            showCamera = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "camera.fill").font(.system(size: 20)).foregroundColor(accent).frame(width: 28)
                                Text(t("take_photo")).font(.system(size: 18, weight: .medium)).foregroundColor(textColor)
                                Spacer()
                                Image(systemName: "chevron.right").font(.system(size: 15, weight: .semibold)).foregroundColor(chevronColor)
                            }
                            .padding(.horizontal, 16).padding(.vertical, 18)
                            .background(RoundedRectangle(cornerRadius: 16).fill(cardBg))
                            .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 6)
                        }
                        .buttonStyle(.plain)
                        .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
                        .opacity(UIImagePickerController.isSourceTypeAvailable(.camera) ? 1 : 0.45)

                        // 相册选取
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            HStack(spacing: 12) {
                                Image(systemName: "photo.on.rectangle.angled").font(.system(size: 20)).foregroundColor(accent).frame(width: 28)
                                Text(t("choose_library")).font(.system(size: 18, weight: .medium)).foregroundColor(textColor)
                                Spacer()
                                Image(systemName: "chevron.right").font(.system(size: 15, weight: .semibold)).foregroundColor(chevronColor)
                            }
                            .padding(.horizontal, 16).padding(.vertical, 18)
                            .background(RoundedRectangle(cornerRadius: 16).fill(cardBg))
                            .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 6)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 24)

                    Spacer()

                    // 保存按钮
                    Button {
                        guard let img = selectedImage else { return }
                        userStore.saveAvatar(img)
                        saved = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { dismiss() }
                    } label: {
                        HStack(spacing: 8) {
                            if saved { Image(systemName: "checkmark").font(.system(size: 16, weight: .bold)) }
                            Text(saved ? t("saved") : t("save_avatar")).font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 16)
                            .fill(selectedImage != nil ? (saved ? Color.green : accent) : accent.opacity(0.35)))
                    }
                    .disabled(selectedImage == nil || saved)
                    .animation(.easeInOut(duration: 0.2), value: saved)
                    .padding(.horizontal, 24).padding(.bottom, 110)
                }
            }
            BottomBarView(bg: bg, accent: accent, active: .profile, onHome: {}, onPlus: {}, onProfile: {})
        }
        .navigationBarHidden(true)
        .onChange(of: photoItem) { _, _ in
            Task {
                if let data = try? await photoItem?.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) { selectedImage = img }
            }
        }
        // ← fullScreenCover：全屏相机，无 popup
        .fullScreenCover(isPresented: $showCamera) {
            FullScreenCameraView(
                onCapture: { img in selectedImage = img; showCamera = false },
                onCancel:  { showCamera = false }
            )
            .ignoresSafeArea()
        }
    }

    private func topBar(title: String) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left").font(.system(size: 18, weight: .semibold)).foregroundColor(textColor)
                }
                Text(title).font(.system(size: 20, weight: .semibold)).foregroundColor(textColor)
                Spacer()
            }
            .padding(.horizontal, 18).padding(.vertical, 14)
            Divider().opacity(0.15)
        }
        .background(bg.ignoresSafeArea(edges: .top))
    }
}

#Preview { NavigationStack { ChangeAvatarView().environmentObject(UserStore()) } }
