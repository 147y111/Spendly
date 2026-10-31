import SwiftUI

struct AppLockGateView: View {
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var userStore: UserStore

    private let accent = Color(hex: "7E6AD6")
    var isDark: Bool { appSettings.isDarkMode }
    var bg:      Color { isDark ? Color(hex: "1C1C1E") : Color(hex: "FFFAFA") }
    var cardBg:  Color { isDark ? Color(hex: "2C2C2E") : Color(hex: "F0EEF8") }
    var textColor: Color { isDark ? .white : .black.opacity(0.85) }
    var subColor:  Color { isDark ? Color.white.opacity(0.40) : Color.black.opacity(0.40) }

    var phone: String { userStore.phone }

    @State private var pin          = ""
    @State private var pinShake     = false
    @State private var errorMsg     = ""
    @State private var attempts     = 0       // 累计错误次数
    @State private var cooldownSecs = 0       // 剩余冷却秒数
    @State private var cooldownTotal = 0      // 本轮冷却总秒数（用于进度圆环）
    @State private var countdownTimer: Timer? = nil

    // 每3次错误 → 冷却：30s → 5min → 30min
    private let cooldownStages = [30, 300, 1800]

    private var roundIndex: Int { max(0, attempts / 3 - 1) }
    private var isInCooldown: Bool { cooldownSecs > 0 }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            VStack(spacing: 36) {
                Spacer()
                headerSection
                dotsRow
                if !errorMsg.isEmpty && !isInCooldown {
                    Text(errorMsg)
                        .font(.system(size: 13)).foregroundColor(.red)
                        .transition(.opacity)
                }
                if isInCooldown { cooldownView } else { numpad }
                Spacer()
            }
        }
        .preferredColorScheme(isDark ? .dark : .light)
        .onDisappear { countdownTimer?.invalidate() }
        .animation(.easeInOut(duration: 0.25), value: isInCooldown)
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isInCooldown ? Color.orange.opacity(0.12) : accent.opacity(0.12))
                    .frame(width: 80, height: 80)
                Image(systemName: isInCooldown ? "timer" : "lock.shield.fill")
                    .font(.system(size: 36))
                    .foregroundColor(isInCooldown ? .orange : accent)
            }
            Text(isInCooldown ? t("locked_temporarily") : t("app_locked"))
                .font(.system(size: 24, weight: .bold)).foregroundColor(textColor)
            Text(isInCooldown ? t("too_many_wrong") : hintText)
                .font(.system(size: 14)).foregroundColor(isInCooldown ? .orange : subColor)
                .multilineTextAlignment(.center).padding(.horizontal, 32)
        }
    }

    private var hintText: String {
        if attempts == 0 { return t("enter_app_lock_pin") }
        let wrongThisRound = attempts % 3
        let left = wrongThisRound == 0 ? 3 : 3 - wrongThisRound
        return "\(t("wrong_pin")) · \(left) \(t("attempts_left"))"
    }

    // MARK: - Dots
    private var dotsRow: some View {
        HStack(spacing: 20) {
            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .fill(i < pin.count ? (isInCooldown ? Color.orange : accent) : cardBg)
                    .frame(width: 18, height: 18)
                    .overlay(Circle().stroke(
                        (isInCooldown ? Color.orange : accent).opacity(0.4), lineWidth: 1.5))
            }
        }
        .modifier(ShakeModifier(shake: pinShake))
    }

    // MARK: - Cooldown ring
    private var cooldownView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.orange.opacity(0.15), lineWidth: 6)
                    .frame(width: 100, height: 100)
                Circle()
                    .trim(from: 0, to: cooldownTotal > 0 ? CGFloat(cooldownSecs) / CGFloat(cooldownTotal) : 0)
                    .stroke(Color.orange, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 100, height: 100)
                    .animation(.linear(duration: 1), value: cooldownSecs)
                Text(timeString(cooldownSecs))
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(.orange)
            }
            Text(t("try_again_after"))
                .font(.system(size: 13)).foregroundColor(subColor)
        }
    }

    private func timeString(_ secs: Int) -> String {
        if secs >= 60 { return "\(secs / 60):\(String(format: "%02d", secs % 60))" }
        return "\(secs)s"
    }

    // MARK: - Numpad
    private var numpad: some View {
        let keys: [[String]] = [["1","2","3"],["4","5","6"],["7","8","9"],["","0","⌫"]]
        return VStack(spacing: 16) {
            ForEach(keys, id: \.self) { row in
                HStack(spacing: 32) {
                    ForEach(row, id: \.self) { key in
                        if key.isEmpty {
                            Circle().fill(Color.clear).frame(width: 72, height: 72)
                        } else {
                            Button { handleKey(key) } label: {
                                ZStack {
                                    Circle().fill(cardBg).frame(width: 72, height: 72)
                                    Text(key)
                                        .font(.system(size: key == "⌫" ? 22 : 26, weight: .medium))
                                        .foregroundColor(textColor)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Logic
    private func handleKey(_ key: String) {
        guard !isInCooldown else { return }
        errorMsg = ""
        if key == "⌫" {
            if !pin.isEmpty { pin.removeLast() }
        } else if pin.count < 4 {
            pin.append(key)
            if pin.count == 4 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { verify() }
            }
        }
    }

    private func verify() {
        if AppLockManager.shared.verify(pin: pin, for: phone) {
            AppLockManager.shared.unlock()
        } else {
            attempts += 1
            pin = ""
            // 震动
            withAnimation { pinShake = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { pinShake = false }

            // 每满3次进入冷却
            if attempts % 3 == 0 {
                let stage = min(attempts / 3 - 1, cooldownStages.count - 1)
                startCooldown(secs: cooldownStages[stage])
            } else {
                let wrongThisRound = attempts % 3
                let left = 3 - wrongThisRound
                errorMsg = "\(t("wrong_pin")) · \(left) \(t("attempts_left"))"
            }
        }
    }

    private func startCooldown(secs: Int) {
        cooldownSecs  = secs
        cooldownTotal = secs
        errorMsg = ""
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if cooldownSecs > 0 {
                cooldownSecs -= 1
            } else {
                countdownTimer?.invalidate()
            }
        }
    }
}
