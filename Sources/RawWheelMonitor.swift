import Foundation
import IOKit.hid

// Trackpad input must not affect mouse acceleration.
final class RawWheelMonitor {
    static let shared = RawWheelMonitor()
    var onDevicesChanged: (() -> Void)?
    private let manager: IOHIDManager
    private var devices: [String: (vertical: PulseAccelerator, horizontal: PulseAccelerator)] = [:]
    private var fallback: [String: (vertical: PulseAccelerator, horizontal: PulseAccelerator)] = [:]

    private init() {
        manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        IOHIDManagerSetDeviceMatching(manager, [kIOHIDDeviceUsagePageKey: 1, kIOHIDDeviceUsageKey: 2] as CFDictionary)
        let lifecycle: IOHIDDeviceCallback = { context, _, _, _ in
            guard let context else { return }
            Unmanaged<RawWheelMonitor>.fromOpaque(context).takeUnretainedValue().devicesChanged()
        }
        IOHIDManagerRegisterDeviceMatchingCallback(manager, lifecycle, Unmanaged.passUnretained(self).toOpaque())
        IOHIDManagerRegisterDeviceRemovalCallback(manager, lifecycle, Unmanaged.passUnretained(self).toOpaque())
        IOHIDManagerRegisterInputValueCallback(manager, { context, result, _, value in
            guard result == kIOReturnSuccess, let context else { return }
            Unmanaged<RawWheelMonitor>.fromOpaque(context).takeUnretainedValue().receive(value)
        }, Unmanaged.passUnretained(self).toOpaque())
        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
        _ = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
    }

    private func devicesChanged() {
        devices.removeAll(keepingCapacity: true)
        fallback.removeAll(keepingCapacity: true)
        HIDBridge.shared.refreshDevices()
        ScrollMomentumEngine.shared.stop()
        onDevicesChanged?()
    }

    func refreshAfterWake() {
        _ = IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        _ = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        devicesChanged()
    }

    private func receive(_ value: IOHIDValue) {
        let element = IOHIDValueGetElement(value)
        let page = IOHIDElementGetUsagePage(element)
        let usage = IOHIDElementGetUsage(element)
        let vertical = page == 1 && usage == 0x38
        let horizontal = page == 0x0c && usage == 0x238
        guard vertical || horizontal, IOHIDElementIsRelative(element) else { return }
        let device = IOHIDElementGetDevice(element)
        let name = IOHIDDeviceGetProperty(device, kIOHIDProductKey as CFString) as? String ?? ""
        let vendor = (IOHIDDeviceGetProperty(device, kIOHIDVendorIDKey as CFString) as? NSNumber)?.intValue ?? 0
        let product = (IOHIDDeviceGetProperty(device, kIOHIDProductIDKey as CFString) as? NSNumber)?.intValue ?? 0
        let acceleration = IOHIDDeviceGetProperty(device, "HIDPointerAccelerationType" as CFString) as? String ?? ""
        guard let identity = HIDBridge.classify(name: name, acceleration: acceleration, vendor: vendor, product: product), identity.isMouse else { return }
        let delta = Double(IOHIDValueGetIntegerValue(value))
        guard delta != 0 else { return }
        let now = ProcessInfo.processInfo.systemUptime
        var history = devices[identity.name] ?? (PulseAccelerator(), PulseAccelerator())
        if vertical { history.vertical.record(delta: delta, at: now) }
        else { history.horizontal.record(delta: delta, at: now) }
        devices[identity.name] = history
    }

    func multipliers(name: String, vertical: Double, horizontal: Double, maximum: Double) -> (Double, Double) {
        let now = ProcessInfo.processInfo.systemUptime
        var estimated = fallback[name] ?? (PulseAccelerator(), PulseAccelerator())
        if vertical != 0 { estimated.vertical.record(delta: vertical > 0 ? 1 : -1, at: now) }
        if horizontal != 0 { estimated.horizontal.record(delta: horizontal > 0 ? 1 : -1, at: now) }
        fallback[name] = estimated
        let hardware = devices[name]
        let y = hardware.map { now - $0.vertical.lastSampleTime <= 0.30 ? $0.vertical : estimated.vertical } ?? estimated.vertical
        let x = hardware.map { now - $0.horizontal.lastSampleTime <= 0.30 ? $0.horizontal : estimated.horizontal } ?? estimated.horizontal
        return (y.multiplier(at: now, maximum: maximum), x.multiplier(at: now, maximum: maximum))
    }
}
