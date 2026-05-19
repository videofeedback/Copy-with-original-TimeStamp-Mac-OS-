import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var model = CopyModel()
    @State private var isDropTargeted = false

    var body: some View {
        VStack(spacing: 0) {
            header

            HStack(spacing: 16) {
                dropZone
                sidePanel
            }
            .padding(20)

            footer
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .alert("Copy failed", isPresented: $model.showsError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(model.errorMessage)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Copy With Creation Date")
                    .font(.title2.weight(.semibold))
                Text("By Ramiro Montes De Oca")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Text("Drop images, choose a destination, and copy without losing original timestamps.")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                model.chooseDestination()
            } label: {
                Label("Choose Folder", systemImage: "folder")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(20)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var dropZone: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.stack")
                .font(.system(size: 54, weight: .light))
                .foregroundStyle(isDropTargeted ? Color.accentColor : Color.secondary)

            Text("Drop images here")
                .font(.title3.weight(.medium))

            Text("\(model.items.count) image\(model.items.count == 1 ? "" : "s") ready")
                .foregroundStyle(.secondary)

            HStack {
                Button {
                    model.chooseImages()
                } label: {
                    Label("Add Images", systemImage: "plus")
                }

                Button {
                    model.clear()
                } label: {
                    Label("Clear", systemImage: "trash")
                }
                .disabled(model.items.isEmpty)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isDropTargeted ? Color.accentColor.opacity(0.12) : Color(nsColor: .textBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isDropTargeted ? Color.accentColor : Color.secondary.opacity(0.28), style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
        )
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            model.addDroppedItems(providers)
        }
    }

    private var sidePanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    Text(model.destination?.path(percentEncoded: false) ?? "No destination selected")
                        .lineLimit(3)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(4)
            } label: {
                Label("Destination", systemImage: "folder")
            }

            GroupBox {
                if model.items.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "photo")
                            .font(.system(size: 34, weight: .light))
                            .foregroundStyle(.secondary)
                        Text("No Images")
                            .font(.headline)
                        Text("Add files with the button or drag them onto the drop area.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    }
                        .frame(height: 220)
                } else {
                    List(model.items) { item in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.url.lastPathComponent)
                                .lineLimit(1)
                            Text(item.createdDescription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                    .frame(height: 260)
                }
            } label: {
                Label("Images", systemImage: "list.bullet")
            }

            Spacer()
        }
        .frame(width: 300)
    }

    private var footer: some View {
        HStack {
            Text(model.status)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer()

            ProgressView(value: model.progress)
                .frame(width: 160)
                .opacity(model.isCopying ? 1 : 0)

            Button {
                model.copyImages()
            } label: {
                Label("Copy Images", systemImage: "doc.on.doc")
            }
            .keyboardShortcut(.defaultAction)
            .disabled(!model.canCopy)
        }
        .padding(20)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}
