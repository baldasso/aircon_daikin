import AirconKit
import SwiftUI

struct SettingsScreen: View {
    let library: DeviceLibrary
    let panel: PanelState
    let close: () -> Void

    @State private var editing: DeviceConfig?
    @State private var browser = DeviceBrowser()
    @State private var opensAtLogin = LoginItem.isEnabled

    init(library: DeviceLibrary, panel: PanelState, close: @escaping () -> Void) {
        self.library = library
        self.panel = panel
        self.close = close
        // Settings can open straight into adding a unit picked elsewhere.
        _editing = State(initialValue: panel.addingHost.map { DeviceConfig(name: "", host: $0, key: "") })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            if let editing {
                DeviceEditor(
                    device: editing,
                    isNew: !library.devices.contains { $0.id == editing.id },
                    nearby: unaddedNearby,
                    save: { library.save($0); self.editing = nil },
                    remove: { library.remove($0); self.editing = nil }
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        savedUnits
                        nearbyUnits
                    }
                }
                .transition(.move(edge: .leading).combined(with: .opacity))
                footer
            }
        }
        .animation(Motion.settle, value: editing?.id)
        .animation(Motion.settle, value: browser.found)
        .padding(16)
        .onAppear {
            browser.start()
            panel.addingHost = nil
        }
        .onDisappear { browser.stop() }
    }

    /// Units announcing themselves on the network that haven't been added yet.
    private var unaddedNearby: [DiscoveredDevice] {
        browser.found.filter { unit in !library.devices.contains { $0.host.caseInsensitiveCompare(unit.host) == .orderedSame } }
    }

    private var title: LocalizedStringKey {
        guard let editing else { return "Units" }
        return editing.name.isEmpty ? "New unit" : "\(editing.name)"
    }

    private var header: some View {
        HStack(spacing: 6) {
            Button(action: editing == nil ? close : { editing = nil }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Ink.mist)
                    .frame(width: 30, height: 30)
                    .contentShape(Circle())
            }
            .buttonStyle(PressableStyle())
            .accessibilityLabel("Back")
            Text(title)
                .font(Typeface.title)
                .foregroundStyle(Ink.frost)
                .accessibilityAddTraits(.isHeader)
            Spacer()
        }
    }

    @ViewBuilder
    private var savedUnits: some View {
        if !library.devices.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                SectionTitle("Your units")
                ForEach(library.devices) { device in
                    Button { editing = device } label: {
                        UnitRow(title: device.name, detail: device.host, symbol: "chevron.right")
                    }
                    .buttonStyle(PressableStyle())
                }
            }
        }
        if let problem = library.problem {
            Text(problem)
                .font(Typeface.caption)
                .foregroundStyle(Accent.ember.light)
        }
    }

    private var nearbyUnits: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle("On your network")
            if unaddedNearby.isEmpty {
                Text(browser.found.isEmpty
                    ? "Looking for units… Your Mac must be on the same Wi-Fi as your air conditioners."
                    : "Every unit on this network has been added.")
                    .font(Typeface.caption)
                    .foregroundStyle(Ink.mist)
                    .fixedSize(horizontal: false, vertical: true)
            }
            ForEach(unaddedNearby) { unit in
                Button {
                    editing = DeviceConfig(name: "", host: unit.host, key: "")
                } label: {
                    UnitRow(title: unit.id, detail: String(localized: "Ready to add"), symbol: "plus")
                }
                .buttonStyle(PressableStyle())
            }
            Button {
                editing = DeviceConfig(name: "", host: "", key: "")
            } label: {
                Text("Add a unit by address")
                    .font(Typeface.label)
                    .foregroundStyle(Accent.glacier.light)
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Accent.glacier.light.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4, 4])))
            }
            .buttonStyle(PressableStyle())
        }
    }

    private var footer: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Open at login")
                    .font(Typeface.label)
                    .foregroundStyle(Ink.frost)
                Spacer()
                Toggle("Open at login", isOn: $opensAtLogin)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .tint(Accent.glacier.deep)
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 44)
            .well(radius: 14)
            .onChange(of: opensAtLogin) { _, enabled in LoginItem.setEnabled(enabled) }

            Button("Quit Aircon") { NSApp.terminate(nil) }
                .buttonStyle(SecondaryButtonStyle())

            Text("Aircon is not affiliated with or endorsed by Daikin.")
                .font(.system(size: 10.5))
                .foregroundStyle(Ink.mist.opacity(0.7))
                .frame(maxWidth: .infinity)
        }
    }
}

struct SectionTitle: View {
    let text: LocalizedStringKey

    init(_ text: LocalizedStringKey) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Ink.mist)
            .textCase(.uppercase)
            .tracking(0.6)
            .accessibilityAddTraits(.isHeader)
    }
}

private struct UnitRow: View {
    let title: String
    let detail: String
    let symbol: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "air.conditioner.horizontal")
                .font(.system(size: 15))
                .foregroundStyle(Accent.glacier.light)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Accent.glacier.deep.opacity(0.22)))
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: title)
                    .font(Typeface.label)
                    .foregroundStyle(Ink.frost)
                Text(verbatim: detail)
                    .font(.system(size: 10.5, design: .monospaced))
                    .foregroundStyle(Ink.mist)
            }
            Spacer()
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Ink.mist.opacity(0.6))
        }
        .padding(.horizontal, 12)
        .frame(height: 54)
        .well(radius: 14)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "\(title), \(detail)"))
    }
}
