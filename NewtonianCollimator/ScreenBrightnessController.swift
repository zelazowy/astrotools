import SwiftUI
import UIKit

final class ScreenBrightnessController: ObservableObject {
    private var originalBrightness: CGFloat?
    private var isActive = false
    private var targetBrightness: CGFloat = UIScreen.main.brightness
    private var timer: Timer?

    func activate(brightness: Double) {
        targetBrightness = CGFloat(brightness)

        if originalBrightness == nil {
            originalBrightness = UIScreen.main.brightness
        }

        isActive = true
        UIApplication.shared.isIdleTimerDisabled = true
        applyBrightness()
        startTimerIfNeeded()
    }

    func deactivate() {
        guard isActive || originalBrightness != nil else {
            return
        }

        isActive = false
        UIApplication.shared.isIdleTimerDisabled = false
        timer?.invalidate()
        timer = nil

        if let originalBrightness {
            UIScreen.main.brightness = originalBrightness
        }

        originalBrightness = nil
    }

    private func startTimerIfNeeded() {
        guard timer == nil else {
            return
        }

        timer = Timer.scheduledTimer(withTimeInterval: 0.75, repeats: true) { [weak self] _ in
            self?.applyBrightness()
        }
    }

    private func applyBrightness() {
        guard isActive else {
            return
        }

        UIScreen.main.brightness = targetBrightness
    }
}
