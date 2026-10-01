import AppKit
import SwiftUI
import ApplicationServices
import ServiceManagement
import Carbon

final class ScrollController: ObservableObject {
    @Published var enabled: Bool { didSet { save() } }
    @Published var reverseVertical: Bool { didSet { save() } }
    @Published var reverseHorizontal: Bool { didSet { save() } }
    @Published var verticalSpeed: Double { didSet { save() } }
    @Published var horizontalSpeed: Double { didSet { save() } }
    @Published var accelerate: Bool { didSet { save() } }
    @Published var accelerationStrength: Double { didSet { save() } }
    @Published var inertia: Bool { didSet { save() } }
    @Published var inertiaStrength: Double { didSet { save() } }
    @Published var loginEnabled = false
    @Published var loginApprovalNeeded = false
    @Published var loginError: String?
    @Published var verticalStep: Double { didSet { save() } }
    @Published var horizontalStep: Double { didSet { save() } }
    @Published var running = false
    @Published var status = "尚未啟動"
    @Published var lastInput = "尚無捲動輸入"
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    private var timer: Timer?
    private var pendingInput = ""
    private var wakeObserver: NSObjectProtocol?

    init() {
        let d = UserDefaults.standard
        d.register(defaults: ["enabled": true, "reverseVertical": true, "reverseHorizontal": false,
                              "verticalSpeed": 1.0, "horizontalSpeed": 1.0, "accelerate": true, "accelerationStrength": 3.0, "inertia": true, "inertiaStrength": 1.8, "verticalStep": 2.0, "horizontalStep": 2.0])
        enabled = d.bool(forKey: "enabled")
        reverseVertical = d.bool(forKey: "reverseVertical")
        reverseHorizontal = d.bool(forKey: "reverseHorizontal")
        verticalSpeed = min(3, max(0.25, d.double(forKey: "verticalSpeed")))
        horizontalSpeed = min(3, max(0.25, d.double(forKey: "horizontalSpeed")))
        accelerate = d.bool(forKey: "accelerate")
        inertia = d.bool(forKey: "inertia")
        inertiaStrength = min(3, max(1, d.double(forKey: "inertiaStrength")))
        accelerationStrength = min(6, max(1, d.double(forKey: "accelerationStrength")))
        _ = RawWheelMonitor.shared
        verticalStep = min(12, max(1, d.double(forKey: "verticalStep")))
        horizontalStep = min(12, max(1, d.double(forKey: "horizontalStep")))
        ScrollMomentumEngine.shared.setStrength(inertiaStrength)
        RawWheelMonitor.shared.onDevicesChanged = { [weak self] in self?.restartScrollTap() }
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { _ in
                RawWheelMonitor.shared.refreshAfterWake()
            }
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self else { return }
            if !self.pendingInput.isEmpty && self.lastInput != self.pendingInput {
                self.lastInput = self.pendingInput
            }
            if self.loginApprovalNeeded { self.refreshLoginStatus() }
            let trusted = AXIsProcessTrusted()
            if self.tap != nil && !trusted {
                if let tap = self.tap { CGEvent.tapEnable(tap: tap, enable: false) }
                if let source = self.source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
                self.tap = nil
                self.source = nil
                self.running = false
                ScrollMomentumEngine.shared.stop()
                self.status = "輔助使用授權已關閉，請重新授權。"
            }
            if let tap = self.tap, trusted, !CGEvent.tapIsEnabled(tap: tap) {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            if self.tap == nil && trusted { self.start() }
        }
    }

    var options: ScrollOptions {
        ScrollOptions(enabled: enabled, reverseVertical: reverseVertical,
                      reverseHorizontal: reverseHorizontal, verticalSpeed: verticalSpeed,
                      horizontalSpeed: horizontalSpeed, fixedStep: true, verticalStep: verticalStep, horizontalStep: horizontalStep, accelerate: accelerate, accelerationStrength: accelerationStrength)
    }

