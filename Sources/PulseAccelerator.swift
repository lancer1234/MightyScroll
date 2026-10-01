import Foundation

struct PulseAccelerator {
    private struct Sample { let time: Double; let ticks: Double }
    private var samples: [Sample] = []
    private var direction = 0.0
    private(set) var lastSampleTime: Double = -.infinity

    mutating func record(delta: Double, at time: Double) {
        guard delta.isFinite, delta != 0, time.isFinite else { return }
        let sign = delta > 0 ? 1.0 : -1.0
        if sign != direction || time - lastSampleTime > 0.30 || time < lastSampleTime {
            samples.removeAll(keepingCapacity: true)
        }
        direction = sign
        lastSampleTime = time
        samples.removeAll { time - $0.time > 0.25 }
        samples.append(Sample(time: time, ticks: min(abs(delta), 8)))
        if samples.count > 128 { samples.removeFirst(samples.count - 128) }
    }

    func multiplier(at time: Double, maximum: Double) -> Double {
        let recent = samples.filter { time >= $0.time && time - $0.time <= 0.25 }
        // A single large movement is not a burst.
        guard recent.count >= 3 else { return 1 }
        let tickRate = recent.reduce(0) { $0 + $1.ticks } / 0.25
        let progress = min(1, max(0, (tickRate - 18) / (60 - 18)))
        let maximum = min(6, max(1, maximum))
        return 1 + progress * (maximum - 1)
    }
}
