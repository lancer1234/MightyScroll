import Foundation

struct MomentumState {
    private(set) var remainingX = 0.0
    private(set) var remainingY = 0.0
    var strength = 1.8
    private var timeConstant: Double { 0.12 * min(3, max(1, strength)) }

    var active: Bool { abs(remainingX) >= 0.2 || abs(remainingY) >= 0.2 }

    mutating func add(x: Double, y: Double) {
        func accumulate(_ remaining: Double, _ input: Double) -> Double {
            guard input != 0 else { return remaining }
            let old = remaining * input < 0 ? 0 : remaining
            return min(1600, max(-1600, old + input))
        }
        remainingX = accumulate(remainingX, x)
        remainingY = accumulate(remainingY, y)
    }

    mutating func advance(seconds: Double) -> (x: Double, y: Double) {
        guard seconds.isFinite, seconds > 0 else { return (0, 0) }
        let fraction = 1 - exp(-seconds / timeConstant)
        let output = (remainingX * fraction, remainingY * fraction)
        remainingX -= output.0
        remainingY -= output.1
        if abs(remainingX) < 0.2 { remainingX = 0 }
        if abs(remainingY) < 0.2 { remainingY = 0 }
        return output
    }

    mutating func stop() { remainingX = 0; remainingY = 0 }
}
