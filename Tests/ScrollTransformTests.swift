import CoreGraphics
import Foundation

@main
struct ScrollTransformTests {
    static func event(continuous: Bool = false, phase: Int64 = 0, momentum: Int64 = 0) -> CGEvent {
        let e = CGEvent(scrollWheelEvent2Source: nil, units: .line, wheelCount: 2, wheel1: 3, wheel2: -2, wheel3: 0)!
        e.setIntegerValueField(.scrollWheelEventIsContinuous, value: continuous ? 1 : 0)
        e.setIntegerValueField(.scrollWheelEventScrollPhase, value: phase)
        e.setIntegerValueField(.scrollWheelEventMomentumPhase, value: momentum)
        e.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1, value: 3)
        e.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2, value: -2)
        e.setIntegerValueField(.scrollWheelEventPointDeltaAxis1, value: 30)
        e.setIntegerValueField(.scrollWheelEventPointDeltaAxis2, value: -20)
        return e
    }
    static func main() {
        let mouse = event()
        assert(ScrollTransform.apply(to: mouse, options: ScrollOptions()))
        assert(mouse.getIntegerValueField(.scrollWheelEventDeltaAxis1) == -3)
        assert(mouse.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1) == -3)
        assert(mouse.getIntegerValueField(.scrollWheelEventPointDeltaAxis1) == -30)
        assert(mouse.getIntegerValueField(.scrollWheelEventDeltaAxis2) == -2)
        let both = event()
        _ = ScrollTransform.apply(to: both, options: ScrollOptions(reverseHorizontal: true, verticalSpeed: 2, horizontalSpeed: 0.5))
        assert(both.getIntegerValueField(.scrollWheelEventDeltaAxis1) == -6)
        assert(both.getIntegerValueField(.scrollWheelEventDeltaAxis2) == 1)
        assert(both.getIntegerValueField(.scrollWheelEventPointDeltaAxis2) == 10)
        for original in [event(continuous: true), event(phase: 1), event(momentum: 1)] {
            let before = original.data!
            assert(!ScrollTransform.apply(to: original, options: ScrollOptions()))
            assert(original.data! == before, "Trackpad/phase events must remain identical")
        }
        let disabled = event()
        let before = disabled.data!
        assert(!ScrollTransform.apply(to: disabled, options: ScrollOptions(enabled: false)))
        assert(disabled.data! == before)
        let small = event()
        small.setIntegerValueField(.scrollWheelEventDeltaAxis1, value: 1)
        _ = ScrollTransform.apply(to: small, options: ScrollOptions(verticalSpeed: 0.25))
        assert(small.getIntegerValueField(.scrollWheelEventDeltaAxis1) == -1)
        let mighty = event(continuous: true)
        assert(ScrollTransform.apply(to: mighty, options: ScrollOptions(), knownMouse: true))
        assert(mighty.getIntegerValueField(.scrollWheelEventDeltaAxis1) == -3)
        assert(mighty.getIntegerValueField(.scrollWheelEventPointDeltaAxis1) == -30)
        let knownPad = event()
        let padBefore = knownPad.data!
        assert(!ScrollTransform.apply(to: knownPad, options: ScrollOptions(), knownTrackpad: true))
        assert(knownPad.data! == padBefore)
        assert(HIDBridge.classify(name: "Renamed device", acceleration: "", vendor: 1452, product: 780)?.isMouse == true)
        assert(HIDBridge.classify(name: "Apple Internal Keyboard / Trackpad", acceleration: "HIDMouseAcceleration", vendor: 1452, product: 780)?.isTrackpad == true)
        assert(HIDBridge.classify(name: "Unknown", acceleration: "", vendor: 0, product: 0) == nil)
        var slow = PulseAccelerator()
        for index in 0..<30 { slow.record(delta: 1, at: Double(index) * 0.10) }
        assert(slow.multiplier(at: 2.9, maximum: 3) == 1, "A long slow roll must stay slow")
        var fast = PulseAccelerator()
        for index in 0..<12 { fast.record(delta: 1, at: Double(index) * 0.02) }
        let fastBoost = fast.multiplier(at: 0.22, maximum: 3)
        assert(fastBoost > 2 && fastBoost <= 3)
        assert(fast.multiplier(at: 0.7, maximum: 3) == 1, "Pausing must reset acceleration")
        fast.record(delta: -1, at: 0.23)
        assert(fast.multiplier(at: 0.23, maximum: 3) == 1, "Direction reversal must reset acceleration")
        var oneLarge = PulseAccelerator()
        oneLarge.record(delta: 100, at: 0)
        assert(oneLarge.multiplier(at: 0, maximum: 6) == 1)

        let step = ScrollTransform.fixedStepEvent(from: event(continuous: true), options: ScrollOptions(), knownMouse: true, knownTrackpad: false)!
        assert(step.getIntegerValueField(.scrollWheelEventDeltaAxis1) == -2)
        assert(step.getIntegerValueField(.scrollWheelEventIsContinuous) == 0)
        let huge = event(continuous: true)
        huge.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1, value: 100)
        let hugeStep = ScrollTransform.fixedStepEvent(from: huge, options: ScrollOptions(), knownMouse: true, knownTrackpad: false)!
        assert(hugeStep.getIntegerValueField(.scrollWheelEventPointDeltaAxis1) == step.getIntegerValueField(.scrollWheelEventPointDeltaAxis1), "OS acceleration must not affect base step size")
        let boosted = ScrollTransform.fixedStepEvent(from: event(continuous: true), options: ScrollOptions(), knownMouse: true, knownTrackpad: false, verticalBoost: fastBoost)!
        assert(abs(boosted.getIntegerValueField(.scrollWheelEventPointDeltaAxis1)) > abs(step.getIntegerValueField(.scrollWheelEventPointDeltaAxis1)))
        assert(ScrollTransform.fixedStepEvent(from: event(continuous: true), options: ScrollOptions(), knownMouse: false, knownTrackpad: true) == nil)
        assert(ScrollTransform.suppressMomentum(event(momentum: 1), options: ScrollOptions(), knownMouse: true, knownTrackpad: false))
        assert(!ScrollTransform.suppressMomentum(event(momentum: 1), options: ScrollOptions(), knownMouse: false, knownTrackpad: true))

        var momentum = MomentumState()
        assert(!momentum.active)
        momentum.add(x: 0, y: 100)
        let firstFrame = momentum.advance(seconds: 1.0 / 120)
        assert(firstFrame.y > 0 && firstFrame.y < 100)
        let secondFrame = momentum.advance(seconds: 1.0 / 120)
        assert(secondFrame.y > 0, "Fast scrolling must continue between input strokes")
        let previous = momentum.remainingY
        momentum.add(x: 0, y: 100)
        assert(momentum.remainingY > previous, "New strokes must add to existing motion")
        momentum.add(x: 0, y: -20)
        assert(momentum.remainingY == -20, "Reverse input must cancel old motion")
        momentum.stop()
        assert(momentum.advance(seconds: 1.0 / 120).y == 0)
        var at30 = MomentumState(); var at120 = MomentumState()
        at30.add(x: 0, y: 300); at120.add(x: 0, y: 300)
        for _ in 0..<6 { _ = at30.advance(seconds: 1.0 / 30) }
        for _ in 0..<24 { _ = at120.advance(seconds: 1.0 / 120) }
        assert(abs(at30.remainingY - at120.remainingY) < 0.00001, "Decay must be independent of timer cadence")
        for _ in 0..<200 { _ = at120.advance(seconds: 1.0 / 120) }
        assert(!at120.active, "Momentum must settle")
        var originalInertia = MomentumState(); originalInertia.strength = 1
        var strongerInertia = MomentumState(); strongerInertia.strength = 1.8
        originalInertia.add(x: 0, y: 100); strongerInertia.add(x: 0, y: 100)
        _ = originalInertia.advance(seconds: 0.2); _ = strongerInertia.advance(seconds: 0.2)
        assert(strongerInertia.remainingY > originalInertia.remainingY, "Stronger inertia should sustain motion longer")
        let pointerA = CGPoint(x: 100, y: 200)
        let pointerB = CGPoint(x: 800, y: 500)
        let outputA = ScrollMomentumEngine.outputEvent(x: 0, y: 10, location: pointerA, flags: [])!
        let outputB = ScrollMomentumEngine.outputEvent(x: 0, y: 10, location: pointerB, flags: .maskShift)!
        assert(outputA.location == pointerA && outputB.location == pointerB, "Output must follow the live pointer, not its initial position")
        assert(outputB.flags.contains(.maskShift))
        assert(outputB.getIntegerValueField(.eventSourceUserData) == ScrollMomentumEngine.eventTag)
        print("HID compatibility available:", HIDBridge.shared.available)
        print("PASS: direction, trackpad protection, base step, slow/fast roll, reversal, pause, momentum accumulation and decay")
    }
}