    private func save() {
        let d = UserDefaults.standard
        d.set(enabled, forKey: "enabled")
        d.set(reverseVertical, forKey: "reverseVertical")
        d.set(reverseHorizontal, forKey: "reverseHorizontal")
        d.set(verticalSpeed, forKey: "verticalSpeed")
        d.set(horizontalSpeed, forKey: "horizontalSpeed")
        d.set(accelerate, forKey: "accelerate")
        d.set(inertia, forKey: "inertia")
        d.set(inertiaStrength, forKey: "inertiaStrength")
        ScrollMomentumEngine.shared.setStrength(inertiaStrength)
        if !enabled || !accelerate || !inertia { ScrollMomentumEngine.shared.stop() }
        d.set(accelerationStrength, forKey: "accelerationStrength")
        d.set(verticalStep, forKey: "verticalStep")
        d.set(horizontalStep, forKey: "horizontalStep")
    }

    func refreshLoginStatus() {
        let status = SMAppService.mainApp.status
        loginEnabled = status == .enabled || status == .requiresApproval
        loginApprovalNeeded = status == .requiresApproval
        if status == .enabled { loginError = nil }
    }

    func configureLoginIfNeeded() {
        refreshLoginStatus()
        let d = UserDefaults.standard
        if Bundle.main.bundlePath.hasPrefix("/Applications/"), !d.bool(forKey: "loginConfigured") {
            setLoginEnabled(true)
        }
    }

    func setLoginEnabled(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled && SMAppService.mainApp.status != .requiresApproval {
                    try SMAppService.mainApp.register()
                }
            } else {
                try SMAppService.mainApp.unregister()
            }
            UserDefaults.standard.set(true, forKey: "loginConfigured")
            loginError = nil
        } catch {
            loginError = error.localizedDescription
        }
        refreshLoginStatus()
    }

    func requestPermission() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        _ = AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
        start()
    }

    private func restartScrollTap() {
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
        }
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        tap = nil
        source = nil
        running = false
        pendingInput = ""
        lastInput = "等待滑鼠輸入"
        if AXIsProcessTrusted() { start() }
    }

    func start() {
        guard tap == nil else { return }
        guard AXIsProcessTrusted() else {
            status = "請授權輔助使用，才能調整滑鼠捲動。"
            return
        }
        let mask = CGEventMask(1) << CGEventType.scrollWheel.rawValue
        tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap,
            options: .defaultTap, eventsOfInterest: mask,
            callback: { _, type, event, pointer in
                guard let pointer else { return Unmanaged.passUnretained(event) }
                let controller = Unmanaged<ScrollController>.fromOpaque(pointer).takeUnretainedValue()
                if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                    if let tap = controller.tap { CGEvent.tapEnable(tap: tap, enable: true) }
                    return Unmanaged.passUnretained(event)
                }
                guard type == .scrollWheel else { return Unmanaged.passUnretained(event) }
                if event.getIntegerValueField(.eventSourceUserData) == ScrollMomentumEngine.eventTag {
                    return Unmanaged.passUnretained(event)
                }
                let context = HIDBridge.shared.inspect(event)
                let device = context?.device
                let isMouse = device?.isMouse ?? false
                let isTrackpad = device?.isTrackpad ?? false
                if isTrackpad { ScrollMomentumEngine.shared.stop() }
                let options = controller.options
                if ScrollTransform.suppressMomentum(event, options: options, knownMouse: isMouse, knownTrackpad: isTrackpad) {
                    return nil
                }
                let movementY = context?.y ?? event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1)
                let movementX = context?.x ?? event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2)
                let boosts = !isTrackpad && options.enabled && options.accelerate
                    ? RawWheelMonitor.shared.multipliers(name: device?.name ?? "一般滑鼠", vertical: movementY,
                        horizontal: movementX, maximum: options.accelerationStrength)
                    : (1.0, 1.0)
                if let replacement = ScrollTransform.fixedStepEvent(from: event, options: options,
                    knownMouse: isMouse, knownTrackpad: isTrackpad,
                    hardwareX: context?.x ?? 0, hardwareY: context?.y ?? 0, verticalBoost: boosts.0, horizontalBoost: boosts.1) {
                    controller.pendingInput = "\(device?.name ?? "滑鼠")：已套用捲動設定"
                    let fastVertical = replacement.getIntegerValueField(.scrollWheelEventPointDeltaAxis1) != 0 && boosts.0 > 1.1
                    let fastHorizontal = replacement.getIntegerValueField(.scrollWheelEventPointDeltaAxis2) != 0 && boosts.1 > 1.1
                    if controller.inertia && (fastVertical || fastHorizontal) {
                        ScrollMomentumEngine.shared.accept(replacement)
                        return nil
                    }
                    ScrollMomentumEngine.shared.stop()
                    replacement.location = CGEvent(source: nil)?.location ?? event.location
                    return Unmanaged.passRetained(replacement)
                }
                let changed = ScrollTransform.apply(to: event, options: controller.options,
                                                    knownMouse: isMouse, knownTrackpad: isTrackpad)
                if changed, let context { HIDBridge.shared.transform(context, options: controller.options) }
                let name = device?.name ?? "未辨識裝置"
                if changed {
                    controller.pendingInput = "\(name)：已套用滑鼠捲動設定"
                } else if isTrackpad {
                    controller.pendingInput = "\(name)：保留觸控板方向"
                } else if !controller.enabled {
                    controller.pendingInput = "\(name)：已暫停調整"
                } else {
                    controller.pendingInput = "\(name)：連續捲動，等待確認來源"
                }
                return Unmanaged.passUnretained(event)
            }, userInfo: Unmanaged.passUnretained(self).toOpaque())
        guard let tap else {
            status = "無法啟動。請確認輔助使用授權後重試；若系統要求輸入監控，也請允許。"
            return
        }
        source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        if let source { CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes) }
        CGEvent.tapEnable(tap: tap, enable: true)
        running = true
        status = "已啟動 · 觸控板維持系統設定"
    }

    func reset() {
        reverseVertical = true
        reverseHorizontal = false
        verticalSpeed = 1
        horizontalSpeed = 1
        accelerate = true
        inertia = true
        inertiaStrength = 1.8
        accelerationStrength = 3
        verticalStep = 2
        horizontalStep = 2
    }
}

