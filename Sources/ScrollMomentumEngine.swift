import Foundation
import CoreGraphics

final class ScrollMomentumEngine {
    static let shared = ScrollMomentumEngine()
    static let eventTag: Int64 = 0x4d4954595343524c
    private var state = MomentumState()
    private var timer: Timer?
    private var lastFrame = 0.0
    private var fractionX = 0.0
    private var fractionY = 0.0

    func accept(_ event: CGEvent) {
        let x = Double(event.getIntegerValueField(.scrollWheelEventPointDeltaAxis2))
        let y = Double(event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1))
        if x * state.remainingX < 0 { fractionX = 0 }
        if y * state.remainingY < 0 { fractionY = 0 }
        // Respond immediately, then add the remainder to the current momentum.
        emit(x: x * 0.25, y: y * 0.25)
        let gain = 1 + (min(3, max(1, state.strength)) - 1) * 0.5
        state.add(x: x * 0.75 * gain, y: y * 0.75 * gain)
        if timer == nil {
            lastFrame = ProcessInfo.processInfo.systemUptime
            let timer = Timer(timeInterval: 1.0 / 120, repeats: true) { [weak self] _ in self?.tick() }
            self.timer = timer
            CFRunLoopAddTimer(CFRunLoopGetMain(), timer, .commonModes)
        }
    }

    private func tick() {
        let now = ProcessInfo.processInfo.systemUptime
        let elapsed = now - lastFrame
        lastFrame = now
        guard elapsed < 0.25 else { stop(); return }
        let delta = state.advance(seconds: elapsed)
        emit(x: delta.x, y: delta.y)
        if !state.active { stop() }
    }

    private func emit(x: Double, y: Double) {
        fractionX += x
        fractionY += y
        let horizontal = Int32(fractionX.rounded(.towardZero))
        let vertical = Int32(fractionY.rounded(.towardZero))
        guard horizontal != 0 || vertical != 0 else { return }
        fractionX -= Double(horizontal)
        fractionY -= Double(vertical)
        // A stored scroll location pins the pointer during inertia. Sample it at emission time.
        let location = CGEvent(source: nil)?.location ?? .zero
        let flags = CGEventSource.flagsState(.combinedSessionState)
        guard let event = Self.outputEvent(x: horizontal, y: vertical, location: location, flags: flags) else { return }
        event.post(tap: .cgSessionEventTap)
    }

    static func outputEvent(x: Int32, y: Int32, location: CGPoint, flags: CGEventFlags) -> CGEvent? {
        guard let event = CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 2,
                                  wheel1: y, wheel2: x, wheel3: 0) else { return nil }
        event.flags = flags
        event.location = location
        event.setIntegerValueField(.eventSourceUserData, value: Self.eventTag)
        return event
    }

    func setStrength(_ strength: Double) { state.strength = min(3, max(1, strength)) }

    func stop() {
        timer?.invalidate()
        timer = nil
        state.stop()
        fractionX = 0
        fractionY = 0
    }
}
