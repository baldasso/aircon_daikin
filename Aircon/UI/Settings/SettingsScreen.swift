import AirconKit
import SwiftUI

struct SettingsScreen: View {
    let library: DeviceLibrary
    let close: () -> Void

    @State private var editing: DeviceConfig?
    @State private var opensAtLogin = LoginItem.isEnabled

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            if let editing {
                DeviceEditor(
                    device: editing,
                    isNew: !library.devices.contains { $0.id == editing.id },
                    save: { library.save($0); self.editing = nil },
                    remove: { library.remove($0); self.editing = nil },
                    cancel: { self.editing = nil }
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                unitList
                    .transition(.move(edge: .leading).combined(with: .opacity))
                Spacer(minLength: 0)
                footer
            }
        }
        .animation(Motion.settle, value: editing?.id)
        .padding(16)
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
            Text(editing == nil ? "Units" : (editing?.name.isEmpty == false ? editing!.name : "New unit"))
                .font(Typeface.title)
                .foregroundStyle(Ink.frost)
            Spacer()
        }
    }

    private var unitList: some View {
        VStack(spacing: 8) {
            ForEach(library.devices) { device in
                Button { editing = device } label: { UnitRow(device: device) }
                    .buttonStyle(PressableStyle())
            }
            Button {
                editing = DeviceConfig(name: "", host: "", key: "")
            } label: {
                Label("Add a unit", systemImage: "plus")
                    .font(Typeface.label)
                    .foregroundStyle(Accent.glacier.light)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Accent.glacier.light.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4, 4])))
            }
            .buttonStyle(PressableStyle())

            if let problem = library.problem {
                Text(problem)
                    .font(Typeface.caption)
                    .foregroundStyle(Accent.ember.light)
            }
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
        }
    }
}

private struct UnitRow: View {
    let device: DeviceConfig

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "air.conditioner.horizontal")
                .font(.system(size: 15))
                .foregroundStyle(Accent.glacier.light)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Accent.glacier.deep.opacity(0.22)))
            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                    .font(Typeface.label)
                    .foregroundStyle(Ink.frost)
                Text(device.host)
                    .font(.system(size: 10.5, design: .monospaced))
                    .foregroundStyle(Ink.mist)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Ink.mist.opacity(0.6))
        }
        .padding(.horizontal, 12)
        .frame(height: 54)
        .well(radius: 14)
        .contentShape(Rectangle())
    }
}
