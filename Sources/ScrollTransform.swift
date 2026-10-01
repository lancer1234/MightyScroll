import CoreGraphics

struct ScrollOptions {
    var enabled = true
    var reverseVertical = true
    var reverseHorizontal = false
    var verticalSpeed = 1.0
    var horizontalSpeed = 1.0
    var fixedStep = true
    var verticalStep = 2.0
    var horizontalStep = 2.0
    var accelerate = true
    var accelerationStrength = 3.0
}

enum ScrollTransform {
    static func eligible(_ event: CGEvent, options: ScrollOptions, knownMouse: Bool, knownTrackpad: Bool) -> Bool {
        guard options.enabled, !knownTrackpad else { return false }
        if knownMouse { return true }
        return event.getIntegerValueField(.scrollWheelEventIsContinuous) == 0 &&
               event.getIntegerValueField(.scrollWheelEventScrollPhase) == 0 &&
               event.getIntegerValueField(.scrollWheelEventMomentumPhase) == 0
    }

    static func suppressMomentum(_ event: CGEvent, options: ScrollOptions, knownMouse: Bool, knownTrackpad: Bool) -> Bool {
        options.fixedStep && eligible(event, options: options, knownMouse: knownMouse, knownTrackpad: knownTrackpad) &&
        event.getIntegerValueField(.scrollWheelEventMomentumPhase) != 0
    }

    // Replace the HID payload to avoid reusing macOS acceleration.
    static func fixedStepEvent(from original: CGEvent, options: ScrollOptions,
                               knownMouse: Bool, knownTrackpad: Bool,
                               hardwareX: Double = 0, hardwareY: Double = 0, verticalBoost: Double = 1, horizontalBoost: Double = 1) -> CGEvent? {
        guard options.fixedStep,
              eligible(original, options: options, knownMouse: knownMouse, knownTrackpad: knownTrackpad),
              !suppressMomentum(original, options: options, knownMouse: knownMouse, knownTrackpad: knownTrackpad) else { return nil }
        func direction(_ fixed: CGEventField, _ point: CGEventField, _ line: CGEventField, hardware: Double) -> Double {
            let candidates = [original.getDoubleValueField(fixed),
                              Double(original.getIntegerValueField(point)),
                              Double(original.getIntegerValueField(line)), hardware]
            guard let value = candidates.first(where: { $0 != 0 }) else { return 0 }
            return value > 0 ? 1 : -1
        }
        let y = direction(.scrollWheelEventFixedPtDeltaAxis1, .scrollWheelEventPointDeltaAxis1,
                          .scrollWheelEventDeltaAxis1, hardware: hardwareY)
        let x = direction(.scrollWheelEventFixedPtDeltaAxis2, .scrollWheelEventPointDeltaAxis2,
                          .scrollWheelEventDeltaAxis2, hardware: hardwareX)
        guard y != 0 || x != 0 else { return nil }
        let vertical = Int32(y * min(72, max(1, (options.verticalStep * (options.accelerate ? verticalBoost : 1)).rounded())) * (options.reverseVertical ? -1 : 1))
        let horizontal = Int32(x * min(72, max(1, (options.horizontalStep * (options.accelerate ? horizontalBoost : 1)).rounded())) * (options.reverseHorizontal ? -1 : 1))
        guard let replacement = CGEvent(scrollWheelEvent2Source: nil, units: .line, wheelCount: 2,
                                        wheel1: vertical, wheel2: horizontal, wheel3: 0) else { return nil }
        replacement.flags = original.flags
        replacement.timestamp = original.timestamp
        replacement.location = original.location
        return replacement
    }

    static func apply(to event: CGEvent, options: ScrollOptions, knownMouse: Bool = false, knownTrackpad: Bool = false) -> Bool {
        guard eligible(event, options: options, knownMouse: knownMouse, knownTrackpad: knownTrackpad) else { return false }
        let axes: [(CGEventField, CGEventField, CGEventField, Double)] = [
            (.scrollWheelEventDeltaAxis1, .scrollWheelEventFixedPtDeltaAxis1,
             .scrollWheelEventPointDeltaAxis1, options.verticalSpeed * (options.reverseVertical ? -1 : 1)),
            (.scrollWheelEventDeltaAxis2, .scrollWheelEventFixedPtDeltaAxis2,
             .scrollWheelEventPointDeltaAxis2, options.horizontalSpeed * (options.reverseHorizontal ? -1 : 1))
        ]
        for (line, fixed, point, factor) in axes {
            guard factor != 1 else { continue }
            // macOS couples these fields: snapshot first, then set line, fixed, point.
            let originalLine = event.getIntegerValueField(line)
            let originalFixed = event.getDoubleValueField(fixed)
            let originalPoint = event.getIntegerValueField(point)
            func scaled(_ original: Int64) -> Int64 {
                var value = Int64((Double(original) * factor).rounded())
                if value == 0 && original != 0 { value = (Double(original) * factor) > 0 ? 1 : -1 }
                return value
            }
            event.setIntegerValueField(line, value: scaled(originalLine))
            event.setDoubleValueField(fixed, value: originalFixed * factor)
            event.setIntegerValueField(point, value: scaled(originalPoint))
        }
        return true
    }
}