struct SettingsView: View {
    @ObservedObject var controller: ScrollController
    @State private var showDetails = false
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                Image(systemName: "computermouse.fill")
                    .font(.system(size: 32, weight: .regular))
                    .foregroundStyle(.white)
                    .frame(width: 64, height: 64)
                    .background(.blue.gradient, in: RoundedRectangle(cornerRadius: 16))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 5) {
                    Text("MightyScroll").font(.system(size: 24, weight: .semibold))
                }
                Spacer()
            }.padding(.horizontal, 28).padding(.top, 24).padding(.bottom, 18)

            Form {
                Section {
                    Toggle(isOn: $controller.enabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("調整滑鼠捲動").fontWeight(.medium)
                        }
                    }.toggleStyle(.switch)
                    Toggle("快速連滾加速", isOn: $controller.accelerate)
                        .toggleStyle(.switch).disabled(!controller.enabled)
                    if controller.accelerate {
                        Toggle("連滾慣性", isOn: $controller.inertia)
                            .toggleStyle(.switch).disabled(!controller.enabled)
                        if controller.inertia {
                            HStack(spacing: 12) {
                                Text("慣性強度")
                                Slider(value: $controller.inertiaStrength, in: 1...3, step: 0.2)
                                    .accessibilityLabel("慣性強度")
                                Text(String(format: "%.1f×", controller.inertiaStrength))
                                    .monospacedDigit().foregroundStyle(.secondary).frame(width: 52, alignment: .trailing)
                            }.disabled(!controller.enabled)
                        }
                        HStack(spacing: 12) {
                            Text("加速上限")
                            Slider(value: $controller.accelerationStrength, in: 1...6, step: 0.5)
                                .accessibilityLabel("加速上限")
                            Text(String(format: "%.1f×", controller.accelerationStrength))
                                .monospacedDigit().foregroundStyle(.secondary).frame(width: 52, alignment: .trailing)
                        }.disabled(!controller.enabled)
                    }
                }
                Section("上下捲動") {
                    Toggle("反轉方向", isOn: $controller.reverseVertical).toggleStyle(.switch)
                    stepRow(value: $controller.verticalStep, axis: "上下")
                }.disabled(!controller.enabled)
                Section("左右捲動") {
                    Toggle("反轉方向", isOn: $controller.reverseHorizontal).toggleStyle(.switch)
                    stepRow(value: $controller.horizontalStep, axis: "左右")
                }.disabled(!controller.enabled)
                Section {
                    Toggle("登入時啟動", isOn: Binding(get: { controller.loginEnabled }, set: { controller.setLoginEnabled($0) }))
                        .toggleStyle(.switch)
                    if controller.loginApprovalNeeded {
                        Button("確認登入項目…") { SMAppService.openSystemSettingsLoginItems() }
                    }
                    if let error = controller.loginError {
                        Text(error).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Section {
                    HStack(spacing: 8) {
                        Circle().fill(controller.running ? Color.green : Color.orange).frame(width: 7, height: 7)
                        Text(controller.running ? (controller.enabled ? "正在執行" : "已暫停") : "需要輔助使用權限")
                        Spacer()
                        if !controller.running {
                            Button("授權…") { controller.requestPermission() }
                        }
                    }
                    if !controller.running {
                        Text(controller.status).font(.caption).foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    DisclosureGroup("辨識資訊", isExpanded: $showDetails) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(controller.lastInput)
                        }.font(.caption).padding(.vertical, 6)
                    }
                }
            }.formStyle(.grouped)
            HStack {
                Button("恢復預設") { controller.reset() }
                    .help("恢復預設方向與每次 2 行")
                Spacer()
            }.padding(.horizontal, 24).padding(.vertical, 16)
        }
        .frame(width: 480, height: 720)
        .background(Color(nsColor: .windowBackgroundColor))
    }
    private func stepRow(value: Binding<Double>, axis: String) -> some View {
        HStack(spacing: 12) {
            Text("基本行數")
            Slider(value: value, in: 1...12, step: 1)
                .accessibilityLabel("\(axis)基本行數")
                .accessibilityValue("\(Int(value.wrappedValue)) 行")
            Text("\(Int(value.wrappedValue)) 行")
                .font(.callout).monospacedDigit().foregroundStyle(.secondary)
                .frame(width: 52, alignment: .trailing)
        }
    }

}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let controller = ScrollController()
    private var item: NSStatusItem!
    private var window: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "computermouse", accessibilityDescription: "MightyScroll")
        let menu = NSMenu()
        let settings = NSMenuItem(title: "MightyScroll 設定…", action: #selector(showSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)
        let pause = NSMenuItem(title: "啟用／暫停", action: #selector(toggleEnabled), keyEquivalent: "")
        pause.target = self
        menu.addItem(pause)
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "結束 MightyScroll", action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        item.menu = menu
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 480, height: 720),
                          styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        window.title = "MightyScroll"
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: SettingsView(controller: controller))
        window.center()
        controller.start()
        controller.configureLoginIfNeeded()
        let properties = NSAppleEventManager.shared().currentAppleEvent?.paramDescriptor(forKeyword: AEKeyword(keyAEPropData))
        let loginLaunch = properties?.forKeyword(AEKeyword(keyAELaunchedAsLogInItem))?.booleanValue ?? false
        if !loginLaunch { showSettings() }
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettings()
        return true
    }
    @objc private func showSettings() {
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
    @objc private func toggleEnabled() { controller.enabled.toggle() }
    @objc private func quitApp() { NSApp.terminate(nil) }
}

@main
struct MightyScrollApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        withExtendedLifetime(delegate) { app.run() }
    }
}
