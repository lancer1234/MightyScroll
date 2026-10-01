import CoreGraphics
import Foundation
import Darwin
import IOKit

// Mighty Mouse can emit continuous scrolling; classify its HID sender before filtering.
final class HIDBridge {
    static let shared = HIDBridge()
    typealias CopyEvent = @convention(c) (UnsafeRawPointer) -> UnsafeRawPointer?
    typealias GetSender = @convention(c) (UnsafeRawPointer) -> UInt64
    typealias GetFloat = @convention(c) (UnsafeRawPointer, UInt32) -> Double
    typealias SetFloat = @convention(c) (UnsafeRawPointer, UInt32, Double) -> Void
    typealias CreateClient = @convention(c) (UnsafeRawPointer?, Int32, UnsafeRawPointer?) -> UnsafeRawPointer?
    typealias CopyService = @convention(c) (UnsafeRawPointer, UInt64) -> UnsafeRawPointer?
    typealias CopyProperty = @convention(c) (UnsafeRawPointer, UnsafeRawPointer) -> UnsafeRawPointer?
    private let copyEvent: CopyEvent?
    private let getSender: GetSender?
    private let getFloat: GetFloat?
    private let setFloat: SetFloat?
    private let copyService: CopyService?
    private let copyProperty: CopyProperty?
    private let createClient: CreateClient?
    private var client: UnsafeRawPointer?
    private var cache: [UInt64: Device] = [:]
    private var lastMiss: [UInt64: Double] = [:]
    private let scrollX: UInt32 = 6 << 16
    private let scrollY: UInt32 = (6 << 16) | 1

    struct Device {
        let name: String
        let isMouse: Bool
        let isTrackpad: Bool
    }

    final class Context {
        let event: UnsafeRawPointer
        let device: Device?
        let x: Double
        let y: Double
        init(event: UnsafeRawPointer, device: Device?, x: Double, y: Double) {
            self.event = event; self.device = device; self.x = x; self.y = y
        }
        deinit { Unmanaged<CFTypeRef>.fromOpaque(event).release() }
    }

    private init() {
        // Keep framework handles open for the process lifetime.
        _ = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_LAZY | RTLD_GLOBAL)
        _ = dlopen("/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics", RTLD_LAZY | RTLD_GLOBAL)
        func resolve<T>(_ name: String, as type: T.Type) -> T? {
            guard let address = dlsym(UnsafeMutableRawPointer(bitPattern: -2), name) else { return nil }
            return unsafeBitCast(address, to: type)
        }
        copyEvent = resolve("CGEventCopyIOHIDEvent", as: CopyEvent.self)
        getSender = resolve("IOHIDEventGetSenderID", as: GetSender.self)
        getFloat = resolve("IOHIDEventGetFloatValue", as: GetFloat.self)
        setFloat = resolve("IOHIDEventSetFloatValue", as: SetFloat.self)
        copyService = resolve("IOHIDEventSystemClientCopyServiceForRegistryID", as: CopyService.self)
        copyProperty = resolve("IOHIDServiceClientCopyProperty", as: CopyProperty.self)
        createClient = resolve("IOHIDEventSystemClientCreateWithType", as: CreateClient.self)
        client = createClient?(nil, 4, nil)
    }

    func refreshDevices() {
        cache.removeAll(keepingCapacity: true)
        lastMiss.removeAll(keepingCapacity: true)
        let replacement = createClient?(nil, 4, nil)
        if let old = client { Unmanaged<CFTypeRef>.fromOpaque(old).release() }
        client = replacement
    }

    private func registryDevice(sender: UInt64) -> Device? {
        guard sender != 0, let matching = IORegistryEntryIDMatching(sender) else { return nil }
        let entry = IOServiceGetMatchingService(kIOMainPortDefault, matching)
        guard entry != 0 else { return nil }
        defer { IOObjectRelease(entry) }
        func property(_ key: String) -> AnyObject? {
            IORegistryEntrySearchCFProperty(entry, kIOServicePlane, key as CFString,
                kCFAllocatorDefault, IOOptionBits(kIORegistryIterateRecursively | kIORegistryIterateParents))
        }
        return Self.classify(name: property("Product") as? String ?? "",
                             acceleration: property("HIDPointerAccelerationType") as? String ?? "",
                             vendor: (property("VendorID") as? NSNumber)?.intValue ?? 0,
                             product: (property("ProductID") as? NSNumber)?.intValue ?? 0)
    }

    func inspect(_ event: CGEvent) -> Context? {
        guard let raw = copyEvent?(Unmanaged.passUnretained(event).toOpaque()) else { return nil }
        let sender = getSender?(raw) ?? 0
        var device = cache[sender]
        let now = CFAbsoluteTimeGetCurrent()
        if device == nil && now - (lastMiss[sender] ?? 0) > 0.25 {
            lastMiss[sender] = now
            if let client, let service = copyService?(client, sender) {
                defer { Unmanaged<CFTypeRef>.fromOpaque(service).release() }
                func property(_ key: String) -> AnyObject? {
                    let keyRef = key as CFString
                    guard let value = copyProperty?(service, Unmanaged.passUnretained(keyRef).toOpaque()) else { return nil }
                    return Unmanaged<CFTypeRef>.fromOpaque(value).takeRetainedValue()
                }
                device = Self.classify(name: property("Product") as? String ?? "",
                                       acceleration: property("HIDPointerAccelerationType") as? String ?? "",
                                       vendor: (property("VendorID") as? NSNumber)?.intValue ?? 0,
                                       product: (property("ProductID") as? NSNumber)?.intValue ?? 0)
            }
            // A reconnected device may exist in IORegistry before the HID client sees it.
            if device == nil { device = registryDevice(sender: sender) }
            if let device { cache[sender] = device }
        }
        return Context(event: raw, device: device,
                       x: getFloat?(raw, scrollX) ?? 0, y: getFloat?(raw, scrollY) ?? 0)
    }

    static func classify(name: String, acceleration: String, vendor: Int, product: Int) -> Device? {
        let trackpad = name.localizedCaseInsensitiveContains("trackpad") ||
                       acceleration.localizedCaseInsensitiveContains("trackpad")
        let mouse = !trackpad && (name.localizedCaseInsensitiveContains("mouse") ||
                                 acceleration == "HIDMouseAcceleration" ||
                                 (vendor == 1452 && product == 780))
        guard mouse || trackpad else { return nil }
        return Device(name: name.isEmpty ? (mouse ? "滑鼠" : "觸控板") : name,
                      isMouse: mouse, isTrackpad: trackpad)
    }

    func transform(_ context: Context, options: ScrollOptions) {
        guard options.enabled else { return }
        let vertical = options.verticalSpeed * (options.reverseVertical ? -1 : 1)
        let horizontal = options.horizontalSpeed * (options.reverseHorizontal ? -1 : 1)
        if vertical != 1 { setFloat?(context.event, scrollY, context.y * vertical) }
        if horizontal != 1 { setFloat?(context.event, scrollX, context.x * horizontal) }
    }

    var available: Bool { copyEvent != nil && getSender != nil && getFloat != nil && setFloat != nil && client != nil }
}
