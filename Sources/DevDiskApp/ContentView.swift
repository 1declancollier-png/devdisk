import SwiftUI
import AppKit
import DevDiskCore

struct ContentView: View {
    @State private var model = ScanModel()
    @State private var expanded: Set<String> = []
    @State private var confirming = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            if model.movedToTrashBytes > 0 { trashNotice }
            Divider()
            if model.groups.isEmpty && model.isScanning {
                scanningPlaceholder
            } else if model.groups.isEmpty {
                emptyState
            } else {
                results
            }
            Divider()
            footer
        }
        .frame(minWidth: 620, minHeight: 480)
        .task { await model.startup() }
    }

    // MARK: the number — first thing on screen, before anything is asked of the user

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(SizeCalculator.human(model.total))
                    .font(.system(size: 44, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text("reclaimable")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                if model.isScanning {
                    ProgressView().controlSize(.small).padding(.leading, 4)
                }
            }
            Text("Nothing is selected. Nothing will be deleted.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
    }

    /// The honest correction to the headline number. Moving to the Trash is recoverable, which
    /// is the point — but recoverable means still on the disk, and someone runs this because
    /// their disk is full. Saying "freed" here would be a lie at the worst possible moment.
    private var trashNotice: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "trash")
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 3) {
                Text("Moved \(SizeCalculator.human(model.movedToTrashBytes)) to the Trash.")
                    .fontWeight(.medium)
                Text("That space is still on your disk. Empty the Trash to actually get it back.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Open Trash") {
                NSWorkspace.shared.open(URL(fileURLWithPath: NSHomeDirectory() + "/.Trash"))
            }
            Button {
                model.dismissTrashNotice()
            } label: {
                Image(systemName: "xmark").font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.quaternary.opacity(0.4))
    }

    // MARK: results

    private var results: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(model.groups) { group in
                    groupRow(group)
                    if expanded.contains(group.id) {
                        ForEach(Array(group.candidates.enumerated()), id: \.offset) { _, c in
                            pathRow(c)
                        }
                    }
                    Divider().opacity(0.5)
                }
                if let d = model.docker { dockerSection(d) }
            }
        }
    }

    /// Docker is report-only. It cannot be moved to the Trash, so it is never selectable and
    /// never goes through the deleter — the user runs the command themselves. See DECISIONS.md.
    private func dockerSection(_ d: DockerReport) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Docker").fontWeight(.medium)
                Spacer()
                Text(SizeCalculator.human(d.reclaimable)).monospacedDigit().foregroundStyle(.secondary)
            }
            ForEach(d.lines, id: \.type) { line in
                HStack {
                    Text(line.type).font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Text("\(SizeCalculator.human(line.reclaimable)) reclaimable of \(SizeCalculator.human(line.size))")
                        .font(.caption).foregroundStyle(.tertiary)
                }
            }
            HStack(spacing: 8) {
                Text(d.pruneCommand)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(.horizontal, 8).padding(.vertical, 5)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
                Button("Copy") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(d.pruneCommand, forType: .string)
                }
                .controlSize(.small)
            }
            Text("Docker reclaim cannot go to the Trash, so this app will not run it for you. "
                 + "Run it yourself when you are ready.")
                .font(.caption2).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private func groupRow(_ group: ScanGroup) -> some View {
        Button {
            withAnimation(.snappy(duration: 0.18)) {
                if expanded.contains(group.id) { expanded.remove(group.id) }
                else { expanded.insert(group.id) }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .rotationEffect(.degrees(expanded.contains(group.id) ? 90 : 0))
                    .frame(width: 12)
                Text(group.name)
                Text("\(group.candidates.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6).padding(.vertical, 1)
                    .background(.quaternary, in: Capsule())
                Spacer()
                Text(SizeCalculator.human(group.bytes))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 9)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    /// Every literal path, ticked one at a time. Nothing is selected by default, and there is
    /// no select-all — seeing what you are about to remove is the product.
    private func pathRow(_ c: Candidate) -> some View {
        HStack(spacing: 8) {
            Toggle(isOn: Binding(
                get: { model.isSelected(c) },
                set: { _ in model.toggle(c) }
            )) { EmptyView() }
                .toggleStyle(.checkbox)
                .labelsHidden()
            Text(abbreviate(c.url))
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
            Text(SizeCalculator.human(c.sizeBytes))
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.tertiary)
        }
        .padding(.leading, 44)
        .padding(.trailing, 20)
        .padding(.vertical, 2)
        .contentShape(.rect)
        .onTapGesture { model.toggle(c) }
    }

    private func abbreviate(_ url: URL) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return url.path.hasPrefix(home) ? "~" + url.path.dropFirst(home.count) : url.path
    }

    // MARK: states

    private var scanningPlaceholder: some View {
        VStack(spacing: 10) {
            ProgressView()
            Text("Looking through your build caches…").foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle").font(.largeTitle).foregroundStyle(.secondary)
            Text("No build caches found.").font(.headline)
            Text("Add a project folder to look for node_modules, target, .venv and friends.")
                .font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }

    private var footer: some View {
        HStack {
            Button("Add project folder…") { chooseProject() }
            Spacer()
            if let err = model.lastError {
                Text(err).font(.caption).foregroundStyle(.red).lineLimit(1)
            } else if model.selectedCount > 0 {
                Text("\(model.selectedCount) selected")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Button {
                confirming = true
            } label: {
                Text(model.selectedCount == 0
                     ? "Move to Trash"
                     : "Move \(model.selectedCount) to Trash — \(SizeCalculator.human(model.selectedBytes))")
            }
            .disabled(model.selectedCount == 0)
            .keyboardShortcut(.delete, modifiers: [.command])
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .confirmationDialog(
            "Move \(model.selectedCount) item\(model.selectedCount == 1 ? "" : "s") to the Trash?",
            isPresented: $confirming,
            titleVisibility: .visible
        ) {
            Button("Move to Trash", role: .destructive) {
                Task { await model.deleteSelected() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("\(SizeCalculator.human(model.selectedBytes)) will be moved to the Trash — "
                 + "recoverable from Finder, and still taking up disk space until you empty it.")
        }
    }

    private func chooseProject() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Scan"
        panel.message = "Pick a folder to look for build artifacts in. Only this folder is read."
        guard panel.runModal() == .OK, let url = panel.url else { return }
        Task { await model.scanProject(at: url) }
    }
}
